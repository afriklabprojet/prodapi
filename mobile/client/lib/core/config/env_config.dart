import 'package:flutter/foundation.dart';

import '../services/app_logger.dart';

/// Service de configuration d'environnement
///
/// Utilise `--dart-define` pour injecter les variables au build-time.
/// Aucun fichier .env n'est embarqué dans l'APK/IPA.
///
/// Usage au build :
///   flutter build apk \
///     --dart-define=API_BASE_URL=https://drlpharma.pro \
///     --dart-define=APP_ENV=production \
///     --dart-define=GOOGLE_MAPS_API_KEY=AIza...
///
/// Ou via un fichier de defines :
///   flutter build apk --dart-define-from-file=config/prod.env
class EnvConfig {
  EnvConfig._();

  // ============================================================
  // CORE — dart-define compile-time constants
  // ============================================================

  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://drlpharma.pro',
  );

  static const String _storageBaseUrl = String.fromEnvironment(
    'STORAGE_BASE_URL',
    defaultValue: '',
  );

  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: kDebugMode ? 'development' : 'production',
  );

  static const bool _debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: kDebugMode,
  );

  static const bool _forceHttps = bool.fromEnvironment(
    'FORCE_HTTPS',
    defaultValue: false,
  );

  static const int _connectionTimeoutMs = int.fromEnvironment(
    'CONNECTION_TIMEOUT',
    defaultValue: 30000,
  );

  static const int _receiveTimeoutMs = int.fromEnvironment(
    'RECEIVE_TIMEOUT',
    defaultValue: 30000,
  );

  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String _supportPhone = String.fromEnvironment(
    'SUPPORT_PHONE',
    defaultValue: '+22507000000000',
  );

  static const String _supportWhatsApp = String.fromEnvironment(
    'SUPPORT_WHATSAPP',
    defaultValue: '22507000000000',
  );

  static const String _supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@drlpharma.com',
  );

  static const String _infobipApplicationCode = String.fromEnvironment(
    'INFOBIP_APPLICATION_CODE',
    defaultValue: '',
  );

  // ============================================================
  // INIT — no-op, kept for backward compatibility
  // ============================================================

  /// Kept for backward compat — all config is compile-time now.
  static Future<void> init() async {
    // No-op: all values are injected via --dart-define at build time.
  }

  // ============================================================
  // API
  // ============================================================

  /// URL de base de l'API
  static String get apiBaseUrl => _ensureHttps(_apiBaseUrl);

  /// URL de base de l'API avec /api
  /// Protège contre le double /api si API_BASE_URL inclut déjà /api
  static String get apiUrl {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    return base.endsWith('/api') ? base : '$base/api';
  }

  /// URL de stockage des fichiers
  static String get storageBaseUrl {
    final url = _storageBaseUrl.isEmpty
        ? '$apiBaseUrl/storage'
        : _storageBaseUrl;
    return _ensureHttps(url);
  }

  // ============================================================
  // ENVIRONMENT
  // ============================================================

  /// Environnement actuel
  static String get environment => _appEnv;

  /// Est-ce l'environnement de développement ?
  static bool get isDevelopment => environment == 'development';

  /// Est-ce l'environnement de staging ?
  static bool get isStaging => environment == 'staging';

  /// Est-ce l'environnement de production ?
  static bool get isProduction => environment == 'production';

  /// Mode debug activé ?
  static bool get debugMode => _debugMode;

  /// Forcer HTTPS ?
  static bool get forceHttps {
    if (isProduction) return true;
    return _forceHttps;
  }

  // ============================================================
  // TIMEOUTS
  // ============================================================

  /// Timeout de connexion
  static Duration get connectionTimeout =>
      Duration(milliseconds: _connectionTimeoutMs);

  /// Timeout de réception
  static Duration get receiveTimeout =>
      Duration(milliseconds: _receiveTimeoutMs);

  // ============================================================
  // THIRD-PARTY KEYS
  // ============================================================

  /// Clé API Google Maps
  static String get googleMapsApiKey => _googleMapsApiKey;

  /// Infobip application code
  static String get infobipApplicationCode => _infobipApplicationCode;

  // ============================================================
  // CONTACT & SUPPORT
  // ============================================================

  /// Numéro de téléphone du support
  static String get supportPhone => _supportPhone;

  /// Numéro WhatsApp du support
  static String get supportWhatsApp => _supportWhatsApp;

  /// Email du support
  static String get supportEmail => _supportEmail;

  // ============================================================
  // URLS
  // ============================================================

  /// URL WhatsApp du support
  static String get whatsAppUrl => 'https://wa.me/$supportWhatsApp';

  /// URL téléphone du support
  static String get phoneUrl => 'tel:$supportPhone';

  // ============================================================
  // HELPERS
  // ============================================================

  /// Convertit HTTP en HTTPS si forceHttps est activé
  static String _ensureHttps(String url) {
    if (!forceHttps) return url;

    if (url.startsWith('http://localhost') ||
        url.startsWith('http://10.0.2.2') ||
        url.startsWith('http://127.0.0.1')) {
      return url;
    }

    return url.replaceFirst('http://', 'https://');
  }

  /// Affiche la configuration actuelle (pour debug)
  static void printConfig() {
    if (!debugMode) return;

    AppLogger.info(
      '═══════════════════════════════════════\n'
      '🔧 DR-PHARMA Environment Configuration\n'
      '═══════════════════════════════════════\n'
      '   Environment: $environment\n'
      '   API URL: $apiUrl\n'
      '   Storage URL: $storageBaseUrl\n'
      '   Debug Mode: $debugMode\n'
      '   Force HTTPS: $forceHttps\n'
      '   Connection Timeout: ${connectionTimeout.inSeconds}s\n'
      '   Support Phone: $supportPhone\n'
      '   Support WhatsApp: $supportWhatsApp\n'
      '═══════════════════════════════════════',
    );
  }
}
