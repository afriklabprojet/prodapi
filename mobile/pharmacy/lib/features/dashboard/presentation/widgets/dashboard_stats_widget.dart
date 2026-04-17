import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/widgets.dart';
import '../../../reports/presentation/providers/reports_provider.dart';

/// Widget de statistiques pour le dashboard
class DashboardStatsWidget extends ConsumerStatefulWidget {
  const DashboardStatsWidget({super.key});

  @override
  ConsumerState<DashboardStatsWidget> createState() => _DashboardStatsWidgetState();
}

class _DashboardStatsWidgetState extends ConsumerState<DashboardStatsWidget> {
  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).loadDashboard(period: 'today');
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);
    final overview = reportsState.overview;
    
    // Extraire les stats du provider ou utiliser des valeurs par défaut
    final stats = _DashboardStats(
      todayRevenue: overview?.sales?.today ?? 0,
      revenueChange: overview?.sales?.growth ?? 0,
      todayOrders: overview?.orders?.total ?? 0,
      todayCustomers: overview?.orders?.completed ?? 0,
      pendingOrders: overview?.orders?.pending ?? 0,
      completedOrders: overview?.orders?.completed ?? 0,
      outOfStockProducts: overview?.inventory?.outOfStock ?? 0,
      pendingPrescriptions: overview?.inventory?.lowStock ?? 0,
    );
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CI',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec salutation
        FadeSlideTransition(
          child: _buildGreetingHeader(context),
        ),
        const SizedBox(height: 24),
        
        // Carte de revenus principale
        FadeSlideTransition(
          delay: const Duration(milliseconds: 100),
          child: GradientCard(
            gradientColors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Revenus du jour',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            stats.revenueChange >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${stats.revenueChange >= 0 ? '+' : ''}${stats.revenueChange.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(stats.todayRevenue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMiniStat(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Commandes',
                      value: stats.todayOrders.toString(),
                    ),
                    const SizedBox(width: 24),
                    _buildMiniStat(
                      icon: Icons.people_outline,
                      label: 'Clients',
                      value: stats.todayCustomers.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Grille de statistiques rapides
        Row(
          children: [
            Expanded(
              child: StaggeredListItem(
                index: 0,
                child: _buildQuickStatCard(
                  context,
                  icon: Icons.pending_actions,
                  iconColor: Colors.orange,
                  iconBgColor: Colors.orange.withValues(alpha: 0.1),
                  title: 'En attente',
                  value: stats.pendingOrders.toString(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StaggeredListItem(
                index: 1,
                child: _buildQuickStatCard(
                  context,
                  icon: Icons.check_circle_outline,
                  iconColor: Colors.green,
                  iconBgColor: Colors.green.withValues(alpha: 0.1),
                  title: 'Complétées',
                  value: stats.completedOrders.toString(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StaggeredListItem(
                index: 2,
                child: _buildQuickStatCard(
                  context,
                  icon: Icons.inventory_2_outlined,
                  iconColor: Colors.red,
                  iconBgColor: Colors.red.withValues(alpha: 0.1),
                  title: 'Rupture stock',
                  value: stats.outOfStockProducts.toString(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StaggeredListItem(
                index: 3,
                child: _buildQuickStatCard(
                  context,
                  icon: Icons.medical_services_outlined,
                  iconColor: Colors.blue,
                  iconBgColor: Colors.blue.withValues(alpha: 0.1),
                  title: 'Ordonnances',
                  value: stats.pendingPrescriptions.toString(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreetingHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;

    if (hour < 12) {
      greeting = 'Bonjour';
      icon = Icons.wb_sunny_outlined;
    } else if (hour < 18) {
      greeting = 'Bon après-midi';
      icon = Icons.wb_sunny;
    } else {
      greeting = 'Bonsoir';
      icon = Icons.nightlight_round;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting 👋',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              DateFormat('EEEE d MMMM', 'fr').format(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _DashboardStats {
  final double todayRevenue;
  final double revenueChange;
  final int todayOrders;
  final int todayCustomers;
  final int pendingOrders;
  final int completedOrders;
  final int outOfStockProducts;
  final int pendingPrescriptions;

  _DashboardStats({
    required this.todayRevenue,
    required this.revenueChange,
    required this.todayOrders,
    required this.todayCustomers,
    required this.pendingOrders,
    required this.completedOrders,
    required this.outOfStockProducts,
    required this.pendingPrescriptions,
  });
}
