import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/product_entity.dart';
import 'pharmacy_model.dart';
import 'category_model.dart';

part 'product_model.g.dart';

/// Helper function to parse category which can be either a String or a Map
CategoryModel? _categoryFromJson(dynamic json) {
  if (json == null) return null;
  if (json is String) {
    // Backend returned category as a string (legacy data)
    return CategoryModel(id: 0, name: json, description: null);
  }
  if (json is Map<String, dynamic>) {
    return CategoryModel.fromJson(json);
  }
  return null;
}

/// Helper to safely parse price which might be null
double _parsePrice(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

double? _parsePriceNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Helper to safely parse int which might be String
int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

List<String>? _parseTagsList(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.map((e) => e.toString()).toList();
  if (value is String) return [value];
  return null;
}

@JsonSerializable()
class ProductModel {
  final int id;
  final String name;
  final String? description;
  @JsonKey(fromJson: _parsePrice)
  final double price;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'image')
  final String? image;
  @JsonKey(name: 'stock_quantity', defaultValue: 0)
  final int stockQuantity;
  @JsonKey(name: 'low_stock_threshold', defaultValue: 10)
  final int lowStockThreshold;
  final String? manufacturer;
  @JsonKey(name: 'active_ingredient')
  final String? activeIngredient;
  @JsonKey(name: 'usage_instructions')
  final String? usageInstructions;
  @JsonKey(name: 'side_effects')
  final String? sideEffects;
  @JsonKey(name: 'requires_prescription', defaultValue: false)
  final bool requiresPrescription;
  final PharmacyModel pharmacy;
  @JsonKey(fromJson: _categoryFromJson)
  final CategoryModel? category;
  @JsonKey(name: 'discount_price', fromJson: _parsePriceNullable)
  final double? discountPrice;
  @JsonKey(name: 'average_rating', fromJson: _parsePriceNullable)
  final double? averageRating;
  @JsonKey(name: 'reviews_count', fromJson: _parseIntNullable)
  final int? reviewsCount;
  @JsonKey(fromJson: _parseTagsList)
  final List<String>? tags;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.discountPrice,
    this.imageUrl,
    this.image,
    required this.stockQuantity,
    this.lowStockThreshold = 10,
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
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Make a mutable copy to safely transform values
    json = Map<String, dynamic>.from(json);

    // Handle String -> int conversion for fields that API may return as strings
    if (json['id'] is String) {
      json['id'] = int.tryParse(json['id']) ?? 0;
    }
    // Ensure id is never null (generated code does `as num`)
    json['id'] ??= 0;

    // Ensure name is never null (generated code does `as String`)
    json['name'] ??= '';

    if (json['stock_quantity'] is String) {
      json['stock_quantity'] = int.tryParse(json['stock_quantity']) ?? 0;
    }
    if (json['low_stock_threshold'] is String) {
      json['low_stock_threshold'] = int.tryParse(json['low_stock_threshold']) ?? 10;
    }

    // Ensure created_at / updated_at are never null (generated code does `as String`)
    json['created_at'] ??= DateTime.now().toIso8601String();
    json['updated_at'] ??= DateTime.now().toIso8601String();

    // Handle pharmacy: ensure it's a valid Map, provide fallback if null
    if (json['pharmacy'] is Map) {
      final pharmacy = Map<String, dynamic>.from(json['pharmacy']);
      if (pharmacy['id'] is String) {
        pharmacy['id'] = int.tryParse(pharmacy['id']) ?? 0;
      }
      json['pharmacy'] = pharmacy;
    } else {
      // pharmacy is null or not a Map — provide a placeholder
      json['pharmacy'] = {
        'id': json['pharmacy_id'] is String
            ? (int.tryParse(json['pharmacy_id']) ?? 0)
            : (json['pharmacy_id'] ?? 0),
        'name': 'Pharmacie',
        'address': '',
        'status': 'active',
        'is_open': false,
      };
    }

    return _$ProductModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      name: name,
      description: description,
      price: price,
      discountPrice: discountPrice,
      imageUrl: imageUrl ?? image,
      stockQuantity: stockQuantity,
      lowStockThreshold: lowStockThreshold,
      manufacturer: manufacturer,
      activeIngredient: activeIngredient,
      usageInstructions: usageInstructions,
      sideEffects: sideEffects,
      requiresPrescription: requiresPrescription,
      pharmacy: pharmacy.toEntity(),
      category: category?.toEntity(),
      averageRating: averageRating,
      reviewsCount: reviewsCount,
      tags: tags,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }
}
