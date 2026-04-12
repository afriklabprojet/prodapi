/// Clés centralisées pour SharedPreferences / SecureStorage
/// Évite les typos et facilite la maintenance
abstract class StorageKeys {
  StorageKeys._();

  // ─────────────────────────────────────────────────────────
  // Authentication
  // ─────────────────────────────────────────────────────────

  /// Token d'authentification Bearer
  static const authToken = 'auth_token';

  /// Token de rafraîchissement
  static const refreshToken = 'refresh_token';

  /// Utilisateur mis en cache (JSON)
  static const cachedUser = 'cached_user';

  /// Timestamp de la dernière vérification du token
  static const lastTokenCheck = 'last_token_check';

  // ─────────────────────────────────────────────────────────
  // Cart / Panier
  // ─────────────────────────────────────────────────────────

  /// Données du panier (JSON)
  static const cart = 'shopping_cart';

  /// Version du schéma du panier (pour migrations)
  static const cartSchemaVersion = 'cart_schema_version';

  // ─────────────────────────────────────────────────────────
  // Deep Links
  // ─────────────────────────────────────────────────────────

  /// Deep link en attente de traitement (après login)
  static const pendingDeepLink = 'pending_deep_link';

  // ─────────────────────────────────────────────────────────
  // Onboarding / First Launch
  // ─────────────────────────────────────────────────────────

  /// Onboarding terminé
  static const onboardingCompleted = 'onboarding_completed';

  /// Première ouverture de l'app
  static const firstLaunch = 'first_launch';

  /// Version de l'app au dernier lancement
  static const lastAppVersion = 'last_app_version';

  // ─────────────────────────────────────────────────────────
  // User Preferences
  // ─────────────────────────────────────────────────────────

  /// Mode de thème (light/dark/system)
  static const themeMode = 'theme_mode';

  /// Locale préférée
  static const locale = 'locale';

  /// Notifications activées
  static const notificationsEnabled = 'notifications_enabled';

  /// ID du device FCM
  static const fcmToken = 'fcm_token';

  // ─────────────────────────────────────────────────────────
  // Search / History
  // ─────────────────────────────────────────────────────────

  /// Historique des recherches
  static const searchHistory = 'search_history';

  /// Produits récemment vus
  static const recentlyViewedProducts = 'recently_viewed_products';

  /// Pharmacies favorites
  static const favoritePharmacies = 'favorite_pharmacies';

  // ─────────────────────────────────────────────────────────
  // Addresses
  // ─────────────────────────────────────────────────────────

  /// Dernière adresse de livraison utilisée
  static const lastDeliveryAddress = 'last_delivery_address';

  /// Adresses sauvegardées localement
  static const savedAddresses = 'saved_addresses';

  // ─────────────────────────────────────────────────────────
  // Checkout
  // ─────────────────────────────────────────────────────────

  /// État temporaire du checkout (prescription uploadée)
  static const checkoutPrescriptionId = 'checkout_prescription_id';

  /// Mode de paiement préféré
  static const preferredPaymentMode = 'preferred_payment_mode';
}
