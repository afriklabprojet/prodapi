import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

/// Utility to convert raw exceptions into user-friendly French messages.
/// Prevents leaking stack traces, API URLs, or internal details to end users.
class ErrorFormatter {
  ErrorFormatter._();

  /// Returns a user-friendly French error message for any exception.
  static String userFriendly(dynamic error) {
    if (error is DioException) {
      return _fromDio(error);
    }
    if (error is SocketException) {
      return 'Pas de connexion Internet. Vérifiez votre réseau.';
    }
    if (error is HttpException) {
      return 'Erreur de communication avec le serveur.';
    }
    if (error is FormatException) {
      return 'Données invalides reçues du serveur.';
    }
    if (error is TimeoutException ||
        error.toString().contains('TimeoutException')) {
      return 'La requête a pris trop de temps. Réessayez.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  static String _fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La connexion a expiré. Vérifiez votre réseau.';
      case DioExceptionType.connectionError:
        return 'Impossible de se connecter au serveur.';
      case DioExceptionType.cancel:
        return 'La requête a été annulée.';
      case DioExceptionType.badResponse:
        return _fromStatusCode(error.response?.statusCode);
      default:
        return 'Erreur de communication. Réessayez.';
    }
  }

  static String _fromStatusCode(int? statusCode) {
    if (statusCode == null) return 'Erreur serveur inattendue.';
    switch (statusCode) {
      case 400:
        return 'Requête invalide. Vérifiez les informations saisies.';
      case 401:
        return 'Session expirée. Veuillez vous reconnecter.';
      case 403:
        return 'Action non autorisée.';
      case 404:
        return 'Ressource introuvable.';
      case 409:
        return 'Conflit détecté. Réessayez.';
      case 422:
        return 'Données invalides. Vérifiez les champs du formulaire.';
      case 429:
        return 'Trop de requêtes. Patientez un moment.';
      case >= 500:
        return 'Erreur serveur. Réessayez dans quelques instants.';
      default:
        return 'Une erreur est survenue (code $statusCode).';
    }
  }
}
