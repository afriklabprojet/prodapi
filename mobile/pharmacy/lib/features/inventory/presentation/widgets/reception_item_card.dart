import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/adaptive_picker.dart';
import '../../../../core/theme/app_colors.dart';
import 'reception_item.dart';

/// Carte d'un article de réception avec stepper de quantité et traçabilité.
class ReceptionItemCard extends StatefulWidget {
  const ReceptionItemCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
    required this.onEdit,
    required this.onLotChanged,
    required this.onExpiryChanged,
  });

  final ReceptionItem item;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<int> onEdit;
  final ValueChanged<String?> onLotChanged;
  final ValueChanged<DateTime?> onExpiryChanged;

  @override
  State<ReceptionItemCard> createState() => _ReceptionItemCardState();
}

class _ReceptionItemCardState extends State<ReceptionItemCard> {
  late final TextEditingController _ctrl;
  late final TextEditingController _lotCtrl;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.quantityToAdd.toString());
    _lotCtrl = TextEditingController(text: widget.item.lotNumber ?? '');
  }

  @override
  void didUpdateWidget(covariant ReceptionItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = widget.item.quantityToAdd.toString();
    if (_ctrl.text != newText) {
      _ctrl.text = newText;
    }
    if (_lotCtrl.text != (widget.item.lotNumber ?? '')) {
      _lotCtrl.text = widget.item.lotNumber ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _lotCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await AdaptivePicker.showDate(
      context: context,
      initialDate: widget.item.expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
      helpText: 'Date d\'expiration',
    );
    if (picked != null) {
      widget.onExpiryChanged(picked);
    }
  }

  String _formatExpiry(DateTime? date) {
    if (date == null) return 'Non définie';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.item.product;
    final isDark = widget.isDark;
    final hasLotInfo = widget.item.lotNumber != null || widget.item.expiryDate != null;
    final isExpiringSoon = widget.item.isExpiringSoon;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpiringSoon
              ? Colors.orange.shade300
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          width: isExpiringSoon ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 12,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Stock: ${p.stockQuantity} → ${p.stockQuantity + widget.item.quantityToAdd}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.teal.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Lot/Expiry badges (compact view)
                      if (hasLotInfo && !_isExpanded) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (widget.item.lotNumber != null)
                              _InfoBadge(
                                icon: Icons.qr_code_2,
                                text: widget.item.lotNumber!,
                                color: Colors.blue,
                                isDark: isDark,
                              ),
                            if (widget.item.expiryDate != null)
                              _InfoBadge(
                                icon: Icons.event,
                                text: _formatExpiry(widget.item.expiryDate),
                                color: isExpiringSoon ? Colors.orange : Colors.green,
                                isDark: isDark,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Quantity stepper
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepButton(
                      icon: Icons.remove,
                      onTap: widget.item.quantityToAdd > 1
                          ? widget.onDecrement
                          : null,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 44,
                      child: TextField(
                        controller: _ctrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Colors.teal, width: 2),
                          ),
                        ),
                        onChanged: (v) {
                          final parsed = int.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            widget.onEdit(parsed);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    _StepButton(
                      icon: Icons.add,
                      onTap: widget.onIncrement,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(width: 8),

                // Expand/collapse button
                Semantics(
                  button: true,
                  label: _isExpanded ? 'Réduire les options' : 'Afficher les options de lot',
                  child: Material(
                    color: _isExpanded
                        ? Colors.teal.withValues(alpha: 0.1)
                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      borderRadius: BorderRadius.circular(6),
                      focusColor: Colors.teal.withValues(alpha: 0.3),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        child: Center(
                          child: Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                            color: _isExpanded ? Colors.teal : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Remove
                Semantics(
                  button: true,
                  label: 'Supprimer ce produit',
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: widget.onRemove,
                      borderRadius: BorderRadius.circular(6),
                      focusColor: Colors.red.withValues(alpha: 0.2),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        child: Center(
                          child: Icon(Icons.close,
                              size: 20,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expanded section: Lot + Expiry fields
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Traçabilité (optionnel)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Lot number
                      Expanded(
                        child: TextField(
                          controller: _lotCtrl,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: 'N° de lot',
                            labelStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            prefixIcon: Icon(
                              Icons.qr_code_2,
                              size: 18,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Colors.teal, width: 2),
                            ),
                          ),
                          onChanged: (v) =>
                              widget.onLotChanged(v.isEmpty ? null : v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Expiry date picker
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'Sélectionner la date d\'expiration',
                          value: _formatExpiry(widget.item.expiryDate),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: _pickExpiryDate,
                              borderRadius: BorderRadius.circular(10),
                              focusColor: Colors.teal.withValues(alpha: 0.2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: widget.item.expiryDate != null && isExpiringSoon
                                        ? Colors.orange
                                        : (isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade300),
                                    width: widget.item.expiryDate != null && isExpiringSoon
                                        ? 2
                                        : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      size: 18,
                                      color: widget.item.expiryDate != null
                                          ? (isExpiringSoon
                                              ? Colors.orange
                                              : Colors.green)
                                          : (isDark
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade500),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatExpiry(widget.item.expiryDate),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: widget.item.expiryDate != null
                                              ? (isDark
                                                  ? Colors.white
                                                  : Colors.black87)
                                              : (isDark
                                                  ? Colors.grey.shade500
                                                  : Colors.grey.shade500),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: isDark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isExpiringSoon && widget.item.expiryDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 14, color: Colors.orange.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'Ce lot expire bientôt (< 3 mois)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StepButton extends StatelessWidget {
  const _StepButton(
      {required this.icon, required this.onTap, required this.isDark});

  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = onTap != null
        ? Colors.teal.withValues(alpha: 0.1)
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade100);
    final iconColor = onTap != null
        ? Colors.teal
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: icon == Icons.add ? 'Augmenter la quantité' : 'Diminuer la quantité',
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          focusColor: Colors.teal.withValues(alpha: 0.3),
          highlightColor: Colors.teal.withValues(alpha: 0.2),
          splashColor: Colors.teal.withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
