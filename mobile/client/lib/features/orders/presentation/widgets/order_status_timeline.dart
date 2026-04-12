import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/order_entity.dart';

/// Widget affichant la timeline des statuts de commande
class OrderStatusTimeline extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;

  const OrderStatusTimeline({
    super.key,
    required this.order,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('dd/MM à HH:mm', 'fr_FR');
    final steps = _buildSteps(timeFormat);
    
    return Card(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Suivi de commande',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Badge paiement
                if (order.isPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Payé',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...steps.map((step) => _TimelineStep(
              title: step.title,
              subtitle: step.subtitle,
              isCompleted: step.isCompleted,
              isCurrent: step.isCurrent,
              isLast: step == steps.last,
              isCancelled: step.isCancelled,
              isDark: isDark,
            )),
          ],
        ),
      ),
    );
  }

  List<_StepData> _buildSteps(DateFormat timeFormat) {
    final List<_StepData> steps = [];
    final currentStatus = order.status;
    final isCancelled = currentStatus == OrderStatus.cancelled || 
                        currentStatus == OrderStatus.failed;

    // Étape 1: Commande passée
    steps.add(_StepData(
      title: 'Commande passée',
      subtitle: timeFormat.format(order.createdAt),
      isCompleted: true,
      isCurrent: currentStatus == OrderStatus.pending,
      isCancelled: false,
    ));

    // Étape 2: Confirmée
    final isConfirmedOrBeyond = _statusIndex(currentStatus) >= _statusIndex(OrderStatus.confirmed);
    steps.add(_StepData(
      title: 'Confirmée',
      subtitle: isConfirmedOrBeyond ? _getEstimatedTime(OrderStatus.confirmed, timeFormat) : 'En attente',
      isCompleted: _statusIndex(currentStatus) > _statusIndex(OrderStatus.confirmed) && !isCancelled,
      isCurrent: currentStatus == OrderStatus.confirmed,
      isCancelled: false,
    ));

    // Étape 3: En préparation
    final isPreparingOrBeyond = _statusIndex(currentStatus) >= _statusIndex(OrderStatus.preparing);
    steps.add(_StepData(
      title: 'En préparation',
      subtitle: isPreparingOrBeyond ? _getEstimatedTime(OrderStatus.preparing, timeFormat) : 'En attente',
      isCompleted: _statusIndex(currentStatus) > _statusIndex(OrderStatus.preparing) && !isCancelled,
      isCurrent: currentStatus == OrderStatus.preparing,
      isCancelled: false,
    ));

    // Étape 4: Prête
    final isReadyOrBeyond = _statusIndex(currentStatus) >= _statusIndex(OrderStatus.ready);
    steps.add(_StepData(
      title: 'Prête',
      subtitle: isReadyOrBeyond ? _getEstimatedTime(OrderStatus.ready, timeFormat) : 'En attente',
      isCompleted: _statusIndex(currentStatus) > _statusIndex(OrderStatus.ready) && !isCancelled,
      isCurrent: currentStatus == OrderStatus.ready,
      isCancelled: false,
    ));

    // Étape 5: En livraison
    final isDeliveringOrBeyond = _statusIndex(currentStatus) >= _statusIndex(OrderStatus.delivering);
    steps.add(_StepData(
      title: 'En livraison',
      subtitle: isDeliveringOrBeyond ? _getEstimatedTime(OrderStatus.delivering, timeFormat) : 'En attente',
      isCompleted: _statusIndex(currentStatus) > _statusIndex(OrderStatus.delivering) && !isCancelled,
      isCurrent: currentStatus == OrderStatus.delivering,
      isCancelled: false,
    ));

    // Étape 6: Livrée OU Annulée
    if (isCancelled) {
      final cancelTime = order.cancelledAt ?? DateTime.now();
      steps.add(_StepData(
        title: currentStatus == OrderStatus.cancelled ? 'Annulée' : 'Échouée',
        subtitle: timeFormat.format(cancelTime),
        isCompleted: false,
        isCurrent: true,
        isCancelled: true,
      ));
    } else {
      steps.add(_StepData(
        title: 'Livrée',
        subtitle: currentStatus == OrderStatus.delivered 
            ? (order.deliveredAt != null ? timeFormat.format(order.deliveredAt!) : 'Livré')
            : 'En attente',
        isCompleted: currentStatus == OrderStatus.delivered,
        isCurrent: currentStatus == OrderStatus.delivered,
        isCancelled: false,
      ));
    }

    return steps;
  }

  int _statusIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.delivering:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
      case OrderStatus.failed:
        return -1; // Spécial
    }
  }

  String _getEstimatedTime(OrderStatus status, DateFormat timeFormat) {
    // Estimation basée sur le temps depuis la création
    // En production, ces timestamps devraient venir de l'API
    final baseTime = order.createdAt;
    
    switch (status) {
      case OrderStatus.confirmed:
        return timeFormat.format(baseTime.add(const Duration(minutes: 2)));
      case OrderStatus.preparing:
        return timeFormat.format(baseTime.add(const Duration(minutes: 10)));
      case OrderStatus.ready:
        return timeFormat.format(baseTime.add(const Duration(minutes: 25)));
      case OrderStatus.delivering:
        return timeFormat.format(baseTime.add(const Duration(minutes: 30)));
      default:
        return '';
    }
  }
}

class _StepData {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final bool isCancelled;

  const _StepData({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
    this.isCancelled = false,
  });
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final bool isCancelled;
  final bool isDark;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    required this.isCancelled,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isCancelled 
        ? AppColors.error 
        : (isCompleted || isCurrent) 
            ? AppColors.success 
            : Colors.grey;
    
    final Color textColor = isDark ? Colors.white : AppColors.textPrimary;
    final Color subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          Column(
            children: [
              // Circle indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isCompleted || isCurrent) 
                      ? activeColor 
                      : (isDark ? Colors.grey[700] : Colors.grey[300]),
                  border: isCurrent && !isCompleted && !isCancelled
                      ? Border.all(color: AppColors.primary, width: 3)
                      : null,
                ),
                child: (isCompleted || isCurrent)
                    ? Icon(
                        isCancelled 
                            ? Icons.close 
                            : (isCompleted ? Icons.check : Icons.circle),
                        size: isCompleted ? 14 : 8,
                        color: Colors.white,
                      )
                    : null,
              ),
              // Connecting line (if not last)
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted 
                        ? AppColors.success 
                        : (isDark ? Colors.grey[700] : Colors.grey[300]),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: (isCompleted || isCurrent) ? FontWeight.bold : FontWeight.normal,
                      color: isCancelled 
                          ? AppColors.error 
                          : ((isCompleted || isCurrent) ? textColor : subtitleColor),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
