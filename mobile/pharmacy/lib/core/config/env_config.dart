import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration d'environnement centralisée.
///
/// Pattern Singleton avec lazy initialization et caching des valeurs
/// fréquemment accédées pour éviter les calculs répétés.
///
/// Usage:
/// ```dart
/// await EnvConfig.init();
/// final apiUrl = EnvConfig.apiBaseUrl;
/// ```
class EnvConfig {
  EnvConfig._(); // Private constructor - use static methods

  // ============================================================
  // STATE
  // ============================================================

  static bool _isInitialized = false;
  static String? _overrideBaseUrl;

  // Cached computed values (populated on init)
  static late final String _cachedBaseUrl;
  static late final String _cachedApiBaseUrl;
  static late final String _cachedStorageBaseUrl;
  static late final int _cachedApiTimeout;
  static late final bool _cachedIsDevelopment;

  // ============================================================
  // DEFAULTS (centralized)
  // ============================================================

  static const _defaults = (
    appName: 'DR-PHARMA',
    appEnv: 'development',
    prodApiUrl: 'https://drlpharma.pro',
    localIp: '192.168.1.100',
    devUrlLocal: 'http://127.0.0.1:8000',
    devUrlAndroid: 'http://10.0.2.2:8000',
    apiTimeout: 15000,
    supportPhone: '+22507000000000',
    supportWhatsApp: '22507000000000',
    supportEmail: 'support@drlpharma.com',
    websiteUrl: 'https://drlpharma.pro',
    tutorialsUrl: 'https://www.youtube.com/@drlpharma',
    guideUrl: 'https://drlpharma.pro/guide',
  );

  // ============================================================
  // INITIALIZATION
  // ============================================================

  static bool get isInitialized => _isInitialized;

  /// Initialise la configuration. Safe to call multiple times.
  static Future<void> init({String? environment}) async {
    if (_isInitialized) return;

    await _loadEnvFile();
    _cacheComputedValues();
    _isInitialized = true;

    _printConfig();
  }

  /// Reset state (for testing only)
  @visibleForTesting
  static void reset() {
    _isInitialized = false;
    _overrideBaseUrl = null;
  }

  static Future<void> _loadEnvFile() async {
    try {
      await dotenv.load(fileName: '.env');
      _log('✅ .env loaded');
    } catch (e) {
      _log('⚠️ .env not found, using defaults: $e');
    }
  }

  static void _cacheComputedValues() {
    _cachedIsDevelopment = _computeIsDevelopment();
    _cachedBaseUrl = _computeBaseUrl();
    _cachedApiBaseUrl = '$_cachedBaseUrl/api';
    _cachedStorageBaseUrl = '$_cachedBaseUrl/storage/';
    _cachedApiTimeout =
        int.tryParse(_get('API_TIMEOUT', '')) ?? _defaults.apiTimeout;
  }

  // ============================================================
  // OVERRIDE (for tests)
  // ============================================================

  /// Override base URL (invalidates cache)
  static void setOverrideBaseUrl(String? url) {
    _overrideBaseUrl = url;
    if (_isInitialized) {
      // Re-cache URLs with new override
      _cachedBaseUrl = _computeBaseUrl();
      _cachedApiBaseUrl = '$_cachedBaseUrl/api';
      _cachedStorageBaseUrl = '$_cachedBaseUrl/storage/';
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _get(String key, String defaultValue) =>
      dotenv.env[key]?.trim().ifEmpty(null) ?? defaultValue;

  static void _log(String message) {
    if (kDebugMode) debugPrint('[EnvConfig] $message');
  }

  // ============================================================
  // APP INFO
  // ============================================================

  static String get appName => _get('APP_NAME', _defaults.appName);
  static String get appEnv => _get('APP_ENV', _defaults.appEnv);

  // ============================================================
  // ENVIRONMENT DETECTION
  // ============================================================

  static bool _computeIsDevelopment() {
    if (kReleaseMode) return false;
    final env = appEnv.toLowerCase();
    return env != 'production' && env != 'prod';
  }

  static bool get isDevelopment =>
      _isInitialized ? _cachedIsDevelopment : _computeIsDevelopment();
  static bool get isProduction => !isDevelopment;
  static String get environment => isDevelopment ? 'development' : 'production';
  static bool get isDebugMode => isDevelopment;

  // ============================================================
  // URLS (cached for performance)
  // ============================================================

  static String _computeBaseUrl() {
    // 1. Override (highest priority)
    if (_overrideBaseUrl case final url? when url.isNotEmpty) {
      return url;
    }

    // 2. Production
    if (isProduction) {
      return _get('PROD_API_URL', _defaults.prodApiUrl);
    }

    // 3. Development - platform-specific
    return _detectDevUrl();
  }

  static String _detectDevUrl() {
    final configuredUrl = _get('API_BASE_URL', '');
    if (configuredUrl.isNotEmpty) return configuredUrl;

    if (kIsWeb) return _defaults.devUrlLocal;

    // Non-web platforms
    return switch (_getPlatform()) {
      _Platform.android => _defaults.devUrlAndroid,
      _Platform.ios => _defaults.devUrlLocal,
      _Platform.other => _defaults.devUrlLocal,
    };
  }

  static _Platform _getPlatform() {
    if (kIsWeb) return _Platform.other;
    try {
      if (Platform.isAndroid) return _Platform.android;
      if (Platform.isIOS) return _Platform.ios;
    } catch (_) {}
    return _Platform.other;
  }

  static String get baseUrl =>
      _isInitialized ? _cachedBaseUrl : _computeBaseUrl();
  static String get apiBaseUrl =>
      _isInitialized ? _cachedApiBaseUrl : '$baseUrl/api';
  static String get storageBaseUrl =>
      _isInitialized ? _cachedStorageBaseUrl : '$baseUrl/storage/';
  static int get apiTimeout =>
      _isInitialized ? _cachedApiTimeout : _defaults.apiTimeout;

  static String get localMachineIP =>
      _get('LOCAL_MACHINE_IP', _defaults.localIp);

  // ============================================================
  // INFOBIP
  // ============================================================

  static String get infobipApplicationCode =>
      _get('INFOBIP_APPLICATION_CODE', '');

  // ============================================================
  // CONTACT & SUPPORT
  // ============================================================

  static String get supportPhone =>
      _get('SUPPORT_PHONE', _defaults.supportPhone);
  static String get supportWhatsApp =>
      _get('SUPPORT_WHATSAPP', _defaults.supportWhatsApp);
  static String get supportEmail =>
      _get('SUPPORT_EMAIL', _defaults.supportEmail);

  // ============================================================
  // EXTERNAL URLS
  // ============================================================

  static String get websiteUrl => _get('WEBSITE_URL', _defaults.websiteUrl);
  static String get tutorialsUrl =>
      _get('TUTORIALS_URL', _defaults.tutorialsUrl);
  static String get guideUrl => _get('GUIDE_URL', _defaults.guideUrl);
  static String get whatsAppUrl => 'https://wa.me/$supportWhatsApp';
  static String get phoneUrl => 'tel:$supportPhone';

  // ============================================================
  // DEBUG
  // ============================================================

  static void _printConfig() {
    if (!kDebugMode) return;

    debugPrint('''
═══════════════════════════════════════
📱 [EnvConfig] Configuration:
   App: $appName
   Environment: $environment
   Base URL: $baseUrl
   API URL: $apiBaseUrl
   Timeout: ${apiTimeout}ms
   Debug: $isDebugMode
═══════════════════════════════════════''');
  }
}

// ============================================================
// EXTENSIONS
// ============================================================

extension on String {
  /// Returns null if string is empty, otherwise returns the string
  String? ifEmpty(String? replacement) => isEmpty ? replacement : this;
}

enum _Platform { android, ios, other }
