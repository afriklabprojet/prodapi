import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/kyc_guard_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/error_utils.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/gamification.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../../data/repositories/gamification_repository.dart';
import '../../../data/repositories/support_repository.dart';
import '../../providers/wallet_provider.dart';
import 'delivery_communication.dart';
import 'delivery_proof.dart';

/// Boutons d'action contextuels + logique de changement de statut
class DeliveryStatusActions extends ConsumerWidget {
  final Delivery delivery;
  final bool isLoading;
  final bool isNearDestination;
  final Animation<double> pulseAnimation;
  final VoidCallback onStatusChanged;
  final ValueChanged<bool> onLoadingChanged;
  final DeliveryCommunicationHelper commHelper;
  final DeliveryProofHelper proofHelper;

  const DeliveryStatusActions({
    super.key,
    required this.delivery,
    required this.isLoading,
    required this.isNearDestination,
    required this.pulseAnimation,
    required this.onStatusChanged,
    required this.onLoadingChanged,
    required this.commHelper,
    required this.proofHelper,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    String label;
    Color color;
    IconData icon;
    String action;

    switch (delivery.status) {
      case 'pending':
        label = 'Accepter la course';
        color = Colors.green;
        icon = Icons.check_circle_outline;
        action = 'accept';
        break;
      case 'assigned':
        label = 'Confirmer récupération';
        color = Colors.blue;
        icon = Icons.store_mall_directory_outlined;
        action = 'pickup';
        break;
      case 'picked_up':
        label = 'Confirmer la livraison';
        color = Colors.orange.shade800;
        icon = Icons.local_shipping_outlined;
        action = 'deliver';
        break;
      default:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xFF2C2C2C)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                'Course terminée',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isNearDestination ? pulseAnimation.value : 1.0,
              child: Container(
                decoration: isNearDestination
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      )
                    : null,
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: Icon(icon, color: Colors.white, size: 20),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isNearDestination ? 6 : 2,
              ),
              onPressed: () => _updateStatus(context, ref, action),
            ),
          ),
        ),
        if (delivery.status != 'delivered')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () => _cancelDelivery(context, ref),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade300,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Signaler un problème / Annuler',
                    style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    String? confirmationCode;

    if (action == 'deliver') {
      final canDeliver = await proofHelper.checkBalanceForDelivery();
      if (!canDeliver) return;

      confirmationCode = await proofHelper.showConfirmationDialog();
      if (confirmationCode == null) return;
    }

    if (!context.mounted) return;
    onLoadingChanged(true);
    try {
      final repo = ref.read(deliveryRepositoryProvider);

      switch (action) {
        case 'accept':
          // Bloquer si KYC non vérifié
          if (!await KycGuard.ensureVerified(context, ref)) {
            onLoadingChanged(false);
            return;
          }
          await repo.acceptDelivery(delivery.id);
          final locationService = ref.read(locationServiceProvider);
          locationService.currentOrderId = delivery.orderId ?? delivery.id;
          if (delivery.pharmacyLat != null && delivery.pharmacyLng != null) {
            locationService.setDestination(
              lat: delivery.pharmacyLat!,
              lng: delivery.pharmacyLng!,
            );
          }
          await locationService.updateDeliveryStatus(
            deliveryId: delivery.orderId ?? delivery.id,
            status: 'accepted',
          );
          break;
        case 'pickup':
          await repo.pickupDelivery(delivery.id);
          if (delivery.deliveryLat != null && delivery.deliveryLng != null) {
            ref
                .read(locationServiceProvider)
                .setDestination(
                  lat: delivery.deliveryLat!,
                  lng: delivery.deliveryLng!,
                );
          }
          await ref
              .read(locationServiceProvider)
              .updateDeliveryStatus(
                deliveryId: delivery.orderId ?? delivery.id,
                status: 'picked_up',
              );
          break;
        case 'deliver':
          await repo.completeDelivery(delivery.id, confirmationCode!);

          final locService = ref.read(locationServiceProvider);
          await locService.updateDeliveryStatus(
            deliveryId: delivery.orderId ?? delivery.id,
            status: 'delivered',
          );
          locService.currentOrderId = null;
          locService.clearDestination();
          break;
      }

      if (!context.mounted) return;

      if (action == 'deliver') {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        HapticFeedback.lightImpact();

        ref.invalidate(walletDataProvider);
        ref.invalidate(walletProvider);

        GamificationBadge? nearBadge;
        try {
          final gamifData = await ref
              .read(gamificationRepositoryProvider)
              .getGamificationData();
          final locked = gamifData.badges
              .where((b) => !b.isUnlocked && b.progress > 0.5)
              .toList();
          if (locked.isNotEmpty) {
            locked.sort((a, b) => b.progress.compareTo(a.progress));
            nearBadge = locked.first;
          }
        } catch (_) {}

        if (!context.mounted) return;
        _showPostDeliverySummary(context, nearBadge);
      } else {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        HapticFeedback.lightImpact();

        if (!context.mounted) return;
        _showTransitionSheet(context, action);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFriendlyError(e))));
      }
    } finally {
      onLoadingChanged(false);
    }
  }

  void _showPostDeliverySummary(
    BuildContext context,
    GamificationBadge? nearBadge,
  ) {
    final netGain =
        delivery.estimatedEarnings ??
        ((delivery.deliveryFee ?? 0) - (delivery.commission ?? 0));
    final commission = delivery.commission ?? 200;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        int inlineRating = 0;
        bool showSkip = false;

        return StatefulBuilder(
          builder: (ctx2, setSheetState) {
            if (!showSkip) {
              Future.delayed(const Duration(seconds: 3), () {
                if (ctx2.mounted) {
                  setSheetState(() => showSkip = true);
                }
              });
            }
            return Container(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Livraison Terminée !',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Earnings summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.green.shade900.withValues(alpha: 0.2)
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '+${netGain.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gain net pour cette course',
                          style: TextStyle(
                            fontSize: 13,
                            color: dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(color: Colors.green.shade200, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Frais livraison',
                              style: TextStyle(
                                color: dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${delivery.deliveryFee?.toStringAsFixed(0) ?? '-'} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Commission',
                              style: TextStyle(
                                color: dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '-${commission.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Gamification nudge
                  if (nearBadge != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dark
                            ? Colors.amber.shade900.withValues(alpha: 0.2)
                            : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: dark
                              ? Colors.amber.shade800.withValues(alpha: 0.3)
                              : Colors.amber.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Encore ${((1 - nearBadge.progress) * nearBadge.requiredValue).ceil()} pour "${nearBadge.name}" !',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: dark
                                        ? Colors.amber.shade300
                                        : Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: nearBadge.progress,
                                    backgroundColor: dark
                                        ? Colors.grey.shade800
                                        : Colors.amber.shade100,
                                    color: Colors.amber.shade600,
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Inline star rating
                  Text(
                    'Comment était le client ?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: dark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() => inlineRating = index + 1);
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (ctx2.mounted) {
                              Navigator.pop(ctx2);
                              context.pushReplacement(
                                AppRoutes.deliveryRating,
                                extra: {
                                  'deliveryId': delivery.id,
                                  'customerName': delivery.customerName,
                                  'customerAddress': delivery.deliveryAddress,
                                  'initialRating': inlineRating,
                                },
                              );
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            index < inlineRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 40,
                            color: index < inlineRating
                                ? Colors.amber
                                : (dark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: showSkip ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: showSkip
                        ? TextButton(
                            onPressed: () {
                              Navigator.pop(ctx2);
                              onStatusChanged();
                            },
                            child: Text(
                              'Passer',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : const SizedBox(height: 36),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTransitionSheet(BuildContext context, String action) {
    final isAccept = action == 'accept';
    final dest = isAccept ? delivery.pharmacyName : delivery.customerName;
    final destAddress = isAccept
        ? delivery.pharmacyAddress
        : delivery.deliveryAddress;
    final destLat = isAccept ? delivery.pharmacyLat : delivery.deliveryLat;
    final destLng = isAccept ? delivery.pharmacyLng : delivery.deliveryLng;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        Future.delayed(const Duration(seconds: 3), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.pop(ctx);
          }
        });
        return Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isAccept
                        ? Colors.blue.shade50
                        : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAccept ? Icons.check_circle : Icons.local_shipping,
                    color: isAccept
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAccept ? 'Course Acceptée !' : 'Colis Récupéré !',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAccept ? 'Direction la pharmacie' : 'En route vers le client',
                style: TextStyle(
                  fontSize: 14,
                  color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dark
                      ? (isAccept
                                ? Colors.blue.shade900
                                : Colors.orange.shade900)
                            .withValues(alpha: 0.2)
                      : (isAccept
                            ? Colors.blue.shade50
                            : Colors.orange.shade50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.place,
                      color: isAccept
                          ? Colors.blue.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dest,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: dark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (destAddress.isNotEmpty)
                            Text(
                              destAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (destLat != null && destLng != null) {
                      commHelper.launchMaps(destLat, destLng);
                    }
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text(
                    'LANCER LA NAVIGATION',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAccept
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 0.0),
                duration: const Duration(seconds: 3),
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  color: isAccept
                      ? Colors.blue.shade400
                      : Colors.orange.shade400,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => onStatusChanged());
  }

  Future<void> _cancelDelivery(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Motif d\'annulation'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "Problème mécanique"),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Problème mécanique"),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "Accident"),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Accident"),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "Client injoignable"),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Client injoignable"),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "Autre"),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Autre"),
            ),
          ),
        ],
      ),
    );

    if (reason != null && context.mounted) {
      try {
        final supportRepo = ref.read(supportRepositoryProvider);
        await supportRepo.reportIncident(
          deliveryId: delivery.id,
          reason: reason,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Incident signalé: $reason. Le support a été prévenu.',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(userFriendlyError(e))));
        }
      }
    }
  }
}
