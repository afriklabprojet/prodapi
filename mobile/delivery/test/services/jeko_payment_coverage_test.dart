import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/services/jeko_payment_service.dart';

void main() {
  group('PaymentDeepLink', () {
    test('constructor with success', () {
      final link = PaymentDeepLink(reference: 'REF-123', isSuccess: true);
      expect(link.reference, 'REF-123');
      expect(link.isSuccess, true);
      expect(link.errorMessage, isNull);
    });

    test('constructor with failure', () {
      final link = PaymentDeepLink(
        reference: 'REF-456',
        isSuccess: false,
        errorMessage: 'Paiement refusé',
      );
      expect(link.reference, 'REF-456');
      expect(link.isSuccess, false);
      expect(link.errorMessage, 'Paiement refusé');
    });
  });

  group('PaymentFlowState', () {
    test('has 8 values', () {
      expect(PaymentFlowState.values.length, 8);
    });

    test('all states accessible', () {
      expect(PaymentFlowState.idle, isNotNull);
      expect(PaymentFlowState.initiating, isNotNull);
      expect(PaymentFlowState.redirecting, isNotNull);
      expect(PaymentFlowState.waitingForCallback, isNotNull);
      expect(PaymentFlowState.verifying, isNotNull);
      expect(PaymentFlowState.success, isNotNull);
      expect(PaymentFlowState.failed, isNotNull);
      expect(PaymentFlowState.timeout, isNotNull);
    });
  });

  group('PaymentFlowStatus', () {
    test('default constructor', () {
      final status = PaymentFlowStatus();
      expect(status.state, PaymentFlowState.idle);
      expect(status.reference, isNull);
      expect(status.redirectUrl, isNull);
      expect(status.statusResponse, isNull);
      expect(status.errorMessage, isNull);
      expect(status.retryCount, 0);
    });

    test('copyWith updates state', () {
      final status = PaymentFlowStatus();
      final updated = status.copyWith(
        state: PaymentFlowState.initiating,
        reference: 'REF-789',
      );
      expect(updated.state, PaymentFlowState.initiating);
      expect(updated.reference, 'REF-789');
      expect(updated.retryCount, 0);
    });

    test('copyWith preserves existing values', () {
      final status = PaymentFlowStatus(
        state: PaymentFlowState.redirecting,
        reference: 'REF-001',
        retryCount: 2,
      );
      final updated = status.copyWith(state: PaymentFlowState.verifying);
      expect(updated.state, PaymentFlowState.verifying);
      expect(updated.reference, 'REF-001');
      expect(updated.retryCount, 2);
    });

    test('isLoading true for initiating', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.initiating).isLoading,
        true,
      );
    });

    test('isLoading true for redirecting', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.redirecting).isLoading,
        true,
      );
    });

    test('isLoading true for verifying', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.verifying).isLoading,
        true,
      );
    });

    test('isLoading false for idle', () {
      expect(PaymentFlowStatus().isLoading, false);
    });

    test('isLoading false for success', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.success).isLoading,
        false,
      );
    });

    test('isFinal true for success', () {
      expect(PaymentFlowStatus(state: PaymentFlowState.success).isFinal, true);
    });

    test('isFinal true for failed', () {
      expect(PaymentFlowStatus(state: PaymentFlowState.failed).isFinal, true);
    });

    test('isFinal true for timeout', () {
      expect(PaymentFlowStatus(state: PaymentFlowState.timeout).isFinal, true);
    });

    test('isFinal false for idle', () {
      expect(PaymentFlowStatus().isFinal, false);
    });

    test('canRetry true for failed', () {
      expect(PaymentFlowStatus(state: PaymentFlowState.failed).canRetry, true);
    });

    test('canRetry true for timeout', () {
      expect(PaymentFlowStatus(state: PaymentFlowState.timeout).canRetry, true);
    });

    test('canRetry false for success', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.success).canRetry,
        false,
      );
    });

    test('canRetry false for idle', () {
      expect(PaymentFlowStatus().canRetry, false);
    });
  });
}
