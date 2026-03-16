/// Messages d'erreur utilisateur centralisés.
class ErrorMessages {
  ErrorMessages._();

  static const String unknownError = 'Une erreur inattendue est survenue. Veuillez réessayer.';
  static const String networkError = 'Vérifiez votre connexion internet et réessayez.';
  static const String serverError = 'Le serveur est temporairement indisponible.';
  static const String sessionExpired = 'Votre session a expiré. Veuillez vous reconnecter.';

  /// Retourne un message d'erreur adapté pour les opérations d'inventaire.
  static String getInventoryError(String rawError) {
    final lower = rawError.toLowerCase();

    if (lower.contains('network') || lower.contains('connexion') || lower.contains('connect')) {
      return networkError;
    }
    if (lower.contains('server') || lower.contains('500')) {
      return serverError;
    }
    if (lower.contains('unauthorized') || lower.contains('401')) {
      return sessionExpired;
    }
    if (lower.contains('duplicate') || lower.contains('already exists')) {
      return 'Ce produit existe déjà dans votre inventaire.';
    }
    if (lower.contains('validation')) {
      return 'Veuillez vérifier les informations saisies.';
    }
    // Return the raw message if somewhat readable, else generic
    if (rawError.length < 120 && !rawError.contains('Exception')) {
      return rawError;
    }
    return unknownError;
  }

  /// Retourne un message d'erreur adapté pour les commandes.
  static String getOrderError(String rawError) {
    final lower = rawError.toLowerCase();

    if (lower.contains('network') || lower.contains('connexion')) {
      return networkError;
    }
    if (lower.contains('not found') || lower.contains('404')) {
      return 'Commande introuvable.';
    }
    return unknownError;
  }
}
