import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/wallet_data.dart';

void main() {
  group('WalletData', () {
    test('fromJson with full data', () {
      final json = {
        'balance': '15000',
        'currency': 'FCFA',
        'pending_payouts': '2000',
        'available_balance': '13000',
        'can_deliver': true,
        'commission_amount': 300,
        'total_topups': '5000',
        'total_earnings': '20000',
        'total_commissions': '3000',
        'deliveries_count': 15,
        'transactions': [
          {
            'id': 1,
            'amount': '1500',
            'type': 'Credit',
            'category': 'commission',
            'description': 'Commission livraison #12',
            'reference': 'TXN-001',
            'status': 'completed',
            'delivery_id': 12,
            'created_at': '2025-01-15T10:00:00.000Z',
          },
        ],
      };

      final wallet = WalletData.fromJson(json);

      expect(wallet.balance, 15000.0);
      expect(wallet.currency, 'FCFA');
      expect(wallet.pendingPayouts, 2000.0);
      expect(wallet.availableBalance, 13000.0);
      expect(wallet.canDeliver, isTrue);
      expect(wallet.commissionAmount, 300);
      expect(wallet.totalTopups, 5000.0);
      expect(wallet.totalEarnings, 20000.0);
      expect(wallet.totalCommissions, 3000.0);
      expect(wallet.deliveriesCount, 15);
      expect(wallet.transactions, hasLength(1));
    });

    test('fromJson with defaults', () {
      final json = {'balance': '0'};

      final wallet = WalletData.fromJson(json);

      expect(wallet.balance, 0.0);
      expect(wallet.currency, 'XOF');
      expect(wallet.transactions, isEmpty);
      expect(wallet.canDeliver, isTrue);
      expect(wallet.commissionAmount, 200);
      expect(wallet.totalTopups, 0.0);
      expect(wallet.totalEarnings, 0.0);
      expect(wallet.deliveriesCount, 0);
    });

    test('fromJson handles numeric balance', () {
      final json = {'balance': 5000.50};
      final wallet = WalletData.fromJson(json);
      expect(wallet.balance, 5000.50);
    });

    test('copyWith creates modified copy', () {
      final original = WalletData(balance: 1000);
      final modified = original.copyWith(balance: 2000, currency: 'FCFA');

      expect(modified.balance, 2000);
      expect(modified.currency, 'FCFA');
      expect(original.balance, 1000);
    });

    test('equality works', () {
      const a = WalletData(balance: 1000);
      const b = WalletData(balance: 1000);
      const c = WalletData(balance: 2000);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('WalletTransaction', () {
    test('fromJson with full data', () {
      final json = {
        'id': 1,
        'amount': '1500',
        'type': 'Credit',
        'category': 'commission',
        'description': 'Commission livraison',
        'reference': 'TXN-001',
        'status': 'completed',
        'delivery_id': 12,
        'created_at': '2025-01-15T10:00:00.000Z',
      };

      final tx = WalletTransaction.fromJson(json);

      expect(tx.id, 1);
      expect(tx.amount, 1500.0);
      expect(tx.type, 'credit'); // lowercased
      expect(tx.category, 'commission');
      expect(tx.description, 'Commission livraison');
      expect(tx.reference, 'TXN-001');
      expect(tx.status, 'completed');
      expect(tx.deliveryId, 12);
      expect(tx.createdAt, DateTime.utc(2025, 1, 15, 10));
    });

    test('fromJson fallback to date field', () {
      final json = {
        'id': 2,
        'amount': '500',
        'date': '2025-02-01T12:00:00.000Z',
      };

      final tx = WalletTransaction.fromJson(json);
      expect(tx.createdAt, DateTime.utc(2025, 2, 1, 12));
    });

    test('computed getters', () {
      final credit = WalletTransaction(
        id: 1,
        amount: 1000,
        type: 'credit',
        category: 'commission',
        createdAt: DateTime.now(),
      );

      expect(credit.isCredit, isTrue);
      expect(credit.isCommission, isTrue);
      expect(credit.isTopUp, isFalse);
      expect(credit.isWithdrawal, isFalse);

      final topup = WalletTransaction(
        id: 2,
        amount: 500,
        type: 'credit',
        category: 'topup',
        createdAt: DateTime.now(),
      );

      expect(topup.isTopUp, isTrue);
      expect(topup.isCommission, isFalse);

      final withdrawal = WalletTransaction(
        id: 3,
        amount: 2000,
        type: 'debit',
        category: 'withdrawal',
        createdAt: DateTime.now(),
      );

      expect(withdrawal.isCredit, isFalse);
      expect(withdrawal.isWithdrawal, isTrue);
    });

    test('type defaults to debit', () {
      final json = {
        'id': 1,
        'amount': '100',
        'created_at': '2025-01-01T00:00:00.000Z',
      };

      final tx = WalletTransaction.fromJson(json);
      expect(tx.type, 'debit');
    });

    test('fromJson with invalid date falls back to now', () {
      final before = DateTime.now();
      final tx = WalletTransaction.fromJson({
        'id': 1,
        'amount': '100',
        'created_at': 'not-a-date',
      });
      final after = DateTime.now();
      expect(
        tx.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        tx.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('fromJson with null date falls back to now', () {
      final before = DateTime.now();
      final tx = WalletTransaction.fromJson({'id': 1, 'amount': '100'});
      final after = DateTime.now();
      expect(
        tx.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        tx.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('fromJson defaults id to 0 when missing', () {
      final tx = WalletTransaction.fromJson({
        'amount': '100',
        'created_at': '2025-01-01T00:00:00.000Z',
      });
      expect(tx.id, 0);
    });
  });

  group('WalletData statistics fallback', () {
    test('picks values from nested statistics when not at top level', () {
      final json = {
        'balance': '10000',
        'statistics': {
          'total_topups': '5000',
          'total_earnings': '8000',
          'total_commissions': '1200',
          'deliveries_count': 20,
          'today_earnings': '500',
        },
      };
      final wallet = WalletData.fromJson(json);
      expect(wallet.totalTopups, 5000.0);
      expect(wallet.totalEarnings, 8000.0);
      expect(wallet.totalCommissions, 1200.0);
      expect(wallet.deliveriesCount, 20);
      expect(wallet.todayEarnings, 500.0);
    });

    test('top-level values take priority over statistics', () {
      final json = {
        'balance': '10000',
        'total_topups': '9000',
        'statistics': {'total_topups': '5000'},
      };
      final wallet = WalletData.fromJson(json);
      expect(wallet.totalTopups, 9000.0);
    });

    test('total_delivery_earnings takes priority over total_earnings', () {
      final json = {
        'balance': '10000',
        'total_delivery_earnings': '15000',
        'total_earnings': '8000',
      };
      final wallet = WalletData.fromJson(json);
      expect(wallet.totalEarnings, 15000.0);
    });

    test('falls back to total_earnings when total_delivery_earnings is 0', () {
      final json = {
        'balance': '10000',
        'total_delivery_earnings': '0',
        'total_earnings': '8000',
      };
      final wallet = WalletData.fromJson(json);
      expect(wallet.totalEarnings, 8000.0);
    });

    test('pendingPayouts parses string', () {
      final wallet = WalletData.fromJson({
        'balance': '0',
        'pending_payouts': '3500',
      });
      expect(wallet.pendingPayouts, 3500.0);
    });

    test('pendingPayouts null defaults to 0', () {
      final wallet = WalletData.fromJson({'balance': '0'});
      expect(wallet.pendingPayouts, 0.0);
    });

    test('availableBalance parses when present', () {
      final wallet = WalletData.fromJson({
        'balance': '10000',
        'available_balance': '8000',
      });
      expect(wallet.availableBalance, 8000.0);
    });

    test('availableBalance is null when missing', () {
      final wallet = WalletData.fromJson({'balance': '10000'});
      expect(wallet.availableBalance, isNull);
    });

    test('todayEarnings from statistics', () {
      final wallet = WalletData.fromJson({
        'balance': '0',
        'statistics': {'today_earnings': '1250'},
      });
      expect(wallet.todayEarnings, 1250.0);
    });
  });
}
