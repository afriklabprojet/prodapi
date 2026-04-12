import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A reusable section card with icon header for order and prescription details.
class OrderSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool isDark;

  const OrderSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? AppColors.darkCard : Colors.white,
      elevation: isDark ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isDark ? Colors.blue[300] : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A reusable info row for displaying label-value pairs.
class OrderInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isDark;

  const OrderInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
