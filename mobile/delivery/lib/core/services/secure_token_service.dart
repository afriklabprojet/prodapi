import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service centralisé pour le stockage sécurisé du token d'authentification.
///
/// Remplace l'ancien stockage en SharedPreferences (plaintext) par
/// FlutterSecureStorage (Keychain sur iOS, EncryptedSharedPreferences sur Android).
///
/// Inclut un cache mémoire pour éviter les lectures répétées du Android Keystore
/// (qui bloquent le thread principal natif et causent des ANR).
class SecureTokenService {
  SecureTokenService._();
  static final SecureTokenService _instance = SecureTokenService._();
  static SecureTokenService get instance => _instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _hasTokenPrefKey = 'has_auth_token';

  /// In-memory cache — avoids repeated Android Keystore reads.
  String? _cachedToken;
  bool _cacheLoaded = false;

  /// Accès lecture seule au token en cache mémoire (null si pas encore chargé).
  String? get cachedToken => _cachedToken;

  /// Completer for first-load deduplication — ensures only ONE Keystore read
  /// even if multiple callers (splash + interceptor) call getToken() concurrently.
  Completer<String?>? _loadCompleter;

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

  /// Vérification rapide synchrone via SharedPreferences (aucun accès au Keystore).
  /// Utilisé par le SplashScreen pour décider du routage instantanément.
  static bool hasTokenSync(SharedPreferences prefs) {
    return prefs.getBool(_hasTokenPrefKey) ?? false;
  }

  /// Lire le token d'authentification (avec cache mémoire).
  /// Le premier appel lit le Keystore ; les suivants retournent instantanément.
  Future<String?> getToken() async {
    if (_testStore != null) return _testStore![_authTokenKey];

    // Retour instantané si déjà en cache
    if (_cacheLoaded) return _cachedToken;

    // Si un chargement est déjà en cours, attendre son résultat
    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }

    _loadCompleter = Completer<String?>();
    try {
      final token = await _storage.read(key: _authTokenKey);
      _cachedToken = token;
      _cacheLoaded = true;
      _loadCompleter!.complete(token);
      _loadCompleter = null;
      return token;
    } catch (e) {
      _loadCompleter!.completeError(e);
      _loadCompleter = null;
      rethrow;
    }
  }

  /// Sauvegarder le token d'authentification
  Future<void> setToken(String token) async {
    if (_testStore != null) {
      _testStore![_authTokenKey] = token;
      return;
    }
    // Mettre en cache immédiatement
    _cachedToken = token;
    _cacheLoaded = true;
    await _storage.write(key: _authTokenKey, value: token);
    // Synchroniser le flag dans SharedPreferences pour le routage rapide du splash
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasTokenPrefKey, true);
    } catch (_) {}
  }

  /// Supprimer le token d'authentification
  Future<void> removeToken() async {
    if (_testStore != null) {
      _testStore!.remove(_authTokenKey);
      return;
    }
    _cachedToken = null;
    _cacheLoaded = true; // Marquer comme chargé avec valeur null
    await _storage.delete(key: _authTokenKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasTokenPrefKey, false);
    } catch (_) {}
  }

  /// Vérifier si un token existe
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Refresh Token ──

  String? _cachedRefreshToken;

  /// Lire le refresh token
  Future<String?> getRefreshToken() async {
    if (_testStore != null) return _testStore![_refreshTokenKey];
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      _cachedRefreshToken = token;
      return token;
    } catch (_) {
      return null;
    }
  }

  /// Sauvegarder le refresh token
  Future<void> setRefreshToken(String token) async {
    if (_testStore != null) {
      _testStore![_refreshTokenKey] = token;
      return;
    }
    _cachedRefreshToken = token;
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Supprimer le refresh token
  Future<void> removeRefreshToken() async {
    if (_testStore != null) {
      _testStore!.remove(_refreshTokenKey);
      return;
    }
    _cachedRefreshToken = null;
    await _storage.delete(key: _refreshTokenKey);
  }
}
