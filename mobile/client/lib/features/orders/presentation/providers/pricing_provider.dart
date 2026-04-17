import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import 'pricing_notifier.dart';

final pricingProvider =
    StateNotifierProvider<PricingNotifier, PricingState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PricingNotifier(apiClient: apiClient);
});
