import 'package:equatable/equatable.dart';
import 'pharmacy_entity.dart';
import 'category_entity.dart';

/// Entité Produit (couche Domain)
class ProductEntity extends Equatable {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double? discountPrice;
  final String? imageUrl;
  final int stockQuantity;
  final String? manufacturer;
  final String? activeIngredient;
  final String? usageInstructions;
  final String? sideEffects;
  final bool requiresPrescription;
  final PharmacyEntity pharmacy;
  final CategoryEntity? category;
  final double? averageRating;
  final int? reviewsCount;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.discountPrice,
    this.imageUrl,
    required this.stockQuantity,
    this.manufacturer,
    this.activeIngredient,
    this.usageInstructions,
    this.sideEffects,
    required this.requiresPrescription,
    required this.pharmacy,
    this.category,
    this.averageRating,
    this.reviewsCount,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.lowStockThreshold = 10,
  });

  final int lowStockThreshold;

  bool get isAvailable => stockQuantity > 0;
  bool get isOutOfStock => stockQuantity <= 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= lowStockThreshold;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  double get finalPrice => hasDiscount ? discountPrice! : price;
  int get discountPercentage => hasDiscount
      ? (((price - discountPrice!) / price) * 100).round()
      : 0;
  bool get hasRating => averageRating != null && averageRating! > 0;

  @override
  List<Object?> get props => [id, name, price, stockQuantity, pharmacy.id];
}
