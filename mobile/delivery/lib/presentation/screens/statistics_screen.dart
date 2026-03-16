import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme_provider.dart';
import '../providers/wallet_provider.dart';
import '../../data/models/statistics.dart';
import '../providers/statistics_provider.dart';
import '../widgets/common/common_widgets.dart';
import '../../core/utils/responsive.dart';

/// Écran de statistiques avancées pour le livreur
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'week'; // 'today', 'week', 'month', 'year'

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mes Statistiques'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Aperçu'),
            Tab(text: 'Livraisons'),
            Tab(text: 'Revenus'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Sélecteur de période
          _buildPeriodSelector(),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDeliveriesTab(),
                _buildRevenueTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      color: Colors.indigo,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPeriodChip('today', "Aujourd'hui"),
            const SizedBox(width: 8),
            _buildPeriodChip('week', 'Cette semaine'),
            const SizedBox(width: 8),
            _buildPeriodChip('month', 'Ce mois'),
            const SizedBox(width: 8),
            _buildPeriodChip('year', 'Cette année'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.indigo : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final statsAsync = ref.watch(statisticsProvider(_selectedPeriod));

    return AsyncValueWidget<Statistics>(
      value: statsAsync,
      onRetry: () => ref.invalidate(statisticsProvider(_selectedPeriod)),
      data: (stats) {
        if (kDebugMode) debugPrint('Stats State: DATA RECEIVED');
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cartes de résumé
              _buildSummaryCards(stats),

              const SizedBox(height: 24),

              // Graphique d'activité
              _buildActivityChart(stats),

            const SizedBox(height: 24),

            // Performance
            _buildPerformanceSection(stats),

            const SizedBox(height: 24),

            // Conseils
            _buildTipsSection(),
          ],
        ),
      );
      },
    );
  }

  Widget _buildSummaryCards(Statistics stats) {
    final overview = stats.overview;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Livraisons',
          value: '${overview.totalDeliveries}',
          icon: Icons.local_shipping,
          color: Colors.blue,
          trend: '${overview.deliveryTrend > 0 ? '+' : ''}${overview.deliveryTrend}%',
          trendUp: overview.deliveryTrend >= 0,
        ),
        _buildStatCard(
          title: 'Revenus',
          value: '${NumberFormat("#,##0").format(overview.totalEarnings)} F',
          icon: Icons.account_balance_wallet,
          color: Colors.green,
          trend: '${overview.earningsTrend > 0 ? '+' : ''}${overview.earningsTrend}%',
          trendUp: overview.earningsTrend >= 0,
        ),
        _buildStatCard(
          title: 'Distance',
          value: '${overview.totalDistanceKm.toStringAsFixed(1)} km',
          icon: Icons.straighten,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Note moyenne',
          value: overview.averageRating.toStringAsFixed(1),
          icon: Icons.star,
          color: Colors.amber,
          suffix: '/5',
        ),
      ],
    );
  }



  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
    bool? trendUp,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (trendUp ?? true) ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (trendUp ?? true) ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: (trendUp ?? true) ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 10,
                          color: (trendUp ?? true) ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: context.secondaryText,
              fontSize: 12,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: context.primaryText,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix,
                  style: TextStyle(
                    color: context.secondaryText,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(Statistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Activité',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem('Livraisons', Colors.blue),
                  // const SizedBox(width: 16),
                  // _buildLegendItem('Revenus', Colors.green), // Bar chart currently only shows count
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Graphique simple en barres
          SizedBox(
            height: context.r.dp(150),
            child: _buildSimpleBarChart(stats.dailyBreakdown),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: context.secondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleBarChart(List<DailyStats> dailyStats) {
      if (dailyStats.isEmpty) {
        return const Center(child: Text("Pas de données"));
      }

      // Find max value for scaling
      final maxValue = dailyStats.isNotEmpty 
          ? dailyStats.map((e) => e.deliveries).reduce((a, b) => a > b ? a : b).toDouble() 
          : 0.0;
      final effectiveMax = maxValue == 0 ? 1.0 : maxValue;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: dailyStats.map((stat) {
          final height = (stat.deliveries / effectiveMax) * 120;
          final isToday = stat.date == DateTime.now().toIso8601String().substring(0, 10);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${stat.deliveries}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Colors.blue : context.tertiaryText,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: height < 2 ? 2 : height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isToday
                        ? [Colors.blue.shade400, Colors.blue.shade700]
                        : [Colors.blue.shade200, Colors.blue.shade300],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stat.dayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Colors.blue : context.secondaryText,
                ),
              ),
            ],
          );
        }).toList(),
      );
  }

  Widget _buildPerformanceSection(Statistics stats) {
    final perf = stats.performance;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          _buildPerformanceItem(
            label: "Taux d'acceptation",
            value: perf.acceptanceRate,
            valueText: '${(perf.acceptanceRate * 100).round()}%',
            color: Colors.green,
          ),
          const SizedBox(height: 12),

          _buildPerformanceItem(
            label: 'Livraisons à temps',
            value: perf.onTimeRate,
            valueText: '${(perf.onTimeRate * 100).round()}%',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),

          _buildPerformanceItem(
            label: "Taux d'annulation",
            value: perf.cancellationRate,
            valueText: '${(perf.cancellationRate * 100).round()}%',
            color: Colors.orange,
            isLowGood: true,
          ),
          const SizedBox(height: 12),

          _buildPerformanceItem(
            label: 'Satisfaction client',
            value: perf.satisfactionRate, // Already 0.0-1.0
            valueText: '${(perf.satisfactionRate * 100).round()}%',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem({
    required String label,
    required double value,
    required String valueText,
    required Color color,
    bool isLowGood = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: context.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'Conseils pour gagner plus',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildTipItem('Soyez en ligne pendant les heures de pointe (11h30-13h30, 18h30-20h30)'),
          _buildTipItem('Complétez vos défis quotidiens pour des bonus'),
          _buildTipItem('Maintenez un taux d\'acceptation élevé'),
          _buildTipItem('Livrez rapidement pour de meilleures évaluations'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesTab() {
    final statsAsync = ref.watch(statisticsProvider(_selectedPeriod));

    return AsyncValueWidget<Statistics>(
      value: statsAsync,
      onRetry: () => ref.invalidate(statisticsProvider(_selectedPeriod)),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Résumé livraisons
              _buildDeliverySummary(stats),

              const SizedBox(height: 24),

              // Répartition par statut
              _buildStatusDistributionV2(stats),

              const SizedBox(height: 24),

              // Heures de pointe
              _buildPeakHoursChartV2(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliverySummary(Statistics stats) {
    final totalDeliveries = stats.overview.totalDeliveries;
    final totalDistance = stats.overview.totalDistanceKm;
    final totalTimeHours = (stats.overview.totalDurationMinutes / 60).toStringAsFixed(1);
    
    int periodDays = 1;
    switch (stats.period) {
      case 'week': periodDays = 7; break;
      case 'month': periodDays = 30; break;
      case 'year': periodDays = 365; break;
      default: periodDays = 1;
    }
    
    final avgPerDay = totalDeliveries > 0 
        ? (totalDeliveries / periodDays).toStringAsFixed(1) 
        : '0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé des livraisons',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.local_shipping,
                  color: Colors.blue,
                  label: 'Total',
                  value: '$totalDeliveries',
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.straighten,
                  color: Colors.orange,
                  label: 'Distance',
                  value: '${totalDistance.toStringAsFixed(0)} km',
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.timer,
                  color: Colors.purple,
                  label: 'Temps (h)',
                  value: totalTimeHours,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.speed,
                  color: Colors.green,
                  label: 'Moy/jour',
                  value: avgPerDay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: context.secondaryText, fontSize: 11),
        ),
      ],
    );
  }



  Widget _buildDistributionLegend(String label, int count, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: context.secondaryText, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }



  Widget _buildRevenueTab() {
    final walletAsync = ref.watch(walletProvider);
    
    return AsyncValueWidget<dynamic>(
      value: walletAsync,
      onRetry: () => ref.invalidate(walletProvider),
      data: (wallet) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Solde actuel
              _buildBalanceCard(wallet),
              
              const SizedBox(height: 24),
              
              // Graphique revenus
              _buildRevenueChart(),
              
              const SizedBox(height: 24),
              
              // Répartition des revenus
              _buildRevenueBreakdown(),
              
              const SizedBox(height: 24),
              
              // Objectifs
              _buildGoalsSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(dynamic wallet) {
    final balance = wallet?.balance ?? 0.0;
    final currencyFormat = NumberFormat("#,##0", "fr_FR");
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${currencyFormat.format(balance)} FCFA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: context.r.sp(32),
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats rapides
          Row(
            children: [
              _buildQuickStat('Cette semaine', '+12,500 F'),
              const SizedBox(width: 24),
              _buildQuickStat('Ce mois', '+45,000 F'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    // Données simulées des 7 derniers jours
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final revenues = [2500.0, 4200.0, 3100.0, 5800.0, 4500.0, 7200.0, 3600.0];
    final maxRevenue = revenues.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenus de la semaine',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            height: context.r.dp(180),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final height = (revenues[index] / maxRevenue) * 120;
                final isToday = index == DateTime.now().weekday - 1;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(revenues[index] / 1000).toStringAsFixed(1)}k',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.green : context.tertiaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [Colors.green.shade400, Colors.green.shade700]
                              : [Colors.green.shade200, Colors.green.shade300],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.green : context.secondaryText,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sources de revenus',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          
          _buildRevenueSource(
            icon: Icons.local_shipping,
            label: 'Commissions livraison',
            amount: 35000,
            percentage: 70,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          
          _buildRevenueSource(
            icon: Icons.emoji_events,
            label: 'Bonus challenges',
            amount: 10000,
            percentage: 20,
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          
          _buildRevenueSource(
            icon: Icons.access_time,
            label: 'Bonus heures de pointe',
            amount: 5000,
            percentage: 10,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSource({
    required IconData icon,
    required String label,
    required int amount,
    required int percentage,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: context.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${NumberFormat("#,##0").format(amount)} F',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '$percentage%',
              style: TextStyle(color: context.secondaryText, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.indigo.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Objectif du mois',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress vers objectif
          Row(
            children: [
              Text(
                '45,000 F',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: context.r.sp(24),
                ),
              ),
              const Text(
                ' / 100,000 F',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.45,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          
          const Text(
            '45% complété - Continue comme ça! 🚀',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistributionV2(Statistics stats) {
    final completed = stats.performance.totalDelivered;
    final cancelled = stats.performance.totalCancelled;
    final returned = 0;
    
    final total = completed + cancelled + returned;
    final effectiveTotal = total > 0 ? total : 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  if (total == 0)
                      Expanded(child: Container(color: Colors.grey.shade200)),
                      
                  if (completed > 0)
                    Expanded(
                      flex: (completed * 100 ~/ effectiveTotal),
                      child: Container(color: Colors.green),
                    ),
                  if (cancelled > 0)
                    Expanded(
                      flex: (cancelled * 100 ~/ effectiveTotal),
                      child: Container(color: Colors.red),
                    ),
                  if (returned > 0)
                    Expanded(
                      flex: (returned * 100 ~/ effectiveTotal),
                      child: Container(color: Colors.orange),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDistributionLegend('Livrées', completed, Colors.green),
              _buildDistributionLegend('Annulées', cancelled, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHoursChartV2(Statistics stats) {
    final peakHours = stats.peakHours;
    if (peakHours.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Pas de données horaires'),
      );
    }

    final maxActivity = peakHours.isNotEmpty
        ? peakHours.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble()
        : 1.0;
    final effectiveMax = maxActivity == 0 ? 1.0 : maxActivity;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Heures de pointe',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: peakHours.map((item) {
                final height = (item.count / effectiveMax) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                        Text('${item.count}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.tertiaryText)),
                        const SizedBox(height: 4),
                        Container(
                          width: 20, 
                          height: height < 2 ? 2 : height,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade300,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(item.label, style: TextStyle(fontSize: 11, color: context.secondaryText)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
