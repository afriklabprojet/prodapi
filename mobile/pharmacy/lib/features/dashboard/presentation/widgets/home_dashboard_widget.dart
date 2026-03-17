import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../inventory/presentation/widgets/add_product_sheet.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../orders/presentation/providers/order_list_provider.dart';
import '../../../orders/presentation/providers/state/order_list_state.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../providers/dashboard_tab_provider.dart';
import 'dashboard_card.dart';

/// Widget de tableau de bord principal avec KPIs
class HomeDashboardWidget extends ConsumerWidget {
  const HomeDashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    // Récupérer le nom de la pharmacie depuis les pharmacies de l'utilisateur
    final pharmacyName = (authState.user?.pharmacies.isNotEmpty == true)
        ? (authState.user!.pharmacies.firstOrNull?.name ?? 'Ma Pharmacie')
        : 'Ma Pharmacie';
    final userName = authState.user?.name ?? 'Pharmacien';
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Rafraîchir les données
            ref.invalidate(orderListProvider);
            ref.invalidate(walletProvider);
            ref.invalidate(notificationsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header avec salutation
              SliverToBoxAdapter(
                child: _buildHeader(context, userName, pharmacyName, ref),
              ),
              
              // Cartes KPI principales
              SliverToBoxAdapter(
                child: _buildMainKPIs(context, ref),
              ),
              
              // Actions rapides
              SliverToBoxAdapter(
                child: _buildQuickActions(context),
              ),
              
              // Commandes récentes
              SliverToBoxAdapter(
                child: _buildRecentOrdersSection(context, ref),
              ),
              
              // Espace en bas
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName, String pharmacyName, WidgetRef ref) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.local_pharmacy,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pharmacyName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Bouton notifications
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(unreadCount.toString()),
                    backgroundColor: Colors.red,
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Date du jour
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(now),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainKPIs(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderListProvider);
    final walletAsync = ref.watch(walletProvider);
    final isDark = AppColors.isDark(context);
    
    // Calculer les statistiques des commandes
    final pendingOrders = orderState.orders.where((o) => o.status == 'pending').length;
    final todayOrders = orderState.orders.where((o) {
      final today = DateTime.now();
      return o.createdAt.year == today.year &&
             o.createdAt.month == today.month &&
             o.createdAt.day == today.day;
    }).length;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu du jour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'En attente',
                  value: pendingOrders.toString(),
                  icon: Icons.hourglass_empty_rounded,
                  color: Colors.orange,
                  subtitle: 'commandes',
                  onTap: () => ref.read(dashboardTabProvider.notifier).state = 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardCard(
                  title: 'Aujourd\'hui',
                  value: todayOrders.toString(),
                  icon: Icons.shopping_bag_rounded,
                  color: Colors.blue,
                  subtitle: 'commandes',
                  onTap: () => ref.read(dashboardTabProvider.notifier).state = 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: walletAsync.when(
                  data: (wallet) => DashboardCard(
                    title: 'Solde',
                    value: _formatCurrency(wallet.balance),
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.green,
                    subtitle: 'FCFA',
                    onTap: () => ref.read(dashboardTabProvider.notifier).state = 4,
                  ),
                  loading: () => DashboardCard(
                    title: 'Solde',
                    value: '...',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.green,
                    subtitle: 'chargement',
                    onTap: () {},
                  ),
                  error: (_, _) => DashboardCard(
                    title: 'Solde',
                    value: '--',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.grey,
                    subtitle: 'erreur',
                    onTap: () => ref.read(dashboardTabProvider.notifier).state = 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: walletAsync.when(
                  data: (wallet) => DashboardCard(
                    title: 'Total gagné',
                    value: _formatCurrency(wallet.totalEarnings),
                    icon: Icons.trending_up_rounded,
                    color: Colors.purple,
                    subtitle: 'FCFA',
                    onTap: () => context.push('/reports'),
                  ),
                  loading: () => DashboardCard(
                    title: 'Total gagné',
                    value: '...',
                    icon: Icons.trending_up_rounded,
                    color: Colors.purple,
                    subtitle: 'chargement',
                    onTap: () {},
                  ),
                  error: (_, _) => DashboardCard(
                    title: 'Total gagné',
                    value: '--',
                    icon: Icons.trending_up_rounded,
                    color: Colors.grey,
                    subtitle: 'erreur',
                    onTap: () => context.push('/reports'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDark = AppColors.isDark(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scanner',
                  color: Colors.teal,
                  onTap: () => context.push('/scanner'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_box_rounded,
                  label: 'Ajouter produit',
                  color: Colors.indigo,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddProductSheet(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.analytics_rounded,
                  label: 'Rapports',
                  color: Colors.deepOrange,
                  onTap: () => context.push('/reports'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderListProvider);
    final recentOrders = orderState.orders.take(3).toList();
    final isLoading = orderState.status == OrderStatus.loading;
    final isDark = AppColors.isDark(context);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commandes récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Naviguer vers l'onglet commandes (index 1)
                  // On ne peut pas changer l'onglet directement ici
                  // mais on peut utiliser un callback ou un provider
                },
                child: Text(
                  'Voir tout',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (recentOrders.isEmpty)
            _buildEmptyOrdersCard(context, isDark)
          else
            ...recentOrders.map((order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecentOrderCard(
                orderNumber: order.reference,
                customerName: order.customerName,
                status: order.status,
                total: order.totalAmount,
                createdAt: order.createdAt,
                onTap: () => context.push('/orders/${order.id}'),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 48,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune commande récente',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Bonjour 👋';
    if (hour < 18) return 'Bon après-midi 👋';
    return 'Bonsoir 👋';
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

/// Bouton d'action rapide
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte commande récente
class _RecentOrderCard extends StatelessWidget {
  final String orderNumber;
  final String customerName;
  final String status;
  final double total;
  final DateTime createdAt;
  final VoidCallback onTap;

  const _RecentOrderCard({
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customerName,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${NumberFormat('#,###', 'fr_FR').format(total)} F',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'ready':
        return Icons.inventory_2_rounded;
      case 'delivered':
        return Icons.local_shipping_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'ready':
        return 'Prête';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }
}
