import 'package:flutter/material.dart';

/// Dialog de chargement professionnel pour les opérations asynchrones.
///
/// Utilisation:
/// ```dart
/// LoadingDialog.show(context, message: 'Sauvegarde en cours...');
/// // ... opération async
/// LoadingDialog.hide(context);
/// ```
class LoadingDialog extends StatelessWidget {
  const LoadingDialog({
    super.key,
    this.message = 'Chargement...',
  });

  final String message;

  /// Affiche le dialog de chargement.
  static void show(BuildContext context, {String message = 'Chargement...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => LoadingDialog(message: message),
    );
  }

  /// Masque le dialog de chargement.
  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
