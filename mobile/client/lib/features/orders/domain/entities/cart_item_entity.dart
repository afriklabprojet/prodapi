import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product_entity.dart';

/// Entité d'article dans le panier
class CartItemEntity extends Equatable {
  final ProductEntity product;
  final int quantity;

  const CartItemEntity({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;
  bool get isAvailable => product.isAvailable && product.stockQuantity >= quantity;

  CartItemEntity copyWith({
    ProductEntity? product,
    int? quantity,
  }) {
    return CartItemEntity(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product.id, quantity];
}
