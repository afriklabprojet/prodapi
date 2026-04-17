import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/domain/enums/order_status.dart';
import '../../../orders/presentation/extensions/order_status_l10n.dart';
import '../../../prescriptions/data/models/prescription_model.dart';

/// Carte d'action requise avec compteur bien visible
class ActionRequiredCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionRequiredCard({
    super.key,
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Material(
      color: isDark ? AppColors.cardColor(context) : Colors.white,
      borderRadius: BorderRadius.circular(UIConstants.spacingMD),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UIConstants.spacingMD),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UIConstants.spacingMD),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: UIConstants.minTouchTargetIOS,
                height: UIConstants.minTouchTargetIOS,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: UIConstants.spacingMD),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte commande récente
class RecentOrderCard extends StatelessWidget {
  final String orderNumber;
  final String customerName;
  final OrderStatus status;
  final double total;
  final DateTime createdAt;
  final VoidCallback onTap;

  const RecentOrderCard({
    super.key,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Semantics(
      button: true,
      label:
          'Commande $orderNumber, $customerName, ${status.localizedLabel}, ${NumberFormat('#,###', 'fr_FR').format(total)} FCFA',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(status.icon, color: status.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customerName,
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat('#,###', 'fr_FR').format(total)} F',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status.color.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.localizedLabel,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte ordonnance récente
class RecentPrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  final VoidCallback onTap;

  const RecentPrescriptionCard({
    super.key,
    required this.prescription,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final customerName = prescription.customer?['name']?.toString() ?? 'Client';
    final statusColor = _getFulfillmentColor(prescription.fulfillmentStatus);
    final statusLabel = _getFulfillmentLabel(prescription.fulfillmentStatus);
    final date = DateFormat(
      'dd/MM/yyyy',
      'fr_FR',
    ).format(DateTime.parse(prescription.createdAt));

    return Material(
      color: AppColors.cardColor(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    prescription.status,
                  ).withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medical_services_rounded,
                  color: _getStatusColor(prescription.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordonnance #${prescription.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$customerName • $date',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        prescription.status,
                      ).withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getPrescriptionStatusLabel(prescription.status),
                      style: TextStyle(
                        color: _getStatusColor(prescription.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (prescription.fulfillmentStatus != 'none') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'validated':
      case 'quoted':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPrescriptionStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'validated':
        return 'Validée';
      case 'quoted':
        return 'Devis envoyé';
      case 'rejected':
        return 'Rejetée';
      default:
        return status;
    }
  }

  Color _getFulfillmentColor(String fulfillmentStatus) {
    switch (fulfillmentStatus) {
      case 'fully_dispensed':
        return Colors.green;
      case 'partially_dispensed':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getFulfillmentLabel(String fulfillmentStatus) {
    switch (fulfillmentStatus) {
      case 'fully_dispensed':
        return 'Délivrée ✓';
      case 'partially_dispensed':
        return 'Partielle';
      default:
        return '';
    }
  }
}
