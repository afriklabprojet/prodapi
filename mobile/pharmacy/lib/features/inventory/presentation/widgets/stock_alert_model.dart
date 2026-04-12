/// Types d'alertes de stock
enum StockAlertType {
  critical, // Stock à 0
  low,      // Stock bas (< seuil)
  expiring, // Expiration proche
  expired,  // Expiré
}

/// Modèle d'alerte de stock
class StockAlert {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final StockAlertType type;
  final int currentStock;
  final int? threshold;
  final DateTime? expirationDate;
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;

  const StockAlert({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.type,
    required this.currentStock,
    this.threshold,
    this.expirationDate,
    required this.createdAt,
    this.isRead = false,
    this.isDismissed = false,
  });

  StockAlert copyWith({
    bool? isRead,
    bool? isDismissed,
  }) {
    return StockAlert(
      id: id,
      productId: productId,
      productName: productName,
      productImage: productImage,
      type: type,
      currentStock: currentStock,
      threshold: threshold,
      expirationDate: expirationDate,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}
