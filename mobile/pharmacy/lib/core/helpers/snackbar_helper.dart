import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centralized SnackBar helper for consistent message display across the app.
///
/// Usage:
/// ```dart
/// SnackBarHelper.showError(context, 'Something went wrong');
/// SnackBarHelper.showSuccess(context, 'Profile updated');
/// SnackBarHelper.showWarning(context, 'Low stock');
/// ```
class SnackBarHelper {
  SnackBarHelper._();

  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..clearMaterialBanners()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () => messenger.hideCurrentSnackBar(),
          ),
        ),
      );
  }

  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..clearMaterialBanners()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () => messenger.hideCurrentSnackBar(),
          ),
        ),
      );
  }

  /// Parses network errors into user-friendly French messages.
  static String parseNetworkError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connexion lente. Vérifiez votre connexion internet.';
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Le serveur met trop de temps à répondre. Réessayez.';
        case DioExceptionType.connectionError:
          return 'Impossible de se connecter au serveur. Vérifiez votre connexion.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) return 'Email ou mot de passe incorrect.';
          if (statusCode == 403) {
            return 'Accès refusé. Compte peut-être désactivé.';
          }
          if (statusCode == 404) return 'Service non disponible.';
          if (statusCode == 422) {
            return 'Données invalides. Vérifiez vos informations.';
          }
          if (statusCode != null && statusCode >= 500) {
            return 'Erreur serveur. Réessayez plus tard.';
          }
          return 'Erreur de communication avec le serveur.';
        case DioExceptionType.cancel:
          return 'Requête annulée.';
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return 'Pas de connexion internet.';
          }
          return 'Erreur réseau inattendue.';
        default:
          return 'Erreur de connexion.';
      }
    }
    if (error is SocketException) {
      return 'Pas de connexion internet.';
    }
    return error?.toString() ?? 'Une erreur est survenue.';
  }
}
