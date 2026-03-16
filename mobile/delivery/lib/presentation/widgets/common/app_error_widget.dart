import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';

/// Widget d'erreur réutilisable avec icône, message et bouton de réessai.
///
/// Remplace le pattern `Column(Icon.error + Text('Erreur') + Button('Réessayer'))`
/// dupliqué dans tous les écrans utilisant AsyncValue.when().
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor,
    this.iconSize = 64,
    this.title,
    this.retryLabel = 'Réessayer',
  });

  /// Message d'erreur détaillé.
  final String message;

  /// Callback pour le bouton de réessai. Si null, le bouton n'est pas affiché.
  final VoidCallback? onRetry;

  /// Icône affichée en haut.
  final IconData icon;

  /// Couleur de l'icône (rouge par défaut).
  final Color? iconColor;

  /// Taille de l'icône.
  final double iconSize;

  /// Titre optionnel affiché en gras au-dessus du message.
  final String? title;

  /// Libellé du bouton de réessai.
  final String retryLabel;

  /// Factory pour erreur de profil coursier (403 / non trouvé).
  factory AppErrorWidget.profile({
    required String message,
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      message: message,
      onRetry: onRetry,
      icon: Icons.person_off,
      iconColor: Colors.orange,
      title: 'Profil coursier non configuré',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: context.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 18),
                    const SizedBox(width: 8),
                    Text(retryLabel),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
