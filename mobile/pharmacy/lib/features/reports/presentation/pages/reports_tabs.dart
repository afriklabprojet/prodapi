import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'reports_ui_components.dart';

/// Tab Vue d'ensemble
class OverviewTab extends StatelessWidget {
  final Map<String, dynamic> salesData;
  final Map<String, dynamic> ordersData;
  final Map<String, dynamic> inventoryData;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final Future<void> Function() onRefresh;
  final dynamic salesReport;

  const OverviewTab({
    super.key,
    required this.salesData,
    required this.ordersData,
    required this.inventoryData,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onRefresh,
    this.salesReport,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportsPeriodSelector(
              selectedPeriod: selectedPeriod,
              onPeriodChanged: onPeriodChanged,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ReportsMetricCard(
                    title: AppLocalizations.of(context).revenueLabel,
                    value:
                        '${(safeDouble(salesData['week']) / 1000).toStringAsFixed(0)}K',
                    suffix: 'FCFA',
                    growth: safeDouble(salesData['growth']),
                    icon: Icons.trending_up,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReportsMetricCard(
                    title: AppLocalizations.of(context).ordersLabel,
                    value: '${ordersData['total']}',
                    suffix: 'total',
                    growth: 8.3,
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ReportsMetricCard(
                    title: AppLocalizations.of(context).productsLabel,
                    value: '${inventoryData['totalProducts']}',
                    suffix: AppLocalizations.of(context).inStockSuffix,
                    growth: -2.1,
                    icon: Icons.inventory_2_outlined,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReportsMetricCard(
                    title: AppLocalizations.of(context).alertsLabel,
                    value:
                        '${safeInt(inventoryData['lowStock']) + safeInt(inventoryData['expiringSoon'])}',
                    suffix: AppLocalizations.of(context).activeSuffix,
                    growth: 0,
                    icon: Icons.warning_amber_outlined,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            ReportsChartCard(
              title: AppLocalizations.of(context).salesTrend,
              subtitle: AppLocalizations.of(context).periodThisWeek,
              child: SalesChart(dailyBreakdown: salesReport?.dailyBreakdown),
            ),

            const SizedBox(height: 16),

            ReportsChartCard(
              title: AppLocalizations.of(context).orderStatus,
              subtitle: 'Répartition',
              child: OrdersStatusChart(data: ordersData),
            ),

            const SizedBox(height: 16),

            TopProductsCard(topProducts: salesReport?.topProducts),
          ],
        ),
      ),
    );
  }
}

/// Tab Ventes
class SalesTab extends StatelessWidget {
  final Map<String, dynamic> salesData;
  final List<dynamic>? dailyBreakdown;
  final Future<void> Function() onRefresh;

  const SalesTab({
    super.key,
    required this.salesData,
    this.dailyBreakdown,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ReportsDetailCard(
              title: AppLocalizations.of(context).periodToday,
              value: '${safeDouble(salesData['today']) ~/ 1000}K FCFA',
              icon: Icons.today,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            ReportsDetailCard(
              title: 'Hier',
              value: '${safeDouble(salesData['yesterday']) ~/ 1000}K FCFA',
              icon: Icons.history,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            ReportsDetailCard(
              title: AppLocalizations.of(context).periodThisWeek,
              value: '${safeDouble(salesData['week']) ~/ 1000}K FCFA',
              icon: Icons.date_range,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            ReportsDetailCard(
              title: AppLocalizations.of(context).periodThisMonth,
              value: '${safeDouble(salesData['month']) ~/ 1000000}M FCFA',
              icon: Icons.calendar_month,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            ReportsChartCard(
              title: 'Tendance mensuelle',
              subtitle: 'Comparaison avec le mois précédent',
              child: SalesChart(dailyBreakdown: dailyBreakdown),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab Commandes
class OrdersTab extends StatelessWidget {
  final Map<String, dynamic> ordersData;
  final Future<void> Function() onRefresh;

  const OrdersTab({
    super.key,
    required this.ordersData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ReportsDetailCard(
                    title: 'Total',
                    value: '${ordersData['total']}',
                    icon: Icons.shopping_bag,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReportsDetailCard(
                    title: 'En attente',
                    value: '${ordersData['pending']}',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ReportsDetailCard(
                    title: 'Livrées',
                    value: '${ordersData['completed']}',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReportsDetailCard(
                    title: 'Annulées',
                    value: '${ordersData['cancelled']}',
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ReportsChartCard(
              title: 'Répartition par statut',
              subtitle: 'Vue détaillée',
              child: OrdersStatusChart(data: ordersData),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab Inventaire
class InventoryTab extends StatelessWidget {
  final Map<String, dynamic> inventoryData;
  final Future<void> Function() onRefresh;

  const InventoryTab({
    super.key,
    required this.inventoryData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ReportsDetailCard(
              title: 'Total produits',
              value: '${inventoryData['totalProducts']}',
              icon: Icons.inventory,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            ReportsDetailCard(
              title: 'Stock faible',
              value: '${inventoryData['lowStock']}',
              icon: Icons.warning_amber,
              color: Colors.orange,
              urgent: true,
            ),
            const SizedBox(height: 12),
            ReportsDetailCard(
              title: 'Expiration proche',
              value: '${inventoryData['expiringSoon']}',
              icon: Icons.access_time,
              color: Colors.red,
              urgent: true,
            ),
            const SizedBox(height: 12),
            ReportsDetailCard(
              title: 'Rupture de stock',
              value: '${inventoryData['outOfStock']}',
              icon: Icons.remove_shopping_cart,
              color: Colors.red,
              urgent: true,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Conseil: Vérifiez régulièrement les alertes de stock pour éviter les ruptures.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
