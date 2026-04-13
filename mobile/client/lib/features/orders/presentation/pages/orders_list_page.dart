import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../main_shell_page.dart';
import '../../../../core/router/app_router.dart';
import '../../../../config/providers.dart';
import '../providers/orders_provider.dart';
import '../providers/orders_state.dart';
import '../providers/reorder_provider.dart';
import '../services/review_prompt_service.dart';
import '../../domain/entities/order_entity.dart';
import '../../../../core/widgets/app_snackbar.dart';

class OrdersListPage extends ConsumerStatefulWidget {
  const OrdersListPage({super.key});

  @override
  ConsumerState<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends ConsumerState<OrdersListPage> {
  bool _reviewPromptShown = false;
  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersProvider.notifier).loadOrders();
    });
  }

  void _checkForReviewPrompt(List<OrderEntity> orders) {
    if (_reviewPromptShown || orders.isEmpty) return;
    _reviewPromptShown = true;

    final prefs = ref.read(sharedPreferencesProvider);
    final reviewService = ReviewPromptService(prefs);
    reviewService.checkAndPrompt(context, orders);
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    // Afficher le prompt de notation automatiquement après chargement
    if (ordersState.status == OrdersStatus.loaded &&
        ordersState.orders.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForReviewPrompt(ordersState.orders);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandes'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              ref.read(mainShellTabProvider.notifier).state = 0;
            }
          },
        ),
      ),
      body: _buildBody(ordersState),
    );
  }

  Widget _buildBody(OrdersState state) {
    if (state.status == OrdersStatus.loading && state.orders.isEmpty) {
      return _buildLoadingSkeleton();
    }
    if (state.status == OrdersStatus.error && state.orders.isEmpty) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Erreur de chargement',
        message:
            'Impossible de charger vos commandes.\nVérifiez votre connexion internet.',
        iconColor: AppColors.error,
        actionLabel: 'Réessayer',
        onAction: () => ref.read(ordersProvider.notifier).loadOrders(),
      );
    }
    if (state.orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Aucune commande',
        message:
            'Vous n\'avez pas encore passé de commande.\nParcourez nos pharmacies pour commander.',
        iconColor: AppColors.textHint,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(),
      child: Column(
        children: [
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _buildFilterChip(null, 'Toutes'),
                _buildFilterChip(OrderStatus.pending, 'En attente'),
                _buildFilterChip(OrderStatus.confirmed, 'Confirmées'),
                _buildFilterChip(OrderStatus.delivering, 'En livraison'),
                _buildFilterChip(OrderStatus.delivered, 'Livrées'),
                _buildFilterChip(OrderStatus.cancelled, 'Annulées'),
              ],
            ),
          ),
          // Filtered orders list
          Expanded(
            child: () {
              final filteredOrders = _selectedStatus == null
                  ? state.orders
                  : state.orders
                        .where((o) => o.status == _selectedStatus)
                        .toList();
              if (filteredOrders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Aucune commande avec ce statut',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return _OrderCard(
                    order: order,
                    onTap: () => context.push('/orders/${order.id}'),
                  );
                },
              );
            }(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(OrderStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedStatus = status),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: 160,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderEntity order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(order.status);
    final dateStr = _formatDate(order.createdAt);
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CI',
      symbol: 'F CFA',
      decimalDigits: 0,
    );

    // Écouter les changements d'état du reorder
    ref.listen<ReorderState>(reorderProvider, (previous, next) {
      if (next.status == ReorderStatus.success) {
        AppSnackbar.success(
          context,
          next.message ?? 'Articles ajoutés au panier',
          actionLabel: 'Voir panier',
          onAction: () => context.push(AppRoutes.cart),
        );
        ref.read(reorderProvider.notifier).reset();
      } else if (next.status == ReorderStatus.partialSuccess) {
        AppSnackbar.warning(
          context,
          '${next.message ?? 'Certains articles ajoutés'}${next.failedProducts.isNotEmpty ? '\nNon disponibles: ${next.failedProducts.join(", ")}' : ''}',
          actionLabel: 'Voir panier',
          onAction: () => context.push(AppRoutes.cart),
        );
        ref.read(reorderProvider.notifier).reset();
      } else if (next.status == ReorderStatus.error) {
        AppSnackbar.error(context, next.message ?? 'Erreur');
        ref.read(reorderProvider.notifier).reset();
      }
    });

    final reorderState = ref.watch(reorderProvider);
    final isReordering = reorderState.status == ReorderStatus.loading;
    final canReorder =
        order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: reference + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.reference}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Pharmacy name
              Row(
                children: [
                  Icon(
                    Icons.local_pharmacy_outlined,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.pharmacyName,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey[300]
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : AppColors.textHint,
                    ),
                  ),
                ],
              ),

              const Divider(height: 20),

              // Bottom: items count + total + reorder button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.itemCount} article${order.itemCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey[400]
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormat.format(order.total),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (canReorder)
                    Semantics(
                      button: true,
                      label: 'Commander à nouveau',
                      child: TextButton.icon(
                        onPressed: isReordering
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(reorderProvider.notifier)
                                    .reorder(order);
                              },
                        icon: isReordering
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.replay, size: 18),
                        label: Text(isReordering ? 'Ajout...' : 'Commander'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Hier à ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE à HH:mm', 'fr_FR').format(date);
    } else {
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return AppColors.statusReady;
      case OrderStatus.delivering:
        return AppColors.statusDelivering;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
      case OrderStatus.failed:
        return Colors.red.shade800;
    }
  }
}
