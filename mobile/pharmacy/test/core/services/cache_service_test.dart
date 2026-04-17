import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_pharmacy/core/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService', () {
    late CacheService cacheService;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cacheService = CacheService(prefs);
    });

    group('setData', () {
      test('should store string data successfully', () async {
        // act
        final result = await cacheService.setData(
          key: 'test_key',
          data: 'test_value',
        );

        // assert
        expect(result, isTrue);
      });

      test('should store map data successfully', () async {
        // act
        final result = await cacheService.setData(
          key: 'test_map',
          data: {'name': 'Test', 'value': 123},
        );

        // assert
        expect(result, isTrue);
      });

      test('should store list data successfully', () async {
        // act
        final result = await cacheService.setData(
          key: 'test_list',
          data: [1, 2, 3, 'four'],
        );

        // assert
        expect(result, isTrue);
      });

      test('should use default cache duration when not specified', () async {
        // act
        final result = await cacheService.setData(
          key: 'default_duration',
          data: 'value',
        );

        // assert
        expect(result, isTrue);
        // Check the data is cached
        final cachedData = cacheService.getData<String>(key: 'default_duration');
        expect(cachedData, equals('value'));
      });

      test('should use custom expiration duration', () async {
        // act
        final result = await cacheService.setData(
          key: 'custom_duration',
          data: 'value',
          expiration: const Duration(hours: 2),
        );

        // assert
        expect(result, isTrue);
      });
    });

    group('getData', () {
      test('should return null for non-existent key', () {
        // act
        final result = cacheService.getData<String>(key: 'non_existent');

        // assert
        expect(result, isNull);
      });

      test('should retrieve stored string data', () async {
        // arrange
        await cacheService.setData(key: 'string_key', data: 'string_value');

        // act
        final result = cacheService.getData<String>(key: 'string_key');

        // assert
        expect(result, equals('string_value'));
      });

      test('should retrieve stored map data', () async {
        // arrange
        final testMap = {'key1': 'value1', 'key2': 42};
        await cacheService.setData(key: 'map_key', data: testMap);

        // act
        final result = cacheService.getData<Map<String, dynamic>>(key: 'map_key');

        // assert
        expect(result, isA<Map>());
        expect(result?['key1'], equals('value1'));
        expect(result?['key2'], equals(42));
      });

      test('should retrieve stored list data', () async {
        // arrange
        final testList = ['a', 'b', 'c'];
        await cacheService.setData(key: 'list_key', data: testList);

        // act
        final result = cacheService.getData<List>(key: 'list_key');

        // assert
        expect(result, isA<List>());
        expect(result?.length, equals(3));
        expect(result?[0], equals('a'));
      });

      test('should return null for expired cache', () async {
        // arrange - Create expired cache entry manually
        final expiredEntry = {
          'data': 'expired_value',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'expirationMs': const Duration(minutes: 5).inMilliseconds,
        };
        await prefs.setString('cache_expired_key', jsonEncode(expiredEntry));

        // act
        final result = cacheService.getData<String>(key: 'expired_key');

        // assert
        expect(result, isNull);
      });
    });

    group('hasValidCache', () {
      test('should return false for non-existent key', () {
        // act
        final result = cacheService.hasValidCache('non_existent');

        // assert
        expect(result, isFalse);
      });

      test('should return true for valid cache', () async {
        // arrange
        await cacheService.setData(key: 'valid_key', data: 'value');

        // act
        final result = cacheService.hasValidCache('valid_key');

        // assert
        expect(result, isTrue);
      });

      test('should return false for expired cache', () async {
        // arrange - Create expired cache entry
        final expiredEntry = {
          'data': 'expired_value',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'expirationMs': const Duration(minutes: 5).inMilliseconds,
        };
        await prefs.setString('cache_expired_valid', jsonEncode(expiredEntry));

        // act
        final result = cacheService.hasValidCache('expired_valid');

        // assert
        expect(result, isFalse);
      });
    });

    group('removeData', () {
      test('should remove cached data successfully', () async {
        // arrange
        await cacheService.setData(key: 'to_remove', data: 'value');
        expect(cacheService.hasValidCache('to_remove'), isTrue);

        // act
        final result = await cacheService.removeData('to_remove');

        // assert
        expect(result, isTrue);
        expect(cacheService.hasValidCache('to_remove'), isFalse);
      });

      test('should return true for non-existent key', () async {
        // act
        final result = await cacheService.removeData('non_existent');

        // assert
        expect(result, isTrue);
      });
    });

    group('clearAll', () {
      test('should clear all cached data', () async {
        // arrange
        await cacheService.setData(key: 'key1', data: 'value1');
        await cacheService.setData(key: 'key2', data: 'value2');
        await cacheService.setData(key: 'key3', data: 'value3');

        // act
        await cacheService.clearAll();

        // assert
        expect(cacheService.hasValidCache('key1'), isFalse);
        expect(cacheService.hasValidCache('key2'), isFalse);
        expect(cacheService.hasValidCache('key3'), isFalse);
      });
    });

    group('clearExpired', () {
      test('should clear only expired entries', () async {
        // arrange - Add valid entry
        await cacheService.setData(key: 'valid', data: 'valid_value');

        // Add expired entry manually
        final expiredEntry = {
          'data': 'expired_value',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'expirationMs': const Duration(minutes: 5).inMilliseconds,
        };
        await prefs.setString('cache_expired_entry', jsonEncode(expiredEntry));

        // act
        await cacheService.clearExpired();

        // assert
        expect(cacheService.hasValidCache('valid'), isTrue);
        expect(prefs.getString('cache_expired_entry'), isNull);
      });
    });

    group('getStats', () {
      test('should return correct stats for empty cache', () {
        // act
        final stats = cacheService.getStats();

        // assert
        expect(stats.totalEntries, equals(0));
        expect(stats.expiredEntries, equals(0));
        expect(stats.validEntries, equals(0));
      });

      test('should return correct stats with cached data', () async {
        // arrange
        await cacheService.setData(key: 'stat1', data: 'value1');
        await cacheService.setData(key: 'stat2', data: 'value2');

        // act
        final stats = cacheService.getStats();

        // assert
        expect(stats.totalEntries, equals(2));
        expect(stats.validEntries, equals(2));
        expect(stats.expiredEntries, equals(0));
        expect(stats.totalSizeKB, greaterThan(0));
      });

      test('should count expired entries correctly', () async {
        // arrange - Add valid entry
        await cacheService.setData(key: 'valid_stat', data: 'value');

        // Add expired entry manually
        final expiredEntry = {
          'data': 'expired_value',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'expirationMs': const Duration(minutes: 5).inMilliseconds,
        };
        await prefs.setString('cache_expired_stat', jsonEncode(expiredEntry));

        // act
        final stats = cacheService.getStats();

        // assert
        expect(stats.totalEntries, equals(2));
        expect(stats.validEntries, equals(1));
        expect(stats.expiredEntries, equals(1));
      });
    });
  });

  group('CacheEntry', () {
    test('should create CacheEntry correctly', () {
      // arrange
      final now = DateTime.now();
      final entry = CacheEntry(
        data: 'test_data',
        timestamp: now,
        expiration: const Duration(minutes: 15),
      );

      // assert
      expect(entry.data, equals('test_data'));
      expect(entry.timestamp, equals(now));
      expect(entry.expiration, equals(const Duration(minutes: 15)));
    });

    test('should detect non-expired entry', () {
      // arrange
      final entry = CacheEntry(
        data: 'data',
        timestamp: DateTime.now(),
        expiration: const Duration(hours: 1),
      );

      // assert
      expect(entry.isExpired, isFalse);
    });

    test('should detect expired entry', () {
      // arrange
      final entry = CacheEntry(
        data: 'data',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        expiration: const Duration(minutes: 30),
      );

      // assert
      expect(entry.isExpired, isTrue);
    });

    test('should serialize to JSON correctly', () {
      // arrange
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final entry = CacheEntry(
        data: {'key': 'value'},
        timestamp: timestamp,
        expiration: const Duration(minutes: 30),
      );

      // act
      final json = entry.toJson();

      // assert
      expect(json['data'], equals({'key': 'value'}));
      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json['expirationMs'], equals(30 * 60 * 1000));
    });

    test('should deserialize from JSON correctly', () {
      // arrange
      final json = {
        'data': 'test_value',
        'timestamp': '2024-01-15T10:30:00.000',
        'expirationMs': 900000, // 15 minutes
      };

      // act
      final entry = CacheEntry.fromJson(json);

      // assert
      expect(entry.data, equals('test_value'));
      expect(entry.timestamp, equals(DateTime(2024, 1, 15, 10, 30)));
      expect(entry.expiration, equals(const Duration(minutes: 15)));
    });
  });

  group('CacheStats', () {
    test('should calculate valid entries correctly', () {
      // arrange
      final stats = CacheStats(
        totalEntries: 10,
        expiredEntries: 3,
        totalSizeKB: 5.5,
      );

      // assert
      expect(stats.validEntries, equals(7));
    });

    test('should have correct toString output', () {
      // arrange
      final stats = CacheStats(
        totalEntries: 10,
        expiredEntries: 3,
        totalSizeKB: 5.5,
      );

      // act
      final result = stats.toString();

      // assert
      expect(result, contains('total: 10'));
      expect(result, contains('valid: 7'));
      expect(result, contains('expired: 3'));
      expect(result, contains('5.50 KB'));
    });
  });

  group('CacheKeys', () {
    test('should have all expected cache keys', () {
      expect(CacheKeys.orders, equals('orders'));
      expect(CacheKeys.inventory, equals('inventory'));
      expect(CacheKeys.notifications, equals('notifications'));
      expect(CacheKeys.userProfile, equals('user_profile'));
      expect(CacheKeys.pharmacyInfo, equals('pharmacy_info'));
      expect(CacheKeys.categories, equals('categories'));
      expect(CacheKeys.statistics, equals('statistics'));
      expect(CacheKeys.walletBalance, equals('wallet_balance'));
      expect(CacheKeys.transactions, equals('transactions'));
    });
  });

  group('CacheService durations', () {
    test('should have correct default cache duration', () {
      expect(CacheService.defaultCacheDuration, equals(const Duration(minutes: 15)));
    });

    test('should have correct long cache duration', () {
      expect(CacheService.longCacheDuration, equals(const Duration(hours: 1)));
    });

    test('should have correct short cache duration', () {
      expect(CacheService.shortCacheDuration, equals(const Duration(minutes: 5)));
    });
  });
}
