import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // PaymentInitResult
  // ────────────────────────────────────────────────────────────────────────────
  group('PaymentInitResult', () {
    test('fromJson parses all required fields', () {
      final json = {
        'reference': 'REF-001',
        'redirect_url': 'https://pay.jeko.ci/session',
        'amount': 5000,
        'currency': 'XOF',
        'payment_method': 'mobile_money',
      };
      final result = PaymentInitResult.fromJson(json);
      expect(result.reference, 'REF-001');
      expect(result.redirectUrl, 'https://pay.jeko.ci/session');
      expect(result.amount, 5000);
      expect(result.currency, 'XOF');
      expect(result.paymentMethod, 'mobile_money');
    });

    test('fromJson uses XOF as default currency when absent', () {
      final json = {
        'reference': 'REF-002',
        'redirect_url': 'https://pay.jeko.ci/x',
        'amount': 2000,
        'payment_method': 'card',
      };
      final result = PaymentInitResult.fromJson(json);
      expect(result.currency, 'XOF');
    });

    test('props are correct', () {
      const a = PaymentInitResult(
        reference: 'REF-A',
        redirectUrl: 'https://a.com',
        amount: 1000,
        currency: 'XOF',
        paymentMethod: 'mm',
      );
      const b = PaymentInitResult(
        reference: 'REF-A',
        redirectUrl: 'https://a.com',
        amount: 1000,
        currency: 'EUR',
        paymentMethod: 'card',
      );
      expect(a, equals(b)); // props only include reference, redirectUrl, amount
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // PaymentStatusResult
  // ────────────────────────────────────────────────────────────────────────────
  group('PaymentStatusResult', () {
    test('fromJson parses all fields', () {
      final json = {
        'reference': 'REF-123',
        'payment_status': 'success',
        'payment_status_label': 'Paiement réussi',
        'is_final': true,
        'amount': 3000,
        'error_message': null,
      };
      final result = PaymentStatusResult.fromJson(json);
      expect(result.reference, 'REF-123');
      expect(result.status, 'success');
      expect(result.statusLabel, 'Paiement réussi');
      expect(result.isFinal, isTrue);
      expect(result.amount, 3000);
      expect(result.errorMessage, isNull);
    });

    test('fromJson uses defaults when optional fields absent', () {
      final json = {
        'reference': 'REF-X',
        'payment_status': 'pending',
        'amount': 1000,
      };
      final result = PaymentStatusResult.fromJson(json);
      // statusLabel defaults to paymentStatus when not explicitly provided
      expect(result.statusLabel, 'pending');
      expect(result.isFinal, isFalse);
      expect(result.errorMessage, isNull);
    });

    test('isSuccess true when status == success', () {
      final r = PaymentStatusResult.fromJson({
        'reference': 'R',
        'payment_status': 'success',
        'amount': 100,
      });
      expect(r.isSuccess, isTrue);
      expect(r.isFailed, isFalse);
    });

    test('isFailed true when status == failed', () {
      final r = PaymentStatusResult.fromJson({
        'reference': 'R',
        'payment_status': 'failed',
        'amount': 100,
      });
      expect(r.isFailed, isTrue);
      expect(r.isSuccess, isFalse);
    });

    test('isFailed true when status == expired', () {
      final r = PaymentStatusResult.fromJson({
        'reference': 'R',
        'payment_status': 'expired',
        'amount': 100,
      });
      expect(r.isFailed, isTrue);
    });

    test('isSuccess and isFailed are false for pending status', () {
      final r = PaymentStatusResult.fromJson({
        'reference': 'R',
        'payment_status': 'pending',
        'amount': 100,
      });
      expect(r.isSuccess, isFalse);
      expect(r.isFailed, isFalse);
    });

    test('props equality uses reference, status, isFinal', () {
      const a = PaymentStatusResult(
        reference: 'R',
        status: 'success',
        statusLabel: 'A',
        isFinal: true,
        amount: 100,
      );
      const b = PaymentStatusResult(
        reference: 'R',
        status: 'success',
        statusLabel: 'B',
        isFinal: true,
        amount: 999,
      );
      expect(a, equals(b));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // WalletStatistics
  // ────────────────────────────────────────────────────────────────────────────
  group('WalletStatistics', () {
    test('default constructor has zero values', () {
      const s = WalletStatistics();
      expect(s.totalTopups, 0);
      expect(s.totalOrderPayments, 0);
      expect(s.totalRefunds, 0);
      expect(s.totalWithdrawals, 0);
      expect(s.ordersPaid, 0);
    });

    test('custom values stored correctly', () {
      const s = WalletStatistics(
        totalTopups: 10000,
        totalOrderPayments: 5000,
        totalRefunds: 500,
        totalWithdrawals: 2000,
        ordersPaid: 3,
      );
      expect(s.totalTopups, 10000);
      expect(s.ordersPaid, 3);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // WalletEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('WalletEntity', () {
    const stats = WalletStatistics();

    test('canWithdraw true when availableBalance >= minimumWithdrawal', () {
      const w = WalletEntity(
        balance: 2000,
        availableBalance: 1000,
        minimumWithdrawal: 500,
        statistics: stats,
      );
      expect(w.canWithdraw, isTrue);
    });

    test('canWithdraw false when availableBalance < minimumWithdrawal', () {
      const w = WalletEntity(
        balance: 300,
        availableBalance: 300,
        minimumWithdrawal: 500,
        statistics: stats,
      );
      expect(w.canWithdraw, isFalse);
    });

    test('canWithdraw true when exactly at minimum', () {
      const w = WalletEntity(
        balance: 500,
        availableBalance: 500,
        minimumWithdrawal: 500,
        statistics: stats,
      );
      expect(w.canWithdraw, isTrue);
    });

    test('default currency is XOF', () {
      const w = WalletEntity(
        balance: 0,
        availableBalance: 0,
        statistics: stats,
      );
      expect(w.currency, 'XOF');
    });

    test(
      'props equality based on balance, currency, pendingWithdrawals, availableBalance',
      () {
        const a = WalletEntity(
          balance: 1000,
          availableBalance: 800,
          pendingWithdrawals: 200,
          statistics: stats,
        );
        const b = WalletEntity(
          balance: 1000,
          availableBalance: 800,
          pendingWithdrawals: 200,
          minimumWithdrawal: 9999,
          statistics: stats,
        );
        expect(a, equals(b));
      },
    );
  });

  // ────────────────────────────────────────────────────────────────────────────
  // WalletTransactionEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('WalletTransactionEntity', () {
    final createdAt = DateTime(2024, 3, 15);

    WalletTransactionEntity make({
      TransactionType type = TransactionType.credit,
      TransactionCategory category = TransactionCategory.topup,
      String? status,
    }) {
      return WalletTransactionEntity(
        id: 1,
        type: type,
        category: category,
        amount: 5000,
        balanceAfter: 10000,
        reference: 'TXN-001',
        description: 'Test transaction',
        status: status,
        createdAt: createdAt,
      );
    }

    test('isCredit true for credit type', () {
      expect(make(type: TransactionType.credit).isCredit, isTrue);
      expect(make(type: TransactionType.credit).isDebit, isFalse);
    });

    test('isDebit true for debit type', () {
      expect(make(type: TransactionType.debit).isDebit, isTrue);
      expect(make(type: TransactionType.debit).isCredit, isFalse);
    });

    test('isPending true when status == pending', () {
      expect(make(status: 'pending').isPending, isTrue);
    });

    test('isPending false when status != pending', () {
      expect(make(status: 'completed').isPending, isFalse);
      expect(make(status: null).isPending, isFalse);
    });

    group('categoryLabel', () {
      test('topup → Rechargement', () {
        expect(
          make(category: TransactionCategory.topup).categoryLabel,
          'Rechargement',
        );
      });
      test('orderPayment → Paiement commande', () {
        expect(
          make(category: TransactionCategory.orderPayment).categoryLabel,
          'Paiement commande',
        );
      });
      test('refund → Remboursement', () {
        expect(
          make(category: TransactionCategory.refund).categoryLabel,
          'Remboursement',
        );
      });
      test('withdrawal → Retrait', () {
        expect(
          make(category: TransactionCategory.withdrawal).categoryLabel,
          'Retrait',
        );
      });
    });
  });
}
