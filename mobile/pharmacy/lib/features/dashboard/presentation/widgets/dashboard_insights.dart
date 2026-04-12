import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dashboard_tab_provider.dart';
import '../providers/week_stats_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Bannière d'insights rapides avec chips
class DashboardInsightsBanner extends ConsumerWidget {
  const DashboardInsightsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = AppColors.isDark(context);
    final statsAsync = ref.watch(weekStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) {
        debugPrint('[HomeDashboard] Insights banner error: $error');
        return const SizedBox.shrink();
      },
      data: (stats) {
        if (stats.thisWeekOrders == 0 &&
            stats.criticalProductsCount == 0 &&
            stats.peakDayLabel == null) {
          return const SizedBox.shrink();
        }

        final trendUp = stats.trendPercent != null && stats.trendPercent! >= 0;
        final chips = <_InsightChipData>[];

        if (stats.trendPercent != null) {
          chips.add(
            _InsightChipData(
              icon: trendUp
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              label:
                  '${trendUp ? '+' : ''}${stats.trendPercent}% ${l10n.thisWeek}',
              color: trendUp ? Colors.green : Colors.orange,
            ),
          );
        } else if (stats.thisWeekOrders > 0) {
          chips.add(
            _InsightChipData(
              icon: Icons.shopping_bag_rounded,
              label: l10n.ordersThisWeek(stats.thisWeekOrders),
              color: Colors.blue,
            ),
          );
        }

        if (stats.criticalProductsCount > 0) {
          final n = stats.criticalProductsCount;
          chips.add(
            _InsightChipData(
              icon: Icons.warning_amber_rounded,
              label: l10n.criticalProducts(n),
              color: Colors.deepOrange,
              onTap: () {
                ref.read(dashboardTabProvider.notifier).state = 2;
              },
            ),
          );
        }

        if (stats.expiringProductsCount > 0) {
          final n = stats.expiringProductsCount;
          chips.add(
            _InsightChipData(
              icon: Icons.schedule_rounded,
              label: l10n.expiringSoon(n),
              color: Colors.amber.shade700,
              onTap: () {
                ref.read(dashboardTabProvider.notifier).state = 2;
              },
            ),
          );
        }

        if (stats.expiredProductsCount > 0) {
          final n = stats.expiredProductsCount;
          chips.add(
            _InsightChipData(
              icon: Icons.error_rounded,
              label: l10n.expiredProducts(n),
              color: Colors.red,
              onTap: () {
                ref.read(dashboardTabProvider.notifier).state = 2;
              },
            ),
          );
        }

        if (stats.peakDayLabel != null) {
          chips.add(
            _InsightChipData(
              icon: Icons.bar_chart_rounded,
              label: l10n.peakDay(stats.peakDayLabel!),
              color: Colors.purple,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: isDark
                        ? Colors.amber.shade300
                        : Colors.amber.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.quickView,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips
                    .map((c) => _InsightChipWidget(chip: c, isDark: isDark))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InsightChipWidget extends StatelessWidget {
  final _InsightChipData chip;
  final bool isDark;

  const _InsightChipWidget({required this.chip, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: chip.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: chip.color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: chip.color.withValues(alpha: isDark ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(chip.icon, size: 14, color: chip.color),
              const SizedBox(width: 6),
              Text(
                chip.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: chip.color,
                ),
              ),
              if (chip.onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: chip.color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightChipData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _InsightChipData({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
}
