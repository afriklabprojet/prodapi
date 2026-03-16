import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import '../../data/models/statistics.dart';
import '../providers/statistics_provider.dart';
import '../widgets/statistics/advanced_charts.dart';
import '../widgets/common/common_widgets.dart';
import '../../core/utils/responsive.dart';

/// Écran de tableau de bord avec statistiques avancées et graphiques
class AdvancedDashboardScreen extends ConsumerStatefulWidget {
  const AdvancedDashboardScreen({super.key});

  @override
  ConsumerState<AdvancedDashboardScreen> createState() => _AdvancedDashboardScreenState();
}

class _AdvancedDashboardScreenState extends ConsumerState<AdvancedDashboardScreen>
    with TickerProviderStateMixin {
  String _selectedPeriod = 'week';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _changePeriod(String period) {
    if (_selectedPeriod != period) {
      _fadeController.reverse().then((_) {
        setState(() => _selectedPeriod = period);
        _fadeController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // AppBar avec gradient
          SliverAppBar(
            expandedHeight: context.r.hp(180),
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade700,
                      Colors.blue.shade500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Tableau de bord',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.r.sp(28),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Analysez vos performances en détail',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => ref.invalidate(statisticsProvider(_selectedPeriod)),
              ),
            ],
          ),

          // Sélecteur de période
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildPeriodSelector(),
            ),
          ),

          // Contenu principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildDashboardContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPeriodChip('today', "Aujourd'hui", Icons.today),
          const SizedBox(width: 8),
          _buildPeriodChip('week', 'Semaine', Icons.view_week),
          const SizedBox(width: 8),
          _buildPeriodChip('month', 'Mois', Icons.calendar_month),
          const SizedBox(width: 8),
          _buildPeriodChip('year', 'Année', Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label, IconData icon) {
    final isSelected = _selectedPeriod == value;
    final isDark = context.isDark;
    
    return GestureDetector(
      onTap: () => _changePeriod(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.indigo 
              : (isDark ? Colors.grey.shade800 : Colors.white),
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.indigo.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final statsAsync = ref.watch(statisticsProvider(_selectedPeriod));

    return AsyncValueWidget<Statistics>(
      value: statsAsync,
      onRetry: () => ref.invalidate(statisticsProvider(_selectedPeriod)),
      data: (stats) => _buildStatsContent(stats),
    );
  }

  Widget _buildStatsContent(Statistics stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards animées
          _buildKPISection(stats),
          
          const SizedBox(height: 24),
          
          // Graphique d'évolution
          _buildEvolutionChart(stats),
          
          const SizedBox(height: 24),
          
          // Répartition des revenus
          _buildRevenueBreakdown(stats),
          
          const SizedBox(height: 24),
          
          // Radar de performance
          _buildPerformanceRadar(stats),
          
          const SizedBox(height: 24),
          
          // Heures de pointe
          _buildPeakHours(stats),
          
          const SizedBox(height: 24),
          
          // Insights et conseils
          _buildInsightsSection(stats),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildKPISection(Statistics stats) {
    final overview = stats.overview;
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        AnimatedStatCard(
          title: 'Livraisons',
          value: overview.totalDeliveries.toDouble(),
          icon: Icons.local_shipping_rounded,
          color: Colors.blue,
          previousValue: _getPreviousValue(overview.deliveryTrend, overview.totalDeliveries.toDouble()),
        ),
        AnimatedStatCard(
          title: 'Revenus',
          value: overview.totalEarnings,
          suffix: 'F',
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.green,
          isCurrency: true,
          previousValue: _getPreviousValue(overview.earningsTrend, overview.totalEarnings),
        ),
        AnimatedStatCard(
          title: 'Distance',
          value: overview.totalDistanceKm,
          suffix: 'km',
          icon: Icons.route_rounded,
          color: Colors.orange,
        ),
        AnimatedStatCard(
          title: 'Note moyenne',
          value: overview.averageRating,
          suffix: '/5',
          icon: Icons.star_rounded,
          color: Colors.amber,
        ),
      ],
    );
  }

  double? _getPreviousValue(double trend, double currentValue) {
    if (trend == 0) return null;
    // Calcul inverse: si trend = ((current - previous) / previous) * 100
    // alors previous = current / (1 + trend/100)
    return currentValue / (1 + trend / 100);
  }

  Widget _buildEvolutionChart(Statistics stats) {
    return _buildSection(
      title: 'Évolution',
      icon: Icons.show_chart_rounded,
      child: Column(
        children: [
          // Légende
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem('Revenus', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem('Livraisons', Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          
          // Graphique
          EarningsLineChart(
            dailyStats: stats.dailyBreakdown,
            showEarnings: true,
            showDeliveries: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final isDark = context.isDark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdown(Statistics stats) {
    if (stats.revenueBreakdown == null || stats.revenueBreakdown!.total == 0) {
      return const SizedBox.shrink();
    }
    
    return _buildSection(
      title: 'Sources de revenus',
      icon: Icons.pie_chart_rounded,
      child: RevenueBreakdownPieChart(
        breakdown: stats.revenueBreakdown!,
      ),
    );
  }

  Widget _buildPerformanceRadar(Statistics stats) {
    return _buildSection(
      title: 'Performance',
      icon: Icons.radar_rounded,
      child: PerformanceRadarChart(
        performance: stats.performance,
      ),
    );
  }

  Widget _buildPeakHours(Statistics stats) {
    if (stats.peakHours.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return _buildSection(
      title: 'Heures de pointe',
      icon: Icons.access_time_rounded,
      subtitle: 'Vos meilleures heures pour livrer',
      child: PeakHoursBarChart(
        peakHours: stats.peakHours,
      ),
    );
  }

  Widget _buildInsightsSection(Statistics stats) {
    final insights = _generateInsights(stats);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade600,
            Colors.purple.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 24),
              SizedBox(width: 10),
              Text(
                'Insights & Conseils',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  insight.icon,
                  color: insight.color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insight.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<_Insight> _generateInsights(Statistics stats) {
    final insights = <_Insight>[];
    final perf = stats.performance;
    final overview = stats.overview;
    
    // Analyse du taux d'acceptation
    if (perf.acceptanceRate < 70) {
      insights.add(_Insight(
        icon: Icons.warning_rounded,
        color: Colors.orange,
        title: 'Taux d\'acceptation bas',
        description: 'Acceptez plus de livraisons pour améliorer votre score et gagner plus.',
      ));
    } else if (perf.acceptanceRate >= 90) {
      insights.add(_Insight(
        icon: Icons.emoji_events_rounded,
        color: Colors.amber,
        title: 'Excellent taux d\'acceptation!',
        description: 'Continuez ainsi pour maintenir votre position privilégiée.',
      ));
    }
    
    // Analyse des revenus
    if (overview.earningsTrend > 10) {
      insights.add(_Insight(
        icon: Icons.trending_up_rounded,
        color: Colors.green,
        title: 'Revenus en hausse!',
        description: '+${overview.earningsTrend.toStringAsFixed(0)}% par rapport à la période précédente.',
      ));
    } else if (overview.earningsTrend < -10) {
      insights.add(_Insight(
        icon: Icons.trending_down_rounded,
        color: Colors.red,
        title: 'Revenus en baisse',
        description: 'Essayez de livrer pendant les heures de pointe pour augmenter vos gains.',
      ));
    }
    
    // Analyse des heures de pointe
    if (stats.peakHours.isNotEmpty) {
      final bestHour = stats.peakHours.reduce((a, b) => a.count > b.count ? a : b);
      insights.add(_Insight(
        icon: Icons.schedule_rounded,
        color: Colors.blue,
        title: 'Meilleure heure: ${bestHour.label}',
        description: 'Maximisez votre présence à cette heure pour plus de livraisons.',
      ));
    }
    
    // Conseil sur la note
    if (overview.averageRating >= 4.5) {
      insights.add(_Insight(
        icon: Icons.star_rounded,
        color: Colors.yellow,
        title: 'Note exceptionnelle!',
        description: 'Vos clients vous adorent. Gardez cette qualité de service.',
      ));
    } else if (overview.averageRating < 4.0 && overview.averageRating > 0) {
      insights.add(_Insight(
        icon: Icons.thumb_up_rounded,
        color: Colors.cyan,
        title: 'Améliorez votre note',
        description: 'Soyez ponctuel et courtois pour de meilleures évaluations.',
      ));
    }
    
    // Si pas d'insights spécifiques, ajouter des conseils généraux
    if (insights.isEmpty) {
      insights.add(_Insight(
        icon: Icons.lightbulb_rounded,
        color: Colors.amber,
        title: 'Conseil du jour',
        description: 'Restez actif pendant les heures de pointe (11h30-13h30, 18h30-20h30).',
      ));
    }
    
    return insights;
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
  }) {
    final isDark = context.isDark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _Insight {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  _Insight({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
