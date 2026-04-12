/// Entité lot/batch d'un produit pharmaceutique.
///
/// Chaque produit peut avoir plusieurs lots avec des dates d'expiration
/// et quantités différentes, conformément aux exigences DPML (Côte d'Ivoire).
class ProductBatchEntity {
  final int id;
  final int productId;
  final String? productName;
  final String batchNumber;
  final String? lotNumber;
  final DateTime expiryDate;
  final int quantity;
  final DateTime? receivedAt;
  final String? supplier;

  const ProductBatchEntity({
    required this.id,
    required this.productId,
    this.productName,
    required this.batchNumber,
    this.lotNumber,
    required this.expiryDate,
    required this.quantity,
    this.receivedAt,
    this.supplier,
  });

  /// Le lot est expiré
  bool get isExpired => expiryDate.isBefore(DateTime.now());

  /// Jours restants avant expiration (négatif si expiré)
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  /// Expire dans les 7 prochains jours
  bool get isCritical => !isExpired && daysUntilExpiry <= 7;

  /// Expire dans les 30 prochains jours
  bool get isExpiringSoon => !isExpired && daysUntilExpiry <= 30;

  /// Expire dans les 90 prochains jours
  bool get isWarning => !isExpired && daysUntilExpiry <= 90;

  /// Sévérité de l'alerte d'expiration
  ExpiryAlertSeverity get alertSeverity {
    if (isExpired) return ExpiryAlertSeverity.expired;
    if (isCritical) return ExpiryAlertSeverity.critical;
    if (isExpiringSoon) return ExpiryAlertSeverity.warning;
    if (isWarning) return ExpiryAlertSeverity.info;
    return ExpiryAlertSeverity.none;
  }

  ProductBatchEntity copyWith({
    int? id,
    int? productId,
    String? productName,
    String? batchNumber,
    String? lotNumber,
    DateTime? expiryDate,
    int? quantity,
    DateTime? receivedAt,
    String? supplier,
  }) {
    return ProductBatchEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      batchNumber: batchNumber ?? this.batchNumber,
      lotNumber: lotNumber ?? this.lotNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      receivedAt: receivedAt ?? this.receivedAt,
      supplier: supplier ?? this.supplier,
    );
  }
}

/// Niveaux d'alerte d'expiration
enum ExpiryAlertSeverity {
  /// Déjà expiré
  expired,

  /// Expire dans ≤ 7 jours
  critical,

  /// Expire dans ≤ 30 jours
  warning,

  /// Expire dans ≤ 90 jours
  info,

  /// Pas d'alerte
  none,
}
