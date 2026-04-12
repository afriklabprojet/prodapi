import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../domain/usecases/initiate_payment_usecase.dart';
import 'payment_notifier.dart';
import 'payment_state.dart';

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final repository = ref.watch(ordersRepositoryProvider);
  return PaymentNotifier(
    initiatePaymentUseCase: InitiatePaymentUseCase(repository),
  );
});
