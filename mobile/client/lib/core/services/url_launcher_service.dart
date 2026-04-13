import 'package:url_launcher/url_launcher.dart';

/// Service pour lancer des URLs (appels, emails, SMS, maps, etc.)
class UrlLauncherService {
  /// Lancer un appel téléphonique
  static Future<bool> makePhoneCall(String phoneNumber) async {
    // Nettoyer le numéro de téléphone (enlever espaces, tirets, etc.)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    if (await canLaunchUrl(phoneUri)) {
      return await launchUrl(phoneUri);
    }
    return false;
  }

  /// Envoyer un email
  static Future<bool> sendEmail({
    required String email,
    String? subject,
    String? body,
  }) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': ?subject,
        'body': ?body,
      },
    );

    if (await canLaunchUrl(emailUri)) {
      return await launchUrl(emailUri);
    }
    return false;
  }

  /// Envoyer un SMS
  static Future<bool> sendSMS(String phoneNumber, {String? body}) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanNumber,
      queryParameters: body != null ? {'body': body} : null,
    );

    if (await canLaunchUrl(smsUri)) {
      return await launchUrl(smsUri);
    }
    return false;
  }

  /// Ouvrir une URL web dans le navigateur
  static Future<bool> openWebUrl(String url) async {
    final Uri webUri = Uri.parse(url);

    if (await canLaunchUrl(webUri)) {
      return await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    }
    return false;
  }

  /// Ouvrir l'application de navigation avec des coordonnées
  static Future<bool> openMap({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    // Essayer Google Maps d'abord
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(googleMapsUri)) {
      return await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );
    }

    // Fallback vers l'URI générique
    final mapUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');

    if (await canLaunchUrl(mapUri)) {
      return await launchUrl(mapUri);
    }

    return false;
  }

  /// Ouvrir l'application de navigation avec une adresse
  static Future<bool> openMapWithAddress(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );

    if (await canLaunchUrl(googleMapsUri)) {
      return await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );
    }
    return false;
  }

  /// Ouvrir WhatsApp avec un numéro
  /// @deprecated Utilisez WhatsAppService.openChat() à la place
  static Future<bool> openWhatsApp(String phoneNumber, {String? message}) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final whatsappUri = Uri.parse(
      'https://wa.me/$cleanNumber${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}',
    );

    if (await canLaunchUrl(whatsappUri)) {
      return await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
    }

    // Fallback: schéma whatsapp://
    final fallbackUri = Uri.parse(
      'whatsapp://send?phone=$cleanNumber${message != null ? '&text=${Uri.encodeComponent(message)}' : ''}',
    );
    if (await canLaunchUrl(fallbackUri)) {
      return await launchUrl(fallbackUri);
    }

    return false;
  }
}
