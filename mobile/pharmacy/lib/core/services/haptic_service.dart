import 'package:flutter/services.dart';

/// Service centralisé pour le feedback haptique.
/// 
/// Sur le marché africain où la connexion est instable, le feedback haptique 
/// rassure que l'action a été prise en compte avant même la réponse serveur.
/// 
/// Usage:
/// ```dart
/// HapticService.onAction(); // Confirmer commande, valider retrait
/// HapticService.onSuccess(); // Action réussie
/// HapticService.onError(); // Action échouée
/// HapticService.onSelection(); // Navigation, sélection d'onglet
/// ```
class HapticService {
  HapticService._();

  /// Feedback pour une action importante (confirmer commande, valider retrait).
  /// Vibration moyenne - utilisateur sent que l'action est prise en compte.
  static Future<void> onAction() async {
    await HapticFeedback.mediumImpact();
  }

  /// Feedback pour une action réussie.
  /// Vibration légère - confirmation positive.
  static Future<void> onSuccess() async {
    await HapticFeedback.lightImpact();
  }

  /// Feedback pour une erreur ou action critique (rejeter commande).
  /// Vibration forte - attire l'attention.
  static Future<void> onError() async {
    await HapticFeedback.heavyImpact();
  }

  /// Feedback pour une sélection (onglet, élément de liste).
  /// Vibration très légère - feedback subtil.
  static Future<void> onSelection() async {
    await HapticFeedback.selectionClick();
  }

  /// Feedback pour une action de suppression ou rejet.
  /// Vibration légère - feedback négatif mais pas alarmant.
  static Future<void> onDelete() async {
    await HapticFeedback.lightImpact();
  }

  /// Feedback pour un bouton pressé.
  /// Pattern: vibration au press down.
  static Future<void> onButtonPress() async {
    await HapticFeedback.selectionClick();
  }

  /// Feedback pour un swipe ou gesture.
  static Future<void> onSwipe() async {
    await HapticFeedback.selectionClick();
  }

  /// Feedback pour une transaction financière (retrait, paiement).
  /// Vibration forte pour les actions sensibles.
  static Future<void> onTransaction() async {
    await HapticFeedback.heavyImpact();
  }

  /// Feedback pour une notification ou alerte.
  static Future<void> onNotification() async {
    await HapticFeedback.mediumImpact();
  }
}
