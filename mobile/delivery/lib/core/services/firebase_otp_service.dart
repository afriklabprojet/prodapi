import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/validators.dart';

/// États possibles de la vérification OTP Firebase
enum FirebaseOtpState { initial, codeSent, verifying, verified, error, timeout }

/// Résultat de la vérification OTP Firebase
class FirebaseOtpResult {
  final bool success;
  final String? errorMessage;
  final String? firebaseUid;
  final String? phoneNumber;

  FirebaseOtpResult({
    required this.success,
    this.errorMessage,
    this.firebaseUid,
    this.phoneNumber,
  });

  factory FirebaseOtpResult.success({
    String? firebaseUid,
    String? phoneNumber,
  }) => FirebaseOtpResult(
    success: true,
    firebaseUid: firebaseUid,
    phoneNumber: phoneNumber,
  );

  factory FirebaseOtpResult.error(String message) =>
      FirebaseOtpResult(success: false, errorMessage: message);
}

/// Service OTP via Firebase Phone Auth pour l'app livreur.
///
/// Utilise `verifyPhoneNumber` de Firebase Auth pour envoyer un SMS
/// et `signInWithCredential` pour vérifier le code.
/// Supporte l'auto-retrieval sur Android.
class FirebaseOtpService {
  final FirebaseAuth _auth;

  String? _verificationId;
  int? _resendToken;

  /// Callback sur changement d'état
  void Function(FirebaseOtpState state, {String? error})? onStateChanged;

  /// Callback appelé quand le SMS est auto-récupéré (Android)
  void Function(String smsCode)? onSmsCodeAutoRetrieved;

  FirebaseOtpService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  bool get hasVerificationId => _verificationId != null;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Envoie un code OTP au numéro de téléphone via Firebase Phone Auth.
  /// Le numéro est normalisé au format E.164 (+225...).
  Future<void> sendOtp({
    required String phoneNumber,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      onStateChanged?.call(FirebaseOtpState.initial);

      final normalizedPhone = Validators.normalizePhone(phoneNumber);
      if (kDebugMode) {
        debugPrint(
          '[FirebaseOTP] Envoi SMS à $normalizedPhone (original: $phoneNumber)',
        );
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        timeout: timeout,

        codeSent: (String verificationId, int? resendToken) {
          if (kDebugMode) {
            debugPrint('[FirebaseOTP] Code envoyé à $normalizedPhone');
          }
          _verificationId = verificationId;
          _resendToken = resendToken;
          onStateChanged?.call(FirebaseOtpState.codeSent);
        },

        verificationCompleted: (PhoneAuthCredential credential) async {
          if (kDebugMode) {
            debugPrint('[FirebaseOTP] Auto-vérification complétée');
          }
          final smsCode = credential.smsCode;
          if (smsCode != null) {
            onSmsCodeAutoRetrieved?.call(smsCode);
          }
          try {
            await _auth.signInWithCredential(credential);
            onStateChanged?.call(FirebaseOtpState.verified);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[FirebaseOTP] Erreur auto-sign in: $e');
            }
            onStateChanged?.call(FirebaseOtpState.error, error: e.toString());
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) {
            debugPrint(
              '[FirebaseOTP] Échec: code=${e.code}, message=${e.message}',
            );
          }
          onStateChanged?.call(
            FirebaseOtpState.error,
            error: _getErrorMessage(e),
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          if (kDebugMode) {
            debugPrint('[FirebaseOTP] Timeout auto-retrieval');
          }
          _verificationId = verificationId;
          onStateChanged?.call(FirebaseOtpState.timeout);
        },

        forceResendingToken: _resendToken,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirebaseOTP] Erreur sendOtp: $e');
      }
      onStateChanged?.call(FirebaseOtpState.error, error: e.toString());
    }
  }

  /// Vérifie le code OTP saisi par l'utilisateur
  Future<FirebaseOtpResult> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      return FirebaseOtpResult.error(
        'Aucun code n\'a été envoyé. Veuillez réessayer.',
      );
    }

    try {
      onStateChanged?.call(FirebaseOtpState.verifying);

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);

      if (kDebugMode) {
        debugPrint('[FirebaseOTP] Vérifié: uid=${userCredential.user?.uid}');
      }
      onStateChanged?.call(FirebaseOtpState.verified);

      return FirebaseOtpResult.success(
        firebaseUid: userCredential.user?.uid,
        phoneNumber: userCredential.user?.phoneNumber,
      );
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('[FirebaseOTP] Erreur vérification: ${e.code}');
      }
      final msg = _getErrorMessage(e);
      onStateChanged?.call(FirebaseOtpState.error, error: msg);
      return FirebaseOtpResult.error(msg);
    } catch (e) {
      onStateChanged?.call(FirebaseOtpState.error, error: e.toString());
      return FirebaseOtpResult.error(
        'Une erreur est survenue. Veuillez réessayer.',
      );
    }
  }

  /// Renvoie le code OTP
  Future<void> resendOtp({
    required String phoneNumber,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await sendOtp(phoneNumber: phoneNumber, timeout: timeout);
  }

  /// Réinitialiser l'état
  void reset() {
    _verificationId = null;
    _resendToken = null;
    onStateChanged = null;
    onSmsCodeAutoRetrieved = null;
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide. Vérifiez le format.';
      case 'too-many-requests':
        return 'Trop de demandes. Veuillez patienter 5 à 15 minutes.';
      case 'invalid-verification-code':
        return 'Code invalide. Vérifiez et réessayez.';
      case 'session-expired':
        return 'Session expirée. Veuillez demander un nouveau code.';
      case 'quota-exceeded':
        return 'Service SMS temporairement indisponible (quota atteint). '
            'Réessayez dans 1h.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion internet.';
      case 'app-not-authorized':
      case 'app-not-verified':
      case 'missing-client-identifier':
        return 'Configuration incomplète. Contactez le support.';
      case 'captcha-check-failed':
        return 'Vérification de sécurité échouée. Réessayez.';
      default:
        final msg = e.message ?? '';
        if (msg.contains('Error code: 39') ||
            msg.contains('MISSING_CLIENT_IDENTIFIER')) {
          return 'Certificat non reconnu. Réinstallez l\'application.';
        }
        return msg.isNotEmpty ? msg : 'Une erreur est survenue.';
    }
  }
}

/// Provider Riverpod pour le service Firebase OTP
final firebaseOtpServiceProvider = Provider<FirebaseOtpService>((ref) {
  return FirebaseOtpService();
});
