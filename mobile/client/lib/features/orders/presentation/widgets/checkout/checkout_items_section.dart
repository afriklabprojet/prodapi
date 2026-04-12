import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/providers/ui_state_providers.dart';
import '../../providers/cart_provider.dart';
import '../../providers/delivery_fee_provider.dart';
import '../widgets.dart';
import '../../mixins/checkout_logic_mixin.dart';

/// Displays the order summary (items, fees, total).
///
/// Uses granular select() calls so the widget only rebuilds when values it
/// actually displays change.
class CheckoutItemsSection extends ConsumerWidget {
  const CheckoutItemsSection({super.key});

  // 💡 static final: computed once per class, never inside build()
  static final _currency = NumberFormat.currency(
    locale: AppConstants.currencyLocale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  @override
  Widget build(context, WidgetRef ref) {
    final items = ref.watch(cartProvider.select((s) => s.items));
    final subtotal = ref.watch(cartProvider.select((s) => s.subtotal));
    final deliveryFee = ref.watch(cartProvider.select((s) => s.deliveryFee));
    final serviceFee = ref.watch(cartProvider.select((s) => s.serviceFee));
    final paymentFee = ref.watch(cartProvider.select((s) => s.paymentFee));
    final total = ref.watch(cartProvider.select((s) => s.total));
    final distanceKm = ref.watch(
      cartProvider.select((s) => s.deliveryDistanceKm),
    );
    final isLoadingDelivery = ref.watch(
      deliveryFeeProvider.select((s) => s.isLoading),
    );
    final paymentMode = ref.watch(
      formFieldsProvider(
        checkoutPaymentModeId,
      ).select((m) => m['mode'] ?? AppConstants.paymentModePlatform),
    );

    return OrderSummaryCard(
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      paymentFee: paymentFee,
      total: total,
      distanceKm: distanceKm,
      isLoadingDeliveryFee: isLoadingDelivery,
      currencyFormat: _currency,
      paymentMode: paymentMode,
    );
  }
}
