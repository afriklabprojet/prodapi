import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../accessibility/a11y_config.dart';
import '../constants/app_colors.dart';

/// Types de snackbar disponibles
enum SnackbarType { success, error, warning, info, undo }

/// Widget unifié pour tous les snackbars de l'application
/// Respecte les guidelines d'accessibilité (WCAG) et offre une UX cohérente
class AppSnackbar {
  AppSnackbar._();

  /// Affiche un snackbar de succès
  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      type: SnackbarType.success,
      icon: Icons.check_circle_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Affiche un snackbar d'erreur avec option de retry
  static void error(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      type: SnackbarType.error,
      icon: Icons.error_rounded,
      actionLabel: onRetry != null ? 'Réessayer' : null,
      onAction: onRetry,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  /// Affiche un snackbar d'avertissement
  static void warning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      type: SnackbarType.warning,
      icon: Icons.warning_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Affiche un snackbar d'information
  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      type: SnackbarType.info,
      icon: Icons.info_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Affiche un snackbar avec option d'annulation (undo)
  /// Idéal pour les suppressions avec possibilité de restaurer
  static void undo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      type: SnackbarType.undo,
      icon: Icons.delete_outline_rounded,
      actionLabel: 'Annuler',
      onAction: onUndo,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  /// Affiche un snackbar de chargement (sans auto-dismiss)
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> loading(
    BuildContext context,
    String message,
  ) {
    HapticFeedback.lightImpact();

    final snackBar = SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(days: 1), // Ne se ferme pas automatiquement
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      dismissDirection: DismissDirection.none,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Ferme le snackbar actuel
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Méthode interne pour construire et afficher le snackbar
  static void _show(
    BuildContext context, {
    required String message,
    required SnackbarType type,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    // Haptic feedback selon le type
    switch (type) {
      case SnackbarType.success:
        HapticFeedback.lightImpact();
        break;
      case SnackbarType.error:
        HapticFeedback.heavyImpact();
        break;
      case SnackbarType.warning:
        HapticFeedback.mediumImpact();
        break;
      default:
        HapticFeedback.selectionClick();
    }

    // Durée adaptée à l'accessibilité
    final effectiveDuration =
        duration ?? A11yConfig.getMessageDuration(context);

    // Couleurs selon le type
    final (backgroundColor, iconColor, actionColor) = _getColors(type);

    final snackBar = SnackBar(
      content: Row(
        children: [
          // Icône avec cercle de fond
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
              semanticLabel: _getSemanticLabel(type),
            ),
          ),
          const SizedBox(width: 12),
          // Message
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      duration: effectiveDuration,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: actionColor,
              onPressed: () {
                HapticFeedback.selectionClick();
                onAction?.call();
              },
            )
          : null,
    );

    // Fermer le snackbar précédent et afficher le nouveau
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Retourne les couleurs selon le type de snackbar
  static (Color, Color, Color) _getColors(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return (AppColors.success, Colors.white, Colors.white);
      case SnackbarType.error:
        return (AppColors.error, Colors.white, Colors.yellow);
      case SnackbarType.warning:
        return (AppColors.warning, Colors.white, Colors.white);
      case SnackbarType.info:
        return (AppColors.info, Colors.white, Colors.white);
      case SnackbarType.undo:
        return (AppColors.textSecondary, Colors.white, AppColors.primary);
    }
  }

  /// Retourne le label sémantique pour les lecteurs d'écran
  static String _getSemanticLabel(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return 'Succès';
      case SnackbarType.error:
        return 'Erreur';
      case SnackbarType.warning:
        return 'Avertissement';
      case SnackbarType.info:
        return 'Information';
      case SnackbarType.undo:
        return 'Élément supprimé';
    }
  }
}

/// Extension pour faciliter l'utilisation depuis BuildContext
extension AppSnackbarExtension on BuildContext {
  void showSuccessSnackbar(String message, {VoidCallback? onAction}) {
    AppSnackbar.success(this, message, onAction: onAction);
  }

  void showErrorSnackbar(String message, {VoidCallback? onRetry}) {
    AppSnackbar.error(this, message, onRetry: onRetry);
  }

  void showInfoSnackbar(String message) {
    AppSnackbar.info(this, message);
  }

  void showUndoSnackbar(String message, VoidCallback onUndo) {
    AppSnackbar.undo(this, message: message, onUndo: onUndo);
  }

  void hideSnackbar() {
    AppSnackbar.hide(this);
  }
}
