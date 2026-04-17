import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/snackbar_extension.dart';
import '../../../core/utils/privacy_utils.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/route_info.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../providers/delivery_providers.dart';
import '../common/eta_display.dart';
import 'delivery_dialogs.dart';

/// Panneau en bas de l'écran affichant la livraison active
class ActiveDeliveryPanel extends ConsumerStatefulWidget {
  final Delivery delivery;
  final RouteInfo? routeInfo;
  final VoidCallback onShowItinerary;

  const ActiveDeliveryPanel({
    super.key,
    required this.delivery,
    this.routeInfo,
    required this.onShowItinerary,
  });

  @override
  ConsumerState<ActiveDeliveryPanel> createState() =>
      _ActiveDeliveryPanelState();
}

class _ActiveDeliveryPanelState extends ConsumerState<ActiveDeliveryPanel> {
  bool _isPickingUp = false;

  Delivery get delivery => widget.delivery;
  RouteInfo? get routeInfo => widget.routeInfo;
  VoidCallback get onShowItinerary => widget.onShowItinerary;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A3A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar - cliquable pour voir les détails
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(AppRoutes.deliveryDetails, extra: delivery);
              },
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 18,
                        color: context.secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Voir les détails',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Status Header
            _buildStatusHeader(context, statusInfo, isDark),
            const SizedBox(height: 14),

            // Earnings row — montant visible pendant la course
            _buildEarningsRow(context, isDark),
            const SizedBox(height: 14),

            // ETA Display - nouveau widget pour afficher temps/distance
            if (routeInfo != null) ...[
              ETADisplayWidget(
                duration: routeInfo!.totalDuration,
                distance: routeInfo!.totalDistance,
                isCompact: false,
                showArrivalTime: true,
              ),
              const SizedBox(height: 18),
            ],

            // Route Info
            _buildRouteInfo(context, statusInfo, isDark),

            const SizedBox(height: 24),

            // Main Action Button
            _buildActionButton(statusInfo, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(
    BuildContext context,
    _StatusInfo info,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: info.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: info.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: info.color.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          info.statusText.toUpperCase(),
          style: TextStyle(
            color: info.color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        if (routeInfo != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildIconButton(
              icon: Icons.list_alt_rounded,
              color: DesignTokens.primary,
              onPressed: onShowItinerary,
              heroTag: 'itinerary_btn',
              isDark: isDark,
            ),
          ),
        _buildIconButton(
          icon: Icons.navigation_rounded,
          color: DesignTokens.primary,
          onPressed: info.onNavigate,
          heroTag: 'nav_btn',
          isDark: isDark,
          filled: true,
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String heroTag,
    required bool isDark,
    bool filled = false,
  }) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      backgroundColor: filled
          ? color.withValues(alpha: 0.15)
          : (isDark ? const Color(0xFF252540) : Colors.white),
      shape: CircleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      elevation: 0,
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildEarningsRow(BuildContext context, bool isDark) {
    final earnings =
        delivery.estimatedEarnings ??
        ((delivery.deliveryFee ?? 0) - (delivery.commission ?? 0));

    if (earnings <= 0 && delivery.deliveryFee == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.primary.withValues(alpha: isDark ? 0.2 : 0.1),
            DesignTokens.primaryLight.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.monetization_on_rounded,
              size: 18,
              color: isDark ? DesignTokens.primaryLight : DesignTokens.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            earnings > 0
                ? earnings.formatCurrency(symbol: 'F')
                : '${delivery.totalAmount.toInt()} F',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: isDark ? DesignTokens.primaryLight : DesignTokens.primary,
            ),
          ),
          if (delivery.commission != null && delivery.commission! > 0) ...[
            const SizedBox(width: 12),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Commission: ${delivery.commission!.toInt()} F',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? DesignTokens.textMutedDarkMode
                    : DesignTokens.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteInfo(BuildContext context, _StatusInfo info, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.circle, size: 10, color: DesignTokens.primary),
            ),
            Container(
              width: 2,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [DesignTokens.primary, Colors.red.shade400],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                size: 10,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                delivery.pharmacyName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark
                      ? DesignTokens.textDarkMode
                      : DesignTokens.textDark,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                delivery.customerName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark
                      ? DesignTokens.textDarkMode
                      : DesignTokens.textDark,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            if (info.phoneToCall != null && info.phoneToCall!.isNotEmpty)
              _buildContactButton(
                icon: Icons.phone_rounded,
                color: DesignTokens.primary,
                onPressed: () => _makePhoneCall(context, info.phoneToCall!),
                isDark: isDark,
              ),
            Stack(
              children: [
                _buildContactButton(
                  icon: Icons.chat_bubble_rounded,
                  color: DesignTokens.primary,
                  onPressed: () => _showChatOptions(context),
                  isDark: isDark,
                ),
                // Badge non-lu géré par l'API
                const SizedBox.shrink(),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      tooltip: icon == Icons.phone_rounded ? 'Appeler' : 'Message',
    );
  }

  Widget _buildActionButton(_StatusInfo info, bool isDark) {
    final isPickup =
        delivery.status == 'assigned' || delivery.status == 'accepted';
    final isLoading = isPickup && _isPickingUp;
    final buttonColor = isPickup ? Colors.orange : DesignTokens.primary;

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPickup
                ? [Colors.orange.shade400, Colors.orange.shade600]
                : [DesignTokens.primaryLight, DesignTokens.primary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  info.onAction();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPickup
                          ? Icons.inventory_2_rounded
                          : Icons.check_circle_rounded,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      info.buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  _StatusInfo _getStatusInfo(BuildContext context) {
    final navService = ref.read(navigationServiceProvider);

    if (delivery.status == 'assigned' || delivery.status == 'accepted') {
      return _StatusInfo(
        statusText: 'En route vers la pharmacie',
        buttonText: 'CONFIRMER RÉCUPÉRATION',
        color: Colors.orange,
        phoneToCall: delivery.pharmacyPhone,
        onNavigate: () {
          if (delivery.pharmacyLat != null && delivery.pharmacyLng != null) {
            navService.showAppSelector(
              context,
              destinationLat: delivery.pharmacyLat!,
              destinationLng: delivery.pharmacyLng!,
              destinationName: delivery.pharmacyName,
            );
          }
        },
        onAction: () async {
          if (_isPickingUp) return;
          setState(() => _isPickingUp = true);
          try {
            await ref
                .read(deliveryRepositoryProvider)
                .pickupDelivery(delivery.id);
            ref.invalidate(deliveriesProvider('active'));
          } catch (e) {
            if (context.mounted) {
              context.showErrorMessage(userFriendlyError(e));
            }
          } finally {
            if (mounted) setState(() => _isPickingUp = false);
          }
        },
      );
    } else {
      return _StatusInfo(
        statusText: 'En route vers le client',
        buttonText: 'CONFIRMER LIVRAISON',
        color: Colors.green,
        phoneToCall: delivery.customerPhone,
        onNavigate: () {
          if (delivery.deliveryLat != null && delivery.deliveryLng != null) {
            navService.showAppSelector(
              context,
              destinationLat: delivery.deliveryLat!,
              destinationLng: delivery.deliveryLng!,
              destinationName: delivery.customerName,
            );
          }
        },
        onAction: () {
          DeliveryDialogs.showConfirmation(
            context,
            ref,
            delivery.id,
            customerName: delivery.customerName,
            customerAddress: delivery.deliveryAddress,
            deliveryFee: delivery.deliveryFee,
            commission: delivery.commission,
          );
        },
      );
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.isEmpty) {
      if (context.mounted) {
        context.showWarning('Numéro de téléphone invalide');
      }
      return;
    }

    final Uri telUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      final canLaunch = await canLaunchUrl(telUri);
      if (canLaunch) {
        final launched = await launchUrl(
          telUri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && context.mounted) {
          context.showErrorMessage(
            'Impossible d\'appeler ${maskPhoneNumber(phoneNumber)}',
          );
        }
      } else {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorMessage(
          'Erreur: impossible d\'appeler ${maskPhoneNumber(phoneNumber)}',
        );
        // SÉCURITÉ: Ne pas copier le numéro complet dans le clipboard
        // pour éviter l'extraction de données personnelles
      }
    }
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Discuter avec...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_pharmacy, color: Colors.orange),
              ),
              title: const Text(
                'Pharmacie',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(delivery.pharmacyName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final chatOrderId = delivery.orderId ?? delivery.id;
                debugPrint('🔥 [Chat] Opening pharmacy chat with orderId: $chatOrderId (delivery.orderId=${delivery.orderId}, delivery.id=${delivery.id})');
                Navigator.pop(ctx);
                context.push(
                  AppRoutes.deliveryChat,
                  extra: {
                    'orderId': chatOrderId,
                    'deliveryId': delivery.id,
                    'target': 'pharmacy',
                    'targetName': delivery.pharmacyName,
                    'targetPhone': delivery.pharmacyPhone,
                  },
                );
              },
            ),
            const Divider(height: 1, indent: 72),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.green),
              ),
              title: const Text(
                'Client',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(delivery.customerName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final chatOrderId = delivery.orderId ?? delivery.id;
                debugPrint('🔥 [Chat] Opening customer chat with orderId: $chatOrderId (delivery.orderId=${delivery.orderId}, delivery.id=${delivery.id})');
                Navigator.pop(ctx);
                context.push(
                  AppRoutes.deliveryChat,
                  extra: {
                    'orderId': chatOrderId,
                    'deliveryId': delivery.id,
                    'target': 'customer',
                    'targetName': delivery.customerName,
                    'targetPhone': delivery.customerPhone,
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatusInfo {
  final String statusText;
  final String buttonText;
  final Color color;
  final String? phoneToCall;
  final VoidCallback onNavigate;
  final VoidCallback onAction;

  _StatusInfo({
    required this.statusText,
    required this.buttonText,
    required this.color,
    this.phoneToCall,
    required this.onNavigate,
    required this.onAction,
  });
}
