import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_init_result.dart';
import '../../domain/usecases/initiate_payment_usecase.dart';
import 'payment_state.dart';

class PaymentNotifier extends StateNotifier<PaymentState> {
  final InitiatePaymentUseCase _initiatePaymentUseCase;

  PaymentNotifier({required InitiatePaymentUseCase initiatePaymentUseCase})
      : _initiatePaymentUseCase = initiatePaymentUseCase,
        super(const PaymentState.idle());

  /// Initiates a payment and updates [PaymentState] accordingly.
  ///
  /// Handles the 409 PAYMENT_IN_PROGRESS case: when JEKO already has an open
  /// session for this order, the server returns a `redirect_url` inside
  /// `responseData.data`.  We surface this as a successful [PaymentInitResult]
  /// with [PaymentInitResult.isExistingPayment] = `true` so the UI can reopen
  /// the existing WebView session instead of showing an error.
  Future<void> initiatePayment({
    required int orderId,
    required String provider,
    String? paymentMethod,
  }) async {
    state = state.copyWith(status: PaymentStatus.loading, errorMessage: null);

    final result = await _initiatePaymentUseCase(
      orderId: orderId,
      provider: provider,
      paymentMethod: paymentMethod,
    );

    result.fold(
      (failure) {
        // 409 PAYMENT_IN_PROGRESS: re-use the existing payment URL
        if (failure is ServerFailure && failure.responseData != null) {
          final data = failure.responseData!['data'];
          final redirectUrl =
              data is Map ? (data['redirect_url'] as String?) : null;
          if (redirectUrl != null && redirectUrl.isNotEmpty) {
            state = state.copyWith(
              status: PaymentStatus.success,
              result: PaymentInitResult(
                paymentUrl: redirectUrl,
                provider: provider,
                isExistingPayment: true,
              ),
            );
            return;
          }
        }
        state = PaymentState(
          status: PaymentStatus.error,
          errorMessage: failure.message,
        );
      },
      (data) {
        final paymentUrl =
            data['payment_url'] as String? ?? data['redirect_url'] as String?;
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          state = state.copyWith(
            status: PaymentStatus.success,
            result: PaymentInitResult(
              paymentUrl: paymentUrl,
              provider: provider,
              transactionId: data['transaction_id'] as String?,
            ),
          );
        } else {
          state = const PaymentState(
            status: PaymentStatus.error,
            errorMessage: 'Erreur lors de l\'initialisation du paiement',
          );
        }
      },
    );
  }

  void reset() => state = const PaymentState.idle();
}
