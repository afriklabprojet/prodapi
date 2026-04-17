import 'package:flutter/material.dart';

/// Raccourcis pour les opérateurs de paiement mobile.
class OperatorShortcuts extends StatelessWidget {
  final Function(String method) onOperatorSelected;

  const OperatorShortcuts({super.key, required this.onOperatorSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _OperatorIcon(
            label: 'Orange Money',
            color: Colors.orange,
            method: 'orange_money',
            onTap: onOperatorSelected,
          ),
          _OperatorIcon(
            label: 'MTN MoMo',
            color: Colors.yellow.shade700,
            method: 'mtn_momo',
            onTap: onOperatorSelected,
          ),
          _OperatorIcon(
            label: 'Wave',
            color: Colors.blue,
            method: 'wave',
            onTap: onOperatorSelected,
          ),
          _OperatorIcon(
            label: 'Carte',
            color: Colors.indigo,
            method: 'card',
            onTap: onOperatorSelected,
          ),
        ],
      ),
    );
  }
}

class _OperatorIcon extends StatelessWidget {
  final String label;
  final Color color;
  final String method;
  final Function(String) onTap;

  const _OperatorIcon({
    required this.label,
    required this.color,
    required this.method,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(method),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
