import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/utils/privacy_utils.dart';
import '../../../data/models/delivery.dart';
import '../../../l10n/app_localizations.dart';

/// Gère tous les appels, WhatsApp, messages rapides et navigation GPS.
class DeliveryCommunicationHelper {
  final BuildContext context;
  final Delivery delivery;

  DeliveryCommunicationHelper({required this.context, required this.delivery});

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  /// Lancer la navigation GPS vers les coordonnées
  Future<void> launchMaps(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final navApp = prefs.getString('navigation_app') ?? 'google_maps';

    Uri? uri;

    if (navApp == 'waze') {
      uri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    } else if (navApp == 'apple_maps') {
      uri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');
    } else {
      uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    }

    bool launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        launched = true;
      }
    } catch (_) {}

    if (!launched) {
      final googleWeb = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
      final appleMaps = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');

      if (await canLaunchUrl(googleWeb)) {
        await launchUrl(googleWeb);
      } else if (await canLaunchUrl(appleMaps)) {
        await launchUrl(appleMaps);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.cannotLaunchNavigation(navApp))),
          );
        }
      }
    }
  }

  /// Passer un appel téléphonique
  Future<void> makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l10n.phoneNumberUnavailable)));
      }
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l10n.cannotCall(maskPhoneNumber(phoneNumber))),
          ),
        );
      }
    }
  }

  /// Ouvrir WhatsApp avec un message pré-rempli
  Future<void> openWhatsApp(
    String? phoneNumber, {
    String? recipientName,
    bool isPharmacy = true,
  }) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l10n.phoneNumberUnavailable)));
      }
      return;
    }

    await WhatsAppService.openChatWithFeedback(
      context: context,
      phoneNumber: phoneNumber,
      recipientName: recipientName,
      isPharmacy: isPharmacy,
      orderReference: delivery.reference,
    );
  }

  /// Afficher les messages rapides WhatsApp
  void showQuickMessages(
    String? phone, {
    String? recipientName,
    bool isPharmacy = true,
  }) {
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l10n.phoneNumberUnavailable)));
      }
      return;
    }

    final List<String> messages = isPharmacy
        ? [
            _l10n.enRouteToPharmacy,
            _l10n.arrivedAtPharmacyMsg,
            _l10n.isOrderReady,
            _l10n.cannotFindAddress,
          ]
        : [
            _l10n.arrivingInFiveMin,
            _l10n.atYourBuilding,
            _l10n.pleaseComeDown,
            _l10n.cannotFindYourAddress,
            _l10n.customerNotResponding,
          ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _l10n.quickMessage,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...messages.map(
                (msg) => ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(
                    Icons.send,
                    size: 18,
                    color: Color(0xFF25D366),
                  ),
                  title: Text(msg, style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    WhatsAppService.openChat(phoneNumber: phone, message: msg);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
