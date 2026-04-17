import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_logger.dart';

/// Service de cache offline utilisant Hive
/// Stocke les données JSON consultées pour un accès hors-ligne
class CacheService {
  static const String _productsBox = 'products_cache';
  static const String _pharmaciesBox = 'pharmacies_cache';
  static const String _ordersBox = 'orders_cache';
  static const String _metaBox = 'cache_meta';

  /// Durée de validité du cache (4 heures)
  static const Duration cacheDuration = Duration(hours: 4);

  /// Initialiser Hive et ouvrir les boxes
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(_productsBox),
      Hive.openBox<String>(_pharmaciesBox),
      Hive.openBox<String>(_ordersBox),
      Hive.openBox<String>(_metaBox),
    ]);
    AppLogger.info('CacheService initialized');
  }

  // ── Produits ──

  /// Mettre en cache la liste des produits
  static Future<void> cacheProducts(String key, List<Map<String, dynamic>> products) async {
    try {
      final box = Hive.box<String>(_productsBox);
      await box.put(key, jsonEncode(products));
      await _setTimestamp(_productsBox, key);
    } catch (e) {
      AppLogger.error('Cache products error', error: e);
    }
  }

  /// Récupérer les produits depuis le cache
  static List<Map<String, dynamic>>? getCachedProducts(String key) {
    try {
      if (!_isValid(_productsBox, key)) return null;
      final box = Hive.box<String>(_productsBox);
      final data = box.get(key);
      if (data == null) return null;
      return (jsonDecode(data) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      AppLogger.error('Get cached products error', error: e);
      return null;
    }
  }

  // ── Pharmacies ──

  /// Mettre en cache la liste des pharmacies
  static Future<void> cachePharmacies(String key, List<Map<String, dynamic>> pharmacies) async {
    try {
      final box = Hive.box<String>(_pharmaciesBox);
      await box.put(key, jsonEncode(pharmacies));
      await _setTimestamp(_pharmaciesBox, key);
    } catch (e) {
      AppLogger.error('Cache pharmacies error', error: e);
    }
  }

  /// Récupérer les pharmacies depuis le cache
  static List<Map<String, dynamic>>? getCachedPharmacies(String key) {
    try {
      if (!_isValid(_pharmaciesBox, key)) return null;
      final box = Hive.box<String>(_pharmaciesBox);
      final data = box.get(key);
      if (data == null) return null;
      return (jsonDecode(data) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      AppLogger.error('Get cached pharmacies error', error: e);
      return null;
    }
  }

  // ── Commandes ──

  /// Mettre en cache les commandes
  static Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
    try {
      final box = Hive.box<String>(_ordersBox);
      await box.put('orders_list', jsonEncode(orders));
      await _setTimestamp(_ordersBox, 'orders_list');
    } catch (e) {
      AppLogger.error('Cache orders error', error: e);
    }
  }

  /// Récupérer les commandes depuis le cache
  static List<Map<String, dynamic>>? getCachedOrders() {
    try {
      if (!_isValid(_ordersBox, 'orders_list')) return null;
      final box = Hive.box<String>(_ordersBox);
      final data = box.get('orders_list');
      if (data == null) return null;
      return (jsonDecode(data) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      AppLogger.error('Get cached orders error', error: e);
      return null;
    }
  }

  // ── Utilitaires ──

  /// Nettoyer tout le cache
  static Future<void> clearAll() async {
    await Hive.box<String>(_productsBox).clear();
    await Hive.box<String>(_pharmaciesBox).clear();
    await Hive.box<String>(_ordersBox).clear();
    await Hive.box<String>(_metaBox).clear();
  }

  static Future<void> _setTimestamp(String boxName, String key) async {
    final meta = Hive.box<String>(_metaBox);
    await meta.put('${boxName}_${key}_ts', DateTime.now().toIso8601String());
  }

  static bool _isValid(String boxName, String key) {
    try {
      final meta = Hive.box<String>(_metaBox);
      final ts = meta.get('${boxName}_${key}_ts');
      if (ts == null) return false;
      final cached = DateTime.parse(ts);
      return DateTime.now().difference(cached) < cacheDuration;
    } catch (_) {
      return false;
    }
  }
}
