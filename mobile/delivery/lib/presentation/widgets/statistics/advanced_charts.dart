import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/statistics.dart';

/// Graphique en ligne pour l'évolution des livraisons et revenus
class EarningsLineChart extends StatelessWidget {
  final List<DailyStats> dailyStats;
  final bool showEarnings;
  final bool showDeliveries;

  const EarningsLineChart({
    super.key,
    required this.dailyStats,
    this.showEarnings = true,
    this.showDeliveries = true,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyStats.isEmpty) {
      return const Center(
        child: Text('Pas de données disponibles'),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.grey.shade600;
    
    // Trouver les valeurs max pour la mise à l'échelle
    final maxEarnings = dailyStats.isEmpty 
        ? 1.0 
        : dailyStats.map((e) => e.earnings).reduce((a, b) => a > b ? a : b);
    final maxDeliveries = dailyStats.isEmpty 
        ? 1.0 
        : dailyStats.map((e) => e.deliveries.toDouble()).reduce((a, b) => a > b ? a : b);
    
    final effectiveMaxEarnings = maxEarnings == 0 ? 1000.0 : maxEarnings * 1.2;
    final effectiveMaxDeliveries = maxDeliveries == 0 ? 10.0 : maxDeliveries * 1.2;

    return SizedBox(
      height: context.r.dp(200),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: effectiveMaxEarnings / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showEarnings,
                reservedSize: 45,
                interval: effectiveMaxEarnings / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _formatAmount(value),
                      style: TextStyle(color: textColor, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showDeliveries,
                reservedSize: 30,
                interval: effectiveMaxDeliveries / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.blue.shade400, fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dailyStats.length) return const SizedBox();
                  
                  // N'afficher que certains labels pour éviter le chevauchement
                  if (dailyStats.length > 7 && index % 2 != 0) return const SizedBox();
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dailyStats[index].dayName.substring(0, 3),
                      style: TextStyle(color: textColor, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (dailyStats.length - 1).toDouble(),
          minY: 0,
          maxY: effectiveMaxEarnings,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => isDark ? Colors.grey.shade800 : Colors.white,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= dailyStats.length) return null;
                  
                  final stat = dailyStats[index];
                  final isEarnings = spot.barIndex == 0;
                  
                  return LineTooltipItem(
                    '${stat.dayName}\n${isEarnings ? '${NumberFormat("#,##0").format(stat.earnings)} F' : '${stat.deliveries} livraisons'}',
                    TextStyle(
                      color: isEarnings ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            // Ligne des revenus (verte)
            if (showEarnings)
              LineChartBarData(
                spots: dailyStats.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.earnings);
                }).toList(),
                isCurved: true,
                curveSmoothness: 0.3,
                color: Colors.green,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.green,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.3),
                      Colors.green.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            // Ligne des livraisons (bleue) - mise à l'échelle
            if (showDeliveries)
              LineChartBarData(
                spots: dailyStats.asMap().entries.map((e) {
                  // Mise à l'échelle pour correspondre à l'axe des revenus
                  final scaledValue = (e.value.deliveries / effectiveMaxDeliveries) * effectiveMaxEarnings;
                  return FlSpot(e.key.toDouble(), scaledValue);
                }).toList(),
                isCurved: true,
                curveSmoothness: 0.3,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.blue,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.2),
                      Colors.blue.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
          ],
        ),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toInt().toString();
  }
}

/// Graphique circulaire pour la répartition des revenus
class RevenueBreakdownPieChart extends StatefulWidget {
  final RevenueBreakdown breakdown;

  const RevenueBreakdownPieChart({
    super.key,
    required this.breakdown,
  });

  @override
  State<RevenueBreakdownPieChart> createState() => _RevenueBreakdownPieChartState();
}

class _RevenueBreakdownPieChartState extends State<RevenueBreakdownPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final sections = <PieChartSectionData>[];
    final legends = <_LegendItem>[];

    // Commissions livraisons
    if (widget.breakdown.deliveryCommissionsPercent > 0) {
      sections.add(_createSection(
        value: widget.breakdown.deliveryCommissionsPercent,
        color: Colors.blue,
        title: '${widget.breakdown.deliveryCommissionsPercent.toStringAsFixed(0)}%',
        index: 0,
      ));
      legends.add(_LegendItem(
        color: Colors.blue,
        label: 'Livraisons',
        amount: widget.breakdown.deliveryCommissionsAmount,
      ));
    }

    // Bonus défis
    if (widget.breakdown.challengeBonusesPercent > 0) {
      sections.add(_createSection(
        value: widget.breakdown.challengeBonusesPercent,
        color: Colors.orange,
        title: '${widget.breakdown.challengeBonusesPercent.toStringAsFixed(0)}%',
        index: 1,
      ));
      legends.add(_LegendItem(
        color: Colors.orange,
        label: 'Défis',
        amount: widget.breakdown.challengeBonusesAmount,
      ));
    }

    // Bonus rush
    if (widget.breakdown.rushBonusesPercent > 0) {
      sections.add(_createSection(
        value: widget.breakdown.rushBonusesPercent,
        color: Colors.purple,
        title: '${widget.breakdown.rushBonusesPercent.toStringAsFixed(0)}%',
        index: 2,
      ));
      legends.add(_LegendItem(
        color: Colors.purple,
        label: 'Rush',
        amount: widget.breakdown.rushBonusesAmount,
      ));
    }

    if (sections.isEmpty) {
      return const Center(
        child: Text('Pas de données de revenus'),
      );
    }

    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: 3,
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
        ),
        
        // Légende
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: legends.map((legend) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: legend.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          legend.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${NumberFormat("#,##0").format(legend.amount)} F',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  PieChartSectionData _createSection({
    required double value,
    required Color color,
    required String title,
    required int index,
  }) {
    final isTouched = index == touchedIndex;
    final fontSize = isTouched ? 16.0 : 12.0;
    final radius = isTouched ? 60.0 : 50.0;

    return PieChartSectionData(
      color: color,
      value: value,
      title: title,
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
      ),
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;
  final double amount;

  _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
  });
}

/// Graphique radar pour les performances
class PerformanceRadarChart extends StatelessWidget {
  final StatsPerformance performance;

  const PerformanceRadarChart({
    super.key,
    required this.performance,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final dataEntries = <RadarEntry>[
      RadarEntry(value: performance.acceptanceRate),
      RadarEntry(value: performance.completionRate),
      RadarEntry(value: performance.onTimeRate),
      RadarEntry(value: performance.satisfactionRate),
      RadarEntry(value: 100 - performance.cancellationRate), // Inverser pour que haut = bon
    ];

    final labels = [
      'Acceptation',
      'Complétion',
      'Ponctualité',
      'Satisfaction',
      'Fiabilité',
    ];

    return Column(
      children: [
        SizedBox(
          height: context.r.dp(200),
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              radarBorderData: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
              gridBorderData: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
                width: 1,
              ),
              tickCount: 4,
              ticksTextStyle: const TextStyle(
                color: Colors.transparent,
                fontSize: 0,
              ),
              tickBorderData: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
              titleTextStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                fontSize: 11,
              ),
              getTitle: (index, angle) {
                return RadarChartTitle(
                  text: labels[index],
                  angle: 0,
                );
              },
              titlePositionPercentageOffset: 0.15,
              dataSets: [
                RadarDataSet(
                  fillColor: Colors.blue.withValues(alpha: 0.2),
                  borderColor: Colors.blue,
                  borderWidth: 2,
                  entryRadius: 3,
                  dataEntries: dataEntries,
                ),
              ],
            ),
          ),
        ),
        
        // Score moyen
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getScoreColor(_calculateAverageScore()).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getScoreIcon(_calculateAverageScore()),
                color: _getScoreColor(_calculateAverageScore()),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Score global: ${_calculateAverageScore().toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _getScoreColor(_calculateAverageScore()),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateAverageScore() {
    return (performance.acceptanceRate +
        performance.completionRate +
        performance.onTimeRate +
        performance.satisfactionRate +
        (100 - performance.cancellationRate)) / 5;
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.emoji_events;
    if (score >= 60) return Icons.thumb_up;
    return Icons.trending_up;
  }
}

/// Graphique en barres pour les heures de pointe
class PeakHoursBarChart extends StatelessWidget {
  final List<PeakHour> peakHours;

  const PeakHoursBarChart({
    super.key,
    required this.peakHours,
  });

  @override
  Widget build(BuildContext context) {
    if (peakHours.isEmpty) {
      return const Center(
        child: Text('Pas de données disponibles'),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxCount = peakHours.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxCount == 0 ? 10.0 : maxCount.toDouble() * 1.2;

    return SizedBox(
      height: context.r.dp(180),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: effectiveMax,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => isDark ? Colors.grey.shade800 : Colors.white,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex < 0 || groupIndex >= peakHours.length) return null;
                final peak = peakHours[groupIndex];
                return BarTooltipItem(
                  '${peak.label}\n${peak.count} livraisons',
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= peakHours.length) return const SizedBox();
                  
                  // N'afficher que certains labels
                  if (peakHours.length > 12 && index % 3 != 0) return const SizedBox();
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      peakHours[index].hour,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: effectiveMax / 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: effectiveMax / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: peakHours.asMap().entries.map((entry) {
            final index = entry.key;
            final peak = entry.value;
            final isPeak = peak.count == maxCount && maxCount > 0;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: peak.count.toDouble(),
                  color: isPeak ? Colors.orange : Colors.blue,
                  width: peakHours.length > 12 ? 8 : 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: effectiveMax,
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }
}

/// Widget de carte animée pour les KPIs
class AnimatedStatCard extends StatefulWidget {
  final String title;
  final double value;
  final String? suffix;
  final IconData icon;
  final Color color;
  final double? previousValue;
  final bool isPercentage;
  final bool isCurrency;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    this.suffix,
    required this.icon,
    required this.color,
    this.previousValue,
    this.isPercentage = false,
    this.isCurrency = false,
  });

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: oldWidget.value,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculer la tendance
    double? trend;
    if (widget.previousValue != null && widget.previousValue! > 0) {
      trend = ((widget.value - widget.previousValue!) / widget.previousValue!) * 100;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.1),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trend >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: trend >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: trend >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatValue(_animation.value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (widget.suffix != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        widget.suffix!,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    if (widget.isCurrency) {
      return NumberFormat("#,##0").format(value);
    }
    if (widget.isPercentage) {
      return value.toStringAsFixed(1);
    }
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

/// Widget de comparaison période vs période
class PeriodComparisonWidget extends StatelessWidget {
  final String currentLabel;
  final String previousLabel;
  final double currentValue;
  final double previousValue;
  final String unit;
  final bool isCurrency;

  const PeriodComparisonWidget({
    super.key,
    required this.currentLabel,
    required this.previousLabel,
    required this.currentValue,
    required this.previousValue,
    this.unit = '',
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final change = previousValue > 0 
        ? ((currentValue - previousValue) / previousValue) * 100 
        : 0.0;
    final isPositive = change >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
        children: [
          Row(
            children: [
              Expanded(
                child: _buildComparisonItem(
                  label: currentLabel,
                  value: currentValue,
                  isHighlighted: true,
                  isDark: isDark,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildComparisonItem(
                  label: previousLabel,
                  value: previousValue,
                  isHighlighted: false,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem({
    required String label,
    required double value,
    required bool isHighlighted,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isCurrency 
              ? '${NumberFormat("#,##0").format(value)} $unit'
              : '${value.toStringAsFixed(value == value.truncateToDouble() ? 0 : 1)} $unit',
          style: TextStyle(
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            fontSize: isHighlighted ? 18 : 16,
            color: isHighlighted 
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white60 : Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
