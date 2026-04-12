import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/cache_service.dart';

void main() {
  late CacheService service;

  setUp(() {
    service = CacheService.instance;
    service.resetForTesting();
  });

  tearDown(() {
    service.resetForTesting();
  });

  group('CacheService', () {
    test('put and get work with testStore', () async {
      await service.put('profile', {'name': 'Jean'});
      final result = await service.get(
        'profile',
        ttl: const Duration(minutes: 30),
      );
      expect(result, isNotNull);
      expect(result?['name'], 'Jean');
    });

    test('get returns null for non-existent key', () async {
      final result = await service.get(
        'nonexistent',
        ttl: const Duration(minutes: 30),
      );
      expect(result, isNull);
    });

    test('remove deletes entry', () async {
      await service.put('wallet', {'balance': 5000});
      await service.remove('wallet');
      final result = await service.get(
        'wallet',
        ttl: const Duration(minutes: 15),
      );
      expect(result, isNull);
    });

    test('clearAll removes all entries', () async {
      await service.cacheProfile({'data': 1});
      await service.cacheWallet({'data': 2});
      await service.clearAll();
      expect(await service.getCachedProfile(), isNull);
      expect(await service.getCachedWallet(), isNull);
    });

    test('cacheProfile and getCachedProfile', () async {
      final profileData = {'id': 1, 'name': 'Test'};
      await service.cacheProfile(profileData);
      final cached = await service.getCachedProfile();
      expect(cached, isNotNull);
    });

    test('cacheWallet and getCachedWallet', () async {
      final walletData = {'balance': '10000'};
      await service.cacheWallet(walletData);
      final cached = await service.getCachedWallet();
      expect(cached, isNotNull);
    });

    test('invalidateProfile clears profile cache', () async {
      await service.cacheProfile({'id': 1});
      await service.invalidateProfile();
      final cached = await service.getCachedProfile();
      expect(cached, isNull);
    });

    test('invalidateWallet clears wallet cache', () async {
      await service.cacheWallet({'balance': '0'});
      await service.invalidateWallet();
      final cached = await service.getCachedWallet();
      expect(cached, isNull);
    });
  });
}
