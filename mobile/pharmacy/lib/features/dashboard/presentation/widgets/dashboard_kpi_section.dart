import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/presentation/providers/order_list_provider.dart';
import '../../../orders/domain/enums/order_status.dart';
import '../../../prescriptions/presentation/providers/prescription_provider.dart';
import '../providers/dashboard_tab_provider.dart';
import '../providers/activity_sub_tab_provider.dart';
import 'dashboard_recent_cards.dart';
import '../../../../l10n/app_localizations.dart';

/// KPIs actionnables (commandes/ordonnances en attente)
class DashboardKpiSection extends ConsumerWidget {
  const DashboardKpiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orderState = ref.watch(orderListProvider);
    final prescriptionState = ref.watch(prescriptionListProvider);
    final isDark = AppColors.isDark(context);

    final pendingOrders = orderState.orders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final pendingPrescriptions = prescriptionState.prescriptions
        .where((p) => p.status == OrderStatus.pending)
        .length;

    if (pendingOrders == 0 && pendingPrescriptions == 0) {
      return const SizedBox.shrink();
    }

    return ResponsiveBuilder(
      builder: (context, responsive) => Container(
        margin: EdgeInsets.fromLTRB(
          responsive.horizontalPadding,
          20,
          responsive.horizontalPadding,
          0,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.orange.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.priority_high_rounded,
                    size: 20,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.actionsRequired,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (pendingOrders > 0)
                  Expanded(
                    child: ActionRequiredCard(
                      count: pendingOrders,
                      label: l10n.pendingOrdersCount(pendingOrders),
                      icon: Icons.shopping_bag_rounded,
                      color: Colors.orange,
                      onTap: () {
                        ref.read(activitySubTabProvider.notifier).state = 0;
                        ref.read(dashboardTabProvider.notifier).state = 1;
                      },
                    ),
                  ),
                if (pendingOrders > 0 && pendingPrescriptions > 0)
                  const SizedBox(width: 12),
                if (pendingPrescriptions > 0)
                  Expanded(
                    child: ActionRequiredCard(
                      count: pendingPrescriptions,
                      label: l10n.pendingPrescriptionsCount(
                        pendingPrescriptions,
                      ),
                      icon: Icons.medical_services_rounded,
                      color: Colors.purple,
                      onTap: () {
                        ref.read(activitySubTabProvider.notifier).state = 1;
                        ref.read(dashboardTabProvider.notifier).state = 1;
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
