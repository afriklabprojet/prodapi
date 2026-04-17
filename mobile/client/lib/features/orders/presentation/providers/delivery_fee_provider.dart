import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import 'delivery_fee_notifier.dart';

final deliveryFeeProvider =
    StateNotifierProvider<DeliveryFeeNotifier, DeliveryFeeState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeliveryFeeNotifier(apiClient: apiClient);
});
