import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  group('WalletEntity', () {
    test('netBalance returns the balance value', () {
      const wallet = WalletEntity(
        balance: 50000,
        currency: 'XOF',
        totalEarnings: 100000,
        totalCommissionPaid: 5000,
        transactions: [],
      );
      expect(wallet.netBalance, 50000);
    });

    test('averageCommissionRate computes correctly', () {
      const wallet = WalletEntity(
        balance: 50000,
        currency: 'XOF',
        totalEarnings: 100000,
        totalCommissionPaid: 5000,
        transactions: [],
      );
      expect(wallet.averageCommissionRate, 5.0);
    });

    test('averageCommissionRate is 0 when totalEarnings is 0', () {
      const wallet = WalletEntity(
        balance: 0,
        currency: 'XOF',
        totalEarnings: 0,
        totalCommissionPaid: 0,
        transactions: [],
      );
      expect(wallet.averageCommissionRate, 0);
    });
  });

  group('TransactionType', () {
    test('fromString returns credit for "credit"', () {
      expect(TransactionType.fromString('credit'), TransactionType.credit);
    });

    test('fromString returns debit for "debit"', () {
      expect(TransactionType.fromString('debit'), TransactionType.debit);
    });

    test('fromString returns unknown for invalid value', () {
      expect(TransactionType.fromString('invalid'), TransactionType.unknown);
    });

    test('fromString returns unknown for null', () {
      expect(TransactionType.fromString(null), TransactionType.unknown);
    });

    test('fromString is case-insensitive', () {
      expect(TransactionType.fromString('CREDIT'), TransactionType.credit);
      expect(TransactionType.fromString('Debit'), TransactionType.debit);
    });
  });

  group('TransactionEntity', () {
    test('isCredit returns true for credit type', () {
      const tx = TransactionEntity(
        id: 1,
        amount: 1000,
        type: TransactionType.credit,
      );
      expect(tx.isCredit, true);
      expect(tx.isDebit, false);
    });

    test('isDebit returns true for debit type', () {
      const tx = TransactionEntity(
        id: 2,
        amount: 500,
        type: TransactionType.debit,
      );
      expect(tx.isDebit, true);
      expect(tx.isCredit, false);
    });
  });

  group('WithdrawalSettingsEntity', () {
    test('isAutoWithdrawReady with mobile money and pin', () {
      const settings = WithdrawalSettingsEntity(
        threshold: 50000,
        autoWithdraw: true,
        hasPin: true,
        hasMobileMoney: true,
        hasBankInfo: false,
      );
      expect(settings.isAutoWithdrawReady, true);
    });

    test('isAutoWithdrawReady false when autoWithdraw disabled', () {
      const settings = WithdrawalSettingsEntity(
        threshold: 50000,
        autoWithdraw: false,
        hasPin: true,
        hasMobileMoney: true,
      );
      expect(settings.isAutoWithdrawReady, false);
    });

    test('isAutoWithdrawReady false when no payment method', () {
      const settings = WithdrawalSettingsEntity(
        threshold: 50000,
        autoWithdraw: true,
        hasPin: true,
        hasMobileMoney: false,
        hasBankInfo: false,
      );
      expect(settings.isAutoWithdrawReady, false);
    });

    test('isAutoWithdrawReady false when pin required but missing', () {
      const settings = WithdrawalSettingsEntity(
        threshold: 50000,
        autoWithdraw: true,
        hasPin: false,
        hasMobileMoney: true,
        config: WithdrawalConfigEntity(requirePin: true),
      );
      expect(settings.isAutoWithdrawReady, false);
    });

    test('isAutoWithdrawReady true with bank info and no pin required', () {
      const settings = WithdrawalSettingsEntity(
        threshold: 50000,
        autoWithdraw: true,
        hasPin: false,
        hasMobileMoney: false,
        hasBankInfo: true,
        config: WithdrawalConfigEntity(requirePin: false),
      );
      expect(settings.isAutoWithdrawReady, true);
    });
  });

  group('WalletStatsEntity', () {
    test('netBalance computes credits minus debits', () {
      const stats = WalletStatsEntity(
        totalCredits: 100000,
        totalDebits: 30000,
        transactionCount: 10,
        averageTransaction: 13000,
        period: 'month',
      );
      expect(stats.netBalance, 70000);
    });

    test('netBalance can be negative', () {
      const stats = WalletStatsEntity(
        totalCredits: 10000,
        totalDebits: 30000,
        transactionCount: 5,
        averageTransaction: 8000,
        period: 'week',
      );
      expect(stats.netBalance, -20000);
    });
  });
}
