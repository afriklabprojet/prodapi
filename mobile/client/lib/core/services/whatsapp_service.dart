import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// @deprecated Use [MessagingService] from `core/services/messaging/messaging.dart` instead.
/// This class is kept for backward compatibility.
@Deprecated('Use MessagingService from core/services/messaging/')
class WhatsAppService {
  /// Code pays par défaut (Côte d'Ivoire)
  static const String _defaultCountryCode = '+225';

  /// Numéro de support par défaut
  static const String _defaultSupportNumber = '+22507000000000';

  // ============================================================
  // MÉTHODES PUBLIQUES
  // ============================================================

  /// Ouvrir une conversation WhatsApp avec un numéro quelconque
  /// [phoneNumber] - Le numéro de téléphone du destinataire
  /// [message] - Message pré-rempli optionnel
  /// Retourne true si WhatsApp a été ouvert avec succès
  static Future<bool> openChat({
    required String phoneNumber,
    String? message,
  }) async {
    final cleanPhone = normalizePhone(phoneNumber);
    if (cleanPhone.isEmpty) return false;

    final encodedMessage = message != null
        ? Uri.encodeComponent(message)
        : null;
    final queryParam = encodedMessage != null ? '?text=$encodedMessage' : '';

    // Essayer wa.me d'abord (fonctionne sur tous les appareils)
    final waUrl = Uri.parse('https://wa.me/$cleanPhone$queryParam');
    if (await canLaunchUrl(waUrl)) {
      return await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    }

    // Fallback: schéma whatsapp://
    final whatsappUrl = Uri.parse(
      'whatsapp://send?phone=$cleanPhone${encodedMessage != null ? '&text=$encodedMessage' : ''}',
    );
    if (await canLaunchUrl(whatsappUrl)) {
      return await launchUrl(whatsappUrl);
    }

    return false;
  }

  /// Contacter le support DR-PHARMA via WhatsApp
  /// [supportNumber] - Numéro du support (optionnel, utilise le défaut)
  /// [message] - Message personnalisé (optionnel)
  static Future<bool> contactSupport({
    String? supportNumber,
    String? message,
  }) async {
    final number = supportNumber ?? _defaultSupportNumber;
    final msg =
        message ?? 'Bonjour, j\'ai besoin d\'aide avec mon compte DR-PHARMA.';

    return openChat(phoneNumber: number, message: msg);
  }

  /// Contacter le coursier via WhatsApp
  /// [courierPhone] - Numéro du coursier
  /// [orderReference] - Référence de la commande (optionnel)
  /// [courierName] - Nom du coursier (optionnel)
  static Future<bool> contactCourier({
    required String courierPhone,
    String? orderReference,
    String? courierName,
  }) async {
    String message = 'Bonjour';
    if (courierName != null && courierName.isNotEmpty) {
      message += ' $courierName';
    }
    message += ', je vous contacte concernant ma livraison';
    if (orderReference != null && orderReference.isNotEmpty) {
      message += ' (commande $orderReference)';
    }
    message += '.';

    return openChat(phoneNumber: courierPhone, message: message);
  }

  /// Contacter la pharmacie via WhatsApp
  /// [pharmacyPhone] - Numéro de la pharmacie
  /// [orderReference] - Référence de la commande (optionnel)
  /// [pharmacyName] - Nom de la pharmacie (optionnel)
  static Future<bool> contactPharmacy({
    required String pharmacyPhone,
    String? orderReference,
    String? pharmacyName,
  }) async {
    String message = 'Bonjour';
    if (pharmacyName != null && pharmacyName.isNotEmpty) {
      message += ' $pharmacyName';
    }
    message += ', je vous contacte concernant ma commande';
    if (orderReference != null && orderReference.isNotEmpty) {
      message += ' $orderReference';
    }
    message += '.';

    return openChat(phoneNumber: pharmacyPhone, message: message);
  }

  // ============================================================
  // MÉTHODES UTILITAIRES
  // ============================================================

  /// Normalise un numéro de téléphone pour WhatsApp
  /// Supprime les espaces, tirets, et ajoute le code pays si absent
  static String normalizePhone(String phoneNumber) {
    // Nettoyer le numéro (garder uniquement chiffres et +)
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.isEmpty) return '';

    // Si le numéro ne commence pas par +, ajouter le code pays
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('00')) {
        // Format international sans +
        cleaned = '+${cleaned.substring(2)}';
      } else if (cleaned.startsWith('0')) {
        // Format local, enlever le 0 et ajouter le code pays
        cleaned = '$_defaultCountryCode${cleaned.substring(1)}';
      } else {
        // Pas de préfixe, ajouter le code pays
        cleaned = '$_defaultCountryCode$cleaned';
      }
    }

    return cleaned;
  }

  /// Ouvrir WhatsApp avec gestion des erreurs et SnackBar
  /// Affiche un SnackBar si WhatsApp n'est pas disponible
  static Future<void> openChatWithFeedback({
    required BuildContext context,
    required String phoneNumber,
    String? message,
    String errorMessage = 'WhatsApp n\'est pas installé sur cet appareil',
    String emptyNumberMessage = 'Numéro WhatsApp non disponible',
  }) async {
    if (phoneNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(emptyNumberMessage)));
      }
      return;
    }

    final success = await openChat(phoneNumber: phoneNumber, message: message);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  /// Vérifie si WhatsApp est probablement disponible
  static Future<bool> isAvailable() async {
    final testUrl = Uri.parse('https://wa.me/0');
    return await canLaunchUrl(testUrl);
  }
}
