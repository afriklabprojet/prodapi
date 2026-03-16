import 'package:flutter/material.dart';

/// Carte de section réutilisable avec titre, widget trailing optionnel
/// et contenu enfant.
///
/// Utilisée dans les écrans statistics, profile, wallet pour les sections
/// avec un titre en gras et du contenu en dessous.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.borderRadius = 16,
  });

  /// Titre de la section.
  final String title;

  /// Contenu de la carte.
  final Widget child;

  /// Widget trailing optionnel affiché à droite du titre.
  final Widget? trailing;

  /// Padding interne de la carte.
  final EdgeInsets padding;

  /// Marge extérieure de la carte.
  final EdgeInsets margin;

  /// Rayon de bordure.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
