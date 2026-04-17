import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';

/// Widget de chargement réutilisable avec indicateur circulaire centré.
///
/// Remplace le pattern `Center(child: CircularProgressIndicator())` dupliqué
/// dans 10+ écrans.
class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size = 36.0,
  });

  /// Message optionnel affiché sous l'indicateur.
  final String? message;

  /// Couleur de l'indicateur (utilise la couleur du thème par défaut).
  final Color? color;

  /// Taille de l'indicateur.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: context.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
