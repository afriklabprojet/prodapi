import '../../domain/entities/product_entity.dart';

/// Représente un article en cours de réception (avec traçabilité lot + expiry).
class ReceptionItem {
  final ProductEntity product;
  int quantityToAdd;
  String? lotNumber;
  DateTime? expiryDate;

  ReceptionItem({
    required this.product,
    this.quantityToAdd = 1,
    this.lotNumber,
    this.expiryDate,
  });

  /// Vérifie si la date d'expiration est valide (dans le futur)
  bool get hasValidExpiry =>
      expiryDate == null || expiryDate!.isAfter(DateTime.now());

  /// Vérifie si le produit expire bientôt (< 3 mois)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now().add(const Duration(days: 90)));
  }
}
