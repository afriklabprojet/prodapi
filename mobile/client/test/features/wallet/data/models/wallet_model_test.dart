import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/features/wallet/data/models/wallet_model.dart';
import 'package:drpharma_client/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // WalletModel
  // ────────────────────────────────────────────────────────────────────────────
  group('WalletModel.fromJson', () {
    test('parses complete JSON correctly', () {
      final json = {
        'balance': 15000.0,
        'currency': 'XOF',
        'pending_withdrawals': 500.0,
        'available_balance': 14500.0,
        'minimum_withdrawal': 1000,
        'statistics': {
          'total_topups': 20000.0,
          'total_order_payments': 4000.0,
          'total_refunds': 500.0,
          'total_withdrawals': 1000.0,
          'orders_paid': 3,
        },
      };

      final model = WalletModel.fromJson(json);

      expect(model.balance, 15000.0);
      expect(model.currency, 'XOF');
      expect(model.pendingWithdrawals, 500.0);
      expect(model.availableBalance, 14500.0);
      expect(model.minimumWithdrawal, 1000);
      expect(model.statistics.totalTopups, 20000.0);
      expect(model.statistics.ordersPaid, 3);
    });

    test('uses default XOF when currency missing', () {
      final json = <String, dynamic>{
        'balance': 0,
        'available_balance': 0,
        'statistics': <String, dynamic>{},
      };
      final model = WalletModel.fromJson(json);
      expect(model.currency, 'XOF');
    });

    test('parses numeric strings for balance', () {
      final json = <String, dynamic>{
        'balance': '5000',
        'available_balance': '5000',
        'statistics': <String, dynamic>{},
      };
      final model = WalletModel.fromJson(json);
      expect(model.balance, 5000.0);
    });

    test('handles null balance as 0', () {
      final json = <String, dynamic>{
        'balance': null,
        'available_balance': null,
        'statistics': <String, dynamic>{},
      };
      final model = WalletModel.fromJson(json);
      expect(model.balance, 0.0);
    });

    test('converts to WalletEntity correctly', () {
      final json = <String, dynamic>{
        'balance': 10000.0,
        'available_balance': 9500.0,
        'minimum_withdrawal': 500,
        'statistics': <String, dynamic>{'orders_paid': 2},
      };
      final entity = WalletModel.fromJson(json).toEntity();
      expect(entity, isA<WalletEntity>());
      expect(entity.balance, 10000.0);
      expect(entity.minimumWithdrawal, 500);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // WalletStatisticsModel
  // ────────────────────────────────────────────────────────────────────────────
  group('WalletStatisticsModel.fromJson', () {
    test('parses all statistics fields', () {
      final json = {
        'total_topups': 10000,
        'total_order_payments': 3000,
        'total_refunds': 200,
        'total_withdrawals': 1500,
        'orders_paid': 5,
      };
      final stats = WalletStatisticsModel.fromJson(json);
      expect(stats.totalTopups, 10000.0);
      expect(stats.totalOrderPayments, 3000.0);
      expect(stats.totalRefunds, 200.0);
      expect(stats.totalWithdrawals, 1500.0);
      expect(stats.ordersPaid, 5);
    });

    test('defaults all fields to 0 when missing', () {
      final stats = WalletStatisticsModel.fromJson(<String, dynamic>{});
      expect(stats.totalTopups, 0.0);
      expect(stats.ordersPaid, 0);
    });

    test('converts to WalletStatistics entity', () {
      final stats = WalletStatisticsModel.fromJson(<String, dynamic>{
        'orders_paid': 10,
      });
      final entity = stats.toEntity();
      expect(entity.ordersPaid, 10);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // WalletTransactionModel
  // ────────────────────────────────────────────────────────────────────────────
  group('WalletTransactionModel.fromJson', () {
    Map<String, dynamic> txJson({
      String type = 'CREDIT',
      String category = 'topup',
    }) => {
      'id': 101,
      'type': type,
      'category': category,
      'amount': 5000.0,
      'balance_after': 20000.0,
      'reference': 'REF-123',
      'description': 'Rechargement Mobile Money',
      'status': 'completed',
      'payment_method': 'orange_money',
      'created_at': '2024-06-01T10:00:00.000Z',
    };

    test('parses credit transaction', () {
      final model = WalletTransactionModel.fromJson(txJson());
      expect(model.id, 101);
      expect(model.type, 'CREDIT');
      expect(model.amount, 5000.0);
      expect(model.reference, 'REF-123');
      expect(model.paymentMethod, 'orange_money');
    });

    test('converts credit to WalletTransactionEntity with correct type', () {
      final entity = WalletTransactionModel.fromJson(
        txJson(type: 'CREDIT'),
      ).toEntity();
      expect(entity.type, TransactionType.credit);
      expect(entity.isCredit, isTrue);
      expect(entity.isDebit, isFalse);
    });

    test('converts debit to WalletTransactionEntity with correct type', () {
      final entity = WalletTransactionModel.fromJson(
        txJson(type: 'DEBIT'),
      ).toEntity();
      expect(entity.type, TransactionType.debit);
      expect(entity.isDebit, isTrue);
    });

    test('maps category topup correctly', () {
      final entity = WalletTransactionModel.fromJson(
        txJson(category: 'topup'),
      ).toEntity();
      expect(entity.category, TransactionCategory.topup);
      expect(entity.categoryLabel, 'Rechargement');
    });

    test('maps category order_payment correctly', () {
      final entity = WalletTransactionModel.fromJson(
        txJson(category: 'order_payment'),
      ).toEntity();
      expect(entity.category, TransactionCategory.orderPayment);
      expect(entity.categoryLabel, 'Paiement commande');
    });

    test('maps category refund correctly', () {
      final entity = WalletTransactionModel.fromJson(
        txJson(category: 'refund'),
      ).toEntity();
      expect(entity.category, TransactionCategory.refund);
      expect(entity.categoryLabel, 'Remboursement');
    });

    test('maps category withdrawal correctly', () {
      final entity = WalletTransactionModel.fromJson(
        txJson(category: 'withdrawal'),
      ).toEntity();
      expect(entity.category, TransactionCategory.withdrawal);
      expect(entity.categoryLabel, 'Retrait');
    });

    test('uses default values for missing fields', () {
      final model = WalletTransactionModel.fromJson({'id': 0});
      expect(model.type, 'CREDIT');
      expect(model.category, 'topup');
      expect(model.amount, 0.0);
    });

    test('handles string id', () {
      final model = WalletTransactionModel.fromJson({
        'id': '200',
        'created_at': '',
      });
      expect(model.id, 200);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // WalletEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('WalletEntity', () {
    WalletEntity entity0({
      double balance = 10000,
      double available = 9000,
      int minWithdraw = 500,
    }) => WalletEntity(
      balance: balance,
      availableBalance: available,
      minimumWithdrawal: minWithdraw,
      statistics: const WalletStatistics(),
    );

    test('canWithdraw returns true when availableBalance >= minimum', () {
      expect(entity0(available: 1000, minWithdraw: 500).canWithdraw, isTrue);
      expect(entity0(available: 500, minWithdraw: 500).canWithdraw, isTrue);
    });

    test('canWithdraw returns false when availableBalance < minimum', () {
      expect(entity0(available: 400, minWithdraw: 500).canWithdraw, isFalse);
      expect(entity0(available: 0, minWithdraw: 500).canWithdraw, isFalse);
    });

    test('props equality', () {
      final a = entity0(balance: 5000);
      final b = entity0(balance: 5000);
      expect(a, b);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // WalletTransactionEntity computed properties
  // ────────────────────────────────────────────────────────────────────────────
  group('WalletTransactionEntity', () {
    WalletTransactionEntity tx({
      TransactionType type = TransactionType.credit,
      String? status,
    }) => WalletTransactionEntity(
      id: 1,
      type: type,
      category: TransactionCategory.topup,
      amount: 1000,
      balanceAfter: 11000,
      reference: 'REF',
      description: 'Test',
      status: status,
      createdAt: DateTime(2024),
    );

    test(
      'isCredit is true for credit transactions',
      () => expect(tx().isCredit, isTrue),
    );
    test(
      'isDebit is true for debit transactions',
      () => expect(tx(type: TransactionType.debit).isDebit, isTrue),
    );
    test(
      'isPending when status is pending',
      () => expect(tx(status: 'pending').isPending, isTrue),
    );
    test(
      'isPending is false for non-pending status',
      () => expect(tx(status: 'completed').isPending, isFalse),
    );
  });

  // ────────────────────────────────────────────────────────────────────────────
  // PaymentInitResult
  // ────────────────────────────────────────────────────────────────────────────
  group('PaymentInitResult', () {
    test('parses JSON correctly', () {
      final json = {
        'reference': 'PAY-001',
        'redirect_url': 'https://pay.jeko.com/001',
        'amount': 5000,
        'currency': 'XOF',
        'payment_method': 'orange_money',
      };
      final result = PaymentInitResult.fromJson(json);
      expect(result.reference, 'PAY-001');
      expect(result.redirectUrl, 'https://pay.jeko.com/001');
      expect(result.amount, 5000);
      expect(result.currency, 'XOF');
    });

    test('props equality', () {
      final json = {
        'reference': 'REF',
        'redirect_url': 'https://url',
        'amount': 1000,
        'payment_method': 'mtn',
      };
      final a = PaymentInitResult.fromJson(json);
      final b = PaymentInitResult.fromJson(json);
      expect(a, b);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // PaymentStatusResult
  // ────────────────────────────────────────────────────────────────────────────
  group('PaymentStatusResult', () {
    PaymentStatusResult result0(String status) => PaymentStatusResult(
      reference: 'REF',
      status: status,
      statusLabel: status,
      isFinal: true,
      amount: 5000,
    );

    test(
      'isSuccess when status is success',
      () => expect(result0('success').isSuccess, isTrue),
    );
    test(
      'isFailed when status is failed',
      () => expect(result0('failed').isFailed, isTrue),
    );
    test(
      'isFailed when status is expired',
      () => expect(result0('expired').isFailed, isTrue),
    );
    test(
      'isSuccess is false for non-success status',
      () => expect(result0('pending').isSuccess, isFalse),
    );

    test('parses from JSON', () {
      final json = {
        'reference': 'PAY-002',
        'payment_status': 'success',
        'payment_status_label': 'Paiement réussi',
        'is_final': true,
        'amount': 10000,
      };
      final result = PaymentStatusResult.fromJson(json);
      expect(result.reference, 'PAY-002');
      expect(result.isSuccess, isTrue);
      expect(result.isFinal, isTrue);
    });
  });
}
