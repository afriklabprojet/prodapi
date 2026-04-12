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
          return 'Ressource introuvable';
        }
        if (statusCode == 422) {
          // Tenter d'extraire le message de validation du serveur
          final data = error.response?.data;
          if (data is Map && data['message'] is String) {
            return data['message'] as String;
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
  if (message.contains('firebase') || message.contains('Firebase')) {
    return 'Erreur de service, veuillez réessayer';
  }

  // Message générique pour tout le reste
  return 'Une erreur est survenue, veuillez réessayer';
}
