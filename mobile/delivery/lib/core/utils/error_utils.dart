import 'dart:io';
import 'package:dio/dio.dart';

/// Convertit une exception technique en message lisible pour l'utilisateur.
String userFriendlyError(dynamic error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connexion lente, veuillez réessayer';
      case DioExceptionType.connectionError:
        return 'Pas de connexion internet';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return 'Session expirée, veuillez vous reconnecter';
        }
        if (statusCode == 404) {
          // Message spécifique selon le contexte
          final data = error.response?.data;
          if (data is Map && data['message'] is String) {
            final serverMsg = data['message'] as String;
            if (serverMsg.contains('Delivery')) {
              return 'Livraison introuvable ou déjà traitée';
            }
            if (serverMsg.contains('Order')) {
              return 'Commande introuvable';
            }
          }
          return 'Élément introuvable';
        }
        if (statusCode == 422) {
          // Tenter d'extraire le message de validation du serveur
          final data = error.response?.data;
          if (data is Map && data['message'] is String) {
            final serverMsg = data['message'] as String;
            // Ne pas exposer les messages techniques
            if (_isTechnicalServerMessage(serverMsg)) {
              return 'Données invalides';
            }
            return serverMsg;
          }
          return 'Données invalides';
        }
        if (statusCode != null && statusCode >= 500) {
          return 'Erreur serveur, veuillez réessayer plus tard';
        }
        return 'Une erreur est survenue';
      case DioExceptionType.cancel:
        return 'Requête annulée';
      default:
        return 'Une erreur réseau est survenue';
    }
  }

  if (error is SocketException) {
    return 'Pas de connexion internet';
  }

  if (error is FormatException) {
    return 'Erreur de format de données';
  }

  final message = error.toString();

  // Ne pas exposer les détails techniques
  if (message.contains('SocketException') || message.contains('Connection refused')) {
    return 'Pas de connexion internet';
  }
  if (message.contains('timeout') || message.contains('Timeout')) {
    return 'Connexion lente, veuillez réessayer';
  }
  if (message.contains('PERMISSION_DENIED') || message.contains('permission-denied')) {
    return 'Accès refusé. Veuillez vous reconnecter.';
  }
  if (message.contains('FAILED_PRECONDITION') || message.contains('requires an index')) {
    return 'Service en cours de configuration, réessayez dans quelques minutes';
  }
  if (message.contains('NOT_FOUND') || message.contains('not-found')) {
    return 'Conversation introuvable';
  }
  if (message.contains('UNAUTHENTICATED') || message.contains('unauthenticated')) {
    return 'Session expirée, veuillez vous reconnecter';
  }
  if (message.contains('firebase') || message.contains('Firebase')) {
    return 'Erreur de service, veuillez réessayer';
  }

  // Filtrer les messages techniques Laravel
  if (message.contains('No query results for model')) {
    if (message.contains('Delivery')) {
      return 'Livraison introuvable ou déjà traitée';
    }
    if (message.contains('Order')) {
      return 'Commande introuvable';
    }
    if (message.contains('Courier')) {
      return 'Profil coursier introuvable';
    }
    return 'Élément introuvable';
  }
  if (message.contains('ServerException:') || message.contains('SQLSTATE')) {
    return 'Une erreur est survenue, veuillez réessayer';
  }
  if (RegExp(r'\[App\\').hasMatch(message)) {
    return 'Une erreur est survenue, veuillez réessayer';
  }

  // Message générique pour tout le reste
  return 'Une erreur est survenue, veuillez réessayer';
}

/// Vérifie si un message serveur est technique (non lisible par l'utilisateur)
bool _isTechnicalServerMessage(String message) {
  final technicalPatterns = [
    'No query results for model',
    'SQLSTATE',
    'Call to undefined',
    'Undefined variable',
    'Trying to get property',
    'Call to a member function',
    'Array to string conversion',
    'Division by zero',
    'Maximum execution time',
    'Allowed memory size',
  ];

  for (final pattern in technicalPatterns) {
    if (message.contains(pattern)) {
      return true;
    }
  }

  // Pattern pour les namespaces Laravel comme [App\Models\Delivery]
  if (RegExp(r'\[App\\').hasMatch(message)) {
    return true;
  }

  return false;
}
