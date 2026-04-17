import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/order_item_entity.dart';

part 'order_item_model.g.dart';

@JsonSerializable(createToJson: false)
class OrderItemModel {
  @JsonKey(name: 'product_id')
  final int? productId;
  final int? id;
  @JsonKey(readValue: _readName)
  final String name;
  final int quantity;
  @JsonKey(name: 'unit_price', readValue: _readUnitPrice)
  final double unitPrice;
  @JsonKey(name: 'total_price', readValue: _readTotalPrice)
  final double totalPrice;

  const OrderItemModel({
    this.productId,
    this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  /// Reads 'name' or 'product_name' from JSON (API returns product_name)
  static Object? _readName(Map<dynamic, dynamic> json, String key) {
    return json['name'] ?? json['product_name'] ?? 'Produit inconnu';
  }

  /// Reads unit_price and converts String to num if needed (API returns "2500.00")
  static Object? _readUnitPrice(Map<dynamic, dynamic> json, String key) {
    final value = json['unit_price'];
    if (value is String) return double.tryParse(value) ?? 0.0;
    return value;
  }

  /// Reads total_price and converts String to num if needed (API returns "2500.00")
  static Object? _readTotalPrice(Map<dynamic, dynamic> json, String key) {
    final value = json['total_price'];
    if (value is String) return double.tryParse(value) ?? 0.0;
    return value;
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);

  /// Convert to JSON for API request (uses 'price' instead of 'unit_price' for Laravel)
  Map<String, dynamic> toJson() {
    return {
      'id': productId ?? id,
      'name': name,
      'quantity': quantity,
      'price': unitPrice,
    };
  }

  OrderItemEntity toEntity() {
    return OrderItemEntity(
      id: id,
      productId: productId,
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }

  factory OrderItemModel.fromEntity(OrderItemEntity entity) {
    return OrderItemModel(
      id: entity.id,
      productId: entity.productId,
      name: entity.name,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      totalPrice: entity.totalPrice,
    );
  }
}
