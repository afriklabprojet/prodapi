import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/rating_bottom_sheet.dart';
import '../../domain/entities/order_entity.dart';

/// Service qui vérifie si l'utilisateur a des commandes livrées non évaluées
/// et affiche automatiquement le bottom sheet de notation.
class ReviewPromptService {
  static const _ratedOrdersKey = 'rated_order_ids';
  static const _dismissedOrdersKey = 'dismissed_review_order_ids';

  final SharedPreferences _prefs;

  ReviewPromptService(this._prefs);

  /// Vérifie et affiche le prompt de notation pour les commandes livrées non évaluées.
  /// Appeler après le chargement de la liste de commandes.
  Future<void> checkAndPrompt(
    BuildContext context,
    List<OrderEntity> orders,
  ) async {
    final ratedIds = _prefs.getStringList(_ratedOrdersKey) ?? [];
    final dismissedIds = _prefs.getStringList(_dismissedOrdersKey) ?? [];

    // Trouver la dernière commande livrée non évaluée
    final unratedDelivered = orders.where((o) =>
        o.status == OrderStatus.delivered &&
        !ratedIds.contains(o.id.toString()) &&
        !dismissedIds.contains(o.id.toString()));

    if (unratedDelivered.isEmpty) return;

    // Prompt pour la plus récente seulement
    final order = unratedDelivered.first;

    if (!context.mounted) return;

    // Petit délai pour ne pas interférer avec la navigation
    await Future.delayed(const Duration(milliseconds: 800));
    if (!context.mounted) return;

    final result = await RatingBottomSheet.show(
      context,
      orderId: order.id,
      pharmacyName: order.pharmacyName,
    );

    if (result == true) {
      await markAsRated(order.id);
    } else {
      await markAsDismissed(order.id);
    }
  }

  /// Marquer une commande comme évaluée
  Future<void> markAsRated(int orderId) async {
    final ids = _prefs.getStringList(_ratedOrdersKey) ?? [];
    if (!ids.contains(orderId.toString())) {
      ids.add(orderId.toString());
      await _prefs.setStringList(_ratedOrdersKey, ids);
    }
  }

  /// Marquer une commande comme dismissée (l'utilisateur a fermé sans évaluer)
  Future<void> markAsDismissed(int orderId) async {
    final ids = _prefs.getStringList(_dismissedOrdersKey) ?? [];
    if (!ids.contains(orderId.toString())) {
      ids.add(orderId.toString());
      await _prefs.setStringList(_dismissedOrdersKey, ids);
    }
  }
}
