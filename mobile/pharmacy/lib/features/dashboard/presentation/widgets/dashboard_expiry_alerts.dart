import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/responsive_builder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../inventory/presentation/providers/batch_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Widget d'alertes d'expiration pour le dashboard.
/// Affiche un résumé des lots expirés / critiques / à surveiller.
class DashboardExpiryAlerts extends ConsumerWidget {
  const DashboardExpiryAlerts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(expiryAlertSummaryProvider);
    final l10n = AppLocalizations.of(context);

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (!summary.hasAlerts) return const SizedBox.shrink();

        final isDark = AppColors.isDark(context);

        return ResponsiveBuilder(
          builder: (context, responsive) => Container(
            margin: EdgeInsets.fromLTRB(
              responsive.horizontalPadding,
              16,
              responsive.horizontalPadding,
              0,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _borderColor(summary).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _borderColor(summary).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: _borderColor(summary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.expiryAlerts,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _borderColor(summary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${summary.totalAlertCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (summary.expiredCount > 0)
                      _AlertChip(
                        label: l10n.expiredBatches(summary.expiredCount),
                        color: Colors.red,
                        icon: Icons.dangerous_rounded,
                      ),
                    if (summary.criticalCount > 0)
                      _AlertChip(
                        label: l10n.criticalBatches(summary.criticalCount),
                        color: Colors.orange,
                        icon: Icons.schedule_rounded,
                      ),
                    if (summary.warningCount > 0)
                      _AlertChip(
                        label: l10n.warningBatches(summary.warningCount),
                        color: Colors.amber.shade700,
                        icon: Icons.info_outline_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _borderColor(ExpiryAlertSummary summary) {
    if (summary.expiredCount > 0) return Colors.red;
    if (summary.criticalCount > 0) return Colors.orange;
    return Colors.amber.shade700;
  }
}

class _AlertChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _AlertChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
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
}
