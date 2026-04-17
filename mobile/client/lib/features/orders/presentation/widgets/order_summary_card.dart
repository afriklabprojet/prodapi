import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../providers/delivery_fee_notifier.dart';

/// Widget affichant le résumé de la commande avec détail des frais
class OrderSummaryCard extends StatelessWidget {
  final List<CartItemEntity> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double paymentFee;
  final double total;
  final NumberFormat currencyFormat;
  final double? distanceKm;
  final bool isLoadingDeliveryFee;
  final String paymentMode;
  final SurgeInfo? surge;

  const OrderSummaryCard({
    super.key,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.serviceFee = 0,
    this.paymentFee = 0,
    required this.total,
    required this.currencyFormat,
    this.distanceKm,
    this.isLoadingDeliveryFee = false,
    this.paymentMode = 'cash',
    this.surge,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasServiceFee = serviceFee > 0;
    final bool hasPaymentFee = paymentFee > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé de la commande',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...items.map((item) => _buildItemRow(item)),
            const Divider(height: 24),
            _buildSummaryRow('Sous-total médicaments', subtotal),
            const SizedBox(height: 8),
            _buildDeliveryFeeRow(),
            if (hasServiceFee) ...[
              const SizedBox(height: 8),
              _buildServiceFeeRow(),
            ],
            if (hasPaymentFee) ...[
              const SizedBox(height: 8),
              _buildPaymentFeeRow(),
            ],
            const SizedBox(height: 8),
            _buildTotalRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryFeeRow() {
    final bool hasSurge = surge != null && surge!.active;
    final surgeColor = _getSurgeColor(surge?.level);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Frais de livraison'),
                  if (hasSurge) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: surgeColor.withAlpha(38),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up, size: 12, color: surgeColor),
                          const SizedBox(width: 2),
                          Text(
                            'x${surge!.multiplier.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: surgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (distanceKm != null || hasSurge)
                Text(
                  hasSurge
                      ? '${distanceKm?.toStringAsFixed(1) ?? "-"} km • Majoration ${_getSurgeLevelText(surge!.level)}'
                      : '${distanceKm!.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasSurge ? surgeColor : Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: isLoadingDeliveryFee
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                )
              : Text(
                  currencyFormat.format(deliveryFee),
                  textAlign: TextAlign.end,
                ),
        ),
      ],
    );
  }

  Widget _buildServiceFeeRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              const Text('Frais de service'),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Frais de la plateforme Dr Pharma',
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            currencyFormat.format(serviceFee),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentFeeRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              const Text('Frais de paiement'),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Frais de traitement du paiement en ligne',
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            currencyFormat.format(paymentFee),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // _buildPharmacyNote removed — was unused (flagged by flutter analyze)

  Widget _buildItemRow(CartItemEntity item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '${item.product.name} x${item.quantity}',
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(item.totalPrice),
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(currencyFormat.format(amount), textAlign: TextAlign.end),
        ),
      ],
    );
  }

  Widget _buildTotalRow() {
    return Row(
      children: [
        const Expanded(
          flex: 2,
          child: Text(
            'Total',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            currencyFormat.format(total),
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// Couleur selon le niveau de surge
  Color _getSurgeColor(String? level) {
    switch (level) {
      case 'low':
        return Colors.orange;
      case 'medium':
        return Colors.deepOrange;
      case 'high':
        return Colors.red;
      case 'extreme':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  /// Texte descriptif du niveau de surge
  String _getSurgeLevelText(String level) {
    switch (level) {
      case 'low':
        return 'légère';
      case 'medium':
        return 'moyenne';
      case 'high':
        return 'forte';
      case 'extreme':
        return 'très forte';
      default:
        return '';
    }
  }
}
