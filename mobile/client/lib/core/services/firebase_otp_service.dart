import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../extensions/extensions.dart';
import 'app_logger.dart';

/// États possibles de la vérification OTP Firebase
enum FirebaseOtpState { initial, codeSent, verifying, verified, error, timeout }

/// Résultat de la vérification OTP
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
  }) {
    return FirebaseOtpResult(
      success: true,
      firebaseUid: firebaseUid,
      phoneNumber: phoneNumber,
    );
  }

  factory FirebaseOtpResult.error(String message) {
    return FirebaseOtpResult(success: false, errorMessage: message);
  }
}

/// Service pour gérer l'authentification OTP via Firebase Phone Auth
class FirebaseOtpService {
  final FirebaseAuth _auth;

  String? _verificationId;
  int? _resendToken;

  // Callbacks pour notifier l'UI
  void Function(FirebaseOtpState state, {String? error})? onStateChanged;
  void Function()? onCodeAutoRetrieved;

  /// Callback appelé quand le SMS est auto-récupéré avec le code
  void Function(String smsCode)? onSmsCodeAutoRetrieved;

  FirebaseOtpService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  /// Vérifie si un verificationId est disponible
  bool get hasVerificationId => _verificationId != null;

  /// Récupère l'ID utilisateur Firebase actuellement connecté
  String? get currentUserId => _auth.currentUser?.uid;

  /// Envoie un code OTP au numéro de téléphone
  /// Le numéro sera automatiquement normalisé au format international E.164
  Future<void> sendOtp({
    required String phoneNumber,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      onStateChanged?.call(FirebaseOtpState.initial);

      // Normaliser le numéro au format international E.164
      // Cette opération peut lancer une FormatException si le format est invalide
      final String normalizedPhone;
      try {
        normalizedPhone = phoneNumber.toInternationalPhone;
      } on FormatException catch (e) {
        AppLogger.warning(
          '[FirebaseOTP] Invalid phone number format',
          error: e,
        );
        onStateChanged?.call(
          FirebaseOtpState.error,
          error: 'Numéro de téléphone invalide. ${e.message}',
        );
        return;
      }

      AppLogger.auth('[FirebaseOTP] Phone number normalized for OTP request');

      if (kIsWeb) {
        // Sur le web, utiliser signInWithPhoneNumber avec reCAPTCHA
        await _sendOtpWeb(normalizedPhone);
      } else {
        // Sur mobile, utiliser verifyPhoneNumber
        await _sendOtpMobile(normalizedPhone, timeout);
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        '[FirebaseOTP] Error while sending OTP',
        error: e,
        stackTrace: stackTrace,
      );
      onStateChanged?.call(FirebaseOtpState.error, error: e.toString());
    }
  }

  /// Envoi OTP pour le web avec reCAPTCHA
  Future<void> _sendOtpWeb(String normalizedPhone) async {
    try {
      AppLogger.auth('[FirebaseOTP] Sending OTP through web flow');

      // Sur le web, signInWithPhoneNumber gère automatiquement le reCAPTCHA
      // Le reCAPTCHA s'affichera dans le conteneur 'recaptcha-container' si présent
      final confirmationResult = await _auth.signInWithPhoneNumber(
        normalizedPhone,
      );

      _verificationId = confirmationResult.verificationId;
      _webConfirmationResult = confirmationResult;
      AppLogger.auth('[FirebaseOTP] OTP code sent successfully on web');
      onStateChanged?.call(FirebaseOtpState.codeSent);
    } on FirebaseAuthException catch (e) {
      AppLogger.warning(
        '[FirebaseOTP] FirebaseAuthException during web OTP',
        error: e,
      );
      onStateChanged?.call(FirebaseOtpState.error, error: _getErrorMessage(e));
    } catch (e, stackTrace) {
      AppLogger.warning(
        '[FirebaseOTP] Unexpected error during web OTP send',
        error: e,
        stackTrace: stackTrace,
      );
      onStateChanged?.call(
        FirebaseOtpState.error,
        error: 'Erreur: ${e.runtimeType} - $e',
      );
    }
  }

  ConfirmationResult? _webConfirmationResult;

  /// Envoi OTP pour mobile
  Future<void> _sendOtpMobile(String normalizedPhone, Duration timeout) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      timeout: timeout,

      // Appelé quand le code est envoyé avec succès
      codeSent: (String verificationId, int? resendToken) {
        AppLogger.auth('[FirebaseOTP] OTP code sent on mobile');
        _verificationId = verificationId;
        _resendToken = resendToken;
        onStateChanged?.call(FirebaseOtpState.codeSent);
      },

      // Appelé si le code est automatiquement récupéré (Android uniquement)
      verificationCompleted: (PhoneAuthCredential credential) async {
        AppLogger.auth('[FirebaseOTP] Automatic verification completed');
        // Notifier l'UI avec le code SMS si disponible
        final smsCode = credential.smsCode;
        if (smsCode != null) {
          AppLogger.auth('[FirebaseOTP] SMS code auto-retrieved');
          onSmsCodeAutoRetrieved?.call(smsCode);
        }
        onCodeAutoRetrieved?.call();
        // Auto-sign in
        try {
          await _auth.signInWithCredential(credential);
          onStateChanged?.call(FirebaseOtpState.verified);
        } catch (e, stackTrace) {
          AppLogger.warning(
            '[FirebaseOTP] Auto sign-in failed',
            error: e,
            stackTrace: stackTrace,
          );
          onStateChanged?.call(FirebaseOtpState.error, error: e.toString());
        }
      },

      // Appelé en cas d'échec
      verificationFailed: (FirebaseAuthException e) {
        AppLogger.warning('[FirebaseOTP] Verification failed', error: e);
        String errorMessage = _getErrorMessage(e);
        onStateChanged?.call(FirebaseOtpState.error, error: errorMessage);
      },

      // Appelé quand le timeout est atteint
      codeAutoRetrievalTimeout: (String verificationId) {
        AppLogger.auth('[FirebaseOTP] Auto-retrieval timeout reached');
        _verificationId = verificationId;
        onStateChanged?.call(FirebaseOtpState.timeout);
      },

      // Token pour renvoyer le code
      forceResendingToken: _resendToken,
    );
  }

  /// Vérifie le code OTP entré par l'utilisateur
  Future<FirebaseOtpResult> verifyOtp(String smsCode) async {
    if (_verificationId == null && _webConfirmationResult == null) {
      return FirebaseOtpResult.error(
        'Aucun code n\'a été envoyé. Veuillez réessayer.',
      );
    }

    try {
      onStateChanged?.call(FirebaseOtpState.verifying);

      UserCredential userCredential;

      if (kIsWeb && _webConfirmationResult != null) {
        // Sur le web, utiliser confirmationResult.confirm()
        userCredential = await _webConfirmationResult!.confirm(smsCode);
      } else {
        // Sur mobile, utiliser le credential classique
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: smsCode,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      AppLogger.auth('[FirebaseOTP] OTP verification succeeded');
      onStateChanged?.call(FirebaseOtpState.verified);

      return FirebaseOtpResult.success(
        firebaseUid: userCredential.user?.uid,
        phoneNumber: userCredential.user?.phoneNumber,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.warning('[FirebaseOTP] OTP verification error', error: e);
      String errorMessage = _getErrorMessage(e);
      onStateChanged?.call(FirebaseOtpState.error, error: errorMessage);
      return FirebaseOtpResult.error(errorMessage);
    } catch (e, stackTrace) {
      AppLogger.warning(
        '[FirebaseOTP] Unexpected OTP verification error',
        error: e,
        stackTrace: stackTrace,
      );
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
    // Réinitialiser pour le web
    _webConfirmationResult = null;
    // Réinitialiser et renvoyer
    await sendOtp(phoneNumber: phoneNumber, timeout: timeout);
  }

  /// Déconnecte l'utilisateur Firebase (pour tests ou réinitialisation)
  Future<void> signOut() async {
    await _auth.signOut();
    _verificationId = null;
    _resendToken = null;
  }

  /// Réinitialise l'état du service
  void reset() {
    _verificationId = null;
    _resendToken = null;
    onStateChanged?.call(FirebaseOtpState.initial);
  }

  /// Traduit les codes d'erreur Firebase en messages utilisateur
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide. Vérifiez le format.';
      case 'too-many-requests':
        return 'Vous avez fait trop de demandes de code récemment.\n\nPour des raisons de sécurité, veuillez patienter 5 à 15 minutes avant de réessayer.';
      case 'invalid-verification-code':
        return 'Code invalide. Vérifiez et réessayez.';
      case 'session-expired':
        return 'Session expirée. Veuillez demander un nouveau code.';
      case 'quota-exceeded':
        return 'Le service SMS est temporairement indisponible (quota atteint).\n\nVeuillez réessayer dans 1 heure ou contacter le support si le problème persiste.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion internet.';
      case 'app-not-authorized':
        return 'Application non autorisée. Contactez le support.';
      case 'captcha-check-failed':
        return 'Vérification de sécurité échouée. Réessayez.';
      case 'missing-client-identifier':
        return 'Configuration incomplète. Contactez le support technique.';
      case 'app-not-verified':
        return 'Application non vérifiée. Contactez le support technique.';
      case 'internal-error':
        return 'Erreur interne Firebase. Veuillez réessayer dans quelques minutes.';
      default:
        // Handle error messages containing error codes (e.g. "Error code: 39")
        final msg = e.message ?? '';
        if (msg.contains('Error code: 39') ||
            msg.contains('MISSING_CLIENT_IDENTIFIER')) {
          return 'Certificat de l\'application non reconnu. Veuillez réinstaller l\'application ou contacter le support.';
        }
        if (msg.contains('internal') || msg.contains('Internal')) {
          return 'Erreur interne du service. Veuillez réessayer.';
        }
        return msg.isNotEmpty ? msg : 'Une erreur est survenue.';
    }
  }
}
