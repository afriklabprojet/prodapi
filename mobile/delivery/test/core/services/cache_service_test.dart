import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/cache_service.dart';

void main() {
  late CacheService cache;

  setUp(() async {
    cache = CacheService.instance;
    cache.resetForTesting();
    await cache.init();
  });

  group('CacheService.put / get', () {
    test('stores and retrieves data within TTL', () async {
      final data = {'name': 'John', 'age': 30};
      await cache.put('test_key', data);

      final result = await cache.get('test_key', ttl: const Duration(minutes: 5));
      expect(result, isNotNull);
      expect(result!['name'], 'John');
      expect(result['age'], 30);
    });

    test('returns null for non-existent key', () async {
      final result = await cache.get('non_existent', ttl: const Duration(minutes: 5));
      expect(result, isNull);
    });

    test('returns null for expired data', () async {
      // Directly inject an expired entry into the test store
      final expiredTime = DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
      CacheService.testStore!['expired_key'] = '{"data":{"x":1},"cached_at":"$expiredTime"}';

      final result = await cache.get('expired_key', ttl: const Duration(minutes: 5));
      expect(result, isNull);

      // Vérifie que l'entrée a été nettoyée
      expect(CacheService.testStore!['expired_key'], isNull);
    });

    test('handles corrupt JSON gracefully', () async {
      CacheService.testStore!['corrupt_key'] = 'not-valid-json{{{';

      final result = await cache.get('corrupt_key', ttl: const Duration(minutes: 5));
      expect(result, isNull);

      // Vérifie que l'entrée corrompue a été supprimée
      expect(CacheService.testStore!['corrupt_key'], isNull);
    });

    test('overwrites existing data', () async {
      await cache.put('key', {'v': 1});
      await cache.put('key', {'v': 2});

      final result = await cache.get('key', ttl: const Duration(minutes: 5));
      expect(result!['v'], 2);
    });
  });

  group('CacheService.remove', () {
    test('removes existing entry', () async {
      await cache.put('to_remove', {'data': true});
      await cache.remove('to_remove');

      final result = await cache.get('to_remove', ttl: const Duration(minutes: 5));
      expect(result, isNull);
    });

    test('does not throw when removing non-existent key', () async {
      // Should not throw
      await cache.remove('non_existent');
    });
  });

  group('CacheService.clearAll', () {
    test('clears all cache_ prefixed entries', () async {
      await cache.put('cache_profile', {'name': 'test'});
      await cache.put('cache_wallet', {'balance': 100});
      await cache.put('cache_statistics_week', {'total': 5});

      await cache.clearAll();

      expect(await cache.get('cache_profile', ttl: const Duration(hours: 1)), isNull);
      expect(await cache.get('cache_wallet', ttl: const Duration(hours: 1)), isNull);
      expect(await cache.get('cache_statistics_week', ttl: const Duration(hours: 1)), isNull);
    });

    test('preserves non-cache entries', () async {
      CacheService.testStore!['auth_token'] = 'secret123';
      await cache.put('cache_profile', {'name': 'test'});

      await cache.clearAll();

      expect(CacheService.testStore!['auth_token'], 'secret123');
    });
  });

  group('CacheService typed helpers', () {
    test('cacheProfile / getCachedProfile', () async {
      await cache.cacheProfile({'name': 'Dr. Pharma', 'email': 'doc@pharma.ci'});

      final cached = await cache.getCachedProfile();
      expect(cached, isNotNull);
      expect(cached!['name'], 'Dr. Pharma');
    });

    test('cacheWallet / getCachedWallet', () async {
      await cache.cacheWallet({'balance': 5000, 'currency': 'FCFA'});

      final cached = await cache.getCachedWallet();
      expect(cached, isNotNull);
      expect(cached!['balance'], 5000);
    });

    test('cacheStatistics / getCachedStatistics per period', () async {
      await cache.cacheStatistics('week', {'total': 10});
      await cache.cacheStatistics('month', {'total': 45});

      final week = await cache.getCachedStatistics('week');
      final month = await cache.getCachedStatistics('month');

      expect(week!['total'], 10);
      expect(month!['total'], 45);
    });

    test('invalidateWallet removes wallet cache', () async {
      await cache.cacheWallet({'balance': 5000});
      await cache.invalidateWallet();

      final cached = await cache.getCachedWallet();
      expect(cached, isNull);
    });

    test('invalidateProfile removes profile cache', () async {
      await cache.cacheProfile({'name': 'test'});
      await cache.invalidateProfile();

      final cached = await cache.getCachedProfile();
      expect(cached, isNull);
    });

    test('invalidateStatistics removes all stats cache', () async {
      await cache.cacheStatistics('week', {'total': 10});
      await cache.cacheStatistics('month', {'total': 45});
      await cache.invalidateStatistics();

      expect(await cache.getCachedStatistics('week'), isNull);
      expect(await cache.getCachedStatistics('month'), isNull);
    });
  });

  group('CacheService TTL constants', () {
    test('profileTtl is 30 minutes', () {
      expect(CacheService.profileTtl, const Duration(minutes: 30));
    });

    test('walletTtl is 5 minutes', () {
      expect(CacheService.walletTtl, const Duration(minutes: 5));
    });

    test('statsTtl is 15 minutes', () {
      expect(CacheService.statsTtl, const Duration(minutes: 15));
    });
  });
}
