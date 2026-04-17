import 'package:equatable/equatable.dart';

/// Entité d'article de commande (couche Domain)
class OrderItemEntity extends Equatable {
  final int? id;
  final int? productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItemEntity({
    this.id,
    this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  OrderItemEntity copyWith({
    int? id,
    int? productId,
    String? name,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return OrderItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  List<Object?> get props => [id, productId, name, quantity, unitPrice, totalPrice];
}
