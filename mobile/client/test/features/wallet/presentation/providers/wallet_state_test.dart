import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/wallet/presentation/providers/wallet_state.dart';
import 'package:drpharma_client/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  const stats = WalletStatistics();
  const testWallet = WalletEntity(
    balance: 10000,
    availableBalance: 9500,
    pendingWithdrawals: 500,
    statistics: stats,
  );

  group('WalletState — initial', () {
    test('WalletState.initial() sets correct defaults', () {
      const s = WalletState.initial();
      expect(s.status, WalletStatus.initial);
      expect(s.wallet, isNull);
      expect(s.transactions, isEmpty);
      expect(s.errorMessage, isNull);
      expect(s.successMessage, isNull);
    });

    test('balance defaults to 0 when no wallet', () {
      const s = WalletState.initial();
      expect(s.balance, 0);
      expect(s.availableBalance, 0);
      expect(s.currency, 'XOF');
    });

    test('isLoading false for initial status', () {
      expect(const WalletState.initial().isLoading, isFalse);
    });
  });

  group('WalletState — balance helpers', () {
    test('balance returns wallet.balance when wallet set', () {
      final s = const WalletState.initial().copyWith(
        wallet: testWallet,
        status: WalletStatus.loaded,
      );
      expect(s.balance, 10000);
    });

    test('availableBalance returns wallet.availableBalance', () {
      final s = const WalletState.initial().copyWith(
        wallet: testWallet,
        status: WalletStatus.loaded,
      );
      expect(s.availableBalance, 9500);
    });

    test('currency returns wallet currency', () {
      const w = WalletEntity(
        balance: 0,
        availableBalance: 0,
        currency: 'EUR',
        statistics: stats,
      );
      final s = const WalletState.initial().copyWith(wallet: w);
      expect(s.currency, 'EUR');
    });
  });

  group('WalletState — isLoading', () {
    test('isLoading true when status == loading', () {
      final s = const WalletState.initial().copyWith(
        status: WalletStatus.loading,
      );
      expect(s.isLoading, isTrue);
    });

    test('isLoading false when status == loaded', () {
      final s = const WalletState.initial().copyWith(
        status: WalletStatus.loaded,
      );
      expect(s.isLoading, isFalse);
    });
  });

  group('WalletState — copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final s1 = const WalletState.initial().copyWith(
        wallet: testWallet,
        status: WalletStatus.loaded,
      );
      final s2 = s1.copyWith(errorMessage: 'error');
      expect(s2.wallet, testWallet);
      expect(s2.status, WalletStatus.loaded);
      expect(s2.errorMessage, 'error');
    });

    test('clearError removes errorMessage', () {
      final s1 = const WalletState.initial().copyWith(
        errorMessage: 'some error',
      );
      final s2 = s1.copyWith(clearError: true);
      expect(s2.errorMessage, isNull);
    });

    test('clearSuccess removes successMessage', () {
      final s1 = const WalletState.initial().copyWith(successMessage: 'done');
      final s2 = s1.copyWith(clearSuccess: true);
      expect(s2.successMessage, isNull);
    });

    test('copyWith with transactions replaces list', () {
      final tx = WalletTransactionEntity(
        id: 1,
        type: TransactionType.credit,
        category: TransactionCategory.topup,
        amount: 5000,
        balanceAfter: 5000,
        reference: 'REF-1',
        description: 'Test',
        createdAt: DateTime(2024),
      );
      final s = const WalletState.initial().copyWith(transactions: [tx]);
      expect(s.transactions.length, 1);
    });
  });

  group('WalletState — props', () {
    test('two identical states are equal', () {
      const a = WalletState.initial();
      const b = WalletState.initial();
      expect(a, equals(b));
    });

    test('different status makes states unequal', () {
      const a = WalletState.initial();
      final b = const WalletState.initial().copyWith(
        status: WalletStatus.loading,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
