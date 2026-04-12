import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/config/app_config.dart';
import 'package:courier/data/services/jeko_payment_service.dart';
import 'package:courier/data/repositories/jeko_payment_repository.dart';

class _FakeJekoPaymentRepository extends JekoPaymentRepository {
  _FakeJekoPaymentRepository({
    this.onInitiateWalletTopup,
    this.onCheckPaymentStatus,
  }) : super(Dio());

  final Future<PaymentInitResponse> Function({
    required double amount,
    required JekoPaymentMethod method,
  })? onInitiateWalletTopup;
  final Future<PaymentStatusResponse> Function(String reference)? onCheckPaymentStatus;

  @override
  Future<PaymentInitResponse> initiateWalletTopup({
    required double amount,
    required JekoPaymentMethod method,
  }) async {
    return onInitiateWalletTopup?.call(amount: amount, method: method) ??
        PaymentInitResponse(
          reference: 'PAY-DEFAULT',
          redirectUrl: 'https://example.com/sandbox/confirm',
          amount: amount,
          currency: 'XOF',
          paymentMethod: method.value,
        );
  }

  @override
  Future<PaymentStatusResponse> checkPaymentStatus(String reference) async {
    return onCheckPaymentStatus?.call(reference) ??
        PaymentStatusResponse(
          reference: reference,
          status: 'pending',
          statusLabel: 'En attente',
          amount: 0,
          currency: 'XOF',
          paymentMethod: '',
          isFinal: false,
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaymentDeepLink', () {
    test('creates success deep link', () {
      final link = PaymentDeepLink(reference: 'PAY-001', isSuccess: true);
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
      expect(
        PaymentFlowState.values,
        contains(PaymentFlowState.waitingForCallback),
      );
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
      expect(PaymentFlowStatus(state: PaymentFlowState.idle).isLoading, false);
    });

    test('isFinal is true for success/failed/timeout', () {
      expect(PaymentFlowStatus(state: PaymentFlowState.success).isFinal, true);
      expect(PaymentFlowStatus(state: PaymentFlowState.failed).isFinal, true);
      expect(PaymentFlowStatus(state: PaymentFlowState.timeout).isFinal, true);
      expect(
        PaymentFlowStatus(state: PaymentFlowState.initiating).isFinal,
        false,
      );
    });

    test('canRetry is true for failed/timeout only', () {
      expect(PaymentFlowStatus(state: PaymentFlowState.failed).canRetry, true);
      expect(PaymentFlowStatus(state: PaymentFlowState.timeout).canRetry, true);
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

    test('isLoading false for idle', () {
      expect(PaymentFlowStatus(state: PaymentFlowState.idle).isLoading, false);
    });

    test('isLoading false for waitingForCallback', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.waitingForCallback).isLoading,
        false,
      );
    });

    test('isLoading false for success', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.success).isLoading,
        false,
      );
    });

    test('isLoading false for failed', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.failed).isLoading,
        false,
      );
    });

    test('isLoading false for timeout', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.timeout).isLoading,
        false,
      );
    });

    test('isFinal false for idle', () {
      expect(PaymentFlowStatus(state: PaymentFlowState.idle).isFinal, false);
    });

    test('isFinal false for redirecting', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.redirecting).isFinal,
        false,
      );
    });

    test('isFinal false for waitingForCallback', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.waitingForCallback).isFinal,
        false,
      );
    });

    test('isFinal false for verifying', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.verifying).isFinal,
        false,
      );
    });

    test('canRetry false for idle', () {
      expect(PaymentFlowStatus(state: PaymentFlowState.idle).canRetry, false);
    });

    test('canRetry false for initiating', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.initiating).canRetry,
        false,
      );
    });

    test('canRetry false for redirecting', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.redirecting).canRetry,
        false,
      );
    });

    test('canRetry false for waitingForCallback', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.waitingForCallback).canRetry,
        false,
      );
    });

    test('canRetry false for verifying', () {
      expect(
        PaymentFlowStatus(state: PaymentFlowState.verifying).canRetry,
        false,
      );
    });

    test('copyWith preserves all fields when no args', () {
      final original = PaymentFlowStatus(
        state: PaymentFlowState.verifying,
        reference: 'REF-123',
        redirectUrl: 'https://pay.example.com',
        errorMessage: 'Some error',
        retryCount: 3,
      );
      final copy = original.copyWith();
      expect(copy.state, PaymentFlowState.verifying);
      expect(copy.reference, 'REF-123');
      expect(copy.redirectUrl, 'https://pay.example.com');
      expect(copy.errorMessage, 'Some error');
      expect(copy.retryCount, 3);
    });

    test('copyWith overrides errorMessage', () {
      final original = PaymentFlowStatus(errorMessage: 'old');
      final copy = original.copyWith(errorMessage: 'new');
      expect(copy.errorMessage, 'new');
    });

    test('copyWith overrides redirectUrl', () {
      final original = PaymentFlowStatus();
      final copy = original.copyWith(redirectUrl: 'https://new.url');
      expect(copy.redirectUrl, 'https://new.url');
    });
  });

  group('PaymentDeepLink edge cases', () {
    test('creates with all fields', () {
      final link = PaymentDeepLink(
        reference: 'PAY-003',
        isSuccess: true,
        errorMessage: null,
      );
      expect(link.reference, 'PAY-003');
      expect(link.isSuccess, true);
      expect(link.errorMessage, isNull);
    });

    test('failed link with empty error message', () {
      final link = PaymentDeepLink(
        reference: 'PAY-004',
        isSuccess: false,
        errorMessage: '',
      );
      expect(link.isSuccess, false);
      expect(link.errorMessage, '');
    });
  });

  group('PaymentFlowState indices', () {
    test('idle is index 0', () {
      expect(PaymentFlowState.idle.index, 0);
    });

    test('initiating is index 1', () {
      expect(PaymentFlowState.initiating.index, 1);
    });

    test('timeout is last', () {
      expect(
        PaymentFlowState.timeout.index,
        PaymentFlowState.values.length - 1,
      );
    });
  });

  group('PaymentDeepLink - additional', () {
    test('reference can be empty string', () {
      final link = PaymentDeepLink(reference: '', isSuccess: true);
      expect(link.reference, '');
    });

    test('reference with long value', () {
      final ref = 'PAY-${'X' * 100}';
      final link = PaymentDeepLink(reference: ref, isSuccess: true);
      expect(link.reference.length, 104);
    });

    test('success link has null errorMessage by default', () {
      final link = PaymentDeepLink(reference: 'R', isSuccess: true);
      expect(link.errorMessage, isNull);
    });

    test('failure link can have long error', () {
      final link = PaymentDeepLink(
        reference: 'R',
        isSuccess: false,
        errorMessage: 'E' * 500,
      );
      expect(link.errorMessage!.length, 500);
    });
  });

  group('PaymentFlowStatus - combined state checks', () {
    test('idle is not loading, not final, cannot retry', () {
      final s = PaymentFlowStatus(state: PaymentFlowState.idle);
      expect(s.isLoading, false);
      expect(s.isFinal, false);
      expect(s.canRetry, false);
    });

    test('initiating is loading, not final, cannot retry', () {
      final s = PaymentFlowStatus(state: PaymentFlowState.initiating);
      expect(s.isLoading, true);
      expect(s.isFinal, false);
      expect(s.canRetry, false);
    });

    test('redirecting is loading, not final, cannot retry', () {
      final s = PaymentFlowStatus(state: PaymentFlowState.redirecting);
      expect(s.isLoading, true);
      expect(s.isFinal, false);
      expect(s.canRetry, false);
    });

    test('waitingForCallback is not loading, not final, cannot retry', () {
      final s = PaymentFlowStatus(state: PaymentFlowState.waitingForCallback);
      expect(s.isLoading, false);
      expect(s.isFinal, false);
      expect(s.canRetry, false);
    });

    test('verifying is loading, not final, cannot retry', () {
      final s = PaymentFlowStatus(state: PaymentFlowState.verifying);
      expect(s.isLoading, true);
      expect(s.isFinal, false);
      expect(s.canRetry, false);
    });

    test('success is not loading, is final, cannot retry', () {
      final s = PaymentFlowStatus(state: PaymentFlowState.success);
      expect(s.isLoading, false);
      expect(s.isFinal, true);
      expect(s.canRetry, false);
    });

    test('failed is not loading, is final, can retry', () {
      final s = PaymentFlowStatus(state: PaymentFlowState.failed);
      expect(s.isLoading, false);
      expect(s.isFinal, true);
      expect(s.canRetry, true);
    });

    test('timeout is not loading, is final, can retry', () {
      final s = PaymentFlowStatus(state: PaymentFlowState.timeout);
      expect(s.isLoading, false);
      expect(s.isFinal, true);
      expect(s.canRetry, true);
    });
  });

  group('PaymentFlowStatus - copyWith individual fields', () {
    test('copyWith state only', () {
      final s = PaymentFlowStatus();
      final copy = s.copyWith(state: PaymentFlowState.success);
      expect(copy.state, PaymentFlowState.success);
      expect(copy.reference, isNull);
    });

    test('copyWith reference only', () {
      final s = PaymentFlowStatus();
      final copy = s.copyWith(reference: 'NEW-REF');
      expect(copy.reference, 'NEW-REF');
      expect(copy.state, PaymentFlowState.idle);
    });

    test('copyWith retryCount only', () {
      final s = PaymentFlowStatus();
      final copy = s.copyWith(retryCount: 5);
      expect(copy.retryCount, 5);
    });

    test('copyWith redirectUrl only', () {
      final s = PaymentFlowStatus();
      final copy = s.copyWith(redirectUrl: 'https://example.com/pay');
      expect(copy.redirectUrl, 'https://example.com/pay');
    });

    test('copyWith errorMessage only', () {
      final s = PaymentFlowStatus();
      final copy = s.copyWith(errorMessage: 'timeout');
      expect(copy.errorMessage, 'timeout');
    });
  });

  group('PaymentFlowStatus - retry scenarios', () {
    test('retryCount starts at 0', () {
      final s = PaymentFlowStatus();
      expect(s.retryCount, 0);
    });

    test('retryCount increments via copyWith', () {
      var s = PaymentFlowStatus();
      s = s.copyWith(retryCount: s.retryCount + 1);
      expect(s.retryCount, 1);
      s = s.copyWith(retryCount: s.retryCount + 1);
      expect(s.retryCount, 2);
    });

    test('failed with retry count', () {
      final s = PaymentFlowStatus(
        state: PaymentFlowState.failed,
        retryCount: 3,
        errorMessage: 'Network error',
      );
      expect(s.canRetry, true);
      expect(s.retryCount, 3);
      expect(s.errorMessage, 'Network error');
    });

    test('timeout with url and reference', () {
      final s = PaymentFlowStatus(
        state: PaymentFlowState.timeout,
        reference: 'PAY-TIMEOUT',
        redirectUrl: 'https://pay.jeko.ci/timeout',
      );
      expect(s.canRetry, true);
      expect(s.reference, 'PAY-TIMEOUT');
      expect(s.redirectUrl, contains('timeout'));
    });
  });

  group('PaymentFlowState - name property', () {
    test('each state has correct name', () {
      expect(PaymentFlowState.idle.name, 'idle');
      expect(PaymentFlowState.initiating.name, 'initiating');
      expect(PaymentFlowState.redirecting.name, 'redirecting');
      expect(PaymentFlowState.waitingForCallback.name, 'waitingForCallback');
      expect(PaymentFlowState.verifying.name, 'verifying');
      expect(PaymentFlowState.success.name, 'success');
      expect(PaymentFlowState.failed.name, 'failed');
      expect(PaymentFlowState.timeout.name, 'timeout');
    });
  });

  group('JekoPaymentService', () {
    test('exposes callback URLs from app config', () {
      expect(
        JekoPaymentService.successUrl,
        '${AppConfig.deepLinkScheme}://${AppConfig.deepLinkPaymentHost}/success',
      );
      expect(
        JekoPaymentService.errorUrl,
        '${AppConfig.deepLinkScheme}://${AppConfig.deepLinkPaymentHost}/error',
      );
      expect(JekoPaymentService.maxRetries, AppConfig.paymentMaxRetries);
      expect(JekoPaymentService.maxWaitTime, const Duration(minutes: 5));
      expect(JekoPaymentService.hasActivePendingPayment, isFalse);
    });

    test('checkStatus delegates to repository', () async {
      final service = JekoPaymentService(
        _FakeJekoPaymentRepository(
          onCheckPaymentStatus: (reference) async => PaymentStatusResponse(
            reference: reference,
            status: 'success',
            statusLabel: 'Réussi',
            amount: 4200,
            currency: 'XOF',
            paymentMethod: 'wave',
            isFinal: true,
          ),
        ),
      );

      final result = await service.checkStatus('PAY-DELEGATE');

      expect(result.reference, 'PAY-DELEGATE');
      expect(result.isSuccess, isTrue);
      expect(result.amount, 4200);
    });

    test('retryPayment stops immediately when max retries is reached', () async {
      final service = JekoPaymentService(_FakeJekoPaymentRepository());
      final updates = <PaymentFlowStatus>[];

      final result = await service.retryPayment(
        amount: 5000,
        method: JekoPaymentMethod.wave,
        currentRetry: JekoPaymentService.maxRetries,
        onStatusChange: updates.add,
      );

      expect(result.state, PaymentFlowState.failed);
      expect(result.errorMessage, contains('maximum'));
      expect(result.retryCount, JekoPaymentService.maxRetries);
      expect(updates, isEmpty);
    });

    test(
      'initiateWalletTopup maps connection failures to a user-friendly message',
      () async {
        final service = JekoPaymentService(
          _FakeJekoPaymentRepository(
            onInitiateWalletTopup: ({required amount, required method}) async {
              throw Exception('SocketException: Failed host lookup');
            },
          ),
        );
        final updates = <PaymentFlowStatus>[];

        final result = await service.initiateWalletTopup(
          amount: 2500,
          method: JekoPaymentMethod.wave,
          onStatusChange: updates.add,
        );

        expect(updates.first.state, PaymentFlowState.initiating);
        expect(result.state, PaymentFlowState.failed);
        expect(
          result.errorMessage,
          'Impossible de contacter le serveur. Vérifiez votre connexion internet.',
        );
        expect(JekoPaymentService.hasActivePendingPayment, isFalse);
      },
    );

    test(
      'initiateWalletTopup completes with success after verification polling',
      () async {
        var statusChecks = 0;
        final service = JekoPaymentService(
          _FakeJekoPaymentRepository(
            onInitiateWalletTopup: ({required amount, required method}) async {
              return PaymentInitResponse(
                reference: 'PAY-SUCCESS',
                redirectUrl: 'https://example.com/sandbox/confirm',
                amount: amount,
                currency: 'XOF',
                paymentMethod: method.value,
              );
            },
            onCheckPaymentStatus: (reference) async {
              statusChecks++;
              return PaymentStatusResponse(
                reference: reference,
                status: 'success',
                statusLabel: 'Réussi',
                amount: 2500,
                currency: 'XOF',
                paymentMethod: 'wave',
                isFinal: true,
              );
            },
          ),
        );
        final updates = <PaymentFlowStatus>[];

        final result = await service.initiateWalletTopup(
          amount: 2500,
          method: JekoPaymentMethod.wave,
          onStatusChange: updates.add,
        );

        expect(statusChecks, 1);
        expect(
          updates.map((status) => status.state),
          containsAllInOrder([
            PaymentFlowState.initiating,
            PaymentFlowState.redirecting,
            PaymentFlowState.waitingForCallback,
            PaymentFlowState.verifying,
            PaymentFlowState.success,
          ]),
        );
        expect(result.state, PaymentFlowState.success);
        expect(result.reference, 'PAY-SUCCESS');
        expect(JekoPaymentService.hasActivePendingPayment, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 8)),
    );

    test(
      'initiateWalletTopup surfaces backend failure status after verification',
      () async {
        final service = JekoPaymentService(
          _FakeJekoPaymentRepository(
            onInitiateWalletTopup: ({required amount, required method}) async {
              return PaymentInitResponse(
                reference: 'PAY-FAILED',
                redirectUrl: 'https://example.com/sandbox/confirm',
                amount: amount,
                currency: 'XOF',
                paymentMethod: method.value,
              );
            },
            onCheckPaymentStatus: (reference) async => PaymentStatusResponse(
              reference: reference,
              status: 'failed',
              statusLabel: 'Échoué',
              amount: 1800,
              currency: 'XOF',
              paymentMethod: 'orange',
              isFinal: true,
              errorMessage: 'Paiement refusé',
            ),
          ),
        );
        final updates = <PaymentFlowStatus>[];

        final result = await service.initiateWalletTopup(
          amount: 1800,
          method: JekoPaymentMethod.orange,
          onStatusChange: updates.add,
        );

        expect(result.state, PaymentFlowState.failed);
        expect(result.errorMessage, 'Paiement refusé');
        expect(updates.last.state, PaymentFlowState.failed);
        expect(JekoPaymentService.hasActivePendingPayment, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 8)),
    );
  });

  // ── JekoPaymentMethod enum tests ──
  group('JekoPaymentMethod', () {
    test('has 5 methods', () {
      expect(JekoPaymentMethod.values.length, 5);
    });

    test('wave has correct value and label', () {
      expect(JekoPaymentMethod.wave.value, 'wave');
      expect(JekoPaymentMethod.wave.label, 'Wave');
      expect(JekoPaymentMethod.wave.icon, contains('wave'));
    });

    test('orange has correct value and label', () {
      expect(JekoPaymentMethod.orange.value, 'orange');
      expect(JekoPaymentMethod.orange.label, 'Orange Money');
      expect(JekoPaymentMethod.orange.icon, contains('orange'));
    });

    test('mtn has correct value and label', () {
      expect(JekoPaymentMethod.mtn.value, 'mtn');
      expect(JekoPaymentMethod.mtn.label, 'MTN MoMo');
      expect(JekoPaymentMethod.mtn.icon, contains('mtn'));
    });

    test('moov has correct value and label', () {
      expect(JekoPaymentMethod.moov.value, 'moov');
      expect(JekoPaymentMethod.moov.label, 'Moov Money');
      expect(JekoPaymentMethod.moov.icon, contains('moov'));
    });

    test('djamo has correct value and label', () {
      expect(JekoPaymentMethod.djamo.value, 'djamo');
      expect(JekoPaymentMethod.djamo.label, 'Djamo');
      expect(JekoPaymentMethod.djamo.icon, contains('djamo'));
    });
  });

  // ── PaymentInitResponse tests ──
  group('PaymentInitResponse', () {
    test('fromJson parses complete data', () {
      final r = PaymentInitResponse.fromJson({
        'reference': 'PAY-123',
        'redirect_url': 'https://pay.example.com',
        'amount': 5000,
        'currency': 'XOF',
        'payment_method': 'wave',
      });
      expect(r.reference, 'PAY-123');
      expect(r.redirectUrl, 'https://pay.example.com');
      expect(r.amount, 5000.0);
      expect(r.currency, 'XOF');
      expect(r.paymentMethod, 'wave');
    });

    test('fromJson handles null fields with defaults', () {
      final r = PaymentInitResponse.fromJson({});
      expect(r.reference, '');
      expect(r.redirectUrl, '');
      expect(r.amount, 0.0);
      expect(r.currency, 'XOF');
      expect(r.paymentMethod, '');
    });

    test('fromJson converts integer amount to double', () {
      final r = PaymentInitResponse.fromJson({'amount': 1000});
      expect(r.amount, 1000.0);
    });
  });

  // ── PaymentStatusResponse tests ──
  group('PaymentStatusResponse', () {
    test('fromJson parses complete data', () {
      final r = PaymentStatusResponse.fromJson({
        'reference': 'PAY-456',
        'payment_status': 'success',
        'payment_status_label': 'Réussi',
        'amount': 3000,
        'currency': 'XOF',
        'payment_method': 'orange',
        'is_final': true,
        'completed_at': '2025-01-15T10:00:00Z',
        'error_message': null,
      });
      expect(r.reference, 'PAY-456');
      expect(r.status, 'success');
      expect(r.statusLabel, 'Réussi');
      expect(r.amount, 3000.0);
      expect(r.isFinal, true);
      expect(r.completedAt, '2025-01-15T10:00:00Z');
      expect(r.errorMessage, isNull);
    });

    test('fromJson handles null fields with defaults', () {
      final r = PaymentStatusResponse.fromJson({});
      expect(r.reference, '');
      expect(r.status, 'pending');
      expect(r.statusLabel, 'En attente');
      expect(r.amount, 0.0);
      expect(r.currency, 'XOF');
      expect(r.paymentMethod, '');
      expect(r.isFinal, false);
    });

    test('isSuccess true for success status', () {
      final r = PaymentStatusResponse.fromJson({'payment_status': 'success'});
      expect(r.isSuccess, true);
      expect(r.isFailed, false);
      expect(r.isPending, false);
    });

    test('isFailed true for failed status', () {
      final r = PaymentStatusResponse.fromJson({'payment_status': 'failed'});
      expect(r.isSuccess, false);
      expect(r.isFailed, true);
      expect(r.isPending, false);
    });

    test('isFailed true for expired status', () {
      final r = PaymentStatusResponse.fromJson({'payment_status': 'expired'});
      expect(r.isFailed, true);
    });

    test('isPending true for pending status', () {
      final r = PaymentStatusResponse.fromJson({'payment_status': 'pending'});
      expect(r.isPending, true);
    });

    test('isPending true for processing status', () {
      final r = PaymentStatusResponse.fromJson({
        'payment_status': 'processing',
      });
      expect(r.isPending, true);
    });

    test('fromJson with error_message', () {
      final r = PaymentStatusResponse.fromJson({
        'payment_status': 'failed',
        'error_message': 'Fonds insuffisants',
      });
      expect(r.errorMessage, 'Fonds insuffisants');
      expect(r.isFailed, true);
    });
  });
}
