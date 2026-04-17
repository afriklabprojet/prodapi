import 'package:flutter/material.dart';

/// Enum exhaustif des statuts de commande.
///
/// Chaque valeur porte sa représentation API (`apiValue`),
/// son libellé d'affichage en français (`displayLabel`),
/// sa couleur et son icône.
///
/// Utiliser [OrderStatusFilter] pour les filtres de liste
/// qui incluent la valeur spéciale `all`.
enum OrderStatus {
  pending('pending', 'En attente'),
  confirmed('confirmed', 'Confirmée'),
  ready('ready', 'Prête'),
  inDelivery('in_delivery', 'En livraison'),
  delivered('delivered', 'Livrée'),
  cancelled('cancelled', 'Annulée'),
  rejected('rejected', 'Refusée');

  const OrderStatus(this.apiValue, this.displayLabel);

  /// Valeur envoyée/reçue de l'API (ex: `'pending'`).
  final String apiValue;

  /// Libellé affiché dans l'UI.
  final String displayLabel;

  /// Couleur associée au statut.
  Color get color => switch (this) {
        OrderStatus.pending => Colors.orange,
        OrderStatus.confirmed => Colors.blue.shade700,
        OrderStatus.ready => Colors.green,
        OrderStatus.inDelivery => const Color(0xFF9C27B0),
        OrderStatus.delivered => Colors.teal,
        OrderStatus.cancelled => Colors.red,
        OrderStatus.rejected => Colors.red,
      };

  /// Icône associée au statut.
  IconData get icon => switch (this) {
        OrderStatus.pending => Icons.hourglass_empty_rounded,
        OrderStatus.confirmed => Icons.check_circle_outline_rounded,
        OrderStatus.ready => Icons.inventory_2_rounded,
        OrderStatus.inDelivery => Icons.delivery_dining_rounded,
        OrderStatus.delivered => Icons.local_shipping_rounded,
        OrderStatus.cancelled => Icons.cancel_rounded,
        OrderStatus.rejected => Icons.cancel_rounded,
      };

  /// Parse une chaîne API vers l'enum. Retourne [pending] par défaut.
  static OrderStatus fromApi(String? value) {
    if (value == null) return OrderStatus.pending;
    final lower = value.toLowerCase();
    // Handle alternate API values
    if (lower == 'ready_for_pickup') return OrderStatus.ready;
    return OrderStatus.values.firstWhere(
      (s) => s.apiValue == lower,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Filtre de liste de commandes, incluant la valeur spéciale [all].
enum OrderStatusFilter {
  all('all', 'Toutes'),
  pending('pending', 'En attente'),
  confirmed('confirmed', 'Confirmées'),
  ready('ready', 'Prêtes'),
  inDelivery('in_delivery', 'En livraison'),
  delivered('delivered', 'Livrées'),
  cancelled('cancelled', 'Annulées');

  const OrderStatusFilter(this.apiValue, this.displayLabel);

  final String apiValue;
  final String displayLabel;

  /// Convertit en valeur API pour le repository (`null` pour `all`).
  String? get apiValueOrNull => this == OrderStatusFilter.all ? null : apiValue;

  /// Parse une chaîne vers le filtre. Retourne [pending] par défaut.
  static OrderStatusFilter fromApi(String? value) {
    if (value == null) return OrderStatusFilter.all;
    return OrderStatusFilter.values.firstWhere(
      (f) => f.apiValue == value,
      orElse: () => OrderStatusFilter.pending,
    );
  }
}
