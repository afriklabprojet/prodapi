import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/features/orders/domain/usecases/initiate_payment_usecase.dart';
import 'package:drpharma_client/features/orders/presentation/providers/payment_notifier.dart';
import 'package:drpharma_client/features/orders/presentation/providers/payment_state.dart';

class MockInitiatePaymentUseCase extends Mock
    implements InitiatePaymentUseCase {}

void main() {
  late MockInitiatePaymentUseCase mockUseCase;
  late PaymentNotifier notifier;

  setUp(() {
    mockUseCase = MockInitiatePaymentUseCase();
    notifier = PaymentNotifier(initiatePaymentUseCase: mockUseCase);
  });

  group('PaymentNotifier — initial state', () {
    test('initial state is idle', () {
      expect(notifier.state.status, PaymentStatus.idle);
      expect(notifier.state.result, isNull);
      expect(notifier.state.errorMessage, isNull);
    });
  });

  group('PaymentNotifier.initiatePayment — success', () {
    test('sets status to success with payment_url', () async {
      when(
        () => mockUseCase(
          orderId: any(named: 'orderId'),
          provider: any(named: 'provider'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer(
        (_) async => Right(<String, dynamic>{
          'payment_url': 'https://pay.example.com/123',
          'transaction_id': 'tx_abc',
        }),
      );

      await notifier.initiatePayment(orderId: 1, provider: 'jeko');

      expect(notifier.state.status, PaymentStatus.success);
      expect(notifier.state.result?.paymentUrl, 'https://pay.example.com/123');
      expect(notifier.state.result?.transactionId, 'tx_abc');
      expect(notifier.state.result?.isExistingPayment, isFalse);
      expect(notifier.state.result?.provider, 'jeko');
    });

    test('uses redirect_url field if payment_url absent', () async {
      when(
        () => mockUseCase(
          orderId: any(named: 'orderId'),
          provider: any(named: 'provider'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer(
        (_) async => Right(<String, dynamic>{
          'redirect_url': 'https://redirect.example.com/pay',
        }),
      );

      await notifier.initiatePayment(orderId: 2, provider: 'momo');

      expect(notifier.state.status, PaymentStatus.success);
      expect(
        notifier.state.result?.paymentUrl,
        'https://redirect.example.com/pay',
      );
    });

    test('sets status to error when both URLs are absent', () async {
      when(
        () => mockUseCase(
          orderId: any(named: 'orderId'),
          provider: any(named: 'provider'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer((_) async => Right(<String, dynamic>{'status': 'pending'}));

      await notifier.initiatePayment(orderId: 3, provider: 'jeko');

      expect(notifier.state.status, PaymentStatus.error);
      expect(notifier.state.errorMessage, isNotNull);
    });
  });

  group('PaymentNotifier.initiatePayment — failure', () {
    test('sets status to error on ServerFailure', () async {
      when(
        () => mockUseCase(
          orderId: any(named: 'orderId'),
          provider: any(named: 'provider'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer(
        (_) async =>
            Left(ServerFailure(message: 'Paiement échoué', statusCode: 500)),
      );

      await notifier.initiatePayment(orderId: 1, provider: 'jeko');

      expect(notifier.state.status, PaymentStatus.error);
      expect(notifier.state.errorMessage, 'Paiement échoué');
    });

    test('handles 409 PAYMENT_IN_PROGRESS with redirect_url', () async {
      when(
        () => mockUseCase(
          orderId: any(named: 'orderId'),
          provider: any(named: 'provider'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer(
        (_) async => Left(
          ServerFailure(
            message: 'PAYMENT_IN_PROGRESS',
            statusCode: 409,
            responseData: {
              'data': {'redirect_url': 'https://existing.pay.example.com'},
            },
          ),
        ),
      );

      await notifier.initiatePayment(orderId: 4, provider: 'jeko');

      expect(notifier.state.status, PaymentStatus.success);
      expect(
        notifier.state.result?.paymentUrl,
        'https://existing.pay.example.com',
      );
      expect(notifier.state.result?.isExistingPayment, isTrue);
    });

    test('409 without redirect_url falls through to error', () async {
      when(
        () => mockUseCase(
          orderId: any(named: 'orderId'),
          provider: any(named: 'provider'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer(
        (_) async => Left(
          ServerFailure(
            message: 'Conflict',
            statusCode: 409,
            responseData: {'data': null},
          ),
        ),
      );

      await notifier.initiatePayment(orderId: 5, provider: 'jeko');

      expect(notifier.state.status, PaymentStatus.error);
      expect(notifier.state.errorMessage, 'Conflict');
    });

    test('sets loading state before completing', () async {
      final states = <PaymentStatus>[];
      states.add(notifier.state.status);

      when(
        () => mockUseCase(
          orderId: any(named: 'orderId'),
          provider: any(named: 'provider'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer((_) async {
        states.add(notifier.state.status);
        return Left(const NetworkFailure(message: 'no network'));
      });

      await notifier.initiatePayment(orderId: 1, provider: 'jeko');

      expect(
        states,
        containsAllInOrder([PaymentStatus.idle, PaymentStatus.loading]),
      );
    });
  });

  group('PaymentNotifier.reset', () {
    test('reset returns state to idle', () async {
      when(
        () => mockUseCase(
          orderId: any(named: 'orderId'),
          provider: any(named: 'provider'),
          paymentMethod: any(named: 'paymentMethod'),
        ),
      ).thenAnswer(
        (_) async => Left(ServerFailure(message: 'error', statusCode: 500)),
      );

      await notifier.initiatePayment(orderId: 1, provider: 'jeko');
      expect(notifier.state.status, PaymentStatus.error);

      notifier.reset();
      expect(notifier.state.status, PaymentStatus.idle);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // PaymentState
  // ---------------------------------------------------------------------------
  group('PaymentState', () {
    test('idle constructor sets all to null/idle', () {
      const s = PaymentState.idle();
      expect(s.status, PaymentStatus.idle);
      expect(s.result, isNull);
      expect(s.errorMessage, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const s = PaymentState.idle();
      final s2 = s.copyWith(status: PaymentStatus.loading);
      expect(s2.status, PaymentStatus.loading);
      expect(s2.result, isNull);
      expect(s2.errorMessage, isNull);
    });

    test('copyWith clears errorMessage when passed null', () {
      const s = PaymentState(status: PaymentStatus.error, errorMessage: 'err');
      final s2 = s.copyWith(status: PaymentStatus.idle, errorMessage: null);
      expect(s2.errorMessage, isNull);
    });

    test('props are correct', () {
      const s = PaymentState.idle();
      expect(s.props, hasLength(3));
    });
  });
}
