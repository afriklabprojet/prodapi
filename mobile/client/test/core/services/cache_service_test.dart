import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:drpharma_client/core/services/cache_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('cache_service_test_');
    Hive.init(tempDir.path);
    // Open boxes manually (same names as CacheService constants)
    await Future.wait([
      Hive.openBox<String>('products_cache'),
      Hive.openBox<String>('pharmacies_cache'),
      Hive.openBox<String>('orders_cache'),
      Hive.openBox<String>('cache_meta'),
    ]);
  });

  tearDown(() async {
    await CacheService.clearAll();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  // ── Products ──────────────────────────────────────────
  group('products cache', () {
    test('getCachedProducts returns null when nothing cached', () {
      expect(CacheService.getCachedProducts('products_all'), isNull);
    });

    test('cacheProducts and getCachedProducts round-trip', () async {
      final products = [
        {'id': 1, 'name': 'Paracetamol'},
        {'id': 2, 'name': 'Ibuprofen'},
      ];
      await CacheService.cacheProducts('products_all', products);

      final result = CacheService.getCachedProducts('products_all');
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0]['name'], 'Paracetamol');
    });

    test('getCachedProducts returns null after clearAll', () async {
      await CacheService.cacheProducts('k1', [
        {'id': 1},
      ]);
      await CacheService.clearAll();
      expect(CacheService.getCachedProducts('k1'), isNull);
    });

    test('cacheProducts with empty list stores empty', () async {
      await CacheService.cacheProducts('empty_key', []);
      final result = CacheService.getCachedProducts('empty_key');
      expect(result, isNotNull);
      expect(result!, isEmpty);
    });
  });

  // ── Pharmacies ───────────────────────────────────────
  group('pharmacies cache', () {
    test('getCachedPharmacies returns null when nothing cached', () {
      expect(CacheService.getCachedPharmacies('pharmacies_all'), isNull);
    });

    test('cachePharmacies and getCachedPharmacies round-trip', () async {
      final pharmacies = [
        {'id': 10, 'name': 'Pharmacie du Coin'},
      ];
      await CacheService.cachePharmacies('pharmacies_all', pharmacies);

      final result = CacheService.getCachedPharmacies('pharmacies_all');
      expect(result, isNotNull);
      expect(result!.first['name'], 'Pharmacie du Coin');
    });
  });

  // ── Orders ────────────────────────────────────────────
  group('orders cache', () {
    test('getCachedOrders returns null when nothing cached', () {
      expect(CacheService.getCachedOrders(), isNull);
    });

    test('cacheOrders and getCachedOrders round-trip', () async {
      final orders = [
        {'id': 100, 'status': 'pending'},
        {'id': 101, 'status': 'completed'},
      ];
      await CacheService.cacheOrders(orders);

      final result = CacheService.getCachedOrders();
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[1]['status'], 'completed');
    });

    test('cacheOrders overwrites previous data', () async {
      await CacheService.cacheOrders([
        {'id': 1},
      ]);
      await CacheService.cacheOrders([
        {'id': 99},
      ]);

      final result = CacheService.getCachedOrders();
      expect(result!.length, 1);
      expect(result.first['id'], 99);
    });
  });

  // ── clearAll ─────────────────────────────────────────
  group('clearAll', () {
    test('clears all caches at once', () async {
      await CacheService.cacheProducts('p', [
        {'id': 1},
      ]);
      await CacheService.cachePharmacies('ph', [
        {'id': 2},
      ]);
      await CacheService.cacheOrders([
        {'id': 3},
      ]);

      await CacheService.clearAll();

      expect(CacheService.getCachedProducts('p'), isNull);
      expect(CacheService.getCachedPharmacies('ph'), isNull);
      expect(CacheService.getCachedOrders(), isNull);
    });
  });

  // ── cache expiry (_isValid) ───────────────────────────
  group('cache validity', () {
    test('returns same data after consecutive write+read', () async {
      await CacheService.cacheProducts('fresh', [
        {'id': 42},
      ]);
      final r1 = CacheService.getCachedProducts('fresh');
      final r2 = CacheService.getCachedProducts('fresh');
      expect(r1, equals(r2));
    });

    test('getCachedProducts returns null for key without timestamp', () async {
      // Put data directly without timestamp → _isValid returns false
      Hive.box<String>('products_cache').put('raw_key', '[{"id":1}]');
      expect(CacheService.getCachedProducts('raw_key'), isNull);
    });
  });
}
