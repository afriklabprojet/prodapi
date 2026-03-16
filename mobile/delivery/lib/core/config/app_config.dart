import 'package:flutter/foundation.dart';

/// Configuration centralisée de l'application
/// En production, ces valeurs devraient venir de variables d'environnement
/// ou d'un fichier de configuration sécurisé (.env)
class AppConfig {
  // Singleton
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  /// Environnement actuel
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const bool isDebug = !isProduction;

  /// API Base URL
  static String get apiBaseUrl {
    // En production, utiliser l'URL de production
    if (isProduction) {
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://drlpharma.com/api',
      );
    }
    
    // En développement
    if (kIsWeb) {
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000/api',
      );
    }
    // Android Emulator
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000/api',
    );
  }

  /// Web Base URL (pour les liens de tracking)
  static String get webBaseUrl {
    if (isProduction) {
      return const String.fromEnvironment(
        'WEB_BASE_URL',
        defaultValue: 'https://drlpharma.com',
      );
    }
    return const String.fromEnvironment(
      'WEB_BASE_URL',
      defaultValue: 'http://localhost:3000',
    );
  }

  /// Google Maps API Key
  /// Passée via --dart-define=GOOGLE_MAPS_API_KEY=xxx au build
  /// Ne JAMAIS hardcoder la clé ici
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '', // Définie via --dart-define ou .env
  );

  /// Timeouts
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Cache
  static const Duration cacheExpiration = Duration(minutes: 5);

  /// Logging
  static bool get enableApiLogging => isDebug;
  static bool get enableLocationLogging => isDebug;

  // ============================================================
  // CONTACT & SUPPORT
  // ============================================================

  /// Numéro de téléphone du support
  static const String supportPhone = String.fromEnvironment(
    'SUPPORT_PHONE',
    defaultValue: '+22507000000000',
  );

  /// Numéro WhatsApp du support
  static const String supportWhatsApp = String.fromEnvironment(
    'SUPPORT_WHATSAPP',
    defaultValue: '22507000000000',
  );

  /// Email du support
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@drlpharma.com',
  );

  /// URL WhatsApp du support
  static String get whatsAppUrl => 'https://wa.me/$supportWhatsApp';

  /// URL téléphone du support
  static String get phoneUrl => 'tel:$supportPhone';

  // ============================================================
  // LEGAL URLs
  // ============================================================

  /// URL politique de confidentialité
  static const String privacyUrl = String.fromEnvironment(
    'PRIVACY_URL',
    defaultValue: 'https://drlpharma.com/privacy',
  );

  /// URL conditions d'utilisation
  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://drlpharma.com/terms',
  );
}
