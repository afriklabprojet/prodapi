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

  /// Force l'utilisation de l'URL de production (pour tester sur device physique)
  static const bool _forceProductionApi = true;

  /// API Base URL
  static String get apiBaseUrl {
    // Toujours utiliser production sauf si explicitement en dev local
    // Pour dev local avec émulateur, mettre _forceProductionApi = false
    if (isProduction || _forceProductionApi) {
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://drlpharma.pro/api',
      );
    }

    // En développement local uniquement
    if (kIsWeb) {
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000/api',
      );
    }
    // Android Emulator uniquement
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
        defaultValue: 'https://drlpharma.pro',
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

  /// Timeouts réseau
  static const Duration connectionTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Timeouts spécifiques pour les paiements (opérations plus lentes)
  static const Duration paymentConnectionTimeout = Duration(seconds: 30);
  static const Duration paymentReceiveTimeout = Duration(seconds: 45);

  /// Connectivity check URL (204 No Content endpoint for fast check)
  static const String connectivityCheckUrl =
      'https://www.google.com/generate_204';

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
    defaultValue: 'support@drlpharma.pro',
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
    defaultValue: 'https://drlpharma.pro/privacy',
  );

  /// URL conditions d'utilisation
  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://drlpharma.pro/terms',
  );

  // ============================================================
  // CARTE / GÉOLOCALISATION
  // ============================================================

  /// Zoom par défaut de la carte
  static const double mapDefaultZoom = 14.5;

  /// Zoom minimum autorisé
  static const double mapMinZoom = 10.0;

  /// Zoom maximum autorisé
  static const double mapMaxZoom = 19.0;

  /// Zoom lors du focus sur une livraison
  static const double mapDeliveryZoom = 16.0;

  /// Coordonnées par défaut (Abidjan, Côte d'Ivoire)
  static const double defaultLatitude = 5.3600;
  static const double defaultLongitude = -4.0083;

  // ============================================================
  // GÉOFENCING
  // ============================================================

  /// Rayon de géofence pour la pharmacie (en mètres)
  static const double geofencePharmacyRadius = 100.0;

  /// Rayon de géofence pour le client (en mètres)
  static const double geofenceClientRadius = 50.0;

  /// Distance minimale pour déclencher une mise à jour de position (en mètres)
  static const double locationMinDistance = 10.0;

  /// Intervalle de mise à jour de la position (en secondes)
  static const int locationUpdateInterval = 30;

  /// Intervalle de mise à jour rapide lors d'une livraison active (en secondes)
  static const int locationUpdateIntervalActive = 10;

  // ============================================================
  // LIMITES & SEUILS
  // ============================================================

  /// Vitesse maximale acceptable (km/h) - au-delà = anomalie
  static const double maxSpeedKmh = 80.0;

  /// Distance maximale acceptable pour une livraison (km)
  static const double maxDeliveryDistanceKm = 50.0;

  /// Nombre maximum de livraisons simultanées (mode batch)
  static const int maxBatchDeliveries = 5;

  /// Délai avant expiration d'une session de paiement (en minutes)
  static const int paymentSessionTimeoutMinutes = 30;

  // ============================================================
  // ANIMATIONS
  // ============================================================

  /// Durée standard des animations (ms)
  static const int animationDurationMs = 300;

  /// Durée des animations longues (ms)
  static const int animationDurationLongMs = 600;

  /// Durée du splash screen (ms)
  static const int splashDurationMs = 2000;

  /// Durée d'affichage des snackbars (secondes)
  static const int snackbarDurationSec = 4;

  // ============================================================
  // FICHIERS & MÉDIAS
  // ============================================================

  /// Taille maximale d'une image uploadée (en octets) - 5 MB
  static const int maxImageSizeBytes = 5 * 1024 * 1024;

  /// Qualité de compression des images (0-100)
  static const int imageCompressionQuality = 80;

  /// Largeur maximale des images après compression
  static const int maxImageWidth = 1024;

  /// Hauteur maximale des images après compression
  static const int maxImageHeight = 1024;

  // ============================================================
  // SCANNER DE DOCUMENTS
  // ============================================================

  /// Largeur maximale des documents scannés (pixels)
  static const int documentMaxWidth = 2048;

  /// Hauteur maximale des documents scannés (pixels)
  static const int documentMaxHeight = 2048;

  /// Qualité JPEG des documents scannés (0-100)
  static const int documentImageQuality = 95;

  /// Ratio d'aspect A4 (hauteur/largeur)
  static const double documentA4AspectRatio = 1.414;

  /// Seuil en pixels pour le scoring qualité (4MP)
  static const int qualityBenchmarkPixels = 4000000;

  /// Poids résolution dans le score qualité (0-1)
  static const double qualityWeightResolution = 0.6;

  /// Poids taille dans le score qualité (0-1)
  static const double qualityWeightSize = 0.4;

  // ============================================================
  // DEEP LINKS & APP IDENTIFIERS
  // ============================================================

  /// Scheme pour les deep links
  static const String deepLinkScheme = 'drpharma-courier';

  /// Host pour les deep links de paiement
  static const String deepLinkPaymentHost = 'payment';

  /// Bundle ID iOS
  static const String iosBundleId = 'com.drpharma.courier';

  /// App Group iOS pour widgets
  static const String iosAppGroup = 'group.com.drpharma.courier';

  /// Package Android
  static const String androidPackage = 'com.drpharma.courier';

  /// Nom du background task localisation
  static const String backgroundTaskName = '$androidPackage.locationUpdate';

  // ============================================================
  // PAIEMENT JEKO
  // ============================================================

  /// Nombre max de tentatives de paiement
  static const int paymentMaxRetries = 3;

  /// Temps max d'attente d'un paiement (minutes)
  static const int paymentMaxWaitMinutes = 5;

  /// Intervalles de polling exponentiels (en secondes)
  static const List<int> paymentPollingIntervals = [
    3,
    3,
    5,
    5,
    8,
    8,
    13,
    13,
    21,
    21,
  ];

  /// Intervalle max de polling (secondes)
  static const int paymentMaxPollingInterval = 30;

  // ============================================================
  // VÉRIFICATION LIVENESS
  // ============================================================

  /// Délais de retry liveness (secondes)
  static const List<int> livenessRetryDelays = [2, 4, 8];

  /// Max tentatives session liveness
  static const int livenessMaxSessionRetries = 3;

  /// Max tentatives challenge liveness
  static const int livenessMaxChallengeRetries = 3;

  /// Timeout connexion liveness
  static const Duration livenessConnectTimeout = Duration(seconds: 15);

  /// Timeout réception liveness (plus long car traitement IA)
  static const Duration livenessReceiveTimeout = Duration(seconds: 30);

  // ============================================================
  // FEATURE FLAGS
  // ============================================================

  /// Active le mode debug des livraisons (affiche coordonnées brutes)
  static const bool debugDeliveries = bool.fromEnvironment(
    'DEBUG_DELIVERIES',
    defaultValue: false,
  );

  /// Active les notifications sonores
  static const bool enableSoundNotifications = true;

  /// Active le mode batch (plusieurs livraisons simultanées)
  static const bool enableBatchMode = true;

  /// Active le système de défis/gamification
  static const bool enableChallenges = true;
}
