import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/statistics.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/wallet_provider.dart';
import '../common/common_widgets.dart';

/// Onglet Revenus des statistiques.
class RevenueTab extends ConsumerWidget {
  final String selectedPeriod;

  const RevenueTab({super.key, required this.selectedPeriod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final statsAsync = ref.watch(statisticsProvider(selectedPeriod));

    return AsyncValueWidget<dynamic>(
      value: walletAsync,
      onRetry: () {
        ref.invalidate(walletProvider);
        ref.invalidate(statisticsProvider(selectedPeriod));
      },
      data: (wallet) {
        final stats = statsAsync.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BalanceCard(wallet: wallet, stats: stats),
              const SizedBox(height: 24),
              if (stats != null) _RevenueChart(stats: stats),
              const SizedBox(height: 24),
              if (stats?.revenueBreakdown != null)
                _RevenueBreakdown(breakdown: stats!.revenueBreakdown!)
              else
                _SimpleRevenueBreakdown(stats: stats),
              const SizedBox(height: 24),
              if (stats?.goals != null)
                _GoalsSection(goals: stats!.goals!)
              else
                const _NoGoalsPlaceholder(),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final dynamic wallet;
  final Statistics? stats;

  const _BalanceCard({required this.wallet, this.stats});

  @override
  Widget build(BuildContext context) {
    final balance = wallet?.balance ?? 0.0;
    final currencyFormat = NumberFormat("#,##0", "fr_FR");
    final totalEarnings = stats?.overview.totalEarnings ?? 0.0;
    final totalCommissions = wallet?.totalCommissions ?? 0.0;

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
          Row(
            children: [
              _QuickStat(
                label: 'Gains période',
                value: '+${currencyFormat.format(totalEarnings)} F',
              ),
              const SizedBox(width: 24),
              _QuickStat(
                label: 'Commissions',
                value: '-${currencyFormat.format(totalCommissions)} F',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;

  const _QuickStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
}

class _RevenueChart extends StatelessWidget {
  final Statistics stats;

  const _RevenueChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final dailyStats = stats.dailyBreakdown;
    if (dailyStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Pas de données de revenus pour cette période'),
        ),
      );
    }

    final maxRevenue = dailyStats
        .map((e) => e.earnings)
        .reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxRevenue == 0 ? 1.0 : maxRevenue;

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
            'Revenus par jour',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: context.r.dp(180),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyStats.map((stat) {
                final height = (stat.earnings / effectiveMax) * 120;
                final isToday =
                    stat.date ==
                    DateTime.now().toIso8601String().substring(0, 10);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      stat.earnings >= 1000
                          ? '${(stat.earnings / 1000).toStringAsFixed(1)}k'
                          : '${stat.earnings.toInt()}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isToday ? Colors.green : context.tertiaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: height < 2 ? 2 : height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [Colors.green.shade400, Colors.green.shade700]
                              : [Colors.green.shade200, Colors.green.shade300],
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
                        fontSize: 12,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isToday ? Colors.green : context.secondaryText,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueBreakdown extends StatelessWidget {
  final RevenueBreakdown breakdown;

  const _RevenueBreakdown({required this.breakdown});

  @override
  Widget build(BuildContext context) {
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
          _RevenueSource(
            icon: Icons.local_shipping,
            label: 'Commissions livraison',
            amount: breakdown.deliveryCommissionsAmount.toInt(),
            percentage: breakdown.deliveryCommissionsPercent.toInt(),
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _RevenueSource(
            icon: Icons.emoji_events,
            label: 'Bonus challenges',
            amount: breakdown.challengeBonusesAmount.toInt(),
            percentage: breakdown.challengeBonusesPercent.toInt(),
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _RevenueSource(
            icon: Icons.access_time,
            label: 'Bonus heures de pointe',
            amount: breakdown.rushBonusesAmount.toInt(),
            percentage: breakdown.rushBonusesPercent.toInt(),
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _SimpleRevenueBreakdown extends StatelessWidget {
  final Statistics? stats;

  const _SimpleRevenueBreakdown({this.stats});

  @override
  Widget build(BuildContext context) {
    final earnings = stats?.overview.totalEarnings ?? 0.0;
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
          _RevenueSource(
            icon: Icons.local_shipping,
            label: 'Gains livraisons',
            amount: earnings.toInt(),
            percentage: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          Text(
            'Le détail des sources sera disponible prochainement',
            style: TextStyle(
              fontSize: 12,
              color: context.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueSource extends StatelessWidget {
  final IconData icon;
  final String label;
  final int amount;
  final int percentage;
  final Color color;

  const _RevenueSource({
    required this.icon,
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: context.isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
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
}

class _GoalsSection extends StatelessWidget {
  final StatsGoals goals;

  const _GoalsSection({required this.goals});

  @override
  Widget build(BuildContext context) {
    final progress = goals.progressPercentage.clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();

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
                'Objectif de la semaine',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${goals.currentProgress}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: context.r.sp(24),
                ),
              ),
              Text(
                ' / ${goals.weeklyTarget} livraisons',
                style: const TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.greenAccent,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goals.remaining > 0
                ? '$progressPercent% — encore ${goals.remaining} livraisons !'
                : 'Objectif atteint ! 🎉',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NoGoalsPlaceholder extends StatelessWidget {
  const _NoGoalsPlaceholder();

  @override
  Widget build(BuildContext context) {
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
      child: const Row(
        children: [
          Icon(Icons.flag, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Les objectifs hebdomadaires seront bientôt disponibles',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
