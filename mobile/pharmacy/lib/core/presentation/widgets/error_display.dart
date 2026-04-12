import 'package:flutter/material.dart';
import '../../utils/haptics.dart';

/// Widget utilitaire pour afficher des SnackBars stylisées avec feedback haptique.
class ErrorSnackBar {
  ErrorSnackBar._();

  static void showSuccess(BuildContext context, String message) {
    Haptics.success();
    _show(context, message, Colors.green, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    Haptics.error();
    _show(context, message, Colors.red, Icons.error_outline);
  }

  static void showWarning(BuildContext context, String message) {
    Haptics.warning();
    _show(context, message, Colors.orange, Icons.warning_amber_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    Haptics.light();
    _show(context, message, Colors.blue, Icons.info_outline);
  }

  /// Shows an error with a retry action button
  static void showErrorWithRetry(BuildContext context, String message, VoidCallback onRetry) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
