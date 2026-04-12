import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Banner displaying the fulfillment status of a prescription.
/// Shows whether the prescription has been fully, partially, or never dispensed.
class FulfillmentStatusBanner extends StatelessWidget {
  final String fulfillmentStatus;
  final int dispensingCount;
  final String? firstDispensedAt;

  const FulfillmentStatusBanner({
    super.key,
    required this.fulfillmentStatus,
    this.dispensingCount = 0,
    this.firstDispensedAt,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (fulfillmentStatus) {
      case 'full':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        icon = Icons.block;
        label = '🔴 ORDONNANCE ENTIÈREMENT DÉLIVRÉE';
        break;
      case 'partial':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        icon = Icons.warning_amber;
        label = '🟡 ORDONNANCE PARTIELLEMENT DÉLIVRÉE';
        break;
      default:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        icon = Icons.verified;
        label = '🟢 NOUVELLE ORDONNANCE — Jamais utilisée';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                if (dispensingCount > 0)
                  Text(
                    '$dispensingCount dispensation(s) • Première: ${firstDispensedAt != null ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse(firstDispensedAt!) ?? DateTime.now()) : "?"}',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
