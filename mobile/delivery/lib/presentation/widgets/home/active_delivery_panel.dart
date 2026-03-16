import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/navigation_service.dart';
import '../../../data/models/delivery.dart';
import '../../../data/models/route_info.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../providers/delivery_providers.dart';
import '../../screens/enhanced_chat_screen.dart';
import '../chat/enhanced_chat_widgets.dart';
import '../common/eta_display.dart';
import 'delivery_dialogs.dart';

/// Panneau en bas de l'écran affichant la livraison active
class ActiveDeliveryPanel extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final statusInfo = _getStatusInfo(context, ref);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Header
            _buildStatusHeader(context, statusInfo),
            const SizedBox(height: 16),

            // ETA Display - nouveau widget pour afficher temps/distance
            if (routeInfo != null) ...[
              ETADisplayWidget(
                duration: routeInfo!.totalDuration,
                distance: routeInfo!.totalDistance,
                isCompact: false,
                showArrivalTime: true,
              ),
              const SizedBox(height: 16),
            ],

            // Route Info
            _buildRouteInfo(context, statusInfo),

            const SizedBox(height: 24),

            // Main Action Button
            _buildActionButton(statusInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, _StatusInfo info) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: info.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          info.statusText.toUpperCase(),
          style: TextStyle(
            color: info.color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const Spacer(),
        if (routeInfo != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FloatingActionButton.small(
              heroTag: 'itinerary_btn',
              onPressed: onShowItinerary,
              backgroundColor: Theme.of(context).cardColor,
              shape: CircleBorder(side: BorderSide(color: Colors.blue.shade100)),
              elevation: 0,
              child: const Icon(Icons.list_alt, color: Colors.blue),
            ),
          ),
        FloatingActionButton.small(
          heroTag: 'nav_btn',
          onPressed: info.onNavigate,
          backgroundColor: Colors.blue.shade50,
          elevation: 0,
          child: const Icon(Icons.navigation, color: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildRouteInfo(BuildContext context, _StatusInfo info) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.circle, size: 12, color: Colors.blue),
            Container(width: 2, height: 30, color: context.dividerColor),
            const Icon(Icons.location_on, size: 12, color: Colors.red),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                delivery.pharmacyName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                delivery.customerName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Column(
          children: [
            if (info.phoneToCall != null && info.phoneToCall!.isNotEmpty)
              IconButton(
                onPressed: () => _makePhoneCall(context, info.phoneToCall!),
                icon: const Icon(Icons.phone, color: Colors.green),
                tooltip: 'Appeler',
              ),
            Stack(
              children: [
                IconButton(
                  onPressed: () => _showChatOptions(context),
                  icon: const Icon(Icons.chat_bubble, color: Colors.blue),
                  tooltip: 'Message',
                ),
                const Positioned(
                  right: 4,
                  top: 4,
                  child: ChatUnreadBadge(size: 16),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(_StatusInfo info) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: info.onAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: info.color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          info.buttonText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  _StatusInfo _getStatusInfo(BuildContext context, WidgetRef ref) {
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
          try {
            await ref.read(deliveryRepositoryProvider).pickupDelivery(delivery.id);
            ref.invalidate(deliveriesProvider('active'));
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
            }
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
          );
        },
      );
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Numéro de téléphone invalide'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final Uri telUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      final canLaunch = await canLaunchUrl(telUri);
      if (canLaunch) {
        final launched = await launchUrl(telUri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'appeler $phoneNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: impossible d\'appeler $phoneNumber'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Copier',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phoneNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Numéro copié dans le presse-papier'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
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
              title: const Text('Pharmacie', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(delivery.pharmacyName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EnhancedChatScreen(
                      orderId: delivery.id,
                      target: 'pharmacy',
                      targetName: delivery.pharmacyName,
                    ),
                  ),
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
              title: const Text('Client', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(delivery.customerName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EnhancedChatScreen(
                      orderId: delivery.id,
                      target: 'customer',
                      targetName: delivery.customerName,
                    ),
                  ),
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
