import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_service.dart';

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
/// class MyScreen extends ConsumerStatefulWidget with AccessibilityMixin {
///   @override
///   void initState() {
///     super.initState();
///     announceScreen('Écran d\'accueil');
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
  bool get shouldReduceMotion =>
      ref.read(accessibilityProvider).reduceMotion ||
      MediaQuery.of(context).disableAnimations;

  /// Retourne la durée d'animation appropriée.
  ///
  /// Retourne Duration.zero si reduce motion est activé.
  Duration animationDuration([Duration normal = const Duration(milliseconds: 300)]) {
    return shouldReduceMotion ? Duration.zero : normal;
  }

  /// Retourne la courbe d'animation appropriée.
  ///
  /// Retourne Curves.linear si reduce motion est activé (transition instantanée).
  Curve animationCurve([Curve normal = Curves.easeInOut]) {
    return shouldReduceMotion ? Curves.linear : normal;
  }

  /// Vérifie si le texte large est activé.
  bool get hasLargeText => ref.read(accessibilityProvider).largeText;

  /// Retourne le facteur d'échelle du texte.
  double get textScaleFactor => ref.read(accessibilityProvider).textScaleFactor;

  /// Vérifie si un lecteur d'écran est actif.
  bool get isScreenReaderActive =>
      ref.read(accessibilityProvider).screenReaderEnabled ||
      MediaQuery.of(context).accessibleNavigation;

  /// Vérifie si le mode contraste élevé est activé.
  bool get isHighContrastMode => ref.read(accessibilityProvider).highContrast;
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

  /// Marque le widget comme en-tête pour l'accessibilité.
  Widget asSemanticHeader(String label) {
    return Semantics(
      label: label,
      header: true,
      child: this,
    );
  }

  /// Marque le widget comme image avec description.
  Widget asSemanticImage(String description) {
    return Semantics(
      label: description,
      image: true,
      child: this,
    );
  }

  /// Marque le widget comme champ de saisie.
  Widget asSemanticTextField({
    required String label,
    String? value,
    String? hint,
    bool? multiline,
    bool? obscured,
  }) {
    return Semantics(
      label: label,
      value: value,
      hint: hint,
      textField: true,
      multiline: multiline,
      obscured: obscured,
      child: this,
    );
  }

  /// Marque le widget comme slider.
  Widget asSemanticSlider({
    required String label,
    required double value,
    String? increasedValue,
    String? decreasedValue,
    VoidCallback? onIncrease,
    VoidCallback? onDecrease,
  }) {
    return Semantics(
      label: label,
      value: value.toStringAsFixed(0),
      increasedValue: increasedValue,
      decreasedValue: decreasedValue,
      slider: true,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      child: this,
    );
  }

  /// Exclut le widget des sémantiques (décoration pure).
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }

  /// Fusionne les sémantiques des enfants.
  Widget mergeSemantics() {
    return MergeSemantics(child: this);
  }
}

/// Widget wrapper pour les écrans accessibles.
///
/// Applique automatiquement :
/// - Annonce de l'écran au lecteur d'écran
/// - Ordre de focus correct
/// - Sémantique de l'écran
class AccessibleScreen extends ConsumerWidget {
  const AccessibleScreen({
    super.key,
    required this.name,
    required this.child,
    this.focusOrder,
  });

  /// Nom de l'écran pour l'annonce.
  final String name;

  /// Contenu de l'écran.
  final Widget child;

  /// Ordre de focus personnalisé (optionnel).
  final List<FocusNode>? focusOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Annonce l'écran au premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: deprecated_member_use
      SemanticsService.announce('Écran: $name', TextDirection.ltr);
    });

    return Semantics(
      label: name,
      namesRoute: true,
      child: child,
    );
  }
}

/// Widget pour les actions accessibles.
///
/// Combine GestureDetector avec les sémantiques appropriées.
class AccessibleTapTarget extends StatelessWidget {
  const AccessibleTapTarget({
    super.key,
    required this.label,
    required this.child,
    required this.onTap,
    this.hint,
    this.enabled = true,
    this.minSize = 48.0,
  });

  /// Label pour le lecteur d'écran.
  final String label;

  /// Widget enfant.
  final Widget child;

  /// Callback au tap.
  final VoidCallback onTap;

  /// Indice supplémentaire pour le lecteur d'écran.
  final String? hint;

  /// Widget activé ou non.
  final bool enabled;

  /// Taille minimale de la zone de tap (WCAG recommande 48px).
  final double minSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minSize,
            minHeight: minSize,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Helpers pour les annonces live regions.
class LiveRegion {
  LiveRegion._();

  static void _announce(String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Annonce un message de statut (non urgent).
  static void status(String message) {
    _announce(message);
  }

  /// Annonce un message d'alerte (interrompt).
  static void alert(String message) {
    _announce(message);
  }

  /// Annonce un compteur ou valeur mise à jour.
  static void counter(String label, int value) {
    _announce('$label: $value');
  }

  /// Annonce un temps restant.
  static void timer(int remainingSeconds) {
    if (remainingSeconds == 60) {
      _announce('1 minute restante');
    } else if (remainingSeconds == 30) {
      _announce('30 secondes restantes');
    } else if (remainingSeconds <= 10 && remainingSeconds > 0) {
      _announce('$remainingSeconds secondes');
    }
  }
}
