import 'package:url_launcher/url_launcher.dart';

import 'phone_normalizer.dart';

/// Result of a channel launch attempt.
enum LaunchResult { success, unavailable, invalidPhone }

/// Abstract channel — WhatsApp, SMS, phone call, etc.
/// Implement this to add new communication channels.
abstract class MessageChannel {
  const MessageChannel();

  String get name;

  Future<LaunchResult> launch({required String phoneNumber, String? message});

  Future<bool> isAvailable();
}

// ═══════════════════════════════════════════════════════════════
// WhatsApp Channel
// ═══════════════════════════════════════════════════════════════

class WhatsAppChannel extends MessageChannel {
  const WhatsAppChannel();

  @override
  String get name => 'whatsapp';

  @override
  Future<LaunchResult> launch({
    required String phoneNumber,
    String? message,
  }) async {
    final normalized = PhoneNormalizer.normalize(phoneNumber);
    if (normalized.isEmpty) return LaunchResult.invalidPhone;

    // Strip leading + for wa.me
    final digits = PhoneNormalizer.digitsOnly(normalized);
    final textParam = message != null
        ? '?text=${Uri.encodeComponent(message)}'
        : '';

    // Primary: wa.me universal link (works on all devices)
    final waUrl = Uri.parse('https://wa.me/$digits$textParam');
    if (await canLaunchUrl(waUrl)) {
      final ok = await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      if (ok) return LaunchResult.success;
    }

    // Fallback: whatsapp:// scheme
    final schemeUrl = Uri.parse(
      'whatsapp://send?phone=$digits${message != null ? '&text=${Uri.encodeComponent(message)}' : ''}',
    );
    if (await canLaunchUrl(schemeUrl)) {
      final ok = await launchUrl(schemeUrl);
      if (ok) return LaunchResult.success;
    }

    return LaunchResult.unavailable;
  }

  @override
  Future<bool> isAvailable() async {
    final url = Uri.parse('https://wa.me/0');
    return canLaunchUrl(url);
  }
}

// ═══════════════════════════════════════════════════════════════
// SMS Channel (fallback)
// ═══════════════════════════════════════════════════════════════

class SmsChannel extends MessageChannel {
  const SmsChannel();

  @override
  String get name => 'sms';

  @override
  Future<LaunchResult> launch({
    required String phoneNumber,
    String? message,
  }) async {
    final normalized = PhoneNormalizer.normalize(phoneNumber);
    if (normalized.isEmpty) return LaunchResult.invalidPhone;

    final smsUri = Uri(
      scheme: 'sms',
      path: normalized,
      queryParameters: message != null ? {'body': message} : null,
    );

    if (await canLaunchUrl(smsUri)) {
      final ok = await launchUrl(smsUri);
      if (ok) return LaunchResult.success;
    }

    return LaunchResult.unavailable;
  }

  @override
  Future<bool> isAvailable() async {
    final url = Uri(scheme: 'sms', path: '0');
    return canLaunchUrl(url);
  }
}
