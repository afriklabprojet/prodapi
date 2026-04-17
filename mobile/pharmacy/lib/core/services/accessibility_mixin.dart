import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mixin d'accessibilité pour les écrans.
///
/// Fournit des helpers pour :
/// - Annoncer les changements d'écran au lecteur d'écran
/// - Créer des labels sémantiques cohérents
/// - Respecter les préférences utilisateur (reduce motion, large text)
/// - Gérer le focus pour la navigation clavier
///
/// Usage :
/// ```dart
/// class MyScreen extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<MyScreen> createState() => _MyScreenState();
/// }
/// 
/// class _MyScreenState extends ConsumerState<MyScreen> with AccessibilityMixin {
///   @override
///   void initState() {
///     super.initState();
///     announceScreen('Tableau de bord pharmacie');
///   }
/// }
/// ```
mixin AccessibilityMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Annonce un message au lecteur d'écran.
  void announce(String message, {TextDirection? textDirection}) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, textDirection ?? TextDirection.ltr);
  }

  /// Annonce le changement d'écran au lecteur d'écran.
  ///
  /// À appeler dans initState() ou après navigation.
  void announceScreen(String screenName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      announce('Écran: $screenName');
    });
  }

  /// Annonce une action réussie.
  void announceSuccess(String message) {
    announce('Succès: $message');
  }

  /// Annonce une erreur.
  void announceError(String message) {
    announce('Erreur: $message');
  }

  /// Vérifie si les animations doivent être réduites.
  bool get shouldReduceMotion => MediaQuery.of(context).disableAnimations;

  /// Retourne la durée d'animation appropriée.
  ///
  /// Retourne Duration.zero si reduce motion est activé.
  Duration animationDuration([
    Duration normal = const Duration(milliseconds: 300),
  ]) {
    return shouldReduceMotion ? Duration.zero : normal;
  }

  /// Retourne la courbe d'animation appropriée.
  ///
  /// Retourne Curves.linear si reduce motion est activé (transition instantanée).
  Curve animationCurve([Curve normal = Curves.easeInOut]) {
    return shouldReduceMotion ? Curves.linear : normal;
  }

  /// Vérifie si le texte large est activé.
  bool get hasLargeText => MediaQuery.textScalerOf(context).scale(1.0) >= 1.3;

  /// Retourne le facteur d'échelle du texte.
  double get textScaleFactor => MediaQuery.textScalerOf(context).scale(1.0);

  /// Vérifie si un lecteur d'écran est actif.
  bool get isScreenReaderActive => MediaQuery.of(context).accessibleNavigation;

  /// Vérifie si le mode contraste élevé est activé.
  bool get isHighContrastMode => MediaQuery.of(context).highContrast;
}

/// Extension pour ajouter facilement des sémantiques aux widgets.
extension AccessibilityExtensions on Widget {
  /// Ajoute un label sémantique au widget.
  Widget withSemanticLabel(String label) {
    return Semantics(
      label: label,
      child: this,
    );
  }

  /// Marque le widget comme bouton pour l'accessibilité.
  Widget asSemanticButton({
    required String label,
    String? hint,
    bool? enabled,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled ?? true,
      onTap: onTap,
      child: this,
    );
  }

  /// Marque le widget comme header pour l'accessibilité.
  Widget asSemanticHeader({required String label}) {
    return Semantics(
      label: label,
      header: true,
      child: this,
    );
  }

  /// Exclut le widget de la navigation accessible.
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }

  /// Masque le widget pour l'accessibilité tout en le gardant visible.
  Widget hideFromAccessibility() {
    return Semantics(
      excludeSemantics: true,
      child: this,
    );
  }
}

/// Extension BuildContext pour accéder facilement aux infos d'accessibilité.
extension AccessibilityContext on BuildContext {
  /// Vérifie si reduce motion est activé.
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  /// Vérifie si le texte large est activé (>= 1.3).
  bool get isLargeText => MediaQuery.textScalerOf(this).scale(1.0) >= 1.3;

  /// Vérifie si un lecteur d'écran est actif.
  bool get hasScreenReader => MediaQuery.of(this).accessibleNavigation;

  /// Vérifie si le contraste élevé est activé.
  bool get highContrast => MediaQuery.of(this).highContrast;

  /// Retourne la durée d'animation appropriée.
  Duration animationDuration([
    Duration normal = const Duration(milliseconds: 300),
  ]) {
    return reduceMotion ? Duration.zero : normal;
  }

  /// Retourne la courbe d'animation appropriée.
  Curve animationCurve([Curve normal = Curves.easeInOut]) {
    return reduceMotion ? Curves.linear : normal;
  }
}
