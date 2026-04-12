/// Contract pour l'analytics multi-provider
abstract class AnalyticsContract {
  /// Initialiser les providers
  Future<void> init();

  /// Identifier l'utilisateur (après login)
  Future<void> identify(String userId, {Map<String, dynamic>? traits});

  /// Réinitialiser (logout)
  Future<void> reset();

  /// Tracker un événement
  Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  });

  /// Tracker un écran
  Future<void> screen(
    String screenName, {
    Map<String, dynamic>? properties,
  });

  /// Définir une propriété utilisateur
  Future<void> setUserProperty(String name, String value);

  /// Tracker une conversion/achat
  Future<void> trackPurchase({
    required String orderId,
    required double total,
    required String currency,
    Map<String, dynamic>? properties,
  });

  /// Tracker le début du checkout
  Future<void> trackCheckoutStarted({
    required double cartValue,
    required int itemCount,
    Map<String, dynamic>? properties,
  });

  /// Tracker un ajout au panier
  Future<void> trackAddToCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
    Map<String, dynamic>? properties,
  });

  /// Tracker une erreur
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? errorCode,
    Map<String, dynamic>? properties,
  });
}
