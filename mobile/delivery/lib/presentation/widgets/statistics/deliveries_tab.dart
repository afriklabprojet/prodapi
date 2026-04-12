import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../data/models/statistics.dart';
import '../../providers/statistics_provider.dart';
import '../common/common_widgets.dart';

/// Onglet Livraisons des statistiques.
class DeliveriesTab extends ConsumerWidget {
  final String selectedPeriod;

  const DeliveriesTab({super.key, required this.selectedPeriod});

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
              _DeliverySummary(stats: stats),
              const SizedBox(height: 24),
              _StatusDistribution(stats: stats),
              const SizedBox(height: 24),
              _PeakHoursChart(stats: stats),
            ],
          ),
        );
      },
    );
  }
}

class _DeliverySummary extends StatelessWidget {
  final Statistics stats;

  const _DeliverySummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalDeliveries = stats.overview.totalDeliveries;
    final totalDistance = stats.overview.totalDistanceKm;
    final totalTimeHours = (stats.overview.totalDurationMinutes / 60)
        .toStringAsFixed(1);

    int periodDays = 1;
    switch (stats.period) {
      case 'week':
        periodDays = 7;
        break;
      case 'month':
        periodDays = 30;
        break;
      case 'year':
        periodDays = 365;
        break;
      default:
        periodDays = 1;
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
                child: _MiniStat(
                  icon: Icons.local_shipping,
                  color: Colors.blue,
                  label: 'Total',
                  value: '$totalDeliveries',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.straighten,
                  color: Colors.orange,
                  label: 'Distance',
                  value: '${totalDistance.toStringAsFixed(0)} km',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.timer,
                  color: Colors.purple,
                  label: 'Temps (h)',
                  value: totalTimeHours,
                ),
              ),
              Expanded(
                child: _MiniStat(
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
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _StatusDistribution extends StatelessWidget {
  final Statistics stats;

  const _StatusDistribution({required this.stats});

  @override
  Widget build(BuildContext context) {
    final completed = stats.performance.totalDelivered;
    final cancelled = stats.performance.totalCancelled;
    const returned = 0;

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
              _DistributionLegend(
                label: 'Livrées',
                count: completed,
                color: Colors.green,
              ),
              _DistributionLegend(
                label: 'Annulées',
                count: cancelled,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionLegend extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _DistributionLegend({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _PeakHoursChart extends StatelessWidget {
  final Statistics stats;

  const _PeakHoursChart({required this.stats});

  @override
  Widget build(BuildContext context) {
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

    final maxActivity = peakHours
        .map((e) => e.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
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
                      Text(
                        '${item.count}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.tertiaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 20,
                        height: height < 2 ? 2 : height,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade300,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.secondaryText,
                        ),
                      ),
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
