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
  final String? manufacturer;
  @JsonKey(name: 'requires_prescription', defaultValue: false)
  final bool requiresPrescription;
  final PharmacyModel pharmacy;
  @JsonKey(fromJson: _categoryFromJson)
  final CategoryModel? category;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.image,
    required this.stockQuantity,
    this.manufacturer,
    required this.requiresPrescription,
    required this.pharmacy,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Handle String -> num conversion for fields that API may return as strings
    json = Map<String, dynamic>.from(json);
    if (json['id'] is String) {
      json['id'] = int.tryParse(json['id']) ?? 0;
    }
    if (json['stock_quantity'] is String) {
      json['stock_quantity'] = int.tryParse(json['stock_quantity']) ?? 0;
    }
    // Handle pharmacy.id potentially being a String
    if (json['pharmacy'] is Map) {
      final pharmacy = Map<String, dynamic>.from(json['pharmacy']);
      if (pharmacy['id'] is String) {
        pharmacy['id'] = int.tryParse(pharmacy['id']) ?? 0;
      }
      json['pharmacy'] = pharmacy;
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
      imageUrl: imageUrl ?? image,
      stockQuantity: stockQuantity,
      manufacturer: manufacturer,
      requiresPrescription: requiresPrescription,
      pharmacy: pharmacy.toEntity(),
      category: category?.toEntity(),
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }
}
