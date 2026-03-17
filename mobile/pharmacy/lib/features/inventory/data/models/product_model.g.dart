// GENERATED CODE — HAND-PATCHED for safe type conversions.
// DO NOT run build_runner on this file — it would regenerate unsafe casts.
// The Laravel API (PDO) may return numeric columns as String.

part of 'product_model.dart';

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: _toInt(json['id']),
  name: json['name']?.toString() ?? '',
  description: json['description']?.toString() ?? '',
  price: _toDouble(json['price']),
  stockQuantity: _toInt(json['stock_quantity']),
  imageUrl: json['image']?.toString(),
  category: json['category']?.toString() ?? '',
  barcode: json['barcode']?.toString(),
  requiresPrescription: _toBool(json['requires_prescription']),
  isAvailable: _toBool(json['is_available']),
  brand: json['brand']?.toString(),
  manufacturer: json['manufacturer']?.toString(),
  activeIngredient: json['active_ingredient']?.toString(),
  unit: json['unit']?.toString(),
  expiryDate: json['expiry_date'] == null
      ? null
      : DateTime.tryParse(json['expiry_date'].toString()),
  usageInstructions: json['usage_instructions']?.toString(),
  sideEffects: json['side_effects']?.toString(),
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'stock_quantity': instance.stockQuantity,
      'image': instance.imageUrl,
      'category': instance.category,
      'barcode': instance.barcode,
      'requires_prescription': instance.requiresPrescription,
      'is_available': instance.isAvailable,
      'brand': instance.brand,
      'manufacturer': instance.manufacturer,
      'active_ingredient': instance.activeIngredient,
      'unit': instance.unit,
      'expiry_date': instance.expiryDate?.toIso8601String(),
      'usage_instructions': instance.usageInstructions,
      'side_effects': instance.sideEffects,
    };
