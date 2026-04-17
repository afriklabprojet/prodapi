import 'package:flutter/material.dart';

/// Informations de layout responsive basées sur la largeur disponible.
/// Breakpoints adaptés aux appareils courants en Côte d'Ivoire :
/// - Mobile : < 600dp (smartphones)
/// - Tablette : 600–900dp (Samsung Tab A 10.1", Tecno Pad 8")
/// - Desktop : ≥ 900dp
class ResponsiveInfo {
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final double width;

  const ResponsiveInfo({
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.width,
  });

  /// Nombre de colonnes recommandé pour les grilles de KPI / cartes.
  int get gridColumns => isDesktop ? 4 : isTablet ? 3 : 2;

  /// Padding horizontal adaptatif.
  double get horizontalPadding => isDesktop ? 40 : isTablet ? 28 : 20;

  /// Espacement entre cartes.
  double get cardSpacing => isDesktop ? 20 : isTablet ? 16 : 12;
}

/// Builder responsive qui fournit [ResponsiveInfo] en fonction de la largeur
/// disponible via [LayoutBuilder].
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveInfo info) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo(
          isMobile: constraints.maxWidth < 600,
          isTablet: constraints.maxWidth >= 600 && constraints.maxWidth < 900,
          isDesktop: constraints.maxWidth >= 900,
          width: constraints.maxWidth,
        );
        return builder(context, info);
      },
    );
  }
}
