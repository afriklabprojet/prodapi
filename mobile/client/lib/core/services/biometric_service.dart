import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'app_logger.dart';
import 'secure_storage_service.dart';

/// Clés de stockage sécurisé pour la biométrie
class BiometricStorageKeys {
  static const String enabled = 'biometric_login_enabled';
  static const String credentials = 'biometric_credentials';
  static const String lastUserId = 'biometric_last_user_id';
}

/// Service d'authentification biométrique
/// Permet la connexion par empreinte digitale / Face ID
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // ══════════════════════════════════════════════════════════════════════
  // DISPONIBILITÉ
  // ══════════════════════════════════════════════════════════════════════

  /// Vérifier si l'appareil supporte la biométrie
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } on PlatformException catch (e) {
      AppLogger.error('Biometric availability check failed', error: e);
      return false;
    }
  }

  /// Types de biométrie disponibles
  static Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      AppLogger.error('Get biometric types failed', error: e);
      return [];
    }
  }

  /// Obtenir le nom du type de biométrie (pour l'UI)
  static Future<String> getBiometricTypeName() async {
    final types = await getAvailableTypes();
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Empreinte digitale';
    } else if (types.contains(BiometricType.iris)) {
      return 'Scanner d\'iris';
    }
    return 'Biométrie';
  }

  /// Vérifier si des empreintes/faces sont enregistrées sur l'appareil
  static Future<bool> hasEnrolledBiometrics() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } on PlatformException catch (e) {
      AppLogger.error('Check enrolled biometrics failed', error: e);
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // AUTHENTIFICATION
  // ══════════════════════════════════════════════════════════════════════

  /// Authentifier l'utilisateur avec biométrie ou PIN
  static Future<bool> authenticate({
    String reason = 'Confirmez votre identité pour continuer',
    bool biometricOnly = false,
  }) async {
    try {
      final isSupported = await isAvailable();
      if (!isSupported) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
        ),
      );
    } on PlatformException catch (e) {
      AppLogger.error('Biometric authentication failed', error: e);
      return false;
    }
  }

  /// Authentification pour connexion rapide
  static Future<bool> authenticateForLogin() async {
    final typeName = await getBiometricTypeName();
    return authenticate(
      reason: 'Utilisez votre $typeName pour vous connecter',
      biometricOnly: true,
    );
  }

  /// Authentification spécifique pour les transactions financières
  static Future<bool> authenticateForTransaction() async {
    return authenticate(
      reason: 'Confirmez votre identité pour valider cette transaction',
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // STOCKAGE DES CREDENTIALS
  // ══════════════════════════════════════════════════════════════════════

  /// Vérifier si la connexion biométrique est activée
  static Future<bool> isBiometricLoginEnabled() async {
    try {
      final enabled = await SecureStorageService.read(
        BiometricStorageKeys.enabled,
      );
      return enabled == 'true';
    } catch (e) {
      AppLogger.error('Check biometric enabled failed', error: e);
      return false;
    }
  }

  /// Vérifier si des credentials sont stockés
  static Future<bool> hasStoredCredentials() async {
    try {
      final credentials = await SecureStorageService.read(
        BiometricStorageKeys.credentials,
      );
      return credentials != null && credentials.isNotEmpty;
    } catch (e) {
      AppLogger.error('Check stored credentials failed', error: e);
      return false;
    }
  }

  /// Sauvegarder les credentials pour la connexion biométrique
  static Future<bool> saveCredentials({
    required String identifier,
    required String password,
    required String userId,
  }) async {
    try {
      // Encoder les credentials en base64 simple (le storage est déjà chiffré)
      final encoded = '$identifier|$password';

      await SecureStorageService.write(
        BiometricStorageKeys.credentials,
        encoded,
      );
      await SecureStorageService.write(BiometricStorageKeys.lastUserId, userId);
      await SecureStorageService.write(BiometricStorageKeys.enabled, 'true');

      AppLogger.info('🔐 Biometric credentials saved for user: $userId');
      return true;
    } catch (e) {
      AppLogger.error('Save biometric credentials failed', error: e);
      return false;
    }
  }

  /// Récupérer les credentials stockés (après authentification biométrique)
  static Future<({String identifier, String password})?>
  getStoredCredentials() async {
    try {
      final credentials = await SecureStorageService.read(
        BiometricStorageKeys.credentials,
      );

      if (credentials == null || credentials.isEmpty) {
        return null;
      }

      final parts = credentials.split('|');
      if (parts.length != 2) {
        return null;
      }

      return (identifier: parts[0], password: parts[1]);
    } catch (e) {
      AppLogger.error('Get stored credentials failed', error: e);
      return null;
    }
  }

  /// Récupérer l'ID du dernier utilisateur connecté par biométrie
  static Future<String?> getLastUserId() async {
    try {
      return await SecureStorageService.read(BiometricStorageKeys.lastUserId);
    } catch (e) {
      AppLogger.error('Get last user ID failed', error: e);
      return null;
    }
  }

  /// Activer/Désactiver la connexion biométrique
  static Future<bool> setBiometricLoginEnabled(bool enabled) async {
    try {
      if (!enabled) {
        // Si on désactive, on supprime aussi les credentials
        await clearCredentials();
      }
      await SecureStorageService.write(
        BiometricStorageKeys.enabled,
        enabled.toString(),
      );
      AppLogger.info('🔐 Biometric login ${enabled ? 'enabled' : 'disabled'}');
      return true;
    } catch (e) {
      AppLogger.error('Set biometric enabled failed', error: e);
      return false;
    }
  }

  /// Supprimer les credentials stockés
  static Future<void> clearCredentials() async {
    try {
      await SecureStorageService.delete(BiometricStorageKeys.credentials);
      await SecureStorageService.delete(BiometricStorageKeys.lastUserId);
      await SecureStorageService.delete(BiometricStorageKeys.enabled);
      AppLogger.info('🔐 Biometric credentials cleared');
    } catch (e) {
      AppLogger.error('Clear biometric credentials failed', error: e);
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // FLOW COMPLET
  // ══════════════════════════════════════════════════════════════════════

  /// Vérifier si la connexion biométrique est disponible ET configurée
  static Future<bool> canUseBiometricLogin() async {
    final isAvail = await isAvailable();
    if (!isAvail) return false;

    final isEnabled = await isBiometricLoginEnabled();
    if (!isEnabled) return false;

    final hasCredentials = await hasStoredCredentials();
    return hasCredentials;
  }

  /// Effectuer une connexion biométrique complète
  /// Retourne les credentials si l'authentification réussit
  static Future<({String identifier, String password})?>
  performBiometricLogin() async {
    try {
      // Vérifier que tout est en place
      final canUse = await canUseBiometricLogin();
      if (!canUse) {
        AppLogger.warning('Biometric login not available or not configured');
        return null;
      }

      // Authentifier l'utilisateur
      final authenticated = await authenticateForLogin();
      if (!authenticated) {
        AppLogger.warning('Biometric authentication failed or cancelled');
        return null;
      }

      // Récupérer les credentials
      final credentials = await getStoredCredentials();
      if (credentials == null) {
        AppLogger.warning('No stored credentials found');
        return null;
      }

      AppLogger.info('🔐 Biometric login successful');
      return credentials;
    } catch (e) {
      AppLogger.error('Biometric login flow failed', error: e);
      return null;
    }
  }
}
