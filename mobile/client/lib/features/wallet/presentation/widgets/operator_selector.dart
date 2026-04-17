import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class OperatorSelector extends StatelessWidget {
  final String? selectedOperator;
  final ValueChanged<String> onSelected;

  const OperatorSelector({
    super.key,
    required this.selectedOperator,
    required this.onSelected,
  });

  static const operators = [
    _Operator('orange', 'Orange Money', Icons.phone_android, AppColors.operatorOrange),
    _Operator('mtn', 'MTN Mobile Money', Icons.phone_android, AppColors.operatorMtn),
    _Operator('moov', 'Moov Money', Icons.phone_android, AppColors.operatorMoov),
    _Operator('wave', 'Wave', Icons.phone_android, AppColors.operatorWave),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opérateur',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...operators.map((op) => _buildOperatorTile(context, op)),
      ],
    );
  }

  Widget _buildOperatorTile(BuildContext context, _Operator op) {
    final isSelected = selectedOperator == op.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.05)
            : Theme.of(context).cardColor,
      ),
      child: InkWell(
        onTap: () => onSelected(op.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: op.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(op.icon, color: op.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  op.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
              else
                Icon(Icons.circle_outlined, color: AppColors.textHint, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _Operator {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const _Operator(this.id, this.label, this.icon, this.color);
}
