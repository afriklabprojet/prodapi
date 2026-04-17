import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==================== LOGGING HELPER ====================

void _log(String message, {String emoji = '🔐'}) {
  if (kDebugMode) debugPrint('$emoji [SecurityService] $message');
}

void _logError(String message, Object error) {
  if (kDebugMode) debugPrint('❌ [SecurityService] $message: $error');
}

/// Service de sécurité pour l'application
/// Gère l'authentification biométrique, le session timeout, et le chiffrement
class SecurityService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;
  
  // Clés de stockage (non-sensibles → SharedPreferences)
  static const String _keyBiometricEnabled = 'security_biometric_enabled';
  static const String _keyLastActivity = 'security_last_activity';
  static const String _keySessionTimeout = 'security_session_timeout';
  static const String _keyPinEnabled = 'security_pin_enabled';
  static const String _keyFailedAttempts = 'security_failed_attempts';
  static const String _keyLockoutUntil = 'security_lockout_until';
  
  // Clés de stockage sécurisé (sensibles → FlutterSecureStorage)
  static const String _keyPinHash = 'security_pin_hash';
  static const String _keyPinSalt = 'security_pin_salt';
  
  // Configuration par défaut
  static const Duration defaultSessionTimeout = Duration(minutes: 15);
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 30);

  Timer? _sessionTimer;
  VoidCallback? _onSessionExpired;

  SecurityService(
    this._prefs, {
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            ),
        _localAuth = localAuth ?? LocalAuthentication();

  /// Configure le callback pour l'expiration de session
  void setSessionExpiredCallback(VoidCallback callback) {
    _onSessionExpired = callback;
  }

  // ==================== SESSION MANAGEMENT ====================

  /// Met à jour l'horodatage de la dernière activité
  Future<void> updateActivity() async {
    await _prefs.setString(
      _keyLastActivity,
      DateTime.now().toIso8601String(),
    );
    _resetSessionTimer();
  }

  /// Vérifie si la session est toujours valide
  bool isSessionValid() {
    final lastActivityStr = _prefs.getString(_keyLastActivity);
    if (lastActivityStr == null) return false;

    final lastActivity = DateTime.tryParse(lastActivityStr);
    if (lastActivity == null) return false;
    final timeout = getSessionTimeout();
    
    return DateTime.now().isBefore(lastActivity.add(timeout));
  }

  /// Retourne la durée du timeout de session
  Duration getSessionTimeout() {
    final minutes = _prefs.getInt(_keySessionTimeout) ?? defaultSessionTimeout.inMinutes;
    return Duration(minutes: minutes);
  }

  /// Définit la durée du timeout de session
  Future<void> setSessionTimeout(Duration timeout) async {
    await _prefs.setInt(_keySessionTimeout, timeout.inMinutes);
  }

  /// Démarre le timer de session
  void startSessionTimer() {
    _resetSessionTimer();
  }

  /// Arrête le timer de session
  void stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    final timeout = getSessionTimeout();
    _sessionTimer = Timer(timeout, () {
      _log('Session expired', emoji: '⏰');
      _onSessionExpired?.call();
    });
  }

  // ==================== BIOMETRIC AUTHENTICATION ====================

  /// Vérifie si l'appareil supporte l'authentification biométrique
  Future<BiometricCapability> checkBiometricCapability() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      return BiometricCapability(
        isAvailable: canAuthenticate && isDeviceSupported,
        hasFaceId: availableBiometrics.contains(BiometricType.face),
        hasFingerprint: availableBiometrics.contains(BiometricType.fingerprint),
        hasIris: availableBiometrics.contains(BiometricType.iris),
      );
    } catch (e) {
      _logError('Error checking biometric', e);
      return const BiometricCapability(
        isAvailable: false,
        hasFaceId: false,
        hasFingerprint: false,
        hasIris: false,
      );
    }
  }

  /// Active/désactive l'authentification biométrique
  Future<void> setBiometricEnabled(bool enabled) async =>
      _prefs.setBool(_keyBiometricEnabled, enabled);

  /// Vérifie si l'authentification biométrique est activée
  bool isBiometricEnabled() => _prefs.getBool(_keyBiometricEnabled) ?? false;

  /// Authentifie l'utilisateur via biométrie
  Future<BiometricResult> authenticateWithBiometric({
    required String reason,
  }) async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      
      return BiometricResult(
        success: didAuthenticate,
        message: didAuthenticate ? 'Authentification réussie' : 'Authentification annulée',
      );
    } on LocalAuthException catch (e) {
      _logError('Biometric auth error: ${e.code}', e.description ?? '');
      final message = _mapBiometricError(e.code);
      return BiometricResult(
        success: false,
        message: message,
        errorCode: e.code.name,
      );
    } catch (e) {
      _logError('Unexpected biometric error', e);
      return BiometricResult(
        success: false,
        message: 'Erreur: $e',
      );
    }
  }
  
  /// Maps biometric error codes to user-friendly messages (Dart 3 switch expression)
  String _mapBiometricError(LocalAuthExceptionCode code) => switch (code) {
    LocalAuthExceptionCode.noBiometricHardware ||
    LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
      'Biométrie non disponible',
    LocalAuthExceptionCode.noBiometricsEnrolled ||
    LocalAuthExceptionCode.noCredentialsSet =>
      'Aucune empreinte enregistrée sur cet appareil',
    LocalAuthExceptionCode.temporaryLockout ||
    LocalAuthExceptionCode.biometricLockout =>
      'Trop de tentatives. Biométrie verrouillée.',
    LocalAuthExceptionCode.userCanceled ||
    LocalAuthExceptionCode.systemCanceled =>
      'Authentification annulée',
    _ => 'Erreur d\'authentification',
  };

  // ==================== PIN AUTHENTICATION ====================

  /// Active l'authentification par PIN
  Future<void> setPinEnabled(bool enabled, {String? pin}) async {
    if (enabled && pin != null) {
      final salt = _generateSalt();
      final hash = _hashPin(pin, salt);
      await _secureStorage.write(key: _keyPinHash, value: hash);
      await _secureStorage.write(key: _keyPinSalt, value: salt);
    } else {
      await _secureStorage.delete(key: _keyPinHash);
      await _secureStorage.delete(key: _keyPinSalt);
    }
    await _prefs.setBool(_keyPinEnabled, enabled);
  }

  /// Vérifie si l'authentification par PIN est activée
  bool isPinEnabled() => _prefs.getBool(_keyPinEnabled) ?? false;

  /// Vérifie le PIN
  Future<PinResult> verifyPin(String pin) async {
    // Vérifier le lockout
    if (isLockedOut()) {
      final lockoutUntil = DateTime.parse(_prefs.getString(_keyLockoutUntil)!);
      final remaining = lockoutUntil.difference(DateTime.now());
      return PinResult(
        success: false,
        message: 'Compte verrouillé. Réessayez dans ${remaining.inMinutes} minutes.',
        isLockedOut: true,
      );
    }

    final storedHash = await _secureStorage.read(key: _keyPinHash);
    final storedSalt = await _secureStorage.read(key: _keyPinSalt);
    if (storedHash == null || storedSalt == null) {
      return PinResult(
        success: false,
        message: 'PIN non configuré',
      );
    }

    final inputHash = _hashPin(pin, storedSalt);
    if (inputHash == storedHash) {
      await _resetFailedAttempts();
      return PinResult(
        success: true,
        message: 'PIN correct',
      );
    } else {
      final attempts = await _incrementFailedAttempts();
      final remaining = maxFailedAttempts - attempts;
      
      if (remaining <= 0) {
        await _setLockout();
        return PinResult(
          success: false,
          message: 'Trop de tentatives. Compte verrouillé.',
          isLockedOut: true,
        );
      }
      
      return PinResult(
        success: false,
        message: 'PIN incorrect. $remaining tentatives restantes.',
        attemptsRemaining: remaining,
      );
    }
  }

  /// Vérifie si le compte est verrouillé
  bool isLockedOut() {
    final lockoutUntilStr = _prefs.getString(_keyLockoutUntil);
    if (lockoutUntilStr == null) return false;
    
    final lockoutUntil = DateTime.parse(lockoutUntilStr);
    if (DateTime.now().isAfter(lockoutUntil)) {
      _prefs.remove(_keyLockoutUntil);
      _prefs.remove(_keyFailedAttempts);
      return false;
    }
    return true;
  }

  Future<int> _incrementFailedAttempts() async {
    final current = _prefs.getInt(_keyFailedAttempts) ?? 0;
    final newCount = current + 1;
    await _prefs.setInt(_keyFailedAttempts, newCount);
    return newCount;
  }

  Future<void> _resetFailedAttempts() async {
    await _prefs.remove(_keyFailedAttempts);
    await _prefs.remove(_keyLockoutUntil);
  }

  Future<void> _setLockout() async {
    final lockoutUntil = DateTime.now().add(lockoutDuration);
    await _prefs.setString(_keyLockoutUntil, lockoutUntil.toIso8601String());
  }

  String _hashPin(String pin, String salt) {
    // SHA-256 with random per-user salt
    final bytes = utf8.encode('$salt:$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a cryptographically random salt
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  // ==================== SECURE DATA ====================

  /// Stocke des données de manière sécurisée (FlutterSecureStorage)
  Future<void> setSecureData(String key, String value) =>
      _secureStorage.write(key: 'secure_$key', value: value);

  /// Récupère des données sécurisées
  Future<String?> getSecureData(String key) =>
      _secureStorage.read(key: 'secure_$key');

  /// Supprime des données sécurisées
  Future<void> removeSecureData(String key) =>
      _secureStorage.delete(key: 'secure_$key');

  // ==================== CLEANUP ====================

  /// Nettoie toutes les données de sécurité (logout)
  Future<void> clearAllSecurityData() async {
    stopSessionTimer();
    await _prefs.remove(_keyLastActivity);
    await _prefs.remove(_keyFailedAttempts);
    await _prefs.remove(_keyLockoutUntil);
    _log('Security data cleared', emoji: '🧹');
  }

  /// Dispose du service
  void dispose() {
    stopSessionTimer();
  }
}

/// Capacités biométriques de l'appareil
class BiometricCapability {
  final bool isAvailable;
  final bool hasFaceId;
  final bool hasFingerprint;
  final bool hasIris;

  const BiometricCapability({
    required this.isAvailable,
    required this.hasFaceId,
    required this.hasFingerprint,
    required this.hasIris,
  });

  String get availableMethodsText {
    final methods = <String>[
      if (hasFaceId) 'Face ID',
      if (hasFingerprint) 'Empreinte digitale',
      if (hasIris) 'Iris',
    ];
    return methods.isEmpty ? 'Aucune' : methods.join(', ');
  }
}

/// Résultat d'authentification biométrique
class BiometricResult {
  final bool success;
  final String message;
  final String? errorCode;

  const BiometricResult({
    required this.success,
    required this.message,
    this.errorCode,
  });
}

/// Résultat de vérification PIN
class PinResult {
  final bool success;
  final String message;
  final bool isLockedOut;
  final int? attemptsRemaining;

  const PinResult({
    required this.success,
    required this.message,
    this.isLockedOut = false,
    this.attemptsRemaining,
  });
}
