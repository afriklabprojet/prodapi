import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/core_providers.dart';

/// Données de revenus quotidiens
class DailyRevenueData {
  final String dayLabel; // "Lun", "Mar", etc.
  final double amount;
  final DateTime date;

  DailyRevenueData({
    required this.dayLabel,
    required this.amount,
    required this.date,
  });
}

/// Statistiques de revenus hebdomadaires
class WeeklyRevenueStats {
  final List<DailyRevenueData> dailyData;
  final double thisWeekTotal;
  final double lastWeekTotal;
  final double percentChange;

  WeeklyRevenueStats({
    required this.dailyData,
    required this.thisWeekTotal,
    required this.lastWeekTotal,
    required this.percentChange,
  });

  factory WeeklyRevenueStats.fromJson(Map<String, dynamic> json) {
    final dailyList = (json['daily_data'] as List?)?.map((d) {
      return DailyRevenueData(
        dayLabel: d['day_label'] ?? '',
        amount: (d['amount'] as num?)?.toDouble() ?? 0,
        date: DateTime.tryParse(d['date'] ?? '') ?? DateTime.now(),
      );
    }).toList() ?? _generateMockData();

    return WeeklyRevenueStats(
      dailyData: dailyList,
      thisWeekTotal: (json['this_week_total'] as num?)?.toDouble() ?? 0,
      lastWeekTotal: (json['last_week_total'] as num?)?.toDouble() ?? 0,
      percentChange: (json['percent_change'] as num?)?.toDouble() ?? 0,
    );
  }

  static List<DailyRevenueData> _generateMockData() {
    final now = DateTime.now();
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return List.generate(7, (i) {
      return DailyRevenueData(
        dayLabel: days[i],
        amount: 0,
        date: now.subtract(Duration(days: 6 - i)),
      );
    });
  }
}

/// Provider pour les stats de revenus hebdomadaires
final weeklyRevenueProvider = FutureProvider.autoDispose<WeeklyRevenueStats>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get('/pharmacy/stats/revenue/week');
    final data = response.data as Map<String, dynamic>;
    return WeeklyRevenueStats.fromJson(data['data'] ?? data);
  } catch (e) {
    // Fallback avec données vides si l'endpoint n'existe pas encore
    return WeeklyRevenueStats(
      dailyData: WeeklyRevenueStats._generateMockData(),
      thisWeekTotal: 0,
      lastWeekTotal: 0,
      percentChange: 0,
    );
  }
});

/// Widget de graphique des revenus hebdomadaires
class RevenueChartWidget extends ConsumerWidget {
  const RevenueChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyRevenueProvider);
    final isDark = AppColors.isDark(context);

    return Semantics(
      label: 'Graphique des revenus de la semaine',
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.show_chart_rounded, 
                        color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Revenus cette semaine',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                // Trend indicator
                statsAsync.when(
                  data: (stats) => _buildTrendBadge(stats.percentChange, isDark),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) {
                    debugPrint('[RevenueChart] Trend badge error: $error');
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Chart
            RepaintBoundary(
              child: SizedBox(
                height: 160,
                child: statsAsync.when(
                  data: (stats) => _buildChart(context, stats, isDark),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Données non disponibles',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ),
            ),
            // Totals comparison
            statsAsync.when(
              data: (stats) => _buildComparison(stats, isDark),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) {
                debugPrint('[RevenueChart] Comparison error: $error');
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBadge(double percentChange, bool isDark) {
    final isPositive = percentChange >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, WeeklyRevenueStats stats, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final maxY = stats.dailyData.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final safeMaxY = maxY == 0 ? 1000.0 : maxY * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: safeMaxY,
        barGroups: stats.dailyData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final isToday = _isToday(data.date);
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.amount,
                color: isToday ? primaryColor : primaryColor.withValues(alpha: 0.5),
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: safeMaxY,
                  color: isDark 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade100,
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < stats.dailyData.length) {
                  final data = stats.dailyData[index];
                  final isToday = _isToday(data.date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data.dayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday 
                          ? primaryColor 
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark ? Colors.grey.shade800 : Colors.white,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = stats.dailyData[group.x];
              return BarTooltipItem(
                '${_formatAmount(rod.toY)} FCFA\n${DateFormat('d MMM', 'fr').format(data.date)}',
                TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildComparison(WeeklyRevenueStats stats, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: _ComparisonItem(
              label: 'Cette semaine',
              amount: stats.thisWeekTotal,
              isMain: true,
              isDark: isDark,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
          Expanded(
            child: _ComparisonItem(
              label: 'Semaine dernière',
              amount: stats.lastWeekTotal,
              isMain: false,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _ComparisonItem extends StatelessWidget {
  final String label;
  final double amount;
  final bool isMain;
  final bool isDark;

  const _ComparisonItem({
    required this.label,
    required this.amount,
    required this.isMain,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatter.format(amount)} FCFA',
            style: TextStyle(
              fontSize: isMain ? 15 : 13,
              fontWeight: isMain ? FontWeight.w700 : FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
