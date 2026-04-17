import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/core/constants/api_constants.dart';
import 'package:courier/data/repositories/jeko_payment_repository.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late JekoPaymentRepository repository;

  setUp(() {
    dio = _MockDio();
    repository = JekoPaymentRepository(dio);
  });

  group('JekoPaymentMethod', () {
    test('has all 5 payment methods', () {
      expect(JekoPaymentMethod.values.length, 5);
    });

    test('wave has correct properties', () {
      const wave = JekoPaymentMethod.wave;
      expect(wave.value, 'wave');
      expect(wave.label, 'Wave');
      expect(wave.icon, 'assets/icons/wave.png');
    });

    test('orange has correct properties', () {
      const orange = JekoPaymentMethod.orange;
      expect(orange.value, 'orange');
      expect(orange.label, 'Orange Money');
      expect(orange.icon, 'assets/icons/orange_money.png');
    });

    test('mtn has correct properties', () {
      const mtn = JekoPaymentMethod.mtn;
      expect(mtn.value, 'mtn');
      expect(mtn.label, 'MTN MoMo');
      expect(mtn.icon, 'assets/icons/mtn_momo.png');
    });

    test('moov has correct properties', () {
      const moov = JekoPaymentMethod.moov;
      expect(moov.value, 'moov');
      expect(moov.label, 'Moov Money');
      expect(moov.icon, 'assets/icons/moov_money.png');
    });

    test('djamo has correct properties', () {
      const djamo = JekoPaymentMethod.djamo;
      expect(djamo.value, 'djamo');
      expect(djamo.label, 'Djamo');
      expect(djamo.icon, 'assets/icons/djamo.png');
    });
  });

  group('PaymentInitResponse', () {
    test('fromJson parses complete response', () {
      final json = {
        'reference': 'PAY-ABC123',
        'redirect_url': 'https://jeko.example.com/pay?ref=PAY-ABC123',
        'amount': 5000,
        'currency': 'XOF',
        'payment_method': 'wave',
      };

      final response = PaymentInitResponse.fromJson(json);

      expect(response.reference, 'PAY-ABC123');
      expect(
        response.redirectUrl,
        'https://jeko.example.com/pay?ref=PAY-ABC123',
      );
      expect(response.amount, 5000.0);
      expect(response.currency, 'XOF');
      expect(response.paymentMethod, 'wave');
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final response = PaymentInitResponse.fromJson(json);

      expect(response.reference, '');
      expect(response.redirectUrl, '');
      expect(response.amount, 0.0);
      expect(response.currency, 'XOF');
      expect(response.paymentMethod, '');
    });

    test('fromJson handles null values with defaults', () {
      final json = {
        'reference': null,
        'redirect_url': null,
        'amount': null,
        'currency': null,
        'payment_method': null,
      };

      final response = PaymentInitResponse.fromJson(json);

      expect(response.reference, '');
      expect(response.redirectUrl, '');
      expect(response.amount, 0.0);
      expect(response.currency, 'XOF');
      expect(response.paymentMethod, '');
    });

    test('fromJson converts int amount to double', () {
      final json = {
        'reference': 'REF-1',
        'redirect_url': 'https://example.com',
        'amount': 10000,
        'currency': 'XOF',
        'payment_method': 'orange',
      };

      final response = PaymentInitResponse.fromJson(json);
      expect(response.amount, isA<double>());
      expect(response.amount, 10000.0);
    });
  });

  group('JekoPaymentRepository methods', () {
    test('initiateWalletTopup posts wallet payload and parses success', () async {
      when(
        () => dio.post(
          ApiConstants.paymentsInitiate,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.paymentsInitiate),
          data: {
            'status': 'success',
            'data': {
              'reference': 'PAY-WALLET',
              'redirect_url': 'https://pay.example.com/wallet',
              'amount': 5000,
              'currency': 'XOF',
              'payment_method': 'wave',
            },
          },
        ),
      );

      final result = await repository.initiateWalletTopup(
        amount: 5000,
        method: JekoPaymentMethod.wave,
      );

      expect(result.reference, 'PAY-WALLET');
      expect(result.redirectUrl, contains('wallet'));
      verify(
        () => dio.post(
          ApiConstants.paymentsInitiate,
          data: {
            'type': 'wallet_topup',
            'amount': 5000.0,
            'payment_method': 'wave',
          },
        ),
      ).called(1);
    });

    test('initiateWalletTopup throws the backend message on failure status', () async {
      when(
        () => dio.post(
          ApiConstants.paymentsInitiate,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.paymentsInitiate),
          data: {
            'status': 'error',
            'message': 'Paiement impossible',
          },
        ),
      );

      await expectLater(
        repository.initiateWalletTopup(
          amount: 3000,
          method: JekoPaymentMethod.orange,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Paiement impossible'),
          ),
        ),
      );
    });

    test('initiateOrderPayment posts order payload and parses success', () async {
      when(
        () => dio.post(
          ApiConstants.paymentsInitiate,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.paymentsInitiate),
          data: {
            'status': 'success',
            'data': {
              'reference': 'PAY-ORDER',
              'redirect_url': 'https://pay.example.com/order',
              'amount': 2500,
              'currency': 'XOF',
              'payment_method': 'orange',
            },
          },
        ),
      );

      final result = await repository.initiateOrderPayment(
        orderId: 42,
        method: JekoPaymentMethod.orange,
      );

      expect(result.reference, 'PAY-ORDER');
      verify(
        () => dio.post(
          ApiConstants.paymentsInitiate,
          data: {
            'type': 'order',
            'order_id': 42,
            'payment_method': 'orange',
          },
        ),
      ).called(1);
    });

    test('checkPaymentStatus returns the parsed status response', () async {
      when(() => dio.get(ApiConstants.paymentStatus('PAY-STATUS'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.paymentStatus('PAY-STATUS')),
          data: {
            'status': 'success',
            'data': {
              'reference': 'PAY-STATUS',
              'payment_status': 'success',
              'payment_status_label': 'Réussi',
              'amount': 4100,
              'currency': 'XOF',
              'payment_method': 'wave',
              'is_final': true,
            },
          },
        ),
      );

      final result = await repository.checkPaymentStatus('PAY-STATUS');

      expect(result.reference, 'PAY-STATUS');
      expect(result.isSuccess, isTrue);
      expect(result.amount, 4100);
    });

    test('getPaymentMethods returns API methods on success', () async {
      when(() => dio.get(ApiConstants.paymentsMethods)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.paymentsMethods),
          data: {
            'status': 'success',
            'data': [
              {'value': 'wave', 'label': 'Wave', 'icon': 'wave.png'},
              {'value': 'orange', 'label': 'Orange Money', 'icon': 'orange.png'},
            ],
          },
        ),
      );

      final methods = await repository.getPaymentMethods();

      expect(methods, hasLength(2));
      expect(methods.first['value'], 'wave');
    });

    test('getPaymentMethods falls back to default values on error', () async {
      when(() => dio.get(ApiConstants.paymentsMethods)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.paymentsMethods),
        ),
      );

      final methods = await repository.getPaymentMethods();

      expect(methods, hasLength(JekoPaymentMethod.values.length));
      expect(methods.map((method) => method['value']), contains('wave'));
      expect(methods.map((method) => method['value']), contains('djamo'));
    });

    test('getPaymentHistory returns API history on success', () async {
      when(
        () => dio.get(
          ApiConstants.paymentsHistory,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.paymentsHistory),
          data: {
            'status': 'success',
            'data': [
              {'reference': 'PAY-1', 'amount': 1000},
              {'reference': 'PAY-2', 'amount': 2000},
            ],
          },
        ),
      );

      final history = await repository.getPaymentHistory(page: 2, perPage: 10);

      expect(history, hasLength(2));
      verify(
        () => dio.get(
          ApiConstants.paymentsHistory,
          queryParameters: {'page': 2, 'per_page': 10},
        ),
      ).called(1);
    });

    test('cancelPayment completes when backend confirms success', () async {
      when(() => dio.post(ApiConstants.cancelPayment('PAY-CANCEL'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.cancelPayment('PAY-CANCEL')),
          data: {'status': 'success'},
        ),
      );

      await repository.cancelPayment('PAY-CANCEL');

      verify(() => dio.post(ApiConstants.cancelPayment('PAY-CANCEL'))).called(1);
    });

    test('cancelPayment throws when backend rejects the cancellation', () async {
      when(() => dio.post(ApiConstants.cancelPayment('PAY-FAIL'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.cancelPayment('PAY-FAIL')),
          data: {
            'status': 'error',
            'message': 'Impossible d\'annuler le paiement',
          },
        ),
      );

      await expectLater(
        repository.cancelPayment('PAY-FAIL'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Impossible d\'annuler le paiement'),
          ),
        ),
      );
    });
  });

  group('PaymentStatusResponse', () {
    test('fromJson parses a successful payment', () {
      final json = {
        'reference': 'PAY-SUCCESS',
        'payment_status': 'success',
        'payment_status_label': 'Réussi',
        'amount': 5000,
        'currency': 'XOF',
        'payment_method': 'wave',
        'is_final': true,
        'completed_at': '2026-04-04T10:30:00Z',
        'error_message': null,
      };

      final status = PaymentStatusResponse.fromJson(json);

      expect(status.reference, 'PAY-SUCCESS');
      expect(status.status, 'success');
      expect(status.isSuccess, isTrue);
      expect(status.isFailed, isFalse);
      expect(status.isPending, isFalse);
      expect(status.isFinal, isTrue);
      expect(status.completedAt, '2026-04-04T10:30:00Z');
      expect(status.errorMessage, isNull);
    });

    test('fromJson parses a failed payment', () {
      final json = {
        'reference': 'PAY-FAIL',
        'payment_status': 'failed',
        'payment_status_label': 'Échoué',
        'amount': 2000,
        'currency': 'XOF',
        'payment_method': 'mtn',
        'is_final': true,
        'error_message': 'Solde insuffisant',
      };

      final status = PaymentStatusResponse.fromJson(json);

      expect(status.isSuccess, isFalse);
      expect(status.isFailed, isTrue);
      expect(status.isPending, isFalse);
      expect(status.errorMessage, 'Solde insuffisant');
    });

    test('fromJson parses a pending payment', () {
      final json = {
        'reference': 'PAY-PENDING',
        'payment_status': 'pending',
        'payment_status_label': 'En attente',
        'amount': 1000,
        'currency': 'XOF',
        'payment_method': 'orange',
        'is_final': false,
      };

      final status = PaymentStatusResponse.fromJson(json);

      expect(status.isSuccess, isFalse);
      expect(status.isFailed, isFalse);
      expect(status.isPending, isTrue);
      expect(status.isFinal, isFalse);
    });

    test('fromJson parses a processing payment as pending', () {
      final json = {
        'reference': 'PAY-PROC',
        'payment_status': 'processing',
        'payment_status_label': 'En traitement',
        'amount': 3000,
        'currency': 'XOF',
        'payment_method': 'moov',
        'is_final': false,
      };

      final status = PaymentStatusResponse.fromJson(json);

      expect(status.isPending, isTrue);
      expect(status.isSuccess, isFalse);
      expect(status.isFailed, isFalse);
    });

    test('expired status counts as failed', () {
      final json = {
        'reference': 'PAY-EXPIRED',
        'payment_status': 'expired',
        'payment_status_label': 'Expiré',
        'amount': 500,
        'currency': 'XOF',
        'payment_method': 'djamo',
        'is_final': true,
      };

      final status = PaymentStatusResponse.fromJson(json);

      expect(status.isFailed, isTrue);
      expect(status.isSuccess, isFalse);
      expect(status.isPending, isFalse);
    });

    test('fromJson with missing fields uses defaults', () {
      final json = <String, dynamic>{};

      final status = PaymentStatusResponse.fromJson(json);

      expect(status.reference, '');
      expect(status.status, 'pending');
      expect(status.statusLabel, 'En attente');
      expect(status.amount, 0.0);
      expect(status.currency, 'XOF');
      expect(status.isFinal, isFalse);
      expect(status.isPending, isTrue);
    });
  });
}
