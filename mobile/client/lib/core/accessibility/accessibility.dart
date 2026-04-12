/// Module d'accessibilité pour DR-PHARMA
///
/// Ce module fournit des outils pour rendre l'application accessible
/// aux utilisateurs de VoiceOver (iOS) et TalkBack (Android).
///
/// Utilisation:
/// ```dart
/// import 'package:drpharma_client/core/accessibility/accessibility.dart';
///
/// // Labels sémantiques
/// Semantics(
///   label: A11yLabels.productCard('Doliprane 1000mg'),
///   child: ProductCard(...),
/// )
///
/// // Widgets accessibles
/// AccessibleButton(
///   semanticLabel: A11yLabels.addToCart('Doliprane'),
///   onPressed: () => addToCart(),
///   child: ElevatedButton(...),
/// )
///
/// // Annonces
/// A11yAnnouncer.announceResult(context, true, customMessage: 'Ajouté au panier');
///
/// // Configuration
/// if (A11yConfig.shouldReduceMotion(context)) {
///   // Désactiver les animations
/// }
/// ```
library accessibility;

export 'a11y_labels.dart';
export 'a11y_widgets.dart';
export 'a11y_config.dart';
