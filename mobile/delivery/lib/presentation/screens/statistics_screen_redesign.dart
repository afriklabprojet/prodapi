import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/router/route_names.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/models/statistics.dart';
import '../providers/statistics_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/common/common_widgets.dart';

// ============================================================================
// DESIGN SYSTEM - Executive Dashboard Theme
// ============================================================================

class _StatColors {
  static const navyDark = Color(0xFF0F1C3F);
  static const navyMedium = Color(0xFF1A2B52);
  // static const navyLight = Color(0xFF243B67); // Unused
  static const accentGold = Color(0xFFE5C76B);
  static const accentTeal = Color(0xFF2DD4BF);
  static const accentBlue = Color(0xFF60A5FA);
  static const accentPurple = Color(0xFFA78BFA);
  // static const accentPink = Color(0xFFF472B6); // Unused
  static const successGreen = Color(0xFF10B981);
  static const warningOrange = Color(0xFFF59E0B);
  static const errorRed = Color(0xFFEF4444);
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

/// Écran de statistiques redesigné - Executive Dashboard.
class StatisticsScreenRedesign extends ConsumerStatefulWidget {
  const StatisticsScreenRedesign({super.key});

  @override
  ConsumerState<StatisticsScreenRedesign> createState() =>
      _StatisticsScreenRedesignState();
}

class _StatisticsScreenRedesignState
    extends ConsumerState<StatisticsScreenRedesign>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header navy avec solde et période
          _buildHeader(context),
          // Onglets
          _buildTabs(context),
          // Contenu
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTabRedesign(selectedPeriod: _selectedPeriod),
                _DeliveriesTabRedesign(selectedPeriod: _selectedPeriod),
                _RevenueTabRedesign(selectedPeriod: _selectedPeriod),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final currencyFormat = NumberFormat("#,##0", "fr_FR");

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_StatColors.navyDark, _StatColors.navyMedium],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  // Espace vide pour équilibrer le layout (pas de bouton retour car c'est un onglet)
                  const SizedBox(width: 44),
                  const Spacer(),
                  Text(
                    'Mes Statistiques',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Export button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push(AppRoutes.historyExport),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Solde principal avec animation
              walletAsync.when(
                data: (wallet) => _AnimatedBalance(
                  balance: wallet.balance,
                  currencyFormat: currencyFormat,
                ),
                loading: () => _buildBalanceSkeleton(),
                error: (_, _) => _buildBalanceError(),
              ),

              const SizedBox(height: 20),

              // Sélecteur de période
              _buildPeriodSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSkeleton() {
    return Column(
      children: [
        Container(
          width: 180,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceError() {
    return Column(
      children: [
        Text(
          '-- FCFA',
          style: GoogleFonts.sora(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Erreur de chargement',
          style: GoogleFonts.inter(fontSize: 13, color: _StatColors.errorRed),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      ('today', "Aujourd'hui"),
      ('week', 'Semaine'),
      ('month', 'Mois'),
      ('year', 'Année'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _StatColors.accentGold
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  period.$2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? _StatColors.navyDark
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: _StatColors.navyDark,
        indicatorWeight: 3,
        labelColor: _StatColors.navyDark,
        unselectedLabelColor: Colors.grey.shade500,
        labelStyle: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.sora(fontSize: 13),
        tabs: const [
          Tab(text: 'Aperçu'),
          Tab(text: 'Livraisons'),
          Tab(text: 'Revenus'),
        ],
      ),
    );
  }
}

// ============================================================================
// ANIMATED BALANCE WIDGET
// ============================================================================

class _AnimatedBalance extends StatefulWidget {
  final double balance;
  final NumberFormat currencyFormat;

  const _AnimatedBalance({required this.balance, required this.currencyFormat});

  @override
  State<_AnimatedBalance> createState() => _AnimatedBalanceState();
}

class _AnimatedBalanceState extends State<_AnimatedBalance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.balance,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedBalance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance != widget.balance) {
      _animation = Tween<double>(begin: oldWidget.balance, end: widget.balance)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => Text(
            '${widget.currencyFormat.format(_animation.value.round())} FCFA',
            style: GoogleFonts.sora(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _StatColors.successGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 14,
                    color: _StatColors.successGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Solde disponible',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _StatColors.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// OVERVIEW TAB REDESIGN
// ============================================================================

class _OverviewTabRedesign extends ConsumerWidget {
  final String selectedPeriod;

  const _OverviewTabRedesign({required this.selectedPeriod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsProvider(selectedPeriod));

    return AsyncValueWidget<Statistics>(
      value: statsAsync,
      onRetry: () => ref.invalidate(statisticsProvider(selectedPeriod)),
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards en grille
            _buildKpiGrid(stats),
            const SizedBox(height: 20),
            // Graphique d'activité
            _buildActivityChart(context, stats),
            const SizedBox(height: 20),
            // Performance gauges
            _buildPerformanceSection(context, stats),
            const SizedBox(height: 20),
            // Rating
            _buildRatingCard(context, stats),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(Statistics stats) {
    final overview = stats.overview;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _KpiCard(
          title: 'Livraisons',
          value: '${overview.totalDeliveries}',
          icon: Icons.local_shipping_rounded,
          color: _StatColors.accentBlue,
          trend: overview.deliveryTrend,
        ),
        _KpiCard(
          title: 'Revenus',
          value: overview.totalEarnings.formatCurrency(),
          icon: Icons.account_balance_wallet_rounded,
          color: _StatColors.successGreen,
          trend: overview.earningsTrend,
        ),
        _KpiCard(
          title: 'Distance',
          value: '${overview.totalDistanceKm.toStringAsFixed(0)} km',
          icon: Icons.route_rounded,
          color: _StatColors.warningOrange,
        ),
        _KpiCard(
          title: 'Note moyenne',
          value: overview.averageRating.toStringAsFixed(1),
          suffix: '/5',
          icon: Icons.star_rounded,
          color: _StatColors.accentGold,
        ),
      ],
    );
  }

  Widget _buildActivityChart(BuildContext context, Statistics stats) {
    final dailyStats = stats.dailyBreakdown;
    if (dailyStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = dailyStats
        .map((e) => e.deliveries)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final effectiveMax = maxValue == 0 ? 1.0 : maxValue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activité',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _StatColors.navyDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _StatColors.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _StatColors.accentBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Livraisons',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _StatColors.accentBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyStats.map((stat) {
                final height = (stat.deliveries / effectiveMax) * 100;
                final isToday =
                    stat.date ==
                    DateTime.now().toIso8601String().substring(0, 10);

                return _AnimatedBar(
                  value: stat.deliveries,
                  height: height < 4 ? 4 : height,
                  label: stat.dayName,
                  isHighlighted: isToday,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context, Statistics stats) {
    final perf = stats.performance;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _StatColors.navyDark,
            ),
          ),
          const SizedBox(height: 20),
          _PerformanceGauge(
            label: "Taux d'acceptation",
            value: perf.acceptanceRate,
            color: _StatColors.successGreen,
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 16),
          _PerformanceGauge(
            label: 'Livraisons à temps',
            value: perf.onTimeRate,
            color: _StatColors.accentBlue,
            icon: Icons.timer_outlined,
          ),
          const SizedBox(height: 16),
          _PerformanceGauge(
            label: "Taux d'annulation",
            value: perf.cancellationRate,
            color: _StatColors.warningOrange,
            icon: Icons.cancel_outlined,
            isNegative: true,
          ),
          const SizedBox(height: 16),
          _PerformanceGauge(
            label: 'Satisfaction client',
            value: perf.satisfactionRate,
            color: _StatColors.accentPurple,
            icon: Icons.emoji_emotions_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(BuildContext context, Statistics stats) {
    final rating = stats.overview.averageRating;
    final totalRatings = stats.performance.totalDelivered;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _StatColors.accentGold.withValues(alpha: 0.15),
            _StatColors.accentGold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _StatColors.accentGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _StatColors.accentGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_rounded,
              color: _StatColors.accentGold,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note moyenne',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.sora(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _StatColors.navyDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/5',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _StatColors.accentGold,
                    size: 18,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalRatings livraisons',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DELIVERIES TAB REDESIGN
// ============================================================================

class _DeliveriesTabRedesign extends ConsumerWidget {
  final String selectedPeriod;

  const _DeliveriesTabRedesign({required this.selectedPeriod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsProvider(selectedPeriod));

    return AsyncValueWidget<Statistics>(
      value: statsAsync,
      onRetry: () => ref.invalidate(statisticsProvider(selectedPeriod)),
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeliverySummary(stats),
            const SizedBox(height: 20),
            _buildStatusDistribution(context, stats),
            const SizedBox(height: 20),
            _buildPeakHours(context, stats),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySummary(Statistics stats) {
    final overview = stats.overview;
    final totalHours = (overview.totalDurationMinutes / 60).toStringAsFixed(1);

    int periodDays = 1;
    switch (stats.period) {
      case 'week':
        periodDays = 7;
      case 'month':
        periodDays = 30;
      case 'year':
        periodDays = 365;
      default:
        periodDays = 1;
    }

    final avgPerDay = overview.totalDeliveries > 0
        ? (overview.totalDeliveries / periodDays).toStringAsFixed(1)
        : '0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_StatColors.navyDark, _StatColors.navyMedium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé des livraisons',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _SummaryTile(
                icon: Icons.local_shipping_rounded,
                value: '${overview.totalDeliveries}',
                label: 'Total',
                color: _StatColors.accentBlue,
              ),
              _SummaryTile(
                icon: Icons.route_rounded,
                value: '${overview.totalDistanceKm.toStringAsFixed(0)} km',
                label: 'Distance',
                color: _StatColors.warningOrange,
              ),
              _SummaryTile(
                icon: Icons.timer_outlined,
                value: '${totalHours}h',
                label: 'Temps',
                color: _StatColors.accentPurple,
              ),
              _SummaryTile(
                icon: Icons.speed_rounded,
                value: avgPerDay,
                label: 'Moy/jour',
                color: _StatColors.successGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution(BuildContext context, Statistics stats) {
    final completed = stats.performance.totalDelivered;
    final cancelled = stats.performance.totalCancelled;
    final total = stats.overview.totalDeliveries;
    final inProgress = stats.performance.totalAccepted - completed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition par statut',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _StatColors.navyDark,
            ),
          ),
          const SizedBox(height: 20),
          _StatusRow(
            label: 'Complétées',
            value: completed,
            total: total,
            color: _StatColors.successGreen,
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'En cours',
            value: inProgress.clamp(0, total),
            total: total,
            color: _StatColors.accentBlue,
            icon: Icons.pending_rounded,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Annulées',
            value: cancelled,
            total: total,
            color: _StatColors.errorRed,
            icon: Icons.cancel_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHours(BuildContext context, Statistics stats) {
    final peakHours = stats.peakHours;
    if (peakHours.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxCount = peakHours
        .map((h) => h.count)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Heures de pointe',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _StatColors.navyDark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: peakHours.take(12).map((peakHour) {
                final height = maxCount > 0
                    ? (peakHour.count / maxCount) * 80
                    : 0.0;
                final isPeak = peakHour.count == maxCount;

                return _PeakHourBar(
                  hourLabel: peakHour.label,
                  height: height < 4 ? 4 : height,
                  isPeak: isPeak,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REVENUE TAB REDESIGN
// ============================================================================

class _RevenueTabRedesign extends ConsumerWidget {
  final String selectedPeriod;

  const _RevenueTabRedesign({required this.selectedPeriod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsProvider(selectedPeriod));
    final walletAsync = ref.watch(walletProvider);

    return AsyncValueWidget<Statistics>(
      value: statsAsync,
      onRetry: () {
        ref.invalidate(statisticsProvider(selectedPeriod));
        ref.invalidate(walletProvider);
      },
      data: (stats) {
        final wallet = walletAsync.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRevenueHeader(stats, wallet),
              const SizedBox(height: 20),
              _buildRevenueChart(context, stats),
              const SizedBox(height: 20),
              _buildRevenueBreakdown(context, stats),
              const SizedBox(height: 20),
              if (stats.goals != null)
                _buildGoalsSection(context, stats.goals!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueHeader(Statistics stats, dynamic wallet) {
    final currencyFormat = NumberFormat("#,##0", "fr_FR");
    final totalEarnings = stats.overview.totalEarnings;
    final avgPerDelivery = stats.overview.totalDeliveries > 0
        ? totalEarnings / stats.overview.totalDeliveries
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_StatColors.successGreen, _StatColors.accentTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gains période',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${currencyFormat.format(totalEarnings)} FCFA',
            style: GoogleFonts.sora(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _RevenueQuickStat(
                icon: Icons.trending_up_rounded,
                label: 'Par livraison',
                value: '${currencyFormat.format(avgPerDelivery.round())} F',
              ),
              const SizedBox(width: 24),
              _RevenueQuickStat(
                icon: Icons.local_shipping_rounded,
                label: 'Livraisons',
                value: '${stats.overview.totalDeliveries}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context, Statistics stats) {
    final dailyStats = stats.dailyBreakdown;
    if (dailyStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxEarnings = dailyStats
        .map((e) => e.earnings)
        .reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxEarnings == 0 ? 1.0 : maxEarnings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Évolution des gains',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _StatColors.navyDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _StatColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _StatColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'FCFA',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _StatColors.successGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyStats.map((stat) {
                final height = (stat.earnings / effectiveMax) * 100;
                final isHighest =
                    stat.earnings == maxEarnings && maxEarnings > 0;

                return _RevenueBar(
                  earnings: stat.earnings,
                  height: height < 4 ? 4 : height,
                  label: stat.dayName,
                  isHighlighted: isHighest,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown(BuildContext context, Statistics stats) {
    final breakdown = stats.revenueBreakdown;
    if (breakdown == null) {
      return _buildSimpleBreakdown(stats);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition des revenus',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _StatColors.navyDark,
            ),
          ),
          const SizedBox(height: 20),
          _BreakdownRow(
            label: 'Commissions livraisons',
            value: breakdown.deliveryCommissionsAmount,
            color: _StatColors.accentBlue,
            icon: Icons.attach_money_rounded,
          ),
          const SizedBox(height: 12),
          _BreakdownRow(
            label: 'Bonus défis',
            value: breakdown.challengeBonusesAmount,
            color: _StatColors.accentGold,
            icon: Icons.emoji_events_rounded,
          ),
          const SizedBox(height: 12),
          _BreakdownRow(
            label: 'Bonus rush',
            value: breakdown.rushBonusesAmount,
            color: _StatColors.successGreen,
            icon: Icons.bolt_rounded,
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _StatColors.navyDark,
                ),
              ),
              Text(
                breakdown.total.formatCurrency(),
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _StatColors.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBreakdown(Statistics stats) {
    final total = stats.overview.totalEarnings;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition des revenus',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _StatColors.navyDark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total net',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                total.formatCurrency(),
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _StatColors.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection(BuildContext context, StatsGoals goals) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _StatColors.accentPurple.withValues(alpha: 0.15),
            _StatColors.accentPurple.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _StatColors.accentPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: _StatColors.accentPurple,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Objectifs',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _StatColors.navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _GoalProgress(
            label: 'Objectif hebdo',
            current: goals.currentProgress,
            target: goals.weeklyTarget,
            color: _StatColors.accentBlue,
          ),
          const SizedBox(height: 8),
          Text(
            '${goals.remaining} livraisons restantes',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHARED COMPONENTS
// ============================================================================

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? suffix;
  final IconData icon;
  final Color color;
  final double? trend;

  const _KpiCard({
    required this.title,
    required this.value,
    this.suffix,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: trend! >= 0
                        ? _StatColors.successGreen.withValues(alpha: 0.12)
                        : _StatColors.errorRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend! >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: trend! >= 0
                            ? _StatColors.successGreen
                            : _StatColors.errorRed,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend! > 0 ? '+' : ''}${trend!.round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: trend! >= 0
                              ? _StatColors.successGreen
                              : _StatColors.errorRed,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _StatColors.navyDark,
                    ),
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 2),
                Text(
                  suffix!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final int value;
  final double height;
  final String label;
  final bool isHighlighted;

  const _AnimatedBar({
    required this.value,
    required this.height,
    required this.label,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            color: isHighlighted
                ? _StatColors.accentBlue
                : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: 28,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHighlighted
                  ? [
                      _StatColors.accentBlue,
                      _StatColors.accentBlue.withValues(alpha: 0.6),
                    ]
                  : [Colors.grey.shade300, Colors.grey.shade200],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            color: isHighlighted
                ? _StatColors.accentBlue
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class _PerformanceGauge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool isNegative;

  const _PerformanceGauge({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (value * 100).round();
    final isGood = isNegative ? displayValue < 10 : displayValue > 80;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isGood
                          ? _StatColors.successGreen.withValues(alpha: 0.1)
                          : _StatColors.warningOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$displayValue%',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isGood
                            ? _StatColors.successGreen
                            : _StatColors.warningOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final IconData icon;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (value / total) : 0.0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '$value',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _StatColors.navyDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeakHourBar extends StatelessWidget {
  final String hourLabel;
  final double height;
  final bool isPeak;

  const _PeakHourBar({
    required this.hourLabel,
    required this.height,
    this.isPeak = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPeak
                  ? [
                      _StatColors.warningOrange,
                      _StatColors.warningOrange.withValues(alpha: 0.6),
                    ]
                  : [Colors.grey.shade300, Colors.grey.shade200],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hourLabel,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: isPeak ? FontWeight.w600 : FontWeight.w400,
            color: isPeak ? _StatColors.warningOrange : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class _RevenueQuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RevenueQuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RevenueBar extends StatelessWidget {
  final double earnings;
  final double height;
  final String label;
  final bool isHighlighted;

  const _RevenueBar({
    required this.earnings,
    required this.height,
    required this.label,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "fr_FR");

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (earnings > 0)
          Text(
            currencyFormat.format(earnings.round()),
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
              color: isHighlighted
                  ? _StatColors.successGreen
                  : Colors.grey.shade500,
            ),
          ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: 28,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHighlighted
                  ? [_StatColors.successGreen, _StatColors.accentTeal]
                  : [Colors.grey.shade300, Colors.grey.shade200],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            color: isHighlighted
                ? _StatColors.successGreen
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
        Text(
          '+${value.formatCurrency()}',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _GoalProgress extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;

  const _GoalProgress({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '$current / $target',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _StatColors.navyDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$percentage% atteint',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: percentage >= 100 ? _StatColors.successGreen : color,
            fontWeight: percentage >= 100 ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
