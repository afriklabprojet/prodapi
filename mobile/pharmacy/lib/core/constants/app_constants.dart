import '../config/env_config.dart';

/// Constantes centralisées de l'application pharmacie.
/// Lit dynamiquement la configuration depuis [EnvConfig].
class AppConstants {
  AppConstants._();

  // ============================================================
  // API
  // ============================================================

  /// URL de base de l'API (avec /api)
  static String get apiBaseUrl => EnvConfig.apiBaseUrl;

  /// URL de base brute (sans /api)
  static String get baseUrl => EnvConfig.baseUrl;

  /// URL de base pour les fichiers storage
  static String get storageBaseUrl => EnvConfig.storageBaseUrl;

  /// Timeout des requêtes API
  static Duration get apiTimeout => Duration(milliseconds: EnvConfig.apiTimeout);

  // ============================================================
  // SECURE STORAGE KEYS
  // ============================================================

  /// Clé de stockage du token d'authentification
  static const String tokenKey = 'auth_token';

  /// Clé de stockage des données utilisateur
  static const String userKey = 'auth_user';

  // ============================================================
  // APP INFO
  // ============================================================

  /// Nom de l'application
  static String get appName => EnvConfig.appName;

  // ============================================================
  // SUPPORT / CONTACT
  // ============================================================

  static String get supportPhone => EnvConfig.supportPhone;
  static String get supportEmail => EnvConfig.supportEmail;
  static String get supportWhatsApp => EnvConfig.supportWhatsApp;

  // ============================================================
  // URLS
  // ============================================================

  static String get websiteUrl => EnvConfig.websiteUrl;
  static String get tutorialsUrl => EnvConfig.tutorialsUrl;
  static String get guideUrl => EnvConfig.guideUrl;
}
