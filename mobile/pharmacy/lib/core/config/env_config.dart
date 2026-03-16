import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service de configuration d'environnement
/// Lit les valeurs depuis le fichier .env
class EnvConfig {
  static bool _isInitialized = false;
  static String? _overrideBaseUrl;

  /// Vérifie si la configuration est initialisée
  static bool get isInitialized => _isInitialized;

  /// Initialise la configuration en chargeant le fichier .env
  static Future<void> init({String? environment}) async {
    if (_isInitialized) {
      if (kDebugMode) debugPrint('⚠️ [EnvConfig] Déjà initialisé');
      return;
    }
    
    try {
      await dotenv.load(fileName: '.env');
      if (kDebugMode) debugPrint('✅ [EnvConfig] Fichier .env chargé');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [EnvConfig] Impossible de charger .env: $e');
    }
    
    _isInitialized = true;
    printConfig();
  }

  /// Permet de surcharger l'URL de base manuellement (utile pour les tests)
  static void setOverrideBaseUrl(String? url) {
    _overrideBaseUrl = url;
  }

  /// Récupère une valeur depuis .env avec une valeur par défaut
  static String _get(String key, String defaultValue) {
    return dotenv.env[key] ?? defaultValue;
  }

  /// Nom de l'application
  static String get appName => _get('APP_NAME', 'DR-PHARMA');

  /// Environnement (development/production)
  static String get appEnv => _get('APP_ENV', 'development');

  /// Détecte automatiquement l'environnement
  static bool get isDevelopment {
    final env = appEnv.toLowerCase();
    if (env == 'production' || env == 'prod') {
      return false;
    }
    return !kReleaseMode;
  }

  /// Est en environnement de production
  static bool get isProduction => !isDevelopment;

  /// Nom de l'environnement actuel
  static String get environment => isDevelopment ? 'development' : 'production';

  /// Mode debug activé
  static bool get isDebugMode => isDevelopment;

  /// IP locale pour appareil physique
  static String get localMachineIP => _get('LOCAL_MACHINE_IP', '192.168.1.100');

  /// URL de production
  static String get prodApiUrl => _get('PROD_API_URL', 'https://drlpharma.com');

  /// Retourne l'URL de base de l'API
  static String get baseUrl {
    // 1. Override manuel (priorité maximale)
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }

    // 2. Production
    if (isProduction) {
      return prodApiUrl;
    }

    // 3. Développement - détection automatique selon la plateforme
    return _detectPlatformUrl();
  }

  /// Détecte automatiquement l'URL selon la plateforme (dev uniquement)
  static String _detectPlatformUrl() {
    final configuredUrl = _get('API_BASE_URL', '');
    
    // Web
    if (kIsWeb) {
      return configuredUrl.isNotEmpty ? configuredUrl : 'http://127.0.0.1:8000';
    }

    // Mobile
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      } else if (Platform.isIOS) {
        return configuredUrl.isNotEmpty ? configuredUrl : 'http://127.0.0.1:8000';
      }
    } catch (e) {
      // Platform non supportée
    }

    return configuredUrl.isNotEmpty ? configuredUrl : 'http://127.0.0.1:8000';
  }

  /// URL de base de l'API (avec /api)
  static String get apiBaseUrl => '$baseUrl/api';

  /// URL de base pour les fichiers storage
  static String get storageBaseUrl => '$baseUrl/storage/';

  /// Timeout des requêtes API en millisecondes
  static int get apiTimeout {
    final timeout = _get('API_TIMEOUT', '15000');
    return int.tryParse(timeout) ?? 15000;
  }

  // ============================================================
  // INFOBIP
  // ============================================================

  /// Infobip application code (from Infobip Portal > App Profile)
  static String get infobipApplicationCode =>
      _get('INFOBIP_APPLICATION_CODE', '');

  // ============================================================
  // CONTACT & SUPPORT
  // ============================================================
  
  static String get supportPhone => _get('SUPPORT_PHONE', '+22507000000000');
  static String get supportWhatsApp => _get('SUPPORT_WHATSAPP', '22507000000000');
  static String get supportEmail => _get('SUPPORT_EMAIL', 'support@drlpharma.com');

  // ============================================================
  // URLS
  // ============================================================
  
  static String get websiteUrl => _get('WEBSITE_URL', 'https://drlpharma.com');
  static String get tutorialsUrl => _get('TUTORIALS_URL', 'https://drlpharma.com/tutoriels');
  static String get guideUrl => _get('GUIDE_URL', 'https://drlpharma.com/guide');
  static String get whatsAppUrl => 'https://wa.me/$supportWhatsApp';
  static String get phoneUrl => 'tel:$supportPhone';

  /// Affiche la configuration actuelle (pour debug)
  static void printConfig() {
    if (kDebugMode) debugPrint('═══════════════════════════════════════');
    if (kDebugMode) debugPrint('📱 [EnvConfig] Configuration actuelle:');
    if (kDebugMode) debugPrint('   App: $appName');
    if (kDebugMode) debugPrint('   Environment: $environment');
    if (kDebugMode) debugPrint('   Base URL: $baseUrl');
    if (kDebugMode) debugPrint('   API URL: $apiBaseUrl');
    if (kDebugMode) debugPrint('   Timeout: ${apiTimeout}ms');
    if (kDebugMode) debugPrint('   Debug Mode: $isDebugMode');
    if (kDebugMode) debugPrint('   Support Phone: $supportPhone');
    if (kDebugMode) debugPrint('═══════════════════════════════════════');
  }
}
