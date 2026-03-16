import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env_config.dart';
import 'core_providers.dart';

/// Modèle pour les paramètres de support
class SupportSettings {
  final String supportPhone;
  final String supportEmail;
  final String supportWhatsapp;
  final String websiteUrl;
  final String tutorialsUrl;
  final String guideUrl;
  final String faqUrl;
  final String termsUrl;
  final String privacyUrl;

  const SupportSettings({
    required this.supportPhone,
    required this.supportEmail,
    required this.supportWhatsapp,
    required this.websiteUrl,
    this.tutorialsUrl = '',
    this.guideUrl = '',
    this.faqUrl = '',
    this.termsUrl = '',
    this.privacyUrl = '',
  });

  /// URLs formatées
  String get phoneUrl => 'tel:$supportPhone';
  String get whatsAppUrl {
    final cleanNumber = supportWhatsapp.replaceAll(RegExp(r'[^\d+]'), '');
    return 'https://wa.me/$cleanNumber';
  }
  String get emailUrl => 'mailto:$supportEmail';

  factory SupportSettings.fromJson(Map<String, dynamic> json) {
    return SupportSettings(
      supportPhone: json['support_phone'] ?? '+225 07 79 00 00 00',
      supportEmail: json['support_email'] ?? 'support@drlpharma.com',
      supportWhatsapp: json['support_whatsapp'] ?? '+225 07 79 00 00 00',
      websiteUrl: json['website_url'] ?? 'https://drlpharma.com',
      tutorialsUrl: json['tutorials_url'] ?? 'https://www.youtube.com/@drlpharma',
      guideUrl: json['guide_url'] ?? 'https://drlpharma.com/guide',
      faqUrl: json['faq_url'] ?? 'https://drlpharma.com/faq',
      termsUrl: json['terms_url'] ?? 'https://drlpharma.com/terms',
      privacyUrl: json['privacy_url'] ?? 'https://drlpharma.com/privacy',
    );
  }

  /// Valeurs par défaut depuis EnvConfig (fallback)
  factory SupportSettings.defaults() {
    return SupportSettings(
      supportPhone: EnvConfig.supportPhone,
      supportEmail: EnvConfig.supportEmail,
      supportWhatsapp: EnvConfig.supportPhone,
      websiteUrl: EnvConfig.websiteUrl,
      tutorialsUrl: EnvConfig.tutorialsUrl,
      guideUrl: EnvConfig.guideUrl,
    );
  }
}

/// Provider pour les paramètres de support (chargés depuis l'API)
final supportSettingsProvider = FutureProvider<SupportSettings>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  
  try {
    final response = await apiClient.get('/support/settings');
    final data = response.data;
    
    if (data['success'] == true && data['data'] != null) {
      return SupportSettings.fromJson(data['data']);
    }
  } catch (e) {
    // En cas d'erreur, utiliser les valeurs par défaut
    if (kDebugMode) debugPrint('Erreur chargement support settings: $e');
  }
  
  return SupportSettings.defaults();
});

/// Provider pour accès simple aux settings (avec valeurs par défaut)
final supportSettingsValueProvider = Provider<SupportSettings>((ref) {
  final asyncSettings = ref.watch(supportSettingsProvider);
  return asyncSettings.maybeWhen(
    data: (settings) => settings,
    orElse: () => SupportSettings.defaults(),
  );
});
