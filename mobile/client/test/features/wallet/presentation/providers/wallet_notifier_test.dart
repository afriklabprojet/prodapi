import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/wallet/domain/entities/wallet_entity.dart';
import 'package:drpharma_client/features/wallet/domain/usecases/wallet_usecases.dart';
import 'package:drpharma_client/features/wallet/presentation/providers/wallet_notifier.dart';
import 'package:drpharma_client/features/wallet/presentation/providers/wallet_state.dart';

class MockGetWalletUseCase extends Mock implements GetWalletUseCase {}

class MockGetTransactionsUseCase extends Mock
    implements GetTransactionsUseCase {}

class MockInitiateTopUpUseCase extends Mock implements InitiateTopUpUseCase {}

class MockCheckPaymentStatusUseCase extends Mock
    implements CheckPaymentStatusUseCase {}

class MockTopUpWalletUseCase extends Mock implements TopUpWalletUseCase {}

class MockWithdrawWalletUseCase extends Mock implements WithdrawWalletUseCase {}

class MockPayOrderUseCase extends Mock implements PayOrderUseCase {}

void main() {
  late MockGetWalletUseCase mockGetWallet;
  late MockGetTransactionsUseCase mockGetTransactions;
  late MockInitiateTopUpUseCase mockInitiateTopUp;
  late MockCheckPaymentStatusUseCase mockCheckPayment;
  late MockTopUpWalletUseCase mockTopUp;
  late MockWithdrawWalletUseCase mockWithdraw;
  late MockPayOrderUseCase mockPayOrder;
  late WalletNotifier notifier;

  const stats = WalletStatistics();
  const testWallet = WalletEntity(
    balance: 15000,
    availableBalance: 15000,
    statistics: stats,
  );

  WalletTransactionEntity makeTx() => WalletTransactionEntity(
    id: 1,
    type: TransactionType.credit,
    category: TransactionCategory.topup,
    amount: 5000,
    balanceAfter: 20000,
    reference: 'TXN-1',
    description: 'Rechargement',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockGetWallet = MockGetWalletUseCase();
    mockGetTransactions = MockGetTransactionsUseCase();
    mockInitiateTopUp = MockInitiateTopUpUseCase();
    mockCheckPayment = MockCheckPaymentStatusUseCase();
    mockTopUp = MockTopUpWalletUseCase();
    mockWithdraw = MockWithdrawWalletUseCase();
    mockPayOrder = MockPayOrderUseCase();
    notifier = WalletNotifier(
      getWalletUseCase: mockGetWallet,
      getTransactionsUseCase: mockGetTransactions,
      initiateTopUpUseCase: mockInitiateTopUp,
      checkPaymentStatusUseCase: mockCheckPayment,
      topUpWalletUseCase: mockTopUp,
      withdrawWalletUseCase: mockWithdraw,
      payOrderUseCase: mockPayOrder,
    );
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Initial state
  // ────────────────────────────────────────────────────────────────────────────
  group('initial state', () {
    test('is WalletState.initial()', () {
      expect(notifier.state.status, WalletStatus.initial);
      expect(notifier.state.wallet, isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // loadWallet
  // ────────────────────────────────────────────────────────────────────────────
  group('loadWallet', () {
    test('sets loaded status and wallet on success', () async {
      when(
        () => mockGetWallet(),
      ).thenAnswer((_) async => const Right(testWallet));

      await notifier.loadWallet();

      expect(notifier.state.status, WalletStatus.loaded);
      expect(notifier.state.wallet, testWallet);
      expect(notifier.state.errorMessage, isNull);
    });

    test('sets error status and message on failure', () async {
      when(
        () => mockGetWallet(),
      ).thenAnswer((_) async => Left(NetworkFailure(message: 'Pas de réseau')));

      await notifier.loadWallet();

      expect(notifier.state.status, WalletStatus.error);
      expect(notifier.state.errorMessage, 'Pas de réseau');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // loadTransactions
  // ────────────────────────────────────────────────────────────────────────────
  group('loadTransactions', () {
    test('updates transactions on success', () async {
      final txList = [makeTx()];
      when(
        () => mockGetTransactions(category: any(named: 'category')),
      ).thenAnswer((_) async => Right(txList));

      await notifier.loadTransactions();

      expect(notifier.state.transactions.length, 1);
    });

    test('sets errorMessage on failure', () async {
      when(
        () => mockGetTransactions(category: any(named: 'category')),
      ).thenAnswer((_) async => Left(const CacheFailure()));

      await notifier.loadTransactions();

      expect(notifier.state.errorMessage, isNotNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // loadAll
  // ────────────────────────────────────────────────────────────────────────────
  group('loadAll', () {
    test('loads both wallet and transactions on success', () async {
      final txList = [makeTx()];
      when(
        () => mockGetWallet(),
      ).thenAnswer((_) async => const Right(testWallet));
      when(
        () => mockGetTransactions(category: any(named: 'category')),
      ).thenAnswer((_) async => Right(txList));

      await notifier.loadAll();

      expect(notifier.state.status, WalletStatus.loaded);
      expect(notifier.state.wallet, testWallet);
      expect(notifier.state.transactions.length, 1);
    });

    test('sets error when getWallet fails', () async {
      when(
        () => mockGetWallet(),
      ).thenAnswer((_) async => Left(const CacheFailure()));
      when(
        () => mockGetTransactions(category: any(named: 'category')),
      ).thenAnswer((_) async => Right([makeTx()]));

      await notifier.loadAll();

      expect(notifier.state.status, WalletStatus.error);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // checkPaymentStatus
  // ────────────────────────────────────────────────────────────────────────────
  group('checkPaymentStatus', () {
    test('returns PaymentStatusResult on success', () async {
      const statusResult = PaymentStatusResult(
        reference: 'REF-123',
        status: 'success',
        statusLabel: 'Payé',
        isFinal: true,
        amount: 5000,
      );
      when(
        () => mockCheckPayment(any()),
      ).thenAnswer((_) async => const Right(statusResult));

      final result = await notifier.checkPaymentStatus('REF-123');

      expect(result, isA<PaymentStatusResult>());
      expect(result!.isSuccess, isTrue);
    });

    test('returns null on failure', () async {
      when(
        () => mockCheckPayment(any()),
      ).thenAnswer((_) async => Left(const NetworkFailure()));

      final result = await notifier.checkPaymentStatus('REF-X');
      expect(result, isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // topUp
  // ────────────────────────────────────────────────────────────────────────────
  group('topUp', () {
    test('returns true on success', () async {
      when(
        () => mockTopUp(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
          paymentReference: any(named: 'paymentReference'),
        ),
      ).thenAnswer((_) async => Right(makeTx()));
      when(
        () => mockGetWallet(),
      ).thenAnswer((_) async => const Right(testWallet));
      when(
        () => mockGetTransactions(category: any(named: 'category')),
      ).thenAnswer((_) async => Right([makeTx()]));

      final result = await notifier.topUp(amount: 5000, paymentMethod: 'mm');
      expect(result, isTrue);
    });

    test('returns false and sets errorMessage on failure', () async {
      when(
        () => mockTopUp(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
          paymentReference: any(named: 'paymentReference'),
        ),
      ).thenAnswer(
        (_) async =>
            Left(ServerFailure(message: 'Paiement refusé', statusCode: 402)),
      );

      final result = await notifier.topUp(amount: 1000, paymentMethod: 'mm');

      expect(result, isFalse);
      expect(notifier.state.errorMessage, 'Paiement refusé');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // withdraw
  // ────────────────────────────────────────────────────────────────────────────
  group('withdraw', () {
    test('returns true and sets successMessage on success', () async {
      when(
        () => mockWithdraw(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => Right(makeTx()));
      when(
        () => mockGetWallet(),
      ).thenAnswer((_) async => const Right(testWallet));
      when(
        () => mockGetTransactions(category: any(named: 'category')),
      ).thenAnswer((_) async => Right([makeTx()]));

      final result = await notifier.withdraw(
        amount: 2000,
        paymentMethod: 'momo',
        phoneNumber: '+2250700000000',
      );

      expect(result, isTrue);
    });

    test('returns false on failure', () async {
      when(
        () => mockWithdraw(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer(
        (_) async =>
            Left(ServerFailure(message: 'Solde insuffisant', statusCode: 422)),
      );

      final result = await notifier.withdraw(
        amount: 1000,
        paymentMethod: 'momo',
        phoneNumber: '+2250700000000',
      );

      expect(result, isFalse);
      expect(notifier.state.errorMessage, 'Solde insuffisant');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // payOrder
  // ────────────────────────────────────────────────────────────────────────────
  group('payOrder', () {
    test('returns true on success', () async {
      when(
        () => mockPayOrder(
          amount: any(named: 'amount'),
          orderReference: any(named: 'orderReference'),
        ),
      ).thenAnswer((_) async => Right(makeTx()));
      when(
        () => mockGetWallet(),
      ).thenAnswer((_) async => const Right(testWallet));
      when(
        () => mockGetTransactions(category: any(named: 'category')),
      ).thenAnswer((_) async => Right([makeTx()]));

      final result = await notifier.payOrder(
        amount: 5000,
        orderReference: 'ORD-1',
      );
      expect(result, isTrue);
    });

    test('returns false on failure', () async {
      when(
        () => mockPayOrder(
          amount: any(named: 'amount'),
          orderReference: any(named: 'orderReference'),
        ),
      ).thenAnswer(
        (_) async => Left(
          ServerFailure(message: 'Commande introuvable', statusCode: 404),
        ),
      );

      final result = await notifier.payOrder(
        amount: 500,
        orderReference: 'ORD-X',
      );
      expect(result, isFalse);
      expect(notifier.state.errorMessage, 'Commande introuvable');
    });
  });
}
