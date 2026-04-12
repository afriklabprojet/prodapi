import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/presentation/providers/order_list_provider.dart';
import '../../../orders/presentation/providers/state/order_list_state.dart';
import 'dashboard_empty_state.dart';
import 'dashboard_recent_cards.dart';
import 'dashboard_skeletons.dart';

/// Orders tab content — watches [orderListProvider] only.
/// Scoped subscription avoids wallet/prescription rebuilds.
class OrdersTabContent extends ConsumerWidget {
  const OrdersTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderListProvider);

    if (orderState.status == OrderLoadStatus.loading) {
      return Column(
        key: const ValueKey('orders_loading'),
        children: [SkeletonList(itemBuilder: () => const OrderRowSkeleton())],
      );
    }

    final recentOrders = orderState.orders.take(3).toList();

    if (recentOrders.isEmpty) {
      return DashboardEmptyState(
        key: const ValueKey('orders_empty'),
        icon: Icons.inbox_rounded,
        message: AppLocalizations.of(context).noRecentOrders,
      );
    }

    return Column(
      key: const ValueKey('orders'),
      children: [
        for (final order in recentOrders)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RecentOrderCard(
              orderNumber: order.reference,
              customerName: order.customerName,
              status: order.status,
              total: order.totalAmount,
              createdAt: order.createdAt,
              onTap: () => context.push('/orders/${order.id}'),
            ),
          ),
      ],
    );
  }
}
