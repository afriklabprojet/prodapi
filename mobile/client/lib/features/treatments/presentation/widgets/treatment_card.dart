import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/treatment_entity.dart';

/// Carte affichant un traitement récurrent
class TreatmentCard extends StatelessWidget {
  final TreatmentEntity treatment;
  final VoidCallback? onTap;
  final VoidCallback? onOrder;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onReminderToggle;

  const TreatmentCard({
    super.key,
    required this.treatment,
    this.onTap,
    this.onOrder,
    this.onDelete,
    this.onReminderToggle,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    final isUrgent = treatment.isOverdue || treatment.needsRenewalSoon;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isUrgent ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent
            ? BorderSide(
                color: treatment.isOverdue ? AppColors.error : AppColors.warning,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec nom et badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône médicament
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medication_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Nom et détails
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          treatment.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (treatment.dosage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            treatment.dosage!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (treatment.frequency != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            treatment.frequency!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Badge statut
                  _buildStatusBadge(),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Informations de renouvellement
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getRenewalText(dateFormat),
                      style: TextStyle(
                        fontSize: 13,
                        color: treatment.isOverdue
                            ? AppColors.error
                            : treatment.needsRenewalSoon
                                ? AppColors.warning
                                : Colors.grey[600],
                        fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Actions
              Row(
                children: [
                  // Toggle rappel
                  IconButton(
                    onPressed: () => onReminderToggle?.call(!treatment.reminderEnabled),
                    icon: Icon(
                      treatment.reminderEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off_outlined,
                      color: treatment.reminderEnabled
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                    tooltip: treatment.reminderEnabled
                        ? 'Désactiver les rappels'
                        : 'Activer les rappels',
                  ),
                  
                  const Spacer(),
                  
                  // Bouton supprimer
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // Bouton commander
                  if (onOrder != null)
                    ElevatedButton.icon(
                      onPressed: onOrder,
                      icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                      label: const Text('Commander'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUrgent ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (treatment.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, size: 14, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              'En retard',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    }
    
    if (treatment.needsRenewalSoon) {
      final days = treatment.daysUntilRenewal!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          days == 0 ? 'Aujourd\'hui' : 'Dans $days j',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.warning,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  String _getRenewalText(DateFormat dateFormat) {
    if (treatment.nextRenewalDate == null) {
      return 'Date de renouvellement non définie';
    }
    
    final days = treatment.daysUntilRenewal!;
    
    if (days < 0) {
      return 'Renouvellement en retard de ${-days} jour${-days > 1 ? 's' : ''}';
    } else if (days == 0) {
      return 'Renouvellement prévu aujourd\'hui';
    } else if (days == 1) {
      return 'Renouvellement prévu demain';
    } else {
      return 'Prochain renouvellement : ${dateFormat.format(treatment.nextRenewalDate!)}';
    }
  }
}
