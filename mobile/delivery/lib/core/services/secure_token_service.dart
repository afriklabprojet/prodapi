import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service centralisé pour le stockage sécurisé du token d'authentification.
///
/// Remplace l'ancien stockage en SharedPreferences (plaintext) par
/// FlutterSecureStorage (Keychain sur iOS, EncryptedSharedPreferences sur Android).
class SecureTokenService {
  SecureTokenService._();
  static final SecureTokenService _instance = SecureTokenService._();
  static SecureTokenService get instance => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _authTokenKey = 'auth_token';

  /// In-memory store for unit tests (avoids platform channel exceptions).
  static Map<String, String>? _testStore;

  /// Enable in-memory test mode so FlutterSecureStorage platform calls are skipped.
  @visibleForTesting
  static void enableTestMode([Map<String, String>? initialData]) {
    _testStore = initialData ?? {};
  }

  /// Disable test mode and restore real storage.
  @visibleForTesting
  static void disableTestMode() {
    _testStore = null;
  }

  /// Lire le token d'authentification
  Future<String?> getToken() async {
    if (_testStore != null) return _testStore![_authTokenKey];
    return _storage.read(key: _authTokenKey);
  }

  /// Sauvegarder le token d'authentification
  Future<void> setToken(String token) async {
    if (_testStore != null) {
      _testStore![_authTokenKey] = token;
      return;
    }
    await _storage.write(key: _authTokenKey, value: token);
  }

  /// Supprimer le token d'authentification
  Future<void> removeToken() async {
    if (_testStore != null) {
      _testStore!.remove(_authTokenKey);
      return;
    }
    await _storage.delete(key: _authTokenKey);
  }

  /// Vérifier si un token existe
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
