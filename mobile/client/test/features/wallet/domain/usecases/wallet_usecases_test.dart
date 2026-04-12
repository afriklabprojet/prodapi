import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/wallet/domain/entities/wallet_entity.dart';
import 'package:drpharma_client/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:drpharma_client/features/wallet/domain/usecases/wallet_usecases.dart';

@GenerateMocks([WalletRepository])
import 'wallet_usecases_test.mocks.dart';

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────
WalletEntity _wallet() => const WalletEntity(
  balance: 15000,
  availableBalance: 14000,
  minimumWithdrawal: 500,
  statistics: WalletStatistics(),
);

WalletTransactionEntity _tx({TransactionType type = TransactionType.credit}) =>
    WalletTransactionEntity(
      id: 1,
      type: type,
      category: TransactionCategory.topup,
      amount: 5000,
      balanceAfter: 20000,
      reference: 'REF-001',
      description: 'Test transaction',
      createdAt: DateTime(2024),
    );

void main() {
  late MockWalletRepository mockRepo;

  setUp(() => mockRepo = MockWalletRepository());

  // ────────────────────────────────────────────────────────────────────────────
  // GetWalletUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetWalletUseCase', () {
    late GetWalletUseCase useCase;
    setUp(() => useCase = GetWalletUseCase(mockRepo));

    test('returns wallet on success', () async {
      when(mockRepo.getWallet()).thenAnswer((_) async => Right(_wallet()));

      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (w) {
        expect(w.balance, 15000);
        expect(w.canWithdraw, isTrue);
      });
      verify(mockRepo.getWallet()).called(1);
    });

    test('returns failure on error', () async {
      when(
        mockRepo.getWallet(),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // GetTransactionsUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('GetTransactionsUseCase', () {
    late GetTransactionsUseCase useCase;
    setUp(() => useCase = GetTransactionsUseCase(mockRepo));

    test('returns transaction list on success', () async {
      final txList = [_tx(), _tx(type: TransactionType.debit)];
      when(
        mockRepo.getTransactions(limit: 50, category: null),
      ).thenAnswer((_) async => Right(txList));

      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (list) => expect(list.length, 2),
      );
    });

    test('passes category filter to repository', () async {
      when(
        mockRepo.getTransactions(limit: 20, category: 'topup'),
      ).thenAnswer((_) async => Right([_tx()]));

      await useCase(limit: 20, category: 'topup');

      verify(mockRepo.getTransactions(limit: 20, category: 'topup')).called(1);
    });

    test('returns failure on server error', () async {
      when(
        mockRepo.getTransactions(limit: 50, category: null),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

      final result = await useCase();
      expect(result.isLeft(), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // InitiateTopUpUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('InitiateTopUpUseCase', () {
    late InitiateTopUpUseCase useCase;
    setUp(() => useCase = InitiateTopUpUseCase(mockRepo));

    test('returns PaymentInitResult on success', () async {
      const result = PaymentInitResult(
        reference: 'REF-PAY',
        redirectUrl: 'https://pay.jeko.com/abc',
        amount: 5000,
        currency: 'XOF',
        paymentMethod: 'orange_money',
      );
      when(
        mockRepo.initiateTopUp(amount: 5000, paymentMethod: 'orange_money'),
      ).thenAnswer((_) async => const Right(result));

      final res = await useCase(amount: 5000, paymentMethod: 'orange_money');

      expect(res.isRight(), isTrue);
      res.fold((_) => fail('Expected Right'), (r) {
        expect(r.reference, 'REF-PAY');
        expect(r.redirectUrl, contains('jeko.com'));
      });
    });

    test('returns failure when payment initiation fails', () async {
      when(
        mockRepo.initiateTopUp(
          amount: anyNamed('amount'),
          paymentMethod: anyNamed('paymentMethod'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Payment error')),
      );

      final res = await useCase(amount: 1000, paymentMethod: 'mtn');
      expect(res.isLeft(), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // CheckPaymentStatusUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('CheckPaymentStatusUseCase', () {
    late CheckPaymentStatusUseCase useCase;
    setUp(() => useCase = CheckPaymentStatusUseCase(mockRepo));

    test('returns success status', () async {
      const status = PaymentStatusResult(
        reference: 'REF-PAY',
        status: 'success',
        statusLabel: 'Paiement réussi',
        isFinal: true,
        amount: 5000,
      );
      when(
        mockRepo.checkPaymentStatus('REF-PAY'),
      ).thenAnswer((_) async => const Right(status));

      final res = await useCase('REF-PAY');

      expect(res.isRight(), isTrue);
      res.fold((_) => fail('Expected Right'), (s) {
        expect(s.isSuccess, isTrue);
        expect(s.isFinal, isTrue);
      });
    });

    test('returns failure for unknown reference', () async {
      when(mockRepo.checkPaymentStatus('UNKNOWN')).thenAnswer(
        (_) async =>
            const Left(ServerFailure(message: 'Not found', statusCode: 404)),
      );

      final res = await useCase('UNKNOWN');
      expect(res.isLeft(), isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // TopUpWalletUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('TopUpWalletUseCase', () {
    late TopUpWalletUseCase useCase;
    setUp(() => useCase = TopUpWalletUseCase(mockRepo));

    test('returns transaction on successful top-up', () async {
      when(
        mockRepo.topUp(
          amount: 5000,
          paymentMethod: 'orange_money',
          paymentReference: 'REF',
        ),
      ).thenAnswer((_) async => Right(_tx()));

      final res = await useCase(
        amount: 5000,
        paymentMethod: 'orange_money',
        paymentReference: 'REF',
      );

      expect(res.isRight(), isTrue);
      res.fold((_) => fail('Expected Right'), (tx) {
        expect(tx.isCredit, isTrue);
        expect(tx.amount, 5000);
      });
    });

    test('passes null paymentReference when not provided', () async {
      when(
        mockRepo.topUp(
          amount: 2000,
          paymentMethod: 'mtn',
          paymentReference: null,
        ),
      ).thenAnswer((_) async => Right(_tx()));

      await useCase(amount: 2000, paymentMethod: 'mtn');

      verify(
        mockRepo.topUp(
          amount: 2000,
          paymentMethod: 'mtn',
          paymentReference: null,
        ),
      ).called(1);
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // WithdrawWalletUseCase
  // ────────────────────────────────────────────────────────────────────────────
  group('WithdrawWalletUseCase', () {
    late WithdrawWalletUseCase useCase;
    setUp(() => useCase = WithdrawWalletUseCase(mockRepo));

    test('returns debit transaction on successful withdrawal', () async {
      when(
        mockRepo.withdraw(
          amount: 5000,
          paymentMethod: 'orange_money',
          phoneNumber: '+2250700000001',
        ),
      ).thenAnswer((_) async => Right(_tx(type: TransactionType.debit)));

      final res = await useCase(
        amount: 5000,
        paymentMethod: 'orange_money',
        phoneNumber: '+2250700000001',
      );

      expect(res.isRight(), isTrue);
      res.fold(
        (_) => fail('Expected Right'),
        (tx) => expect(tx.isDebit, isTrue),
      );
    });

    test('returns failure on insufficient balance', () async {
      when(
        mockRepo.withdraw(
          amount: anyNamed('amount'),
          paymentMethod: anyNamed('paymentMethod'),
          phoneNumber: anyNamed('phoneNumber'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Solde insuffisant')),
      );

      final res = await useCase(
        amount: 100000,
        paymentMethod: 'mtn',
        phoneNumber: '+225',
      );

      expect(res.isLeft(), isTrue);
    });
  });
}
