import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/route_info.dart';
import '../common/eta_display.dart';
import 'delivery_communication.dart';

/// Header avec référence et statut de la commande
class DeliveryInfoHeader extends StatelessWidget {
  final Delivery delivery;

  const DeliveryInfoHeader({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commande #${delivery.reference}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      delivery.status,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(delivery.status),
                    style: TextStyle(
                      color: _getStatusColor(delivery.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Colors.blue,
                size: 28,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En Attente';
      case 'assigned':
        return 'Assignée - En route Pharma';
      case 'picked_up':
        return 'En Livraison - Vers Client';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }
}

/// Barre de progression horizontale (stepper) du statut
class DeliveryStepperBar extends StatelessWidget {
  final Delivery delivery;
  final RouteInfo? routeInfo;

  const DeliveryStepperBar({super.key, required this.delivery, this.routeInfo});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final status = delivery.status;

    const steps = [
      {
        'key': 'assigned',
        'label': 'Acceptée',
        'icon': Icons.check_circle_outline,
      },
      {
        'key': 'en_route_pharmacy',
        'label': 'En route',
        'icon': Icons.directions_car,
      },
      {'key': 'picked_up', 'label': 'Récupéré', 'icon': Icons.inventory_2},
      {
        'key': 'en_route_client',
        'label': 'En livraison',
        'icon': Icons.delivery_dining,
      },
      {'key': 'delivered', 'label': 'Livré', 'icon': Icons.done_all},
    ];

    int currentStepIndex;
    switch (status) {
      case 'pending':
        currentStepIndex = -1;
      case 'assigned':
      case 'accepted':
        currentStepIndex = 0;
      case 'picked_up':
        currentStepIndex = 2;
      case 'delivered':
        currentStepIndex = 4;
      case 'cancelled':
        currentStepIndex = -1;
      default:
        currentStepIndex = 0;
    }

    if ((status == 'assigned' || status == 'accepted') && routeInfo != null) {
      currentStepIndex = 1;
    }
    if (status == 'picked_up' && routeInfo != null) {
      currentStepIndex = 3;
    }
    if (status == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepBefore = i ~/ 2;
            final isCompleted = stepBefore < currentStepIndex;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green
                      : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            );
          }

          final stepIndex = i ~/ 2;
          final step = steps[stepIndex];
          final isCompleted = stepIndex <= currentStepIndex;
          final isCurrent = stepIndex == currentStepIndex;
          final color = isCompleted
              ? Colors.green
              : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 32 : 26,
                height: isCurrent ? 32 : 26,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Colors.green
                      : isCompleted
                      ? Colors.green.withValues(alpha: 0.15)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  border: isCompleted
                      ? Border.all(color: Colors.green, width: 2)
                      : null,
                ),
                child: Icon(
                  step['icon'] as IconData,
                  size: isCurrent ? 18 : 14,
                  color: isCurrent
                      ? Colors.white
                      : isCompleted
                      ? Colors.green
                      : color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step['label'] as String,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted
                      ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Section ETA (temps et distance estimés)
class DeliveryETASection extends StatelessWidget {
  final Delivery delivery;
  final RouteInfo? routeInfo;
  final bool isLoadingRoute;
  final VoidCallback onRefreshRoute;

  const DeliveryETASection({
    super.key,
    required this.delivery,
    this.routeInfo,
    required this.isLoadingRoute,
    required this.onRefreshRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final status = delivery.status;

    if (status == 'delivered' || status == 'cancelled') {
      return const SizedBox.shrink();
    }

    if (isLoadingRoute) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Calcul du trajet...'),
          ],
        ),
      );
    }

    if (routeInfo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == 'assigned' || status == 'accepted'
                    ? Icons.store
                    : Icons.person_pin_circle,
                size: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                status == 'assigned' || status == 'accepted'
                    ? 'Vers la pharmacie'
                    : 'Vers le client',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ETADisplayWidget(
            duration: routeInfo!.totalDuration,
            distance: routeInfo!.totalDistance,
            isCompact: false,
            showArrivalTime: true,
          ),
        ],
      );
    }

    return InkWell(
      onTap: onRefreshRoute,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Calculer le trajet',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Timeline pharmacie → client
class DeliveryTimeline extends StatelessWidget {
  final Delivery delivery;
  final DeliveryCommunicationHelper commHelper;

  const DeliveryTimeline({
    super.key,
    required this.delivery,
    required this.commHelper,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      children: [
        _buildTimelineItem(
          context: context,
          title: 'Pharmacie',
          name: delivery.pharmacyName,
          address: delivery.pharmacyAddress,
          icon: Icons.store_mall_directory_outlined,
          color: Colors.blue,
          phone: delivery.pharmacyPhone,
          lat: delivery.pharmacyLat,
          lng: delivery.pharmacyLng,
          isPharmacy: true,
          heroTag: DeliveryHeroTags.icon(delivery.id),
        ),
        Container(
          height: 30,
          margin: const EdgeInsets.only(left: 24),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 2,
              ),
            ),
          ),
        ),
        _buildTimelineItem(
          context: context,
          title: 'Client',
          name: delivery.customerName,
          address: delivery.deliveryAddress,
          icon: Icons.person_outline,
          color: Colors.orange,
          phone: delivery.customerPhone,
          lat: delivery.deliveryLat,
          lng: delivery.deliveryLng,
          isPharmacy: false,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required String title,
    required String name,
    required String address,
    required IconData icon,
    required Color color,
    required double? lat,
    required double? lng,
    String? phone,
    bool isPharmacy = false,
    String? heroTag,
  }) {
    final isDark = context.isDark;

    Widget iconWidget = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 24),
    );

    if (heroTag != null) {
      iconWidget = Hero(tag: heroTag, child: iconWidget);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [iconWidget]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (lat != null && lng != null)
                    SmallActionButton(
                      icon: Icons.navigation_outlined,
                      label: 'Y aller',
                      color: Colors.blue.shade700,
                      onTap: () => commHelper.launchMaps(lat, lng),
                    ),
                  if (phone != null && phone.isNotEmpty)
                    SmallActionButton(
                      icon: Icons.phone_outlined,
                      label: 'Appeler',
                      color: Colors.green.shade700,
                      onTap: () => commHelper.makePhoneCall(phone),
                    ),
                  if (phone != null && phone.isNotEmpty)
                    SmallActionButton(
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () => commHelper.openWhatsApp(
                        phone,
                        recipientName: name,
                        isPharmacy: isPharmacy,
                      ),
                    ),
                  if (phone != null && phone.isNotEmpty)
                    SmallActionButton(
                      icon: Icons.flash_on,
                      label: 'Rapide',
                      color: Colors.orange.shade700,
                      onTap: () => commHelper.showQuickMessages(
                        phone,
                        recipientName: name,
                        isPharmacy: isPharmacy,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Informations de paiement (frais, commission, gains estimés)
class DeliveryPaymentInfo extends StatelessWidget {
  final Delivery delivery;

  const DeliveryPaymentInfo({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isPending = delivery.status == 'pending';
    final deliveryFee = delivery.deliveryFee ?? 500;
    final commission = delivery.commission ?? 200;
    final estimatedEarnings =
        delivery.estimatedEarnings ?? (deliveryFee - commission);
    final distanceKm = delivery.distanceKm;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending
            ? (isDark
                  ? Colors.green.shade900.withValues(alpha: 0.3)
                  : Colors.green.shade50)
            : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? (isDark ? Colors.green.shade700 : Colors.green.shade200)
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total à la livraison:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '${delivery.totalAmount.toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.monetization_on,
                          color: Colors.green.shade700,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vos gains estimés',
                              style: TextStyle(
                                color: context.secondaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${estimatedEarnings.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                fontSize: context.r.sp(24),
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildEarningsRow(
                          context,
                          'Frais de livraison',
                          '+${deliveryFee.toStringAsFixed(0)} FCFA',
                          context.primaryText,
                        ),
                        const SizedBox(height: 6),
                        _buildEarningsRow(
                          context,
                          'Commission plateforme',
                          '-${commission.toStringAsFixed(0)} FCFA',
                          Colors.red.shade600,
                        ),
                        if (distanceKm != null) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          _buildEarningsRow(
                            context,
                            'Distance estimée',
                            '${distanceKm.toStringAsFixed(1)} km',
                            Colors.blue.shade700,
                            icon: Icons.straighten,
                          ),
                        ],
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

  Widget _buildEarningsRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor, {
    IconData? icon,
  }) {
    final isDark = context.isDark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Petit bouton d'action (Y aller, Appeler, WhatsApp, Rapide)
class SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const SmallActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tags Hero pour les transitions
class DeliveryHeroTags {
  static String icon(int deliveryId) => 'delivery_icon_$deliveryId';
}
