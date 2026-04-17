import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'checkout_prescription_notifier.dart';

final checkoutPrescriptionProvider = StateNotifierProvider<
    CheckoutPrescriptionNotifier, CheckoutPrescriptionState>((ref) {
  return CheckoutPrescriptionNotifier();
});
