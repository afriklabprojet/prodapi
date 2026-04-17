// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      price: _parsePrice(json['price']),
      discountPrice: _parsePriceNullable(json['discount_price']),
      imageUrl: json['image_url'] as String?,
      image: json['image'] as String?,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 10,
      manufacturer: json['manufacturer'] as String?,
      activeIngredient: json['active_ingredient'] as String?,
      usageInstructions: json['usage_instructions'] as String?,
      sideEffects: json['side_effects'] as String?,
      requiresPrescription: json['requires_prescription'] as bool? ?? false,
      pharmacy:
          PharmacyModel.fromJson(json['pharmacy'] as Map<String, dynamic>),
      category: _categoryFromJson(json['category']),
      averageRating: _parsePriceNullable(json['average_rating']),
      reviewsCount: _parseIntNullable(json['reviews_count']),
      tags: _parseTagsList(json['tags']),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'image_url': instance.imageUrl,
      'image': instance.image,
      'stock_quantity': instance.stockQuantity,
      'low_stock_threshold': instance.lowStockThreshold,
      'manufacturer': instance.manufacturer,
      'active_ingredient': instance.activeIngredient,
      'usage_instructions': instance.usageInstructions,
      'side_effects': instance.sideEffects,
      'requires_prescription': instance.requiresPrescription,
      'pharmacy': instance.pharmacy,
      'category': instance.category,
      'discount_price': instance.discountPrice,
      'average_rating': instance.averageRating,
      'reviews_count': instance.reviewsCount,
      'tags': instance.tags,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
