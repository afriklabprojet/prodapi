import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_init_result.dart';

enum PaymentStatus { idle, loading, success, error }

class PaymentState extends Equatable {
  final PaymentStatus status;
  final PaymentInitResult? result;
  final String? errorMessage;

  const PaymentState({
    required this.status,
    this.result,
    this.errorMessage,
  });

  const PaymentState.idle()
      : status = PaymentStatus.idle,
        result = null,
        errorMessage = null;

  PaymentState copyWith({
    PaymentStatus? status,
    PaymentInitResult? result,
    String? errorMessage,
  }) {
    return PaymentState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, result, errorMessage];
}
