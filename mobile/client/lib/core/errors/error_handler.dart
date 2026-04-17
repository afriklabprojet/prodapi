import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/app_logger.dart';
import 'exceptions.dart' as exc;

/// Service centralisé pour la gestion des erreurs.
class ErrorHandler {
  ErrorHandler._();

  // ---------------------------------------------------------------------------
  // Message d'erreur
  // ---------------------------------------------------------------------------

  /// Retourne un message lisible à partir de n'importe quelle exception.
  static String getErrorMessage(dynamic error) {
    if (error is AppException) return error.userMessage;

    if (error is exc.ServerException) return error.message;
    if (error is exc.NetworkException) return error.message;
    if (error is exc.CacheException) return error.message;
    if (error is exc.UnauthorizedException) {
      return 'Session expirée. Veuillez vous reconnecter';
    }
    if (error is exc.ValidationException) {
      return error.errors.values.firstOrNull?.firstOrNull ?? 'Données invalides';
    }

    if (error is DioException) return _handleDioError(error);

    if (!kIsWeb && error.runtimeType.toString() == 'SocketException') {
      return 'Pas de connexion internet';
    }
    if (error is TimeoutException) return 'La requête a pris trop de temps';
    if (error is FormatException) return 'Données invalides reçues du serveur';

    AppLogger.error('Erreur non gérée', error: error);
    return 'Une erreur inattendue s\'est produite';
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Délai de connexion dépassé';
      case DioExceptionType.connectionError:
        if (!kIsWeb && error.error?.runtimeType.toString() == 'SocketException') {
          return 'Pas de connexion internet';
        }
        return 'Impossible de se connecter au serveur';
      case DioExceptionType.badResponse:
        return _handleHttpError(error.response?.statusCode, error.response?.data);
      case DioExceptionType.cancel:
        return 'Requête annulée';
      case DioExceptionType.badCertificate:
        return 'Certificat de sécurité invalide';
      case DioExceptionType.unknown:
        return 'Erreur de connexion';
    }
  }

  static String _handleHttpError(int? statusCode, dynamic data) {
    final serverMessage = switch (data) {
      Map() => data['message'] as String? ??
          data['error'] as String? ??
          (data['errors'] is Map
              ? (data['errors'] as Map).values.first?.toString()
              : null),
      _ => null,
    };

    return switch (statusCode) {
      400 => serverMessage ?? 'Requête invalide',
      401 => 'Session expirée. Veuillez vous reconnecter',
      403 => serverMessage ?? 'Accès non autorisé',
      404 => serverMessage ?? 'Ressource non trouvée',
      409 => serverMessage ?? 'Conflit de données',
      422 => serverMessage ?? 'Données invalides',
      429 => 'Trop de requêtes. Veuillez patienter',
      500 => 'Erreur serveur. Veuillez réessayer plus tard',
      502 || 503 => 'Service temporairement indisponible',
      _ => serverMessage ?? 'Erreur $statusCode',
    };
  }

  // ---------------------------------------------------------------------------
  // Opération protégée
  // ---------------------------------------------------------------------------

  /// Exécute une opération en capturant les erreurs automatiquement.
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

  // ---------------------------------------------------------------------------
  // Snackbars
  // ---------------------------------------------------------------------------

  static void showErrorSnackBar(BuildContext context, String message) =>
      _showSnackBar(context, message, Colors.red.shade700, Icons.error_outline);

  static void showSuccessSnackBar(BuildContext context, String message) =>
      _showSnackBar(context, message, Colors.green.shade700, Icons.check_circle_outline);

  static void showWarningSnackBar(BuildContext context, String message) =>
      _showSnackBar(context, message, Colors.orange.shade700, Icons.warning_amber);

  static void _showSnackBar(
    BuildContext context,
    String message,
    Color color,
    IconData icon, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: duration,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () => messenger.hideCurrentSnackBar(),
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  /// Affiche une dialog d'erreur.
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

  /// Affiche une dialog de confirmation et retourne `true` si l'utilisateur confirme.
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

// =============================================================================
// Exceptions applicatives
// =============================================================================

/// Classe de base pour les exceptions métier de l'application.
class AppException implements Exception {
  const AppException({
    required this.userMessage,
    this.technicalMessage,
    this.code,
    this.originalError,
  });

  final String userMessage;
  final String? technicalMessage;
  final String? code;
  final dynamic originalError;

  @override
  String toString() => 'AppException[$code]: $userMessage';
}

class NetworkException extends AppException {
  const NetworkException({
    super.userMessage = 'Erreur de connexion',
    super.technicalMessage,
    super.originalError,
  }) : super(code: 'NETWORK_ERROR');
}

class AuthException extends AppException {
  const AuthException({
    super.userMessage = 'Erreur d\'authentification',
    super.technicalMessage,
    super.originalError,
  }) : super(code: 'AUTH_ERROR');
}

class ValidationException extends AppException {
  const ValidationException({
    required super.userMessage,
    this.fieldErrors = const {},
    super.technicalMessage,
    super.originalError,
  }) : super(code: 'VALIDATION_ERROR');

  final Map<String, String> fieldErrors;
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.userMessage = 'Ressource non trouvée',
    super.technicalMessage,
    super.originalError,
  }) : super(code: 'NOT_FOUND');
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.userMessage = 'Action non autorisée',
    super.technicalMessage,
    super.originalError,
  }) : super(code: 'FORBIDDEN');
}

// =============================================================================
// Extension BuildContext
// =============================================================================

extension ErrorHandlerContext on BuildContext {
  void showError(String message) => ErrorHandler.showErrorSnackBar(this, message);
  void showSuccess(String message) => ErrorHandler.showSuccessSnackBar(this, message);
  void showWarning(String message) => ErrorHandler.showWarningSnackBar(this, message);
}

