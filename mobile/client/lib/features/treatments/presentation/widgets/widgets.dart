import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/treatment_entity.dart';

/// Carte de traitement avec swipe-to-delete et animations
class TreatmentCard extends ConsumerStatefulWidget {
  final TreatmentEntity treatment;
  final VoidCallback? onTap;
  final VoidCallback? onOrder;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onReminderToggle;
  final int? animationDelay;

  const TreatmentCard({
    super.key,
    required this.treatment,
    this.onTap,
    this.onOrder,
    this.onDelete,
    this.onReminderToggle,
    this.animationDelay,
  });

  @override
  ConsumerState<TreatmentCard> createState() => _TreatmentCardState();
}

class _TreatmentCardState extends ConsumerState<TreatmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Démarrer l'animation avec un délai
    Future.delayed(Duration(milliseconds: widget.animationDelay ?? 0), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.onDelete != null
            ? Dismissible(
                key: ValueKey(widget.treatment.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await _confirmDelete(context);
                },
                background: _buildDismissBackground(),
                child: _buildCard(context),
              )
            : _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    final isUrgent =
        widget.treatment.isOverdue || widget.treatment.needsRenewalSoon;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isUrgent ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent
            ? BorderSide(
                color: widget.treatment.isOverdue
                    ? AppColors.error
                    : AppColors.warning,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: widget.onTap,
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
                  Hero(
                    tag: 'treatment_icon_${widget.treatment.id}',
                    child: Container(
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
                  ),
                  const SizedBox(width: 12),

                  // Nom et détails
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.treatment.productName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.treatment.dosage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.treatment.dosage!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (widget.treatment.frequency != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.treatment.frequency!,
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
                        color: widget.treatment.isOverdue
                            ? AppColors.error
                            : widget.treatment.needsRenewalSoon
                            ? AppColors.warning
                            : Colors.grey[600],
                        fontWeight: isUrgent
                            ? FontWeight.w600
                            : FontWeight.normal,
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
                    onPressed: () => widget.onReminderToggle?.call(
                      !widget.treatment.reminderEnabled,
                    ),
                    icon: Icon(
                      widget.treatment.reminderEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off_outlined,
                      color: widget.treatment.reminderEnabled
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                    tooltip: widget.treatment.reminderEnabled
                        ? 'Désactiver les rappels'
                        : 'Activer les rappels',
                  ),

                  const Spacer(),

                  // Bouton supprimer (si disponible)
                  if (widget.onDelete != null)
                    TextButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                    ),

                  const SizedBox(width: 8),

                  // Bouton commander
                  if (widget.onOrder != null)
                    ElevatedButton.icon(
                      onPressed: widget.onOrder,
                      icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                      label: const Text('Commander'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUrgent
                            ? AppColors.error
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
    if (widget.treatment.isOverdue) {
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

    if (widget.treatment.needsRenewalSoon) {
      final days = widget.treatment.daysUntilRenewal!;
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

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 32),
          SizedBox(height: 4),
          Text(
            'Supprimer',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getRenewalText(DateFormat dateFormat) {
    if (widget.treatment.nextRenewalDate == null) {
      return 'Date de renouvellement non définie';
    }

    final days = widget.treatment.daysUntilRenewal!;

    if (days < 0) {
      return 'Renouvellement en retard de ${-days} jour${-days > 1 ? 's' : ''}';
    } else if (days == 0) {
      return 'Renouvellement prévu aujourd\'hui';
    } else if (days == 1) {
      return 'Renouvellement prévu demain';
    } else {
      return 'Prochain renouvellement : ${dateFormat.format(widget.treatment.nextRenewalDate!)}';
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le traitement'),
        content: Text(
          'Voulez-vous vraiment supprimer "${widget.treatment.productName}" de vos traitements récurrents ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

/// Widget de chargement skeleton pour les traitements
class TreatmentCardSkeleton extends StatefulWidget {
  const TreatmentCardSkeleton({super.key});

  @override
  State<TreatmentCardSkeleton> createState() => _TreatmentCardSkeletonState();
}

class _TreatmentCardSkeletonState extends State<TreatmentCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: _animation.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 14,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Container(
                    height: 13,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 36,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 36,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Empty State pour les traitements
class TreatmentsEmptyState extends StatelessWidget {
  final VoidCallback? onAdd;

  const TreatmentsEmptyState({super.key, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun traitement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez votre premier traitement récurrent\npour ne jamais manquer un renouvellement',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (onAdd != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un traitement'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error State pour les traitements
class TreatmentsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const TreatmentsErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
