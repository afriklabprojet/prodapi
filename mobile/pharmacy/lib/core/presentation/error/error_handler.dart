import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Types d'erreurs pour personnaliser l'affichage
enum ErrorType {
  /// Erreur d'authentification (identifiants incorrects)
  authentication,
  
  /// Erreur réseau (pas de connexion, timeout)
  network,
  
  /// Erreur serveur (500, 503)
  server,
  
  /// Erreur de validation (champs invalides)
  validation,
  
  /// Erreur générique
  generic,
}

/// Configuration d'affichage pour une erreur
class ErrorConfig {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const ErrorConfig({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.backgroundColor = Colors.white,
  });

  /// Factory pour créer une config selon le type d'erreur
  factory ErrorConfig.fromType(ErrorType type) {
    switch (type) {
      case ErrorType.authentication:
        return const ErrorConfig(
          title: 'Identifiants incorrects',
          icon: Icons.lock_outline,
          iconColor: Colors.orange,
        );
      case ErrorType.network:
        return const ErrorConfig(
          title: 'Erreur de connexion',
          icon: Icons.wifi_off_rounded,
          iconColor: Colors.blueGrey,
        );
      case ErrorType.server:
        return const ErrorConfig(
          title: 'Erreur serveur',
          icon: Icons.cloud_off_rounded,
          iconColor: Colors.red,
        );
      case ErrorType.validation:
        return const ErrorConfig(
          title: 'Données invalides',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.amber,
        );
      case ErrorType.generic:
        return const ErrorConfig(
          title: 'Erreur',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
    }
  }
}

/// Service centralisé pour la gestion des erreurs UI
/// 
/// Utilisation:
/// ```dart
/// ErrorHandler.showErrorDialog(context, 'Message d\'erreur');
/// ErrorHandler.showErrorSnackBar(context, 'Message d\'erreur');
/// ```
class ErrorHandler {
  ErrorHandler._();


  // ══════════════════════════════════════════════════════════════════════════
  // DÉTECTION DU TYPE D'ERREUR
  // ══════════════════════════════════════════════════════════════════════════

  /// Détecte automatiquement le type d'erreur selon le message
  static ErrorType detectErrorType(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('identifiants') ||
        lowerMessage.contains('incorrect') ||
        lowerMessage.contains('mot de passe') ||
        lowerMessage.contains('authentification') ||
        lowerMessage.contains('non autorisé') ||
        lowerMessage.contains('unauthorized')) {
      return ErrorType.authentication;
    }

    if (lowerMessage.contains('connexion') ||
        lowerMessage.contains('réseau') ||
        lowerMessage.contains('internet') ||
        lowerMessage.contains('timeout') ||
        lowerMessage.contains('network')) {
      return ErrorType.network;
    }

    if (lowerMessage.contains('serveur') ||
        lowerMessage.contains('server') ||
        lowerMessage.contains('500') ||
        lowerMessage.contains('503') ||
        lowerMessage.contains('indisponible')) {
      return ErrorType.server;
    }

    if (lowerMessage.contains('invalide') ||
        lowerMessage.contains('validation') ||
        lowerMessage.contains('format') ||
        lowerMessage.contains('requis')) {
      return ErrorType.validation;
    }

    return ErrorType.generic;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOG D'ERREUR
  // ══════════════════════════════════════════════════════════════════════════

  /// Affiche un dialogue d'erreur stylisé
  /// 
  /// [context] - BuildContext pour afficher le dialogue
  /// [message] - Message d'erreur à afficher
  /// [type] - Type d'erreur (auto-détecté si null)
  /// [onDismiss] - Callback appelé après fermeture du dialogue
  static Future<void> showErrorDialog(
    BuildContext context,
    String message, {
    ErrorType? type,
    VoidCallback? onDismiss,
  }) async {
    final errorType = type ?? detectErrorType(message);
    final config = ErrorConfig.fromType(errorType);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _ErrorDialog(
        config: config,
        message: message,
        onDismiss: () {
          Navigator.of(dialogContext).pop();
          onDismiss?.call();
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SNACKBAR D'ERREUR
  // ══════════════════════════════════════════════════════════════════════════

  /// Affiche un snackbar d'erreur
  /// 
  /// [context] - BuildContext pour afficher le snackbar
  /// [message] - Message d'erreur à afficher
  /// [type] - Type d'erreur (auto-détecté si null)
  /// [duration] - Durée d'affichage (défaut: 4 secondes)
  /// [action] - Action optionnelle (ex: "Réessayer")
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    ErrorType? type,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final errorType = type ?? detectErrorType(message);
    final config = ErrorConfig.fromType(errorType);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(config.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: config.iconColor.withAlpha(230),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
        action: action,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SNACKBAR DE SUCCÈS
  // ══════════════════════════════════════════════════════════════════════════

  /// Affiche un snackbar de succès
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SNACKBAR D'INFO
  // ══════════════════════════════════════════════════════════════════════════

  /// Affiche un snackbar d'information
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET PRIVÉ: DIALOG D'ERREUR
// ══════════════════════════════════════════════════════════════════════════════

class _ErrorDialog extends StatelessWidget {
  final ErrorConfig config;
  final String message;
  final VoidCallback onDismiss;

  const _ErrorDialog({
    required this.config,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: config.iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(config.icon, color: config.iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              config.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 15, color: Color(0xFF616161)),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDismiss,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
    );
  }
}
