import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import 'stock_alert_model.dart';

/// Carte d'alerte individuelle
class StockAlertCard extends StatelessWidget {
  final StockAlert alert;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback onAction;

  const StockAlertCard({
    super.key,
    required this.alert,
    required this.onTap,
    required this.onDismiss,
    required this.onAction,
  });

  Color get _alertColor {
    switch (alert.type) {
      case StockAlertType.critical:
        return Colors.red;
      case StockAlertType.low:
        return Colors.orange;
      case StockAlertType.expiring:
        return Colors.orange;
      case StockAlertType.expired:
        return Colors.red.shade900;
    }
  }

  Color _alertBgColor(BuildContext context) {
    final isDark = AppColors.isDark(context);
    switch (alert.type) {
      case StockAlertType.critical:
        return isDark
            ? Colors.red.withValues(alpha: 0.2)
            : Colors.red.withValues(alpha: 0.1);
      case StockAlertType.low:
        return isDark
            ? Colors.orange.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.1);
      case StockAlertType.expiring:
        return isDark
            ? Colors.orange.withValues(alpha: 0.15)
            : Colors.orange.shade50;
      case StockAlertType.expired:
        return isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50;
    }
  }

  IconData get _alertIcon {
    switch (alert.type) {
      case StockAlertType.critical:
        return Icons.error;
      case StockAlertType.low:
        return Icons.trending_down;
      case StockAlertType.expiring:
        return Icons.schedule;
      case StockAlertType.expired:
        return Icons.event_busy;
    }
  }

  String get _alertTitle {
    switch (alert.type) {
      case StockAlertType.critical:
        return 'Rupture de stock';
      case StockAlertType.low:
        return 'Stock bas';
      case StockAlertType.expiring:
        return 'Expiration proche';
      case StockAlertType.expired:
        return 'Produit expiré';
    }
  }

  String get _alertSubtitle {
    switch (alert.type) {
      case StockAlertType.critical:
        return 'Stock à 0';
      case StockAlertType.low:
        return '${alert.currentStock} restants (seuil: ${alert.threshold})';
      case StockAlertType.expiring:
        final days =
            alert.expirationDate?.difference(DateTime.now()).inDays ?? 0;
        return 'Expire dans $days jours';
      case StockAlertType.expired:
        final days = DateTime.now().difference(alert.expirationDate!).inDays;
        return 'Expiré depuis $days jours';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final semanticLabel =
        '${alert.isRead ? "" : "Nouvelle alerte: "}'
        '$_alertTitle pour ${alert.productName}. $_alertSubtitle. '
        'Appuyer pour voir les détails, glisser vers la gauche pour ignorer.';

    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      child: Dismissible(
        key: Key(alert.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.visibility_off, color: Colors.white),
        ),
        child: Material(
          color: AppColors.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: alert.isRead
                      ? (isDark ? Colors.grey.shade700 : Colors.grey.shade200)
                      : _alertColor.withValues(alpha: 0.3),
                  width: alert.isRead ? 1 : 2,
                ),
                boxShadow: alert.isRead
                    ? null
                    : [
                        BoxShadow(
                          color: _alertColor.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Alert icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _alertBgColor(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_alertIcon, color: _alertColor, size: 24),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              if (!alert.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: _alertColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  _alertTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _alertColor,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alert.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _alertSubtitle,
                            style: TextStyle(
                              color: AppColors.textColor(
                                context,
                              ).withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),

                    // Action button
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textColor(
                          context,
                        ).withValues(alpha: 0.4),
                      ),
                      onPressed: onAction,
                      tooltip: 'Voir les détails',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter chip for stock alerts
class StockAlertFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const StockAlertFilterChip({
    super.key,
    required this.label,
    required this.count,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label, $count alertes${isSelected ? ", sélectionné" : ""}',
      onTap: onTap,
      child: Material(
        color: isSelected
            ? (color ?? Theme.of(context).colorScheme.primary)
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textColor(context).withValues(alpha: 0.8),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : (isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textColor(
                                context,
                              ).withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Summary card for stock alert counts
class StockAlertSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final Color backgroundColor;

  const StockAlertSummaryCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: iconColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action tile for stock alert bottom sheets
class StockAlertActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const StockAlertActionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
