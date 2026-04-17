import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/statistics.dart';
import '../../providers/statistics_provider.dart';
import '../common/common_widgets.dart';
import 'statistics_widgets.dart';

/// Onglet Aperçu des statistiques.
class OverviewTab extends ConsumerWidget {
  final String selectedPeriod;

  const OverviewTab({super.key, required this.selectedPeriod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsProvider(selectedPeriod));

    return AsyncValueWidget<Statistics>(
      value: statsAsync,
      onRetry: () => ref.invalidate(statisticsProvider(selectedPeriod)),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCards(stats: stats),
              const SizedBox(height: 24),
              _ActivityChart(stats: stats),
              const SizedBox(height: 24),
              _PerformanceSection(stats: stats),
              const SizedBox(height: 24),
              _RatingSection(overview: stats.overview),
              const SizedBox(height: 24),
              const _TipsSection(),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final Statistics stats;

  const _SummaryCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    final overview = stats.overview;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          title: 'Livraisons',
          value: '${overview.totalDeliveries}',
          icon: Icons.local_shipping,
          color: Colors.blue,
          trend:
              '${overview.deliveryTrend > 0 ? '+' : ''}${overview.deliveryTrend}%',
          trendUp: overview.deliveryTrend >= 0,
        ),
        StatCard(
          title: 'Revenus',
          value: overview.totalEarnings.formatCurrency(),
          icon: Icons.account_balance_wallet,
          color: Colors.green,
          trend:
              '${overview.earningsTrend > 0 ? '+' : ''}${overview.earningsTrend}%',
          trendUp: overview.earningsTrend >= 0,
        ),
        StatCard(
          title: 'Distance',
          value: '${overview.totalDistanceKm.toStringAsFixed(1)} km',
          icon: Icons.straighten,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Note moyenne',
          value: overview.averageRating.toStringAsFixed(1),
          icon: Icons.star,
          color: Colors.amber,
          suffix: '/5',
        ),
      ],
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final Statistics stats;

  const _ActivityChart({required this.stats});

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [LegendItem(label: 'Livraisons', color: Colors.blue)],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: context.r.dp(150),
            child: _buildSimpleBarChart(context, stats.dailyBreakdown),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart(
    BuildContext context,
    List<DailyStats> dailyStats,
  ) {
    if (dailyStats.isEmpty) {
      return const Center(child: Text("Pas de données"));
    }

    final maxValue = dailyStats
        .map((e) => e.deliveries)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final effectiveMax = maxValue == 0 ? 1.0 : maxValue;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: dailyStats.map((stat) {
        final height = (stat.deliveries / effectiveMax) * 120;
        final isToday =
            stat.date == DateTime.now().toIso8601String().substring(0, 10);

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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
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
}

class _PerformanceSection extends StatelessWidget {
  final Statistics stats;

  const _PerformanceSection({required this.stats});

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _PerformanceItem(
            label: "Taux d'acceptation",
            value: perf.acceptanceRate,
            valueText: '${(perf.acceptanceRate * 100).round()}%',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _PerformanceItem(
            label: 'Livraisons à temps',
            value: perf.onTimeRate,
            valueText: '${(perf.onTimeRate * 100).round()}%',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _PerformanceItem(
            label: "Taux d'annulation",
            value: perf.cancellationRate,
            valueText: '${(perf.cancellationRate * 100).round()}%',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _PerformanceItem(
            label: 'Satisfaction client',
            value: perf.satisfactionRate,
            valueText: '${(perf.satisfactionRate * 100).round()}%',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _PerformanceItem extends StatelessWidget {
  final String label;
  final double value;
  final String valueText;
  final Color color;

  const _PerformanceItem({
    required this.label,
    required this.value,
    required this.valueText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            Text(
              valueText,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: context.isDark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _RatingSection extends StatelessWidget {
  final StatsOverview overview;

  const _RatingSection({required this.overview});

  @override
  Widget build(BuildContext context) {
    final rating = overview.averageRating;
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;

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
            'Votre note client',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      if (i < fullStars) {
                        return const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 24,
                        );
                      } else if (i == fullStars && hasHalf) {
                        return const Icon(
                          Icons.star_half,
                          color: Colors.amber,
                          size: 24,
                        );
                      }
                      return Icon(
                        Icons.star_border,
                        color: Colors.grey.shade300,
                        size: 24,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rating >= 4.5
                        ? 'Excellent !'
                        : rating >= 4.0
                        ? 'Très bien'
                        : rating >= 3.0
                        ? 'Peut mieux faire'
                        : 'À améliorer',
                    style: TextStyle(
                      color: rating >= 4.0 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipsSection extends StatelessWidget {
  const _TipsSection();

  @override
  Widget build(BuildContext context) {
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
          _buildTipItem(
            'Soyez en ligne pendant les heures de pointe (11h30-13h30, 18h30-20h30)',
          ),
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
}
