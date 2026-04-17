import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

/// Service centralisé WhatsApp pour l'application coursier
/// Gère l'ouverture de conversations WhatsApp avec clients, pharmacies, support
class WhatsAppService {
  /// Code pays par défaut (Côte d'Ivoire)
  static const String _defaultCountryCode = '+225';

  /// Numéro de support par défaut (depuis AppConfig)
  static String get _defaultSupportNumber => '+${AppConfig.supportWhatsApp}';

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
        message ??
        'Bonjour, je suis coursier DR-PHARMA et j\'ai besoin d\'aide.';

    return openChat(phoneNumber: number, message: msg);
  }

  /// Contacter le client via WhatsApp
  /// [clientPhone] - Numéro du client
  /// [orderReference] - Référence de la commande (optionnel)
  /// [clientName] - Nom du client (optionnel)
  static Future<bool> contactClient({
    required String clientPhone,
    String? orderReference,
    String? clientName,
  }) async {
    String message = 'Bonjour';
    if (clientName != null && clientName.isNotEmpty) {
      message += ' $clientName';
    }
    message += ', je suis votre livreur pour la commande';
    if (orderReference != null && orderReference.isNotEmpty) {
      message += ' $orderReference';
    }
    message += '. ';

    return openChat(phoneNumber: clientPhone, message: message);
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
    message += ', je suis le livreur pour la commande';
    if (orderReference != null && orderReference.isNotEmpty) {
      message += ' $orderReference';
    }
    message += '. ';

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
    String? recipientName,
    bool isPharmacy = true,
    String? orderReference,
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

    bool success;
    if (isPharmacy) {
      success = await contactPharmacy(
        pharmacyPhone: phoneNumber,
        orderReference: orderReference,
        pharmacyName: recipientName,
      );
    } else {
      success = await contactClient(
        clientPhone: phoneNumber,
        orderReference: orderReference,
        clientName: recipientName,
      );
    }

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
