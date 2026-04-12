import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_token_service.dart';

/// Provider pour le service d'authentification biométrique
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Provider pour l'état d'activation de la biométrie (simple bool)
final biometricEnabledProvider = Provider<bool>((ref) => false);

/// Provider pour les réglages biométriques
final biometricSettingsProvider = NotifierProvider<BiometricSettingsNotifier, bool>(
  BiometricSettingsNotifier.new,
);

/// Notifier pour gérer l'état des réglages biométriques.
/// Stocke le flag dans FlutterSecureStorage (chiffré) au lieu de
/// SharedPreferences (clair) pour empêcher la falsification.
class BiometricSettingsNotifier extends Notifier<bool> {
  static const String _key = 'biometric_login_enabled';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  bool build() {
    _loadSettings();
    return false;
  }

  Future<void> _loadSettings() async {
    try {
      final value = await _storage.read(key: _key);
      state = value == 'true';
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Biometric settings load failed: $e');
      state = false;
    }
  }

  Future<void> enableBiometricLogin() async {
    await _storage.write(key: _key, value: 'true');
    state = true;
  }

  Future<void> disableBiometricLogin() async {
    await _storage.write(key: _key, value: 'false');
    state = false;
  }
}

/// Types de biométrie disponibles
enum AppBiometricType {
  fingerprint,
  faceId,
  iris,
  none,
}

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Vérifie si le device peut vérifier les biométries
  Future<bool> canCheckBiometrics() async {
    // Biometrics not supported on web
    if (kIsWeb) return false;
    
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('Error checking biometrics: $e');
      return false;
    } on MissingPluginException catch (_) {
      if (kDebugMode) debugPrint('Biometrics not available on this platform');
      return false;
    }
  }

  /// Vérifie si le device supporte la biométrie
  Future<bool> isDeviceSupported() async {
    // Biometrics not supported on web
    if (kIsWeb) return false;
    
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('Error checking device support: $e');
      return false;
    } on MissingPluginException catch (_) {
      return false;
    }
  }

  /// Vérifie si des biométries sont enregistrées sur le device
  Future<bool> hasBiometrics() async {
    // Biometrics not supported on web
    if (kIsWeb) return false;
    
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('Error checking biometrics: $e');
      return false;
    } on MissingPluginException catch (_) {
      return false;
    }
  }

  /// Retourne les types de biométrie disponibles
  Future<List<AppBiometricType>> getAvailableBiometrics() async {
    // Biometrics not supported on web
    if (kIsWeb) return [];
    
    try {
      final available = await _localAuth.getAvailableBiometrics();
      return available.map((bio) {
        switch (bio) {
          case BiometricType.fingerprint:
            return AppBiometricType.fingerprint;
          case BiometricType.face:
            return AppBiometricType.faceId;
          case BiometricType.iris:
            return AppBiometricType.iris;
          default:
            return AppBiometricType.none;
        }
      }).where((b) => b != AppBiometricType.none).toList();
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('Error getting available biometrics: $e');
      return [];
    } on MissingPluginException catch (_) {
      if (kDebugMode) debugPrint('Biometrics not available on this platform');
      return [];
    }
  }

  /// Retourne le type de biométrie principal disponible
  Future<AppBiometricType> getPrimaryBiometricType() async {
    final types = await getAvailableBiometrics();
    if (types.contains(AppBiometricType.faceId)) {
      return AppBiometricType.faceId;
    } else if (types.contains(AppBiometricType.fingerprint)) {
      return AppBiometricType.fingerprint;
    } else if (types.contains(AppBiometricType.iris)) {
      return AppBiometricType.iris;
    }
    return AppBiometricType.none;
  }

  /// Retourne le nom localisé du type de biométrie
  String getBiometricName(AppBiometricType type) {
    switch (type) {
      case AppBiometricType.fingerprint:
        return 'Empreinte digitale';
      case AppBiometricType.faceId:
        return 'Face ID';
      case AppBiometricType.iris:
        return 'Iris';
      case AppBiometricType.none:
        return 'Non disponible';
    }
  }

  /// Authentifie l'utilisateur avec biométrie
  Future<bool> authenticate({
    String reason = 'Veuillez vous authentifier pour continuer',
  }) async {
    // Biometrics not supported on web
    if (kIsWeb) return false;
    
    try {
      // Vérifier d'abord si la biométrie est disponible
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheck || !isSupported) {
        if (kDebugMode) debugPrint('Biometric auth not available');
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('Authentication error: ${e.message}');
      return false;
    } on MissingPluginException catch (_) {
      if (kDebugMode) debugPrint('Biometrics not available on this platform');
      return false;
    }
  }

  /// Vérifie si la biométrie est activée dans les préférences (stockage chiffré)
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ isBiometricEnabled check failed: $e');
      return false;
    }
  }

  /// Active ou désactive la biométrie (stockage chiffré)
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  /// Stocke le token d'authentification pour la reconnexion biométrique
  Future<void> saveAuthToken(String token) async {
    await SecureTokenService.instance.setToken(token);
  }

  /// Récupère le token d'authentification stocké
  Future<String?> getStoredAuthToken() async {
    return SecureTokenService.instance.getToken();
  }

  /// Supprime le token stocké (logout)
  Future<void> clearAuthToken() async {
    await SecureTokenService.instance.removeToken();
  }

  /// Authentification rapide avec biométrie si activée
  /// Retourne le token si succès, null sinon
  Future<String?> quickLogin() async {
    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) return null;

    final token = await getStoredAuthToken();
    if (token == null) return null;

    final authenticated = await authenticate(
      reason: 'Authentifiez-vous pour accéder à DR-PHARMA',
    );

    return authenticated ? token : null;
  }
}
