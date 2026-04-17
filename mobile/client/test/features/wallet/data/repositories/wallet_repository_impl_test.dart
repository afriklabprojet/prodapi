import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drpharma_client/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:drpharma_client/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:drpharma_client/features/wallet/data/models/wallet_model.dart';
import 'package:drpharma_client/core/errors/exceptions.dart';
import 'package:drpharma_client/core/errors/failures.dart';

class MockWalletRemoteDataSource extends Mock
    implements WalletRemoteDataSource {}

WalletModel _makeWallet() => const WalletModel(
  balance: 15000,
  availableBalance: 14500,
  statistics: WalletStatisticsModel(),
);

WalletTransactionModel _makeTx({String type = 'topup'}) =>
    WalletTransactionModel.fromJson({
      'id': 1,
      'type': type,
      'amount': '5000',
      'balance_after': '15000',
      'status': 'completed',
      'description': 'Test',
      'created_at': '2024-01-01T00:00:00.000Z',
    });

void main() {
  late MockWalletRemoteDataSource mockDs;
  late WalletRepositoryImpl repo;

  setUp(() {
    mockDs = MockWalletRemoteDataSource();
    repo = WalletRepositoryImpl(remoteDataSource: mockDs);
  });

  // ──────────────────────────────────────────────────────
  // getWallet
  // ──────────────────────────────────────────────────────
  group('getWallet', () {
    test('success', () async {
      when(() => mockDs.getWallet()).thenAnswer((_) async => _makeWallet());
      final result = await repo.getWallet();
      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => throw AssertionError()).balance, 15000);
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockDs.getWallet(),
      ).thenThrow(ServerException(message: 'Erreur', statusCode: 500));
      final result = await repo.getWallet();
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('unexpected'),
      );
    });

    test('NetworkException → NetworkFailure', () async {
      when(
        () => mockDs.getWallet(),
      ).thenThrow(NetworkException(message: 'No network'));
      final result = await repo.getWallet();
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('unexpected'),
      );
    });

    test('generic exception → ServerFailure', () async {
      when(() => mockDs.getWallet()).thenThrow(Exception('oops'));
      final result = await repo.getWallet();
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('unexpected'),
      );
    });
  });

  // ──────────────────────────────────────────────────────
  // getTransactions
  // ──────────────────────────────────────────────────────
  group('getTransactions', () {
    test('success — returns list', () async {
      when(
        () => mockDs.getTransactions(
          limit: any(named: 'limit'),
          category: any(named: 'category'),
        ),
      ).thenAnswer((_) async => [_makeTx()]);
      final result = await repo.getTransactions();
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('unexpected'), (list) => expect(list.length, 1));
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockDs.getTransactions(
          limit: any(named: 'limit'),
          category: any(named: 'category'),
        ),
      ).thenThrow(ServerException(message: 'E', statusCode: 500));
      final result = await repo.getTransactions();
      expect(result.isLeft(), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────
  // initiateTopUp
  // ──────────────────────────────────────────────────────
  group('initiateTopUp', () {
    test('success', () async {
      when(
        () => mockDs.initiateTopUp(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer(
        (_) async => {
          'reference': 'REF123',
          'redirect_url': 'https://pay.example.com',
          'amount': 5000,
          'currency': 'XOF',
          'payment_method': 'momo',
        },
      );
      final result = await repo.initiateTopUp(
        amount: 5000,
        paymentMethod: 'momo',
      );
      expect(result.isRight(), isTrue);
    });

    test('ValidationException → ValidationFailure', () async {
      when(
        () => mockDs.initiateTopUp(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenThrow(
        ValidationException(
          errors: {
            'amount': ['Must be > 0'],
          },
        ),
      );
      final result = await repo.initiateTopUp(
        amount: -1,
        paymentMethod: 'momo',
      );
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('unexpected'),
      );
    });
  });

  // ──────────────────────────────────────────────────────
  // topUp / withdraw / payOrder
  // ──────────────────────────────────────────────────────
  group('topUp', () {
    final txData = {
      'transaction': {
        'id': 10,
        'type': 'topup',
        'amount': '5000',
        'balance_after': '20000',
        'status': 'completed',
        'description': 'Top-up',
        'created_at': '2024-01-01T00:00:00.000Z',
      },
    };

    test('success', () async {
      when(
        () => mockDs.topUp(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
          paymentReference: any(named: 'paymentReference'),
        ),
      ).thenAnswer((_) async => txData);
      final result = await repo.topUp(amount: 5000, paymentMethod: 'momo');
      expect(result.isRight(), isTrue);
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockDs.topUp(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
          paymentReference: any(named: 'paymentReference'),
        ),
      ).thenThrow(ServerException(message: 'E', statusCode: 422));
      final result = await repo.topUp(amount: 5000, paymentMethod: 'momo');
      expect(result.isLeft(), isTrue);
    });
  });

  group('withdraw', () {
    final txData = {
      'transaction': {
        'id': 11,
        'type': 'withdrawal',
        'amount': '3000',
        'balance_after': '12000',
        'status': 'pending',
        'description': 'Retrait',
        'created_at': '2024-01-01T00:00:00.000Z',
      },
    };

    test('success', () async {
      when(
        () => mockDs.withdraw(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => txData);
      final result = await repo.withdraw(
        amount: 3000,
        paymentMethod: 'momo',
        phoneNumber: '+225XXXXXXXX',
      );
      expect(result.isRight(), isTrue);
    });

    test('NetworkException → NetworkFailure', () async {
      when(
        () => mockDs.withdraw(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenThrow(NetworkException(message: 'No net'));
      final result = await repo.withdraw(
        amount: 3000,
        paymentMethod: 'momo',
        phoneNumber: '+225XXXXXXXX',
      );
      expect(result.isLeft(), isTrue);
    });

    test('ValidationException → ValidationFailure', () async {
      when(
        () => mockDs.withdraw(
          amount: any(named: 'amount'),
          paymentMethod: any(named: 'paymentMethod'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenThrow(
        ValidationException(
          errors: {
            'phone_number': ['Numéro invalide'],
          },
        ),
      );
      final result = await repo.withdraw(
        amount: 3000,
        paymentMethod: 'momo',
        phoneNumber: 'bad',
      );
      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail(''));
    });
  });

  // ──────────────────────────────────────────────────────
  // checkPaymentStatus
  // ──────────────────────────────────────────────────────
  group('checkPaymentStatus', () {
    test('success — returns PaymentStatusResult', () async {
      when(() => mockDs.checkPaymentStatus(any())).thenAnswer(
        (_) async => {
          'status': 'success',
          'reference': 'REF-001',
          'transaction_id': 'TXN-001',
        },
      );

      final result = await repo.checkPaymentStatus('REF-001');
      expect(result.isRight(), isTrue);
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockDs.checkPaymentStatus(any()),
      ).thenThrow(ServerException(message: 'Not found', statusCode: 404));

      final result = await repo.checkPaymentStatus('INVALID');
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail(''));
    });

    test('NetworkException → NetworkFailure', () async {
      when(
        () => mockDs.checkPaymentStatus(any()),
      ).thenThrow(NetworkException(message: 'No net'));

      final result = await repo.checkPaymentStatus('REF');
      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail(''));
    });

    test('generic exception → ServerFailure', () async {
      when(
        () => mockDs.checkPaymentStatus(any()),
      ).thenThrow(Exception('unexpected'));

      final result = await repo.checkPaymentStatus('REF');
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail(''));
    });
  });

  // ──────────────────────────────────────────────────────
  // payOrder
  // ──────────────────────────────────────────────────────
  group('payOrder', () {
    final txData = {
      'transaction': {
        'id': 2,
        'type': 'order_payment',
        'amount': '8000',
        'balance_after': '7000',
        'status': 'completed',
        'description': 'Paiement commande',
        'created_at': '2024-01-01T00:00:00.000Z',
      },
    };

    test('success', () async {
      when(
        () => mockDs.payOrder(
          amount: any(named: 'amount'),
          orderReference: any(named: 'orderReference'),
        ),
      ).thenAnswer((_) async => txData);

      final result = await repo.payOrder(
        amount: 8000,
        orderReference: 'ORD-ABC',
      );
      expect(result.isRight(), isTrue);
    });

    test('ServerException → ServerFailure', () async {
      when(
        () => mockDs.payOrder(
          amount: any(named: 'amount'),
          orderReference: any(named: 'orderReference'),
        ),
      ).thenThrow(
        ServerException(message: 'Insufficient funds', statusCode: 422),
      );

      final result = await repo.payOrder(
        amount: 9999999,
        orderReference: 'ORD-X',
      );
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail(''));
    });

    test('NetworkException → NetworkFailure', () async {
      when(
        () => mockDs.payOrder(
          amount: any(named: 'amount'),
          orderReference: any(named: 'orderReference'),
        ),
      ).thenThrow(NetworkException(message: 'No net'));

      final result = await repo.payOrder(amount: 1000, orderReference: 'ORD-Y');
      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail(''));
    });

    test('generic exception → ServerFailure', () async {
      when(
        () => mockDs.payOrder(
          amount: any(named: 'amount'),
          orderReference: any(named: 'orderReference'),
        ),
      ).thenThrow(Exception('oops'));

      final result = await repo.payOrder(amount: 1000, orderReference: 'ORD-Z');
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail(''));
    });
  });
}
