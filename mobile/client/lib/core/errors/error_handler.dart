import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/app_logger.dart';
import 'exceptions.dart' as exc;

/// Service centralisé pour la gestion des erreurs
/// Fournit des patterns consistants pour gérer les erreurs à travers l'application
class ErrorHandler {
  ErrorHandler._();

  /// Convertit une exception en message utilisateur friendly
  static String getErrorMessage(dynamic error) {
    // --- AppException hierarchy (error_handler.dart) ---
    if (error is AppException) {
      return error.userMessage;
    }

    // --- Data-layer exceptions (exceptions.dart) ---
    if (error is exc.ServerException) {
      return error.message;
    }
    if (error is exc.NetworkException) {
      return error.message;
    }
    if (error is exc.UnauthorizedException) {
      return 'Session expirée. Veuillez vous reconnecter';
    }
    if (error is exc.ValidationException) {
      final first = error.errors.values.firstOrNull?.firstOrNull;
      return first ?? 'Données invalides';
    }
    if (error is exc.CacheException) {
      return error.message;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    // SocketException n'existe pas sur Web - vérifier le type par nom
    if (!kIsWeb && error.runtimeType.toString() == 'SocketException') {
      return 'Pas de connexion internet';
    }

    if (error is TimeoutException) {
      return 'La requête a pris trop de temps';
    }

    if (error is FormatException) {
      return 'Données invalides reçues du serveur';
    }

    // Log l'erreur inconnue
    AppLogger.error('Erreur non gérée', error: error);
    return 'Une erreur inattendue s\'est produite';
  }

  /// Gère les erreurs Dio spécifiquement
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Délai de connexion dépassé';

      case DioExceptionType.connectionError:
        return 'Impossible de se connecter au serveur';

      case DioExceptionType.badResponse:
        return _handleHttpError(error.response?.statusCode, error.response?.data);

      case DioExceptionType.cancel:
        return 'Requête annulée';

      case DioExceptionType.badCertificate:
        return 'Certificat de sécurité invalide';

      case DioExceptionType.unknown:
        // SocketException n'existe pas sur Web
        if (!kIsWeb && error.error?.runtimeType.toString() == 'SocketException') {
          return 'Pas de connexion internet';
        }
        return 'Erreur de connexion';
    }
  }

  /// Gère les codes d'erreur HTTP
  static String _handleHttpError(int? statusCode, dynamic data) {
    // Essayer d'extraire le message du serveur
    String? serverMessage;
    if (data is Map) {
      serverMessage = data['message'] as String? ?? 
                      data['error'] as String? ??
                      (data['errors'] is Map ? 
                        (data['errors'] as Map).values.first?.toString() : null);
    }

    switch (statusCode) {
      case 400:
        return serverMessage ?? 'Requête invalide';
      case 401:
        return 'Session expirée. Veuillez vous reconnecter';
      case 403:
        return serverMessage ?? 'Accès non autorisé';
      case 404:
        return serverMessage ?? 'Ressource non trouvée';
      case 409:
        return serverMessage ?? 'Conflit de données';
      case 422:
        return serverMessage ?? 'Données invalides';
      case 429:
        return 'Trop de requêtes. Veuillez patienter';
      case 500:
        return 'Erreur serveur. Veuillez réessayer plus tard';
      case 502:
      case 503:
        return 'Service temporairement indisponible';
      default:
        return serverMessage ?? 'Erreur $statusCode';
    }
  }

  /// Exécute une opération avec gestion d'erreur automatique
  static Future<T?> runSafe<T>(
    Future<T> Function() operation, {
    required void Function(String message) onError,
    String? operationName,
    T? fallbackValue,
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      if (operationName != null) {
        AppLogger.error('Erreur dans $operationName', error: e, stackTrace: stack);
      }
      onError(getErrorMessage(e));
      return fallbackValue;
    }
  }

  /// Affiche un snackbar d'erreur
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
  }

  /// Affiche un snackbar de succès
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Affiche un snackbar d'avertissement
  static void showWarningSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Affiche une dialog d'erreur
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) async {
    if (!context.mounted) return;
    
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
        title: Text(title),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onPressed?.call();
            },
            child: Text(buttonText ?? 'OK'),
          ),
        ],
      ),
    );
  }

  /// Affiche une dialog de confirmation
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    bool isDangerous = false,
  }) async {
    if (!context.mounted) return false;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: isDangerous
            ? Icon(Icons.warning, color: Colors.orange.shade700, size: 48)
            : null,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDangerous
                ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}

/// Classe de base pour les exceptions de l'application
class AppException implements Exception {
  const AppException({
    required this.userMessage,
    this.technicalMessage,
    this.code,
    this.originalError,
  });

  /// Message à afficher à l'utilisateur
  final String userMessage;

  /// Message technique pour le debug
  final String? technicalMessage;

  /// Code d'erreur (optionnel)
  final String? code;

  /// Erreur originale
  final dynamic originalError;

  @override
  String toString() => 'AppException: $userMessage (code: $code)';
}

/// Exception pour les erreurs réseau
class NetworkException extends AppException {
  const NetworkException({
    super.userMessage = 'Erreur de connexion',
    super.technicalMessage,
    super.originalError,
  }) : super(code: 'NETWORK_ERROR');
}

/// Exception pour les erreurs d'authentification
class AuthException extends AppException {
  const AuthException({
    super.userMessage = 'Erreur d\'authentification',
    super.technicalMessage,
    super.originalError,
  }) : super(code: 'AUTH_ERROR');
}

/// Exception pour les erreurs de validation
class ValidationException extends AppException {
  const ValidationException({
    required super.userMessage,
    this.fieldErrors = const {},
    super.technicalMessage,
    super.originalError,
  }) : super(code: 'VALIDATION_ERROR');

  /// Erreurs par champ
  final Map<String, String> fieldErrors;
}

/// Exception pour les ressources non trouvées
class NotFoundException extends AppException {
  const NotFoundException({
    super.userMessage = 'Ressource non trouvée',
    super.technicalMessage,
    super.originalError,
  }) : super(code: 'NOT_FOUND');
}

/// Exception pour les opérations non autorisées
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.userMessage = 'Action non autorisée',
    super.technicalMessage,
    super.originalError,
  }) : super(code: 'FORBIDDEN');
}

/// Extension pour gérer les erreurs dans les widgets
extension ErrorHandlerContext on BuildContext {
  /// Affiche une erreur
  void showError(String message) {
    ErrorHandler.showErrorSnackBar(this, message);
  }

  /// Affiche un succès
  void showSuccess(String message) {
    ErrorHandler.showSuccessSnackBar(this, message);
  }

  /// Affiche un avertissement
  void showWarning(String message) {
    ErrorHandler.showWarningSnackBar(this, message);
  }
}
