import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drpharma_client/features/orders/presentation/providers/promo_code_provider.dart';
import 'package:drpharma_client/core/network/api_client.dart';
import 'package:drpharma_client/config/providers.dart';

// ─────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────
class MockApiClient extends Mock implements ApiClient {}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────
Response<dynamic> _makeSuccessResponse({
  String code = 'PROMO10',
  dynamic discount = 1000.0,
  String? description,
}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/promo-codes/validate'),
    data: {
      'success': true,
      'data': {'code': code, 'discount': discount, 'description': description},
    },
    statusCode: 200,
  );
}

Response<dynamic> _makeFailureResponse({String? message}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/promo-codes/validate'),
    data: {'success': false, 'message': message ?? 'Code invalide'},
    statusCode: 200,
  );
}

ProviderContainer _makeContainer(MockApiClient mockApi) {
  return ProviderContainer(
    overrides: [apiClientProvider.overrideWith((_) => mockApi)],
  );
}

void main() {
  late MockApiClient mockApi;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockApi = MockApiClient();
  });

  // ─────────────────────────────────────────────────────────
  // PromoCodeState — model tests
  // ─────────────────────────────────────────────────────────

  group('PromoCodeState — model', () {
    test('default state is neutral', () {
      const state = PromoCodeState();
      expect(state.code, isNull);
      expect(state.discount, 0);
      expect(state.description, isNull);
      expect(state.isValidating, isFalse);
      expect(state.error, isNull);
    });

    test('hasDiscount is false with no code', () {
      const state = PromoCodeState(discount: 500);
      expect(state.hasDiscount, isFalse);
    });

    test('hasDiscount is false with code but zero discount', () {
      const state = PromoCodeState(code: 'PROMO10', discount: 0);
      expect(state.hasDiscount, isFalse);
    });

    test('hasDiscount is true with code and positive discount', () {
      const state = PromoCodeState(code: 'PROMO10', discount: 500);
      expect(state.hasDiscount, isTrue);
    });

    test('copyWith updates individual fields', () {
      const state = PromoCodeState();
      expect(state.copyWith(code: 'ABC').code, 'ABC');
      expect(state.copyWith(discount: 250).discount, 250);
      expect(state.copyWith(isValidating: true).isValidating, isTrue);
      expect(state.copyWith(error: 'Oops').error, 'Oops');
    });

    test('copyWith error clears to null when not provided', () {
      const state = PromoCodeState(error: 'some error');
      final updated = state.copyWith(discount: 100);
      expect(updated.error, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────
  // PromoCodeNotifier — validate
  // ─────────────────────────────────────────────────────────

  group('PromoCodeNotifier — validate', () {
    test('does nothing when code is empty', () async {
      final container = _makeContainer(mockApi);
      addTearDown(container.dispose);

      final notifier = container.read(promoCodeProvider.notifier);
      await notifier.validate('   ', 5000.0);

      verifyNever(() => mockApi.post(any(), data: any(named: 'data')));
      // State should remain unchanged
      expect(container.read(promoCodeProvider).code, isNull);
    });

    test('updates state to validating=true initially', () async {
      when(
        () => mockApi.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _makeSuccessResponse());

      final container = _makeContainer(mockApi);
      addTearDown(container.dispose);

      final notifier = container.read(promoCodeProvider.notifier);
      final future = notifier.validate('PROMO10', 5000.0);

      // After the call completes, check final state
      await future;

      final state = container.read(promoCodeProvider);
      expect(state.isValidating, isFalse); // should be false after completion
      expect(state.code, 'PROMO10');
    });

    test('sets promo code and discount on successful validation', () async {
      when(() => mockApi.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => _makeSuccessResponse(
          code: 'DISCOUNT20',
          discount: 2000.0,
          description: '20% de réduction',
        ),
      );

      final container = _makeContainer(mockApi);
      addTearDown(container.dispose);

      await container
          .read(promoCodeProvider.notifier)
          .validate('DISCOUNT20', 10000.0);

      final state = container.read(promoCodeProvider);
      expect(state.code, 'DISCOUNT20');
      expect(state.discount, 2000.0);
      expect(state.description, '20% de réduction');
      expect(state.isValidating, isFalse);
      expect(state.error, isNull);
    });

    test('parses discount as String correctly', () async {
      when(() => mockApi.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => _makeSuccessResponse(
          discount: '1500', // String instead of num
        ),
      );

      final container = _makeContainer(mockApi);
      addTearDown(container.dispose);

      await container.read(promoCodeProvider.notifier).validate('CODE', 5000.0);

      final state = container.read(promoCodeProvider);
      expect(state.discount, 1500.0);
    });

    test('parses discount of 0 for invalid string', () async {
      when(() => mockApi.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => _makeSuccessResponse(discount: 'invalid_string'),
      );

      final container = _makeContainer(mockApi);
      addTearDown(container.dispose);

      await container.read(promoCodeProvider.notifier).validate('CODE', 5000.0);

      final state = container.read(promoCodeProvider);
      expect(state.discount, 0.0);
    });

    test('sets error when success is false', () async {
      when(() => mockApi.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => _makeFailureResponse(message: 'Code promo expiré'),
      );

      final container = _makeContainer(mockApi);
      addTearDown(container.dispose);

      await container
          .read(promoCodeProvider.notifier)
          .validate('EXPIRED', 5000.0);

      final state = container.read(promoCodeProvider);
      expect(state.code, isNull);
      expect(state.error, 'Code promo expiré');
      expect(state.isValidating, isFalse);
    });

    test('uses default error when message missing in failure', () async {
      when(() => mockApi.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/promo-codes/validate'),
          data: {'success': false},
          statusCode: 200,
        ),
      );

      final container = _makeContainer(mockApi);
      addTearDown(container.dispose);

      await container.read(promoCodeProvider.notifier).validate('BAD', 5000.0);

      final state = container.read(promoCodeProvider);
      expect(state.error, 'Code invalide');
    });

    test('sets error when DioException is thrown', () async {
      when(() => mockApi.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/promo-codes/validate'),
          type: DioExceptionType.connectionError,
        ),
      );

      final container = _makeContainer(mockApi);
      addTearDown(container.dispose);

      await container.read(promoCodeProvider.notifier).validate('CODE', 5000.0);

      final state = container.read(promoCodeProvider);
      expect(state.error, isNotNull);
      expect(state.isValidating, isFalse);
      expect(state.code, isNull);
    });

    test('sets error on generic exception', () async {
      when(
        () => mockApi.post(any(), data: any(named: 'data')),
      ).thenThrow(Exception('Network error'));

      final container = _makeContainer(mockApi);
      addTearDown(container.dispose);

      await container
          .read(promoCodeProvider.notifier)
          .validate('PROMO', 5000.0);

      final state = container.read(promoCodeProvider);
      expect(state.error, contains('invalide'));
    });

    test('trims whitespace from code before validating', () async {
      when(
        () => mockApi.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _makeSuccessResponse(code: 'PROMO10'));

      final container = _makeContainer(mockApi);
      addTearDown(container.dispose);

      await container
          .read(promoCodeProvider.notifier)
          .validate('  PROMO10  ', 5000.0);

      final verify_ = verify(
        () => mockApi.post(any(), data: captureAny(named: 'data')),
      );
      verify_.called(1);
      final capturedData = verify_.captured.first as Map<String, dynamic>;
      expect(capturedData['code'], 'PROMO10');
    });
  });

  // ─────────────────────────────────────────────────────────
  // PromoCodeNotifier — clear
  // ─────────────────────────────────────────────────────────

  group('PromoCodeNotifier — clear', () {
    test('clear resets state to empty', () async {
      when(
        () => mockApi.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _makeSuccessResponse());

      final container = _makeContainer(mockApi);
      addTearDown(container.dispose);

      final notifier = container.read(promoCodeProvider.notifier);

      await notifier.validate('PROMO10', 5000.0);
      expect(container.read(promoCodeProvider).code, isNotNull);

      notifier.clear();

      final state = container.read(promoCodeProvider);
      expect(state.code, isNull);
      expect(state.discount, 0);
      expect(state.error, isNull);
    });
  });
}
