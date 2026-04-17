import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/providers/ui_state_providers.dart';
import '../../providers/cart_provider.dart';
import '../../mixins/checkout_logic_mixin.dart';
import '../checkout_submit_button.dart';

/// Displays the submit button with the order total.
///
/// Watches only the two fields it needs ([CartState.total] and loading state)
/// so unrelated cart changes do not trigger a rebuild.
class CheckoutSummarySection extends ConsumerWidget {
  final VoidCallback onSubmit;

  // 💡 static final: identical to the format used in CheckoutItemsSection;
  //    keeping it here avoids importing that widget just for the format.
  static final _currency = NumberFormat.currency(
    locale: AppConstants.currencyLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  const CheckoutSummarySection({super.key, required this.onSubmit});

  @override
  Widget build(context, WidgetRef ref) {
    final total       = ref.watch(cartProvider.select((s) => s.total));
    final isSubmitting = ref.watch(
      loadingProvider(checkoutIsSubmittingId).select((s) => s.isLoading),
    );

    return CheckoutSubmitButton(
      isSubmitting:   isSubmitting,
      totalFormatted: _currency.format(total),
      onPressed:      onSubmit,
    );
  }
}
