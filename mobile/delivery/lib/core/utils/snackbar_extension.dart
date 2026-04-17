import 'package:flutter/material.dart';
import '../utils/app_exceptions.dart';
import '../utils/error_handler.dart';

/// Extension sur [BuildContext] pour simplifier l'affichage de SnackBars
/// et la gestion d'erreurs dans l'UI.
extension SnackBarExtension on BuildContext {
  ScaffoldMessengerState get _messenger => ScaffoldMessenger.of(this);

  // ── SnackBars de succès ────────────────────────────

  /// Affiche un SnackBar de succès (vert).
  void showSuccess(String message, {Duration? duration}) {
    _messenger.hideCurrentSnackBar();
    _messenger.showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 3),
    ));
  }

  // ── SnackBars d'erreur ─────────────────────────────

  /// Affiche un SnackBar d'erreur à partir d'une [AppException] ou erreur brute.
  void showError(dynamic error, {String? fallbackMessage}) {
    final message = error is AppException
        ? error.userMessage
        : ErrorHandler.cleanMessage(error);
    _messenger.hideCurrentSnackBar();
    _messenger.showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(fallbackMessage ?? message)),
        ],
      ),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () => _messenger.hideCurrentSnackBar(),
      ),
    ));
  }

  /// Affiche un SnackBar d'erreur avec un message statique.
  void showErrorMessage(String message) {
    _messenger.hideCurrentSnackBar();
    _messenger.showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }

  // ── SnackBars d'info ───────────────────────────────

  /// Affiche un SnackBar informatif (bleu).
  void showInfo(String message, {Duration? duration}) {
    _messenger.hideCurrentSnackBar();
    _messenger.showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.blue.shade600,
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 3),
    ));
  }

  // ── SnackBars d'avertissement ──────────────────────

  /// Affiche un SnackBar d'avertissement (orange).
  void showWarning(String message, {Duration? duration}) {
    _messenger.hideCurrentSnackBar();
    _messenger.showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.orange.shade700,
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 3),
    ));
  }
}
