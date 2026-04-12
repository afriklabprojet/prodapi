import '../../domain/entities/product_batch_entity.dart';

/// Modèle de données pour un lot/batch produit (couche data).
class ProductBatchModel {
  final int id;
  final int productId;
  final String? productName;
  final String batchNumber;
  final String? lotNumber;
  final DateTime expiryDate;
  final int quantity;
  final DateTime? receivedAt;
  final String? supplier;

  const ProductBatchModel({
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

  factory ProductBatchModel.fromJson(Map<String, dynamic> json) {
    return ProductBatchModel(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      productName:
          json['product_name'] as String? ??
          json['product']?['name'] as String?,
      batchNumber: json['batch_number'] as String? ?? '',
      lotNumber: json['lot_number'] as String?,
      expiryDate:
          DateTime.tryParse(json['expiry_date']?.toString() ?? '') ??
          DateTime.now(),
      quantity: json['quantity'] as int? ?? 0,
      receivedAt: json['received_at'] != null
          ? DateTime.tryParse(json['received_at'].toString())
          : null,
      supplier: json['supplier'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'batch_number': batchNumber,
    'lot_number': lotNumber,
    'expiry_date': expiryDate.toIso8601String().split('T')[0],
    'quantity': quantity,
    'received_at': receivedAt?.toIso8601String().split('T')[0],
    'supplier': supplier,
  };

  ProductBatchEntity toEntity() => ProductBatchEntity(
    id: id,
    productId: productId,
    productName: productName,
    batchNumber: batchNumber,
    lotNumber: lotNumber,
    expiryDate: expiryDate,
    quantity: quantity,
    receivedAt: receivedAt,
    supplier: supplier,
  );

  static List<ProductBatchEntity> toEntityList(
    List<ProductBatchModel> models,
  ) => models.map((m) => m.toEntity()).toList();
}
