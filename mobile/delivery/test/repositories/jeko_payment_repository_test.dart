import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/data/repositories/jeko_payment_repository.dart';
import 'package:courier/core/constants/api_constants.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late JekoPaymentRepository repo;

  setUp(() async {
    mockDio = MockDio();
    repo = JekoPaymentRepository(mockDio);
    await setupTestDependencies();
  });

  // ── Models ─────────────────────────────────────────

  group('PaymentInitResponse', () {
    test('fromJson with full data', () {
      final r = PaymentInitResponse.fromJson({
        'reference': 'PAY-001',
        'redirect_url': 'https://pay.jeko.com/checkout',
        'amount': 5000,
        'currency': 'XOF',
        'payment_method': 'wave',
      });
      expect(r.reference, 'PAY-001');
      expect(r.redirectUrl, 'https://pay.jeko.com/checkout');
      expect(r.amount, 5000.0);
      expect(r.currency, 'XOF');
      expect(r.paymentMethod, 'wave');
    });

    test('fromJson with defaults', () {
      final r = PaymentInitResponse.fromJson(<String, dynamic>{});
      expect(r.reference, '');
      expect(r.redirectUrl, '');
      expect(r.amount, 0.0);
      expect(r.currency, 'XOF');
    });
  });

  group('PaymentStatusResponse', () {
    test('fromJson with full data', () {
      final r = PaymentStatusResponse.fromJson({
        'reference': 'PAY-001',
        'payment_status': 'success',
        'payment_status_label': 'Réussi',
        'amount': 5000,
        'currency': 'XOF',
        'payment_method': 'wave',
        'is_final': true,
        'completed_at': '2026-02-13T10:00:00Z',
        'error_message': null,
      });
      expect(r.reference, 'PAY-001');
      expect(r.status, 'success');
      expect(r.isSuccess, true);
      expect(r.isFailed, false);
      expect(r.isPending, false);
      expect(r.isFinal, true);
      expect(r.completedAt, '2026-02-13T10:00:00Z');
    });

    test('isSuccess/isFailed/isPending computed getters', () {
      final pending = PaymentStatusResponse.fromJson({
        'payment_status': 'pending',
        'is_final': false,
      });
      expect(pending.isPending, true);
      expect(pending.isSuccess, false);
      expect(pending.isFailed, false);

      final failed = PaymentStatusResponse.fromJson({
        'payment_status': 'failed',
        'is_final': true,
      });
      expect(failed.isFailed, true);

      final expired = PaymentStatusResponse.fromJson({
        'payment_status': 'expired',
        'is_final': true,
      });
      expect(expired.isFailed, true);

      final processing = PaymentStatusResponse.fromJson({
        'payment_status': 'processing',
        'is_final': false,
      });
      expect(processing.isPending, true);
    });
  });

  group('JekoPaymentMethod', () {
    test('has correct values', () {
      expect(JekoPaymentMethod.wave.value, 'wave');
      expect(JekoPaymentMethod.wave.label, 'Wave');
      expect(JekoPaymentMethod.orange.value, 'orange');
      expect(JekoPaymentMethod.mtn.value, 'mtn');
      expect(JekoPaymentMethod.moov.value, 'moov');
      expect(JekoPaymentMethod.djamo.value, 'djamo');
    });

    test('has 5 payment methods', () {
      expect(JekoPaymentMethod.values.length, 5);
    });
  });

  // ── Repository methods ─────────────────────────────

  group('initiateWalletTopup', () {
    test('returns PaymentInitResponse on success', () async {
      when(() => mockDio.post(ApiConstants.paymentsInitiate, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'status': 'success',
                'data': {
                  'reference': 'PAY-001',
                  'redirect_url': 'https://pay.jeko.com/checkout',
                  'amount': 5000,
                  'currency': 'XOF',
                  'payment_method': 'wave',
                }
              }));

      final result = await repo.initiateWalletTopup(
        amount: 5000,
        method: JekoPaymentMethod.wave,
      );
      expect(result.reference, 'PAY-001');
      expect(result.amount, 5000.0);
    });

    test('throws on API error response', () async {
      when(() => mockDio.post(ApiConstants.paymentsInitiate, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'status': 'error',
                'message': 'Montant insuffisant',
              }));

      expect(
        () => repo.initiateWalletTopup(amount: 100, method: JekoPaymentMethod.wave),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on DioException', () async {
      when(() => mockDio.post(ApiConstants.paymentsInitiate, data: any(named: 'data')))
          .thenThrow(dioError(statusCode: 422, data: {'message': 'Validation failed'}));

      expect(
        () => repo.initiateWalletTopup(amount: 5000, method: JekoPaymentMethod.wave),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('initiateOrderPayment', () {
    test('returns PaymentInitResponse on success', () async {
      when(() => mockDio.post(ApiConstants.paymentsInitiate, data: any(named: 'data')))
          .thenAnswer((_) async => successResponse({
                'status': 'success',
                'data': {
                  'reference': 'ORD-001',
                  'redirect_url': 'https://pay.jeko.com/order',
                  'amount': 15000,
                  'currency': 'XOF',
                  'payment_method': 'orange',
                }
              }));

      final result = await repo.initiateOrderPayment(
        orderId: 42,
        method: JekoPaymentMethod.orange,
      );
      expect(result.reference, 'ORD-001');
      expect(result.amount, 15000.0);
    });
  });

  group('checkPaymentStatus', () {
    test('returns PaymentStatusResponse on success', () async {
      when(() => mockDio.get(ApiConstants.paymentStatus('PAY-001')))
          .thenAnswer((_) async => successResponse({
                'status': 'success',
                'data': {
                  'reference': 'PAY-001',
                  'payment_status': 'success',
                  'payment_status_label': 'Réussi',
                  'amount': 5000,
                  'currency': 'XOF',
                  'payment_method': 'wave',
                  'is_final': true,
                }
              }));

      final result = await repo.checkPaymentStatus('PAY-001');
      expect(result.isSuccess, true);
      expect(result.isFinal, true);
    });

    test('throws on error response', () async {
      when(() => mockDio.get(ApiConstants.paymentStatus('PAY-BAD')))
          .thenAnswer((_) async => successResponse({
                'status': 'error',
                'message': 'Paiement introuvable',
              }));

      expect(
        () => repo.checkPaymentStatus('PAY-BAD'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getPaymentMethods', () {
    test('returns list on success', () async {
      when(() => mockDio.get(ApiConstants.paymentsMethods))
          .thenAnswer((_) async => successResponse({
                'status': 'success',
                'data': [
                  {'value': 'wave', 'label': 'Wave', 'icon': 'wave.png'},
                  {'value': 'orange', 'label': 'Orange Money', 'icon': 'om.png'},
                ]
              }));

      final result = await repo.getPaymentMethods();
      expect(result.length, 2);
      expect(result[0]['value'], 'wave');
    });

    test('returns defaults on error', () async {
      when(() => mockDio.get(ApiConstants.paymentsMethods))
          .thenThrow(dioError(statusCode: 500, data: {}));

      final result = await repo.getPaymentMethods();
      expect(result.length, JekoPaymentMethod.values.length);
    });
  });

  group('getPaymentHistory', () {
    test('returns list on success', () async {
      when(() => mockDio.get(
            ApiConstants.paymentsHistory,
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => successResponse({
                'status': 'success',
                'data': [
                  {'reference': 'PAY-001', 'amount': 5000},
                ]
              }));

      final result = await repo.getPaymentHistory();
      expect(result.length, 1);
    });

    test('throws on error', () async {
      when(() => mockDio.get(
            ApiConstants.paymentsHistory,
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(dioError(statusCode: 500, data: {}));

      expect(
        () => repo.getPaymentHistory(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('cancelPayment', () {
    test('succeeds on success response', () async {
      when(() => mockDio.post(ApiConstants.cancelPayment('PAY-001')))
          .thenAnswer((_) async => successResponse({
                'status': 'success',
              }));

      await repo.cancelPayment('PAY-001');
      verify(() => mockDio.post(ApiConstants.cancelPayment('PAY-001'))).called(1);
    });

    test('throws on error response', () async {
      when(() => mockDio.post(ApiConstants.cancelPayment('PAY-002')))
          .thenAnswer((_) async => successResponse({
                'status': 'error',
                'message': 'Cannot cancel completed payment',
              }));

      expect(
        () => repo.cancelPayment('PAY-002'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on DioException', () async {
      when(() => mockDio.post(ApiConstants.cancelPayment('PAY-003')))
          .thenThrow(dioError(statusCode: 403, data: {'message': 'Forbidden'}));

      expect(
        () => repo.cancelPayment('PAY-003'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
