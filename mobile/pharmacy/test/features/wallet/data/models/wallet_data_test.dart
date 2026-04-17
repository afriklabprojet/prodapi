import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/wallet/data/models/wallet_data.dart';

void main() {
  group('WalletData.fromJson', () {
    test('parses complete valid JSON', () {
      final json = {
        'balance': '50000',
        'currency': 'XOF',
        'total_earnings': 100000,
        'total_commission_paid': '5000',
        'transactions': [
          {
            'id': 1,
            'amount': '2500.50',
            'type': 'credit',
            'description': 'Order #DR-001',
            'reference': 'REF-001',
            'date': '2026-03-14',
          },
        ],
      };

      final wallet = WalletData.fromJson(json);

      expect(wallet.balance, 50000.0);
      expect(wallet.currency, 'XOF');
      expect(wallet.totalEarnings, 100000.0);
      expect(wallet.totalCommissionPaid, 5000.0);
      expect(wallet.transactions.length, 1);
      expect(wallet.transactions.first.id, 1);
      expect(wallet.transactions.first.amount, 2500.50);
      expect(wallet.transactions.first.type, 'credit');
    });

    test('handles missing fields with defaults', () {
      final wallet = WalletData.fromJson({});

      expect(wallet.balance, 0.0);
      expect(wallet.currency, 'XOF');
      expect(wallet.totalEarnings, 0.0);
      expect(wallet.totalCommissionPaid, 0.0);
      expect(wallet.transactions, isEmpty);
    });

    test('handles null balance gracefully', () {
      final wallet = WalletData.fromJson({'balance': null});
      expect(wallet.balance, 0.0);
    });

    test('parses numeric balance (not string)', () {
      final wallet = WalletData.fromJson({'balance': 12345});
      expect(wallet.balance, 12345.0);
    });
  });

  group('WalletTransaction.fromJson', () {
    test('parses complete transaction', () {
      final json = {
        'id': 42,
        'amount': '7500',
        'type': 'debit',
        'description': 'Retrait',
        'reference': 'WD-42',
        'date': '2026-03-14 10:30:00',
      };

      final tx = WalletTransaction.fromJson(json);

      expect(tx.id, 42);
      expect(tx.amount, 7500.0);
      expect(tx.type, 'debit');
      expect(tx.description, 'Retrait');
      expect(tx.reference, 'WD-42');
      expect(tx.date, '2026-03-14 10:30:00');
    });

    test('handles missing fields', () {
      final tx = WalletTransaction.fromJson({});

      expect(tx.id, 0);
      expect(tx.amount, 0.0);
      expect(tx.type, 'unknown');
      expect(tx.description, isNull);
      expect(tx.reference, isNull);
      expect(tx.date, isNull);
    });
  });

  group('WithdrawalSettings.fromJson', () {
    test('parses complete settings', () {
      final json = {
        'threshold': 75000,
        'auto_withdraw': true,
        'has_pin': true,
        'has_mobile_money': true,
        'has_bank_info': false,
        'config': {
          'min_threshold': 5000,
          'max_threshold': 1000000,
          'default_threshold': 50000,
          'step': 10000,
          'auto_withdraw_allowed': true,
          'require_pin': true,
          'require_mobile_money': false,
        },
      };

      final settings = WithdrawalSettings.fromJson(json);

      expect(settings.threshold, 75000);
      expect(settings.autoWithdraw, true);
      expect(settings.hasPin, true);
      expect(settings.hasMobileMoney, true);
      expect(settings.hasBankInfo, false);
      expect(settings.config.minThreshold, 5000);
      expect(settings.config.maxThreshold, 1000000);
      expect(settings.config.step, 10000);
      expect(settings.config.requireMobileMoney, false);
    });

    test('uses defaults for missing fields', () {
      final settings = WithdrawalSettings.fromJson({});

      expect(settings.threshold, 50000);
      expect(settings.autoWithdraw, false);
      expect(settings.hasPin, false);
      expect(settings.config.minThreshold, 10000);
      expect(settings.config.maxThreshold, 500000);
    });

    test('toJson produces correct map', () {
      final settings = WithdrawalSettings(
        threshold: 75000,
        autoWithdraw: true,
        hasPin: true,
        hasMobileMoney: true,
        hasBankInfo: false,
      );

      final json = settings.toJson();

      expect(json['threshold'], 75000);
      expect(json['auto_withdraw'], true);
      expect(json['has_pin'], true);
      expect(json['has_mobile_money'], true);
      expect(json['has_bank_info'], false);
    });
  });

  group('WithdrawalConfig', () {
    test('defaults() returns expected values', () {
      final config = WithdrawalConfig.defaults();

      expect(config.minThreshold, 10000);
      expect(config.maxThreshold, 500000);
      expect(config.defaultThreshold, 50000);
      expect(config.step, 5000);
      expect(config.autoWithdrawAllowed, true);
      expect(config.requirePin, true);
      expect(config.requireMobileMoney, true);
    });

    test('fromJson parses correctly', () {
      final config = WithdrawalConfig.fromJson({
        'min_threshold': 20000,
        'max_threshold': 200000,
        'default_threshold': 100000,
        'step': 10000,
        'auto_withdraw_allowed': false,
        'require_pin': false,
        'require_mobile_money': false,
      });

      expect(config.minThreshold, 20000);
      expect(config.maxThreshold, 200000);
      expect(config.autoWithdrawAllowed, false);
      expect(config.requirePin, false);
    });
  });
}
