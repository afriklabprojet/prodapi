import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'encrypted_storage_service.dart';

/// Service de cache local chiffré avec TTL (Time-To-Live).
///
/// Utilise une box Hive chiffrée (AES-256) pour stocker les données fréquentes
/// (profil, wallet, statistiques) afin de réduire les appels API, permettre un
/// mode offline basique, et protéger les données personnelles au repos.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  Box<String>? _box;

  /// In-memory fallback for unit tests (avoids platform channel calls).
  @visibleForTesting
  static Map<String, String>? testStore;

  /// Réinitialise l'instance interne (pour les tests uniquement).
  @visibleForTesting
  void resetForTesting() {
    _box = null;
    testStore = {};
  }

  // ── Clés de cache ──────────────────────────────────
  static const String _keyProfile = 'cache_profile';
  static const String _keyCourierProfile = 'cache_courier_profile';
  static const String _keyWallet = 'cache_wallet';
  static const String _keyStatistics = 'cache_statistics';

  // ── TTL par défaut ─────────────────────────────────
  /// Profil utilisateur : 30 minutes
  static const Duration profileTtl = Duration(minutes: 30);

  /// Wallet : 5 minutes (données sensibles)
  static const Duration walletTtl = Duration(minutes: 5);

  /// Statistiques : 15 minutes
  static const Duration statsTtl = Duration(minutes: 15);

  // ── Initialisation ─────────────────────────────────

  Future<void> init() async {
    if (testStore != null) return; // test mode
    if (_box != null && _box!.isOpen) return;
    _box = await EncryptedStorageService.instance.openEncryptedBox('app_cache');
    if (kDebugMode) debugPrint('💾 [CACHE] Initialized (encrypted Hive box)');
  }

  // ── Internal storage accessors ─────────────────────

  String? _get(String key) {
    if (testStore != null) return testStore![key];
    return _box?.get(key);
  }

  Future<void> _set(String key, String value) async {
    if (testStore != null) {
      testStore![key] = value;
      return;
    }
    await _box?.put(key, value);
  }

  Future<void> _delete(String key) async {
    if (testStore != null) {
      testStore!.remove(key);
      return;
    }
    await _box?.delete(key);
  }

  Iterable<String> _allKeys() {
    if (testStore != null) return testStore!.keys;
    return _box?.keys.cast<String>() ?? [];
  }

  // ── API publique ───────────────────────────────────

  /// Sauvegarde un objet JSON avec un timestamp.
  Future<void> put(String key, Map<String, dynamic> data) async {
    await init();
    final entry = {
      'data': data,
      'cached_at': DateTime.now().toIso8601String(),
    };
    await _set(key, jsonEncode(entry));
    if (kDebugMode) debugPrint('💾 [CACHE] Saved: $key');
  }

  /// Récupère un objet JSON s'il est encore valide (dans le TTL).
  /// Retourne `null` si absent ou expiré.
  Future<Map<String, dynamic>?> get(String key, {required Duration ttl}) async {
    await init();
    final raw = _get(key);
    if (raw == null) return null;

    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(entry['cached_at'] as String);

      if (DateTime.now().difference(cachedAt) > ttl) {
        if (kDebugMode) debugPrint('⏰ [CACHE] Expired: $key');
        await _delete(key);
        return null;
      }

      if (kDebugMode) debugPrint('✅ [CACHE] Hit: $key (age: ${DateTime.now().difference(cachedAt).inSeconds}s)');
      return entry['data'] as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [CACHE] Corrupt entry removed: $key');
      await _delete(key);
      return null;
    }
  }

  /// Supprime une entrée du cache.
  Future<void> remove(String key) async {
    await init();
    await _delete(key);
    if (kDebugMode) debugPrint('🗑️ [CACHE] Removed: $key');
  }

  /// Vide tout le cache applicatif (garde les tokens d'auth).
  Future<void> clearAll() async {
    await init();
    final keys = [_keyProfile, _keyCourierProfile, _keyWallet, _keyStatistics];
    for (final key in keys) {
      await _delete(key);
    }
    // Supprimer aussi les entrées de stats par période
    final allKeys = _allKeys().toList();
    for (final key in allKeys) {
      if (key.startsWith('cache_')) {
        await _delete(key);
      }
    }
    if (kDebugMode) debugPrint('🧹 [CACHE] All cache cleared');
  }

  // ── Helpers typés ──────────────────────────────────

  /// Cache du profil utilisateur (données /me).
  Future<void> cacheProfile(Map<String, dynamic> data) =>
      put(_keyProfile, data);

  Future<Map<String, dynamic>?> getCachedProfile() =>
      get(_keyProfile, ttl: profileTtl);

  /// Cache du profil coursier (données /courier/profile).
  Future<void> cacheCourierProfile(Map<String, dynamic> data) =>
      put(_keyCourierProfile, data);

  Future<Map<String, dynamic>?> getCachedCourierProfile() =>
      get(_keyCourierProfile, ttl: profileTtl);

  /// Cache du wallet.
  Future<void> cacheWallet(Map<String, dynamic> data) =>
      put(_keyWallet, data);

  Future<Map<String, dynamic>?> getCachedWallet() =>
      get(_keyWallet, ttl: walletTtl);

  /// Cache des statistiques (par période).
  Future<void> cacheStatistics(String period, Map<String, dynamic> data) =>
      put('${_keyStatistics}_$period', data);

  Future<Map<String, dynamic>?> getCachedStatistics(String period) =>
      get('${_keyStatistics}_$period', ttl: statsTtl);

  /// Invalide le cache wallet (après un top-up, retrait, livraison…).
  Future<void> invalidateWallet() => remove(_keyWallet);

  /// Invalide le cache profil (après un update profil).
  Future<void> invalidateProfile() async {
    await remove(_keyProfile);
    await remove(_keyCourierProfile);
  }

  /// Invalide le cache stats.
  Future<void> invalidateStatistics() async {
    await init();
    final allKeys = _allKeys().toList();
    for (final key in allKeys) {
      if (key.startsWith(_keyStatistics)) {
        await _delete(key);
      }
    }
  }
}
