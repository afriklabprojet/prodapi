import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/global_search_sheet.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../on_call/presentation/providers/on_call_provider.dart';
import '../../../on_call/data/models/on_call_model.dart';

import '../../../orders/presentation/providers/order_list_provider.dart';
import '../../../orders/domain/enums/order_status.dart';
import '../../../prescriptions/presentation/providers/prescription_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import 'guard_summary_sheet.dart';

/// Header du dashboard avec salutation, pharmacie, notifications et mode garde.
class DashboardHeader extends ConsumerWidget {
  final String userName;
  final String pharmacyName;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.pharmacyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final onCallState = ref.watch(onCallProvider);
    final activeShift = _getActiveShift(onCallState.onCalls);
    final bool isOnCall = activeShift != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.local_pharmacy,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pharmacyName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Boutons recherche + notifications
              Row(
                children: [
                  // Bouton recherche globale
                  Semantics(
                    button: true,
                    label: 'Recherche globale. Appuyez pour chercher.',
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => showGlobalSearch(context),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton notifications
                  Semantics(
                    button: true,
                    label: unreadCount > 0
                        ? '$unreadCount notifications non lues. Appuyez pour voir.'
                        : 'Notifications. Aucune notification non lue.',
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/notifications');
                        },
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Badge(
                            isLabelVisible: unreadCount > 0,
                            label: Text(unreadCount.toString()),
                            backgroundColor: Colors.red,
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre info : date + Mode Garde
          Row(
            children: [
              // Date du jour
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(now),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Toggle Mode Garde
              _buildGuardToggle(context, ref, isOnCall, activeShift),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuardToggle(
    BuildContext context,
    WidgetRef ref,
    bool isOnCall,
    OnCallModel? activeShift,
  ) {
    return Material(
      color: isOnCall
          ? Colors.green.shade600.withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (isOnCall && activeShift != null) {
            _showEndGuardDialog(context, ref, activeShift);
          } else {
            context.push('/on-call');
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isOnCall
                ? Border.all(color: Colors.green.shade300, width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOnCall ? Icons.emergency : Icons.nightlight_round,
                color: Colors.white,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                isOnCall ? 'En garde' : 'Mode garde',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndGuardDialog(
    BuildContext context,
    WidgetRef ref,
    OnCallModel activeShift,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer la garde ?'),
        content: const Text('Voulez-vous arrêter votre garde en cours ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ended = DateTime.now();
              final success = await ref
                  .read(onCallProvider.notifier)
                  .deleteOnCall(activeShift.id);
              if (success && context.mounted) {
                // Construire les données du bilan
                final orders = ref.read(orderListProvider).orders;
                final prescriptions = ref
                    .read(prescriptionListProvider)
                    .prescriptions;
                final products = ref.read(inventoryProvider).products;
                final duration = ended.difference(activeShift.startAt);
                final ordersHandledCount = orders
                    .where(
                      (o) =>
                          o.createdAt.isAfter(activeShift.startAt) &&
                          o.status != OrderStatus.pending,
                    )
                    .length;
                final prescriptionsValidatedCount = prescriptions
                    .where((p) => p.status == 'validated')
                    .length;
                final critical = products
                    .where((p) => p.isLowStock || p.isOutOfStock)
                    .toList();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => GuardSummarySheet(
                    data: GuardSummaryData(
                      shift: activeShift,
                      duration: duration,
                      ordersHandledCount: ordersHandledCount,
                      prescriptionsValidatedCount: prescriptionsValidatedCount,
                      criticalProducts: critical,
                    ),
                  ),
                );
              }
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Bonjour 👋';
    if (hour < 18) return 'Bon après-midi 👋';
    return 'Bonsoir 👋';
  }

  OnCallModel? _getActiveShift(List<OnCallModel> onCalls) {
    final now = DateTime.now();
    for (final shift in onCalls) {
      if (shift.startAt.isBefore(now) && shift.endAt.isAfter(now)) {
        return shift;
      }
    }
    return null;
  }
}
