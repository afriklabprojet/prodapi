import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service de stockage sécurisé pour les données sensibles
class SecureStorageService {
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user';

  // ── Token ──
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ── User ──
  static Future<String?> getCachedUserJson() async {
    return await _storage.read(key: _userKey);
  }

  static Future<void> setCachedUserJson(String json) async {
    await _storage.write(key: _userKey, value: json);
  }

  static Future<void> deleteCachedUser() async {
    await _storage.delete(key: _userKey);
  }

  // ── Clear All ──
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ── Generic ──
  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
