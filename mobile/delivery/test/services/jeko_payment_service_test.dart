import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/services/jeko_payment_service.dart';

void main() {
  group('PaymentDeepLink', () {
    test('creates success deep link', () {
      final link = PaymentDeepLink(
        reference: 'PAY-001',
        isSuccess: true,
      );
      expect(link.reference, 'PAY-001');
      expect(link.isSuccess, true);
      expect(link.errorMessage, isNull);
    });

    test('creates failure deep link with error', () {
      final link = PaymentDeepLink(
        reference: 'PAY-002',
        isSuccess: false,
        errorMessage: 'Paiement refusé',
      );
      expect(link.isSuccess, false);
      expect(link.errorMessage, 'Paiement refusé');
    });
  });

  group('PaymentFlowState', () {
    test('has all expected values', () {
      expect(PaymentFlowState.values.length, 8);
      expect(PaymentFlowState.values, contains(PaymentFlowState.idle));
      expect(PaymentFlowState.values, contains(PaymentFlowState.initiating));
      expect(PaymentFlowState.values, contains(PaymentFlowState.redirecting));
      expect(PaymentFlowState.values, contains(PaymentFlowState.waitingForCallback));
      expect(PaymentFlowState.values, contains(PaymentFlowState.verifying));
      expect(PaymentFlowState.values, contains(PaymentFlowState.success));
      expect(PaymentFlowState.values, contains(PaymentFlowState.failed));
      expect(PaymentFlowState.values, contains(PaymentFlowState.timeout));
    });
  });

  group('PaymentFlowStatus', () {
    test('default state is idle', () {
      final status = PaymentFlowStatus();
      expect(status.state, PaymentFlowState.idle);
      expect(status.reference, isNull);
      expect(status.redirectUrl, isNull);
      expect(status.errorMessage, isNull);
      expect(status.retryCount, 0);
    });

    test('isLoading is true for initiating/redirecting/verifying', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.initiating).isLoading,
        true,
      );
      expect(
        PaymentFlowStatus(state: PaymentFlowState.redirecting).isLoading,
        true,
      );
      expect(
        PaymentFlowStatus(state: PaymentFlowState.verifying).isLoading,
        true,
      );
      expect(
        PaymentFlowStatus(state: PaymentFlowState.idle).isLoading,
        false,
      );
    });

    test('isFinal is true for success/failed/timeout', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.success).isFinal,
        true,
      );
      expect(
        PaymentFlowStatus(state: PaymentFlowState.failed).isFinal,
        true,
      );
      expect(
        PaymentFlowStatus(state: PaymentFlowState.timeout).isFinal,
        true,
      );
      expect(
        PaymentFlowStatus(state: PaymentFlowState.initiating).isFinal,
        false,
      );
    });

    test('canRetry is true for failed/timeout only', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.failed).canRetry,
        true,
      );
      expect(
        PaymentFlowStatus(state: PaymentFlowState.timeout).canRetry,
        true,
      );
      expect(
        PaymentFlowStatus(state: PaymentFlowState.success).canRetry,
        false,
      );
    });

    test('copyWith creates modified copy', () {
      final original = PaymentFlowStatus(
        state: PaymentFlowState.initiating,
        reference: 'PAY-001',
      );
      final modified = original.copyWith(
        state: PaymentFlowState.success,
        retryCount: 2,
      );
      expect(modified.state, PaymentFlowState.success);
      expect(modified.reference, 'PAY-001'); // unchanged
      expect(modified.retryCount, 2);
    });
  });
}
