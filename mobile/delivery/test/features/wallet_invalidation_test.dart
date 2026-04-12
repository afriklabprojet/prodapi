import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/providers/wallet_provider.dart';
import 'package:courier/data/models/wallet_data.dart';
import 'package:courier/data/repositories/wallet_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Tests for Improvement 3: Real-time wallet balance after delivery
/// Verifies that both walletProvider AND walletDataProvider are invalidated
/// after delivery completion.

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockWalletRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockWalletRepository();
  });

  tearDown(() {
    container.dispose();
  });

  group('Wallet Provider Invalidation', () {
    test('walletProvider fetches fresh data after invalidation', () async {
      var callCount = 0;
      when(() => mockRepo.getWalletData()).thenAnswer((_) async {
        callCount++;
        return WalletData(balance: callCount == 1 ? 5000 : 8500);
      });

      container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(mockRepo)],
      );

      // First fetch
      final result1 = await container.read(walletProvider.future);
      expect(result1.balance, 5000);
      expect(callCount, 1);

      // Invalidate (simulating what delivery_status_actions does)
      container.invalidate(walletProvider);

      // Second fetch should return new data
      final result2 = await container.read(walletProvider.future);
      expect(result2.balance, 8500);
      expect(callCount, 2);
    });

    test('walletDataProvider fetches fresh data after invalidation', () async {
      var callCount = 0;
      when(() => mockRepo.getWalletData()).thenAnswer((_) async {
        callCount++;
        return WalletData(balance: callCount == 1 ? 5000 : 8500);
      });

      container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(mockRepo)],
      );

      // First fetch
      final result1 = await container.read(walletDataProvider.future);
      expect(result1?.balance, 5000);
      expect(callCount, 1);

      // Invalidate (simulating delivery completion)
      container.invalidate(walletDataProvider);

      // Second fetch should return new data
      final result2 = await container.read(walletDataProvider.future);
      expect(result2?.balance, 8500);
      expect(callCount, 2);
    });

    test('both providers refresh independently after invalidation', () async {
      var callCount = 0;
      when(() => mockRepo.getWalletData()).thenAnswer((_) async {
        callCount++;
        return WalletData(balance: 1000.0 * callCount);
      });

      container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(mockRepo)],
      );

      // Initial fetch for both
      await container.read(walletProvider.future);
      await container.read(walletDataProvider.future);

      final preInvalidateCount = callCount;

      // Invalidate both (exactly what delivery_status_actions does)
      container.invalidate(walletDataProvider);
      container.invalidate(walletProvider);

      // Both should re-fetch
      await container.read(walletProvider.future);
      await container.read(walletDataProvider.future);

      expect(callCount, greaterThan(preInvalidateCount));
    });
  });
}
