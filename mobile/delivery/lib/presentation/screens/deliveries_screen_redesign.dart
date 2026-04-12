import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/utils/app_exceptions.dart';
import '../../core/services/delivery_alert_service.dart';
import '../../core/router/route_names.dart';
import '../../data/models/delivery.dart';
import 'delivery_details_screen.dart';
import '../providers/delivery_providers.dart';
import '../providers/history_providers.dart';
import '../providers/dashboard_tab_provider.dart';
import '../widgets/common/common_widgets.dart';
import '../widgets/history/history_filter_sheet.dart';
import '../widgets/history/history_stats_card.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DELIVERIES SCREEN REDESIGN — Design "Dashboard Pro"
/// Style cohérent avec login/register : Navy + Gold + Teal
/// ═══════════════════════════════════════════════════════════════════════════

class DeliveriesScreenRedesign extends ConsumerStatefulWidget {
  const DeliveriesScreenRedesign({super.key});

  @override
  ConsumerState<DeliveriesScreenRedesign> createState() =>
      _DeliveriesScreenRedesignState();
}

class _DeliveriesScreenRedesignState
    extends ConsumerState<DeliveriesScreenRedesign>
    with TickerProviderStateMixin {
  // Controllers
  late TabController _tabController;
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  // Design Colors
  static const _navyDark = Color(0xFF0F1C3F);
  static const _navyMedium = Color(0xFF1A2B52);
  static const _accentGold = Color(0xFFE5C76B);
  static const _accentTeal = Color(0xFF2DD4BF);
  static const _primaryGreen = Color(0xFF0D6644);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
    _initAnimations();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerController.forward();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final isDark = context.isDark;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0F1C)
          : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // HEADER DASHBOARD — Navy gradient avec stats
          // ═══════════════════════════════════════════════════════════════════
          _buildDashboardHeader(isDark, statusBarHeight),

          // ═══════════════════════════════════════════════════════════════════
          // ALERT BANNER — Si nouvelle course disponible
          // ═══════════════════════════════════════════════════════════════════
          Consumer(
            builder: (context, ref, _) {
              final isAlertActive = ref.watch(deliveryAlertActiveProvider);
              if (!isAlertActive) return const SizedBox.shrink();
              return _ModernAlertBanner(
                onDismiss: () {
                  ref.read(deliveryAlertServiceProvider).stopAlert();
                  ref.read(deliveryAlertActiveProvider.notifier).deactivate();
                  _tabController.animateTo(0);
                  ref.invalidate(deliveriesProvider('pending'));
                },
              );
            },
          ),

          // ═══════════════════════════════════════════════════════════════════
          // TABS & CONTENT
          // ═══════════════════════════════════════════════════════════════════
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0F1C) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildModernTabs(isDark),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _ModernDeliveryList(
                          status: 'pending',
                          searchQuery: _searchQuery,
                          emptyIcon: Icons.hourglass_empty_rounded,
                          emptyMessage: 'Aucune course disponible',
                        ),
                        _ModernDeliveryList(
                          status: 'active',
                          searchQuery: _searchQuery,
                          emptyIcon: Icons.delivery_dining_rounded,
                          emptyMessage: 'Aucune course en cours',
                        ),
                        _ModernHistoryTab(searchQuery: _searchQuery),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header dashboard avec stats du jour
  Widget _buildDashboardHeader(bool isDark, double statusBarHeight) {
    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, statusBarHeight + 16, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_navyDark, _navyMedium],
          ),
        ),
        child: Stack(
          children: [
            // Cercles décoratifs
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accentGold.withValues(alpha: 0.12),
                    width: 2,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentTeal.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Contenu
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mes Courses',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Row(
                      children: [
                        // Search toggle
                        _buildHeaderIconButton(
                          icon: _isSearchExpanded
                              ? Icons.close
                              : Icons.search_rounded,
                          onTap: () => setState(() {
                            _isSearchExpanded = !_isSearchExpanded;
                            if (!_isSearchExpanded) {
                              _searchController.clear();
                            }
                          }),
                        ),
                        const SizedBox(width: 8),
                        // Multi-select mode
                        _buildHeaderIconButton(
                          icon: Icons.layers_rounded,
                          badge: 'Multi',
                          onTap: () => context.push(AppRoutes.batchDeliveries),
                        ),
                      ],
                    ),
                  ],
                ),

                // Search bar (expandable)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isSearchExpanded ? 56 : 0,
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _isSearchExpanded ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildSearchField(),
                    ),
                  ),
                ),

                SizedBox(height: _isSearchExpanded ? 8 : 20),

                // Stats row
                _buildStatsRow(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: badge != null ? 14 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Rechercher #REF, pharmacie...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer(
      builder: (context, ref, _) {
        final pendingAsync = ref.watch(deliveriesProvider('pending'));
        final activeAsync = ref.watch(deliveriesProvider('active'));

        final pendingCount = pendingAsync.hasValue
            ? pendingAsync.value!.length
            : 0;
        final activeCount = activeAsync.hasValue
            ? activeAsync.value!.length
            : 0;

        return Row(
          children: [
            _buildStatCard(
              icon: Icons.hourglass_empty_rounded,
              value: '$pendingCount',
              label: 'Disponibles',
              color: _accentGold,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.delivery_dining_rounded,
              value: '$activeCount',
              label: 'En cours',
              color: _accentTeal,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.account_balance_wallet_rounded,
              value: 'Voir',
              label: 'Gains',
              color: _primaryGreen,
              onTap: () => ref.read(dashboardTabProvider.notifier).setTab(3),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTabs(bool isDark) {
    final tabs = ['Disponibles', 'En cours', 'Historique'];
    final icons = [
      Icons.hourglass_empty_rounded,
      Icons.delivery_dining_rounded,
      Icons.history_rounded,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(colors: [_navyDark, _navyMedium]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _navyDark.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark
            ? Colors.grey.shade400
            : Colors.grey.shade600,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: List.generate(3, (i) {
          return Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icons[i], size: 16),
                const SizedBox(width: 6),
                Text(tabs[i]),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODERN DELIVERY LIST — Cards avec timeline visuelle
// ═══════════════════════════════════════════════════════════════════════════════

class _ModernDeliveryList extends ConsumerWidget {
  final String status;
  final String searchQuery;
  final IconData emptyIcon;
  final String emptyMessage;

  const _ModernDeliveryList({
    required this.status,
    required this.searchQuery,
    required this.emptyIcon,
    required this.emptyMessage,
  });

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(deliveriesProvider(status));
    await ref.read(deliveriesProvider(status).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(deliveriesProvider(status));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return deliveriesAsync.when(
      data: (allDeliveries) {
        final deliveries = searchQuery.isEmpty
            ? allDeliveries
            : allDeliveries.where((d) {
                final q = searchQuery.toLowerCase();
                return d.pharmacyName.toLowerCase().contains(q) ||
                    d.id.toString().contains(q);
              }).toList();

        if (deliveries.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _onRefresh(ref),
            color: const Color(0xFF0D6644),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: _ModernEmptyState(
                  icon: emptyIcon,
                  message: emptyMessage,
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _onRefresh(ref),
          color: const Color(0xFF0D6644),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return _ModernDeliveryCard(
                delivery: delivery,
                isDark: isDark,
                index: index,
                onTap: () {
                  if (ref.read(deliveryAlertActiveProvider)) {
                    ref.read(deliveryAlertServiceProvider).stopAlert();
                    ref.read(deliveryAlertActiveProvider.notifier).deactivate();
                  }
                  HapticFeedback.lightImpact();
                  context.pushHeroFade(
                    DeliveryDetailsScreen(delivery: delivery),
                  );
                },
              );
            },
          ),
        );
      },
      loading: () => const AppLoadingWidget(),
      error: (e, _) => RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: e is IncompleteKycException
                ? AppErrorWidget(
                    message:
                        'Complétez votre vérification d\'identité pour accéder aux livraisons.',
                    icon: Icons.verified_user_outlined,
                    iconColor: Colors.orange,
                    title: 'Vérification requise',
                  )
                : AppErrorWidget(
                    message: e is AppException
                        ? e.userMessage
                        : e.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.invalidate(deliveriesProvider(status)),
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODERN DELIVERY CARD — Design avec timeline visuelle
// ═══════════════════════════════════════════════════════════════════════════════

class _ModernDeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final bool isDark;
  final int index;
  final VoidCallback onTap;

  const _ModernDeliveryCard({
    required this.delivery,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  static const _navyDark = Color(0xFF0F1C3F);
  static const _primaryGreen = Color(0xFF0D6644);
  static const _accentGold = Color(0xFFE5C76B);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Hero(
        tag: DeliveryHeroTags.card(delivery.id),
        child: Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header avec ID et date
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    decoration: BoxDecoration(
                      color: _navyDark.withValues(alpha: isDark ? 0.3 : 0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ID badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_navyDark, const Color(0xFF1A2B52)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tag_rounded,
                                color: _accentGold,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${delivery.id}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(delivery.createdAt),
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content avec timeline
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline visuelle
                        _buildTimeline(),
                        const SizedBox(width: 14),

                        // Détails
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pharmacie (départ)
                              _buildLocationRow(
                                icon: Icons.store_rounded,
                                color: Colors.orange,
                                title: delivery.pharmacyName,
                                isStart: true,
                              ),
                              const SizedBox(height: 16),
                              // Client (arrivée)
                              _buildLocationRow(
                                icon: Icons.location_on_rounded,
                                color: _primaryGreen,
                                title: delivery.deliveryAddress,
                                isStart: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer avec montant et statut
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Montant
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _primaryGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.payments_rounded,
                                color: _primaryGreen,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_formatAmount(delivery.totalAmount)} FCFA',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                        // Status badge
                        _buildStatusBadge(delivery.status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return SizedBox(
      width: 20,
      child: Column(
        children: [
          // Point de départ
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          // Ligne pointillée
          Container(
            width: 2,
            height: 36,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: CustomPaint(painter: _DottedLinePainter()),
          ),
          // Point d'arrivée
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String title,
    required bool isStart,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isStart ? 'Pharmacie' : 'Client',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.color.withValues(alpha: 0.15),
            config.color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: config.color, size: 14),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return _StatusConfig(
          Colors.orange,
          Icons.schedule_rounded,
          'En attente',
        );
      case 'active':
        return _StatusConfig(
          Colors.blue,
          Icons.delivery_dining_rounded,
          'En cours',
        );
      case 'delivered':
        return _StatusConfig(
          _primaryGreen,
          Icons.check_circle_rounded,
          'Livrée',
        );
      case 'cancelled':
        return _StatusConfig(Colors.red, Icons.cancel_rounded, 'Annulée');
      default:
        return _StatusConfig(Colors.grey, Icons.help_outline_rounded, status);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return DateFormat('dd MMM, HH:mm', 'fr_FR').format(date);
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat('#,###', 'fr_FR').format(num);
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;

  _StatusConfig(this.color, this.icon, this.label);
}

// ═══════════════════════════════════════════════════════════════════════════════
// HISTORY TAB MODERNE
// ═══════════════════════════════════════════════════════════════════════════════

class _ModernHistoryTab extends ConsumerWidget {
  final String searchQuery;

  const _ModernHistoryTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(historyFiltersProvider);
    final filteredAsync = ref.watch(filteredHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Filter bar
        _buildFilterBar(context, ref, filters, isDark),

        // Stats card
        const HistoryStatsCard(),

        // List
        Expanded(
          child: filteredAsync.when(
            data: (deliveries) {
              final filtered = searchQuery.isEmpty
                  ? deliveries
                  : deliveries.where((d) {
                      final q = searchQuery.toLowerCase();
                      return d.pharmacyName.toLowerCase().contains(q) ||
                          d.id.toString().contains(q) ||
                          d.reference.toLowerCase().contains(q);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        filters.hasActiveFilters
                            ? 'Aucune livraison ne correspond'
                            : 'Aucune livraison terminée',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),
                      if (filters.hasActiveFilters) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => ref
                              .read(historyFiltersProvider.notifier)
                              .clearFilters(),
                          icon: const Icon(Icons.filter_alt_off_rounded),
                          label: const Text('Effacer les filtres'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0D6644),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(filteredHistoryProvider),
                color: const Color(0xFF0D6644),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _ModernDeliveryCard(
                      delivery: filtered[index],
                      isDark: isDark,
                      index: index,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.pushSlide(
                          DeliveryDetailsScreen(delivery: filtered[index]),
                        );
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const AppLoadingWidget(),
            error: (e, _) => AppErrorWidget(
              message: e is AppException
                  ? e.userMessage
                  : e.toString().replaceAll('Exception: ', ''),
              onRetry: () => ref.invalidate(filteredHistoryProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    filters,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Filter button
          GestureDetector(
            onTap: () => HistoryFilterSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: filters.hasActiveFilters
                    ? const Color(0xFF0D6644).withValues(alpha: 0.1)
                    : (isDark ? const Color(0xFF1A1F2E) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: filters.hasActiveFilters
                      ? const Color(0xFF0D6644).withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: filters.hasActiveFilters
                        ? const Color(0xFF0D6644)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filters.hasActiveFilters
                        ? 'Filtres (${filters.activeFilterCount})'
                        : 'Filtres',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: filters.hasActiveFilters
                          ? const Color(0xFF0D6644)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Quick chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickChip(ref, "Aujourd'hui", 'today', isDark),
                  const SizedBox(width: 8),
                  _buildQuickChip(ref, 'Semaine', 'week', isDark),
                  const SizedBox(width: 8),
                  _buildQuickChip(ref, 'Mois', 'month', isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(
    WidgetRef ref,
    String label,
    String preset,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(historyFiltersProvider.notifier).setPreset(preset);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _ModernEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ModernEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D6644).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: const Color(0xFF0D6644).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tirez vers le bas pour actualiser',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ModernAlertBanner extends StatefulWidget {
  final VoidCallback onDismiss;

  const _ModernAlertBanner({required this.onDismiss});

  @override
  State<_ModernAlertBanner> createState() => _ModernAlertBannerState();
}

class _ModernAlertBannerState extends State<_ModernAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glow = Tween<double>(
      begin: 0.3,
      end: 0.6,
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
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulse.value,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6644), Color(0xFF15A865)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D6644).withValues(alpha: _glow.value),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.heavyImpact();
            widget.onDismiss();
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚀 Nouvelle course disponible !',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Appuyez pour voir les détails',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'VOIR',
                    style: TextStyle(
                      color: Color(0xFF0D6644),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne pointillée pour la timeline
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
