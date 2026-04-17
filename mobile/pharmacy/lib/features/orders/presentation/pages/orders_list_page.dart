import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../../../core/presentation/widgets/app_error_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/master_detail_layout.dart';
import '../../../../core/services/order_alert_service.dart';

import '../../../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/enums/order_status.dart';
import '../extensions/order_status_l10n.dart';
import '../providers/order_list_provider.dart';
import '../widgets/enhanced_order_card.dart';
import '../providers/state/order_list_state.dart';
import 'order_details_page.dart';

class OrdersListPage extends ConsumerStatefulWidget {
  /// When false, hides the page title row (used when embedded inside ActivityPage).
  final bool showActivityHeader;

  const OrdersListPage({super.key, this.showActivityHeader = true});

  @override
  ConsumerState<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends ConsumerState<OrdersListPage> {
  /// Selected order for master-detail view on tablet/desktop
  OrderEntity? _selectedOrder;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: SafeArea(
        child: MasterDetailLayout<OrderEntity>(
          selectedItem: _selectedOrder,
          detailFraction: 0.45,
          masterBuilder: (context, isCompact) => Column(
            children: [
              Container(
                color: AppColors.cardColor(context),
                padding: const EdgeInsets.only(top: 16, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header amélioré — masqué quand intégré dans ActivityPage
                    if (widget.showActivityHeader)
                      EnhancedPageHeader(
                        title: 'Commandes',
                        subtitle: 'Gérez vos commandes',
                        icon: Icons.receipt_long_rounded,
                        iconBackgroundColor: primaryColor,
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[50],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Consumer(
                              builder: (context, ref, child) {
                                final unreadCount = ref.watch(
                                  unreadNotificationCountProvider,
                                );
                                return Badge(
                                  isLabelVisible: unreadCount > 0,
                                  backgroundColor: Colors.redAccent,
                                  label: Text('$unreadCount'),
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    size: 28,
                                  ),
                                );
                              },
                            ),
                            onPressed: () => context.push('/notifications'),
                            tooltip: 'Notifications',
                          ),
                        ),
                      ),
                    if (widget.showActivityHeader) const SizedBox(height: 24),
                    // Filtres défilants
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          for (final filter in OrderStatusFilter.values) ...[
                            if (filter != OrderStatusFilter.values.first)
                              const SizedBox(width: 12),
                            _FilterChip(
                              label: filter.localizedLabel,
                              isActive: state.activeFilter == filter,
                              onTap: () => ref
                                  .read(orderListProvider.notifier)
                                  .setFilter(filter),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark
                          ? Colors.grey[800]
                          : const Color(0xFFF0F0F0),
                    ),
                  ],
                ),
              ),

              // Bannière d'alerte sonore pour nouvelles commandes
              Consumer(
                builder: (context, ref, _) {
                  final isAlertActive = ref.watch(orderAlertActiveProvider);
                  if (!isAlertActive) return const SizedBox.shrink();
                  return _OrderAlertBanner(
                    onDismiss: () {
                      ref.read(orderAlertServiceProvider).stopAlert();
                      ref.read(orderAlertActiveProvider.notifier).state = false;
                      // Basculer sur le filtre "En attente"
                      ref
                          .read(orderListProvider.notifier)
                          .setFilter(OrderStatusFilter.pending);
                    },
                  );
                },
              ),

              // Corps de la liste
              Expanded(child: _buildBody(context, state, isCompact)),
            ],
          ),
          detailBuilder: (context, order) =>
              OrderDetailsPage(key: ValueKey(order.id), order: order),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrderListState state,
    bool isCompact,
  ) {
    // Loading state avec shimmer
    if (state.status == OrderLoadStatus.loading) {
      return const SkeletonList(itemCount: 5, skeleton: _OrderSkeleton());
    }

    // Error state
    if (state.status == OrderLoadStatus.error) {
      return FadeSlideTransition(
        child: AppErrorState.loadFailed(
          onRetry: () => ref.read(orderListProvider.notifier).fetchOrders(),
          what: 'les commandes',
        ),
      );
    }

    // Empty state
    if (state.orders.isEmpty) {
      return FadeSlideTransition(
        child: AppEmptyState.orders(
          onRefresh: () => ref.read(orderListProvider.notifier).fetchOrders(),
        ),
      );
    }

    // Liste des commandes avec infinite scroll
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          // Charger plus quand on approche de la fin
          ref.read(orderListProvider.notifier).loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: AppColors.cardColor(context),
        onRefresh: () => ref.read(orderListProvider.notifier).fetchOrders(),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 12,
            vertical: 20,
          ),
          itemCount: state.orders.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Indicateur de chargement en bas de la liste
            if (index == state.orders.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: state.isLoadingMore
                      ? const CircularProgressIndicator()
                      : TextButton.icon(
                          onPressed: () =>
                              ref.read(orderListProvider.notifier).loadMore(),
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Charger plus'),
                        ),
                ),
              );
            }

            final order = state.orders[index];
            final isSelected = !isCompact && _selectedOrder?.id == order.id;

            return StaggeredListItem(
              index: index,
              child: Semantics(
                label:
                    'Commande ${order.reference}, ${order.customerName}, ${order.status}, ${order.totalAmount} FCFA',
                button: true,
                child: Container(
                  decoration: isSelected
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        )
                      : null,
                  child: EnhancedOrderCard(
                    order: order,
                    onTap: () {
                      // Arrêter l'alerte sonore si active
                      if (ref.read(orderAlertActiveProvider)) {
                        ref.read(orderAlertServiceProvider).stopAlert();
                        ref.read(orderAlertActiveProvider.notifier).state =
                            false;
                      }
                      // On tablet: show in detail panel; on mobile: push
                      if (isCompact) {
                        context.push('/order-details', extra: order);
                      } else {
                        setState(() => _selectedOrder = order);
                      }
                    },
                    onConfirm: () async {
                      // Arrêter l'alerte sonore si active
                      if (ref.read(orderAlertActiveProvider)) {
                        ref.read(orderAlertServiceProvider).stopAlert();
                        ref.read(orderAlertActiveProvider.notifier).state =
                            false;
                      }
                      final success = await ref
                          .read(orderListProvider.notifier)
                          .confirmOrder(order.id);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Commande confirmée'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      return success;
                    },
                    onReject: () => _showRejectDialog(context, order.id),
                    onMarkReady: () async {
                      final success = await ref
                          .read(orderListProvider.notifier)
                          .markOrderReady(order.id);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Commande prête pour le ramassage'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                      return success;
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, int orderId) {
    final reasonController = TextEditingController();
    String? selectedReason;

    final commonReasons = [
      'Produit en rupture de stock',
      'Ordonnance invalide ou illisible',
      'Pharmacie fermée',
      'Délai de livraison impossible',
      'Autre raison',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
              const SizedBox(width: 8),
              const Text('Refuser la commande'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cette action est irréversible. Le client sera notifié du refus.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Raison du refus :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: selectedReason ?? '',
                  onChanged: (value) {
                    setState(() => selectedReason = value);
                  },
                  child: Column(
                    children: commonReasons
                        .map(
                          (reason) => RadioListTile<String>(
                            title: Text(
                              reason,
                              style: const TextStyle(fontSize: 14),
                            ),
                            value: reason,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (selectedReason == 'Autre raison') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: 'Précisez la raison...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();

                      final reason = selectedReason == 'Autre raison'
                          ? reasonController.text.trim()
                          : selectedReason;

                      try {
                        await ref
                            .read(orderListProvider.notifier)
                            .rejectOrder(orderId, reason: reason);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Commande refusée'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Refuser'),
            ),
          ],
        ),
      ),
    ).whenComplete(() => reasonController.dispose());
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: '$label${isActive ? ", sélectionné" : ""}',
      child: AnimatedScale(
        scale: isActive ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Material(
          color: isActive ? Theme.of(context).colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: isActive
                    ? Border.all(color: Colors.transparent)
                    : Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton pour les commandes en chargement
class _OrderSkeleton extends StatelessWidget {
  const _OrderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  ShimmerLoading(width: 40, height: 40, borderRadius: 10),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(width: 100, height: 16),
                      SizedBox(height: 6),
                      ShimmerLoading(width: 70, height: 12),
                    ],
                  ),
                ],
              ),
              const ShimmerLoading(width: 80, height: 28, borderRadius: 14),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              ShimmerLoading(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(width: 120, height: 14),
                    SizedBox(height: 6),
                    ShimmerLoading(width: 100, height: 12),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShimmerLoading(width: 90, height: 18),
                  SizedBox(height: 6),
                  ShimmerLoading(width: 60, height: 12),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bannière d'alerte animée pour signaler une nouvelle commande
class _OrderAlertBanner extends StatefulWidget {
  final VoidCallback onDismiss;

  const _OrderAlertBanner({required this.onDismiss});

  @override
  State<_OrderAlertBanner> createState() => _OrderAlertBannerState();
}

class _OrderAlertBannerState extends State<_OrderAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          widget.onDismiss();
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF4444)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔔 Nouvelle commande !',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Appuyez pour voir et arrêter l\'alerte',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VOIR',
                  style: TextStyle(
                    color: Color(0xFFFF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
