import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../../../core/presentation/widgets/app_error_state.dart';
import '../../../../core/presentation/widgets/skeleton_screens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/prescription_provider.dart';

import '../../data/models/prescription_model.dart';
import 'package:intl/intl.dart';

class PrescriptionsListPage extends ConsumerWidget {
  /// When false, hides the page title row (used when embedded inside ActivityPage).
  final bool showActivityHeader;

  const PrescriptionsListPage({super.key, this.showActivityHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prescriptionListProvider);
    final notifier = ref.read(prescriptionListProvider.notifier);
    final filtered = notifier.filteredPrescriptions;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.cardColor(context),
              padding: const EdgeInsets.only(top: 16, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header amélioré avec icône — masqué quand intégré dans ActivityPage
                  if (showActivityHeader)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Icône avec fond dégradé
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade600,
                                  Colors.purple.shade300,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.purple.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Titre et sous-titre
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mes Ordonnances',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Demandes de médicaments sur ordonnance',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Notification
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[50],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Consumer(
                                builder: (context, ref, child) {
                                  final unreadCount = ref.watch(
                                    unreadNotificationCountProvider,
                                  );
                                  return Badge(
                                    isLabelVisible: unreadCount > 0,
                                    backgroundColor: Colors.redAccent,
                                    label: Text('$unreadCount'),
                                    child: Icon(
                                      Icons.notifications_none_rounded,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      size: 28,
                                    ),
                                  );
                                },
                              ),
                              onPressed: () => context.push('/notifications'),
                              tooltip: 'Notifications',
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (showActivityHeader) const SizedBox(height: 20),
                  // Filtres défilants
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Toutes',
                          isActive: state.activeFilter == 'all',
                          onTap: () => notifier.setFilter('all'),
                        ),
                        const SizedBox(width: 12),
                        _FilterChip(
                          label: 'En attente',
                          isActive: state.activeFilter == 'pending',
                          onTap: () => notifier.setFilter('pending'),
                        ),
                        const SizedBox(width: 12),
                        _FilterChip(
                          label: 'Validées',
                          isActive: state.activeFilter == 'validated',
                          onTap: () => notifier.setFilter('validated'),
                        ),
                        const SizedBox(width: 12),
                        _FilterChip(
                          label: 'Refusées',
                          isActive:
                              state.activeFilter ==
                              'rejected', // Ajout d'un filtre manquant souvent utile
                          onTap: () => notifier.setFilter('rejected'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? Colors.grey[800] : const Color(0xFFF0F0F0),
                  ),
                ],
              ),
            ),

            // Corps de la liste
            Expanded(child: _buildBody(context, state, filtered, ref, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PrescriptionListState state,
    List<PrescriptionModel> prescriptions,
    WidgetRef ref,
    bool isDark,
  ) {
    if (state.status == PrescriptionStatus.loading) {
      return SkeletonListBuilder.prescriptions();
    }

    if (state.status == PrescriptionStatus.error) {
      return AppErrorState.loadFailed(
        onRetry: () =>
            ref.read(prescriptionListProvider.notifier).getPrescriptions(),
        what: 'les ordonnances',
      );
    }

    if (prescriptions.isEmpty) {
      return AppEmptyState.prescriptions(
        onRefresh: () =>
            ref.read(prescriptionListProvider.notifier).getPrescriptions(),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      backgroundColor: AppColors.cardColor(context),
      onRefresh: () =>
          ref.read(prescriptionListProvider.notifier).getPrescriptions(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = prescriptions[index];
          return Semantics(
            button: true,
            label:
                'Ordonnance numéro ${prescription.id}, client ${prescription.customer?['name'] ?? 'Inconnu'}, statut ${_getStatusLabel(prescription.status)}',
            child: _PrescriptionCard(
              prescription: prescription,
              onTap: () {
                context.push('/prescription-details', extra: prescription);
              },
            ),
          );
        },
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'en attente';
      case 'quoted':
        return 'devis envoyé';
      case 'accepted':
        return 'accepté';
      case 'rejected':
        return 'refusé';
      case 'completed':
        return 'terminé';
      default:
        return status;
    }
  }
}

class _PrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  final VoidCallback onTap;

  const _PrescriptionCard({required this.prescription, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF8D8D8D).withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : ID + Statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[800]
                            : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${prescription.id}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (prescription.isDuplicate) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.content_copy,
                              color: Colors.red,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'DOUBLON',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    _StatusBadge(status: prescription.status),
                  ],
                ),
                const SizedBox(height: 20),

                // Informations Client
                Row(
                  children: [
                    Hero(
                      tag: 'prescription_icon_${prescription.id}',
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        prescription.customer?['name'] ?? 'Client Inconnu',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isDark ? Colors.white : null,
                            ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Date et Heure
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[800]
                            : const Color(0xFFF5F7FA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        size: 20,
                        color: isDark
                            ? Colors.grey[400]
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      DateFormat('dd MMM yyyy • HH:mm', 'fr').format(
                        DateTime.tryParse(prescription.createdAt) ??
                            DateTime.now(),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.grey[400]
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Semantics(
      button: true,
      selected: isActive,
      label: '$label${isActive ? ", sélectionné" : ""}',
      child: AnimatedScale(
        scale: isActive ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).primaryColor
                  : (isDark ? AppColors.cardColor(context) : Colors.white),
              borderRadius: BorderRadius.circular(30),
              border: isActive
                  ? Border.all(color: Colors.transparent)
                  : Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 1.5,
                    ),
              boxShadow: isActive && !isDark
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = AppColors.warning; // Amber 700
        label = 'En attente';
        break;
      case 'validated':
        color = AppColors.primary; // Green 800
        label = 'Validée';
        break;
      case 'rejected':
        color = AppColors.urgent; // Red 800
        label = 'Refusée';
        break;
      default:
        color = Colors.grey[700]!;
        label = status;
    }

    return Semantics(
      label: 'Statut de l\'ordonnance: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
