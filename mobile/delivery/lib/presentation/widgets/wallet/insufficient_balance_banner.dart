import 'package:flutter/material.dart';
import '../../../core/utils/number_formatter.dart';

/// Bannière d'avertissement quand le solde est insuffisant pour livrer.
class InsufficientBalanceBanner extends StatelessWidget {
  final num commissionAmount;

  const InsufficientBalanceBanner({super.key, required this.commissionAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Solde insuffisant pour livrer. Rechargez au moins ${commissionAmount.formatCurrency()}.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
