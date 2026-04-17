import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/services/delivery_alert_service.dart';
import '../../core/router/route_names.dart';
import 'delivery_details_screen.dart';
import '../providers/delivery_providers.dart';
import '../providers/history_providers.dart';
import '../widgets/common/common_widgets.dart';
import '../widgets/history/history_filter_sheet.dart';
import '../widgets/history/history_stats_card.dart';
import 'package:intl/intl.dart';

class DeliveriesScreen extends ConsumerStatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  ConsumerState<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends ConsumerState<DeliveriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements de thème
    ref.watch(themeProvider);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          'Mes Courses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          // Batch mode button
          TextButton.icon(
            onPressed: () {
              context.push(AppRoutes.batchDeliveries);
            },
            icon: const Icon(Icons.layers, size: 20),
            label: const Text('Multi'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _buildSearchBar(),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: isDark ? Colors.white : Colors.black,
                  unselectedLabelColor: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  indicator: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Disponibles'),
                    Tab(text: 'En Cours'),
                    Tab(text: 'Terminées'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Bannière d'alerte sonore pour nouvelles courses
          Consumer(
            builder: (context, ref, _) {
              final isAlertActive = ref.watch(deliveryAlertActiveProvider);
              if (!isAlertActive) return const SizedBox.shrink();
              return _DeliveryAlertBanner(
                onDismiss: () {
                  ref.read(deliveryAlertServiceProvider).stopAlert();
                  ref.read(deliveryAlertActiveProvider.notifier).deactivate();
                  // Basculer sur l'onglet "Disponibles"
                  _tabController.animateTo(0);
                  ref.invalidate(deliveriesProvider('pending'));
                },
              );
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                DeliveryList(status: 'pending', searchQuery: _searchQuery),
                DeliveryList(status: 'active', searchQuery: _searchQuery),
                HistoryTab(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Rechercher #REF, Pharmacie...',
          prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class DeliveryList extends ConsumerWidget {
  final String status;
  final String searchQuery;

  const DeliveryList({
    super.key,
    required this.status,
    required this.searchQuery,
  });

  Future<void> _onRefresh(WidgetRef ref) async {
    // Invalide le provider pour forcer un rechargement
    ref.invalidate(deliveriesProvider(status));
    // Attend que la nouvelle donnée soit chargée
    await ref.read(deliveriesProvider(status).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesFuture = ref.watch(deliveriesProvider(status));

    return deliveriesFuture.when(
      data: (allDeliveries) {
        // Filter locally
        final deliveries = allDeliveries.where((d) {
          if (searchQuery.isEmpty) return true;
          return d.pharmacyName.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              d.id.toString().contains(searchQuery);
        }).toList();

        if (deliveries.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _onRefresh(ref),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: const AppEmptyWidget(
                  icon: Icons.inventory_2_outlined,
                  message: 'Aucune course trouvée',
                  subtitle: 'Tirez vers le bas pour actualiser',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _onRefresh(ref),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return Hero(
                tag: DeliveryHeroTags.card(delivery.id),
                child: Material(
                  type: MaterialType.transparency,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        // Arrêter l'alerte sonore si active
                        if (ref.read(deliveryAlertActiveProvider)) {
                          ref.read(deliveryAlertServiceProvider).stopAlert();
                          ref
                              .read(deliveryAlertActiveProvider.notifier)
                              .deactivate();
                        }
                        context.pushHeroFade(
                          DeliveryDetailsScreen(delivery: delivery),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '#${delivery.id}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                Text(
                                  delivery.createdAt != null
                                      ? DateFormat(
                                          'dd/MM HH:mm',
                                          'fr_FR',
                                        ).format(
                                          DateTime.tryParse(
                                                delivery.createdAt!,
                                              ) ??
                                              DateTime.now(),
                                        )
                                      : '',
                                  style: TextStyle(
                                    color: context.tertiaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.orange,
                                  child: Icon(
                                    Icons.store,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    delivery.pharmacyName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                top: 4,
                                bottom: 4,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: context.dividerColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.green,
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    delivery.deliveryAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${delivery.totalAmount} FCFA',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                _buildStatusBadge(delivery.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const AppLoadingWidget(),
      error: (e, st) => RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(deliveriesProvider(status)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'En attente';
        break;
      case 'active':
        color = Colors.blue;
        text = 'En cours';
        break;
      case 'delivered':
        color = Colors.green;
        text = 'Terminée';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Annulée';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Tab dédié à l'historique avec filtres avancés
class HistoryTab extends ConsumerWidget {
  final String searchQuery;

  const HistoryTab({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(historyFiltersProvider);
    final filteredDeliveriesAsync = ref.watch(filteredHistoryProvider);

    return Column(
      children: [
        // Barre de filtres
        _buildFilterBar(context, ref, filters),

        // Statistiques
        const HistoryStatsCard(),

        // Liste des livraisons
        Expanded(
          child: filteredDeliveriesAsync.when(
            data: (deliveries) {
              // Appliquer la recherche textuelle
              final filtered = searchQuery.isEmpty
                  ? deliveries
                  : deliveries
                        .where(
                          (d) =>
                              d.pharmacyName.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ) ||
                              d.id.toString().contains(searchQuery) ||
                              d.reference.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ),
                        )
                        .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        filters.hasActiveFilters
                            ? 'Aucune livraison ne correspond aux filtres'
                            : 'Aucune livraison terminée',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      if (filters.hasActiveFilters) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => ref
                              .read(historyFiltersProvider.notifier)
                              .clearFilters(),
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('Effacer les filtres'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(filteredHistoryProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final delivery = filtered[index];
                    return _buildDeliveryCard(context, delivery);
                  },
                ),
              );
            },
            loading: () => const AppLoadingWidget(),
            error: (e, _) => AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(filteredHistoryProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, filters) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Bouton filtres
          FilledButton.tonalIcon(
            onPressed: () => HistoryFilterSheet.show(context),
            icon: const Icon(Icons.filter_list, size: 18),
            label: Text(
              filters.hasActiveFilters
                  ? 'Filtres (${filters.activeFilterCount})'
                  : 'Filtres',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: filters.hasActiveFilters
                  ? Colors.blue.withValues(alpha: 0.15)
                  : null,
            ),
          ),

          const SizedBox(width: 8),

          // Chips de préréglages rapides
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickChip(context, ref, "Aujourd'hui", 'today'),
                  const SizedBox(width: 6),
                  _buildQuickChip(context, ref, 'Semaine', 'week'),
                  const SizedBox(width: 6),
                  _buildQuickChip(context, ref, 'Mois', 'month'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    String preset,
  ) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () =>
          ref.read(historyFiltersProvider.notifier).setPreset(preset),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, delivery) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.pushSlide(DeliveryDetailsScreen(delivery: delivery));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${delivery.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  Text(
                    delivery.createdAt != null
                        ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(
                            DateTime.tryParse(delivery.createdAt!) ??
                                DateTime.now(),
                          )
                        : '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.store, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      delivery.pharmacyName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      delivery.deliveryAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${delivery.totalAmount} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusBadge(delivery.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'delivered':
        color = Colors.green;
        text = 'Livrée';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Annulée';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Bannière d'alerte animée pour signaler une nouvelle course
class _DeliveryAlertBanner extends StatefulWidget {
  final VoidCallback onDismiss;

  const _DeliveryAlertBanner({required this.onDismiss});

  @override
  State<_DeliveryAlertBanner> createState() => _DeliveryAlertBannerState();
}

class _DeliveryAlertBannerState extends State<_DeliveryAlertBanner>
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
              colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.35),
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
                  Icons.delivery_dining_rounded,
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
                      '🚚 Nouvelle course disponible !',
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
                    color: Color(0xFF1565C0),
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
