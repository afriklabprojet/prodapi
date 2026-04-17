import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../core/utils/phone_masker.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/enums/order_status.dart';
import '../extensions/order_status_l10n.dart';

/// Carte de commande améliorée avec animations et actions
class EnhancedOrderCard extends StatefulWidget {
  final OrderEntity order;
  final VoidCallback? onTap;

  /// Callback async pour confirmer - retourne true si succès
  final Future<bool> Function()? onConfirm;

  /// Callback sync pour rejeter (ouvre un dialogue)
  final VoidCallback? onReject;

  /// Callback async pour marquer prête - retourne true si succès
  final Future<bool> Function()? onMarkReady;

  const EnhancedOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onConfirm,
    this.onReject,
    this.onMarkReady,
  });

  @override
  State<EnhancedOrderCard> createState() => _EnhancedOrderCardState();
}

class _EnhancedOrderCardState extends State<EnhancedOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _statusColor {
    if (widget.order.status == OrderStatus.pending && !widget.order.isPaid) {
      return Colors.red.shade400;
    }
    return widget.order.status.color;
  }

  StatusType get _statusType {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return widget.order.isPaid ? StatusType.pending : StatusType.error;
      case OrderStatus.confirmed:
        return StatusType.info;
      case OrderStatus.ready:
        return StatusType.success;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return StatusType.error;
      default:
        return StatusType.neutral;
    }
  }

  String get _statusLabel {
    if (widget.order.status == OrderStatus.pending && !widget.order.isPaid) {
      return 'Non payée';
    }
    return widget.order.status.localizedLabel;
  }

  bool get _showActions {
    if (widget.order.status == OrderStatus.pending) return widget.order.isPaid;
    if (widget.order.status == OrderStatus.confirmed) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_CI',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryLight = primaryColor.withValues(alpha: 0.1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return Semantics(
      button: true,
      label:
          'Commande ${widget.order.reference}, ${widget.order.customerName}, $_statusLabel, ${currencyFormat.format(widget.order.totalAmount)}. Appuyer pour voir les détails, maintenir pour plus d\'options.',
      onTap: widget.onTap,
      onLongPress: () => setState(() => _isExpanded = !_isExpanded),
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          setState(() => _isExpanded = !_isExpanded);
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // En-tête de la carte
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: _statusColor, width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne du haut: Référence + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Hero(
                                tag: 'order_icon_${widget.order.id}',
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${widget.order.reference}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(widget.order.createdAt),
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          StatusBadge(label: _statusLabel, type: _statusType),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Infos client
                      Row(
                        children: [
                          UserAvatar(name: widget.order.customerName, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.order.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 14,
                                      color: secondaryTextColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      PhoneMasker.mask(
                                        widget.order.customerPhone,
                                      ),
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(widget.order.totalAmount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryColor,
                                ),
                              ),
                              if (widget.order.items != null)
                                Text(
                                  '${widget.order.items!.length} article(s)',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              // Payment status indicator for unpaid orders
                              if (widget.order.isPendingUnpaid)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.payment_rounded,
                                        size: 12,
                                        color: Colors.red.shade600,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Non payé',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Banner for unpaid pending orders
                if (widget.order.isPendingUnpaid)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          size: 16,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'En attente de paiement',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Section d'actions (expandable)
                if (_showActions)
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: _buildActionsSection(),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),

                // Bouton pour montrer/cacher les actions
                if (_showActions)
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isExpanded
                                ? 'Masquer les actions'
                                : 'Voir les actions',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    final status = widget.order.status;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 12),
          if (status == OrderStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: AsyncSmallButton(
                    label: 'Confirmer',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    onPressed: widget.onConfirm,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SyncActionButton(
                    label: 'Refuser',
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                    isOutlined: true,
                    onTap: widget.onReject,
                  ),
                ),
              ],
            ),
          ] else if (status == OrderStatus.confirmed) ...[
            AsyncSmallButton(
              label: 'Marquer comme prête',
              icon: Icons.inventory_2_outlined,
              color: Colors.blue,
              onPressed: widget.onMarkReady,
              isFullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier à ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM à HH:mm').format(date);
    }
  }
}

/// Bouton d'action synchrone (pour actions qui ouvrent un dialogue)
class _SyncActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isOutlined;

  const _SyncActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOutlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isOutlined ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isOutlined ? color : Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isOutlined ? color : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
