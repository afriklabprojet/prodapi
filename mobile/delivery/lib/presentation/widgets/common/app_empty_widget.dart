import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';

/// Widget d'état vide réutilisable avec icône, titre, sous-titre et action optionnelle.
///
/// Remplace les patterns 'Aucune course/transaction/message' dupliqués
/// dans deliveries, chat, support, batch, earnings screens.
class AppEmptyWidget extends StatelessWidget {
  const AppEmptyWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.iconSize = 64,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Message principal affiché (ex: 'Aucune course trouvée').
  final String message;

  /// Icône affichée en haut.
  final IconData icon;

  /// Couleur de l'icône (gris par défaut).
  final Color? iconColor;

  /// Taille de l'icône.
  final double iconSize;

  /// Sous-titre optionnel affiché sous le message.
  final String? subtitle;

  /// Libellé du bouton d'action optionnel.
  final String? actionLabel;

  /// Callback du bouton d'action.
  final VoidCallback? onAction;

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
              color: iconColor ?? context.dividerColor,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: context.tertiaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
