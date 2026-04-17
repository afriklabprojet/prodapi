import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/wallet_repository.dart';
import 'package:courier/data/models/wallet_data.dart';
import 'package:courier/presentation/providers/wallet_provider.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  group('walletProvider', () {
    late MockWalletRepository mockRepo;

    setUp(() {
      mockRepo = MockWalletRepository();
    });

    test('returns WalletData when getWalletData succeeds', () async {
      final testData = WalletData.fromJson({
        'balance': 15000,
        'transactions': [],
      });
      when(() => mockRepo.getWalletData()).thenAnswer((_) async => testData);

      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(walletProvider.future);
      expect(result, isA<WalletData>());
      verify(() => mockRepo.getWalletData()).called(1);
    });
  });

  group('walletDataProvider', () {
    late MockWalletRepository mockRepo;

    setUp(() {
      mockRepo = MockWalletRepository();
    });

    test('returns WalletData on success', () async {
      final testData = WalletData.fromJson({
        'balance': 10000,
        'transactions': [],
      });
      when(() => mockRepo.getWalletData()).thenAnswer((_) async => testData);

      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final result = await container.read(walletDataProvider.future);
      expect(result, isA<WalletData>());
    });
  });
}
