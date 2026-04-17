/// Typed result from a successful payment initiation.
///
/// [isExistingPayment] is `true` when the server returned 409
/// PAYMENT_IN_PROGRESS — the [paymentUrl] is the redirect URL of the
/// still-active payment session, not a newly created one.
class PaymentInitResult {
  final String paymentUrl;
  final String provider;
  final String? transactionId;
  final bool isExistingPayment;

  const PaymentInitResult({
    required this.paymentUrl,
    required this.provider,
    this.transactionId,
    this.isExistingPayment = false,
  });
}
