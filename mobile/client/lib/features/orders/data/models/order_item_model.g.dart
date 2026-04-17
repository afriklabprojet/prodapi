// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItemModel _$OrderItemModelFromJson(Map<String, dynamic> json) =>
    OrderItemModel(
      productId: (json['product_id'] as num?)?.toInt(),
      id: (json['id'] as num?)?.toInt(),
      name: OrderItemModel._readName(json, 'name') as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice:
          (OrderItemModel._readUnitPrice(json, 'unit_price') as num).toDouble(),
      totalPrice: (OrderItemModel._readTotalPrice(json, 'total_price') as num)
          .toDouble(),
    );
