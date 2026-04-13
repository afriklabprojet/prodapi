import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/orders/data/models/order_model.dart';
import 'package:drpharma_client/features/orders/data/models/order_item_model.dart';
import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_item_entity.dart';

// ────────────────────────────────────────────────────────────────────────────
// JSON helpers
// ────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _pharmacyBasicJson({
  int id = 1,
  String name = 'Ph Centre',
  String? phone,
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'phone': ?phone,
};

Map<String, dynamic> _orderItemJson({
  int? productId = 10,
  String? name,
  String? productName,
  int quantity = 2,
  dynamic unitPrice = 1500.0,
  dynamic totalPrice = 3000.0,
}) => <String, dynamic>{
  'product_id': ?productId,
  'name': ?name,
  'product_name': ?productName,
  'quantity': quantity,
  'unit_price': unitPrice,
  'total_price': totalPrice,
};

Map<String, dynamic> _orderJson({
  int id = 1001,
  String reference = 'ORD-2024-001',
  String status = 'pending',
  String paymentStatus = 'pending',
  String paymentMode = 'platform',
  dynamic totalAmount = 5000.0,
  dynamic subtotal,
  dynamic deliveryFee,
  String deliveryAddress = 'Plateau, Abidjan',
  String? deliveryCity,
  List<Map<String, dynamic>>? items,
  Map<String, dynamic>? pharmacy,
  int? pharmacyId,
  String createdAt = '2024-06-01T10:00:00.000Z',
  String? deliveryLatitude,
  String? deliveryLongitude,
  String? cancellationReason,
}) => <String, dynamic>{
  'id': id,
  'reference': reference,
  'status': status,
  'payment_status': paymentStatus,
  'payment_mode': paymentMode,
  'total_amount': totalAmount,
  'subtotal': ?subtotal,
  'delivery_fee': ?deliveryFee,
  'delivery_address': deliveryAddress,
  'delivery_city': ?deliveryCity,
  'delivery_latitude': ?deliveryLatitude,
  'delivery_longitude': ?deliveryLongitude,
  'items': items ?? [],
  'pharmacy': ?pharmacy,
  'pharmacy_id': ?pharmacyId,
  'cancellation_reason': ?cancellationReason,
  'created_at': createdAt,
};

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // OrderItemModel
  // ────────────────────────────────────────────────────────────────────────────
  group('OrderItemModel', () {
    group('fromJson', () {
      test('parses all standard fields', () {
        final item = OrderItemModel.fromJson(_orderItemJson(name: 'Doliprane'));
        expect(item.productId, 10);
        expect(item.name, 'Doliprane');
        expect(item.quantity, 2);
        expect(item.unitPrice, 1500.0);
        expect(item.totalPrice, 3000.0);
      });

      test('reads product_name when name is missing', () {
        final item = OrderItemModel.fromJson(
          _orderItemJson(productName: 'Amoxicilline'),
        );
        expect(item.name, 'Amoxicilline');
      });

      test('defaults name to "Produit inconnu" when both absent', () {
        final json = <String, dynamic>{
          'quantity': 1,
          'unit_price': 100.0,
          'total_price': 100.0,
        };
        expect(OrderItemModel.fromJson(json).name, 'Produit inconnu');
      });

      test('parses unit_price from String', () {
        final item = OrderItemModel.fromJson(
          _orderItemJson(name: 'P', unitPrice: '2500.00'),
        );
        expect(item.unitPrice, 2500.0);
      });

      test('parses total_price from String', () {
        final item = OrderItemModel.fromJson(
          _orderItemJson(name: 'P', totalPrice: '5000.00'),
        );
        expect(item.totalPrice, 5000.0);
      });
    });

    group('toEntity', () {
      test('converts to OrderItemEntity', () {
        final entity = OrderItemModel.fromJson(
          _orderItemJson(name: 'Doliprane'),
        ).toEntity();
        expect(entity, isA<OrderItemEntity>());
        expect(entity.name, 'Doliprane');
        expect(entity.quantity, 2);
        expect(entity.unitPrice, 1500.0);
      });
    });

    group('fromEntity', () {
      test('round-trips entity', () {
        const entity = OrderItemEntity(
          id: 5,
          productId: 10,
          name: 'Aspirine',
          quantity: 3,
          unitPrice: 800.0,
          totalPrice: 2400.0,
        );
        final model = OrderItemModel.fromEntity(entity);
        expect(model.name, 'Aspirine');
        expect(model.quantity, 3);
        expect(model.unitPrice, 800.0);
      });
    });

    group('toJson', () {
      test('uses price key (not unit_price) per Laravel convention', () {
        final item = OrderItemModel.fromJson(_orderItemJson(name: 'P'));
        final json = item.toJson();
        expect(json.containsKey('price'), isTrue);
        expect(json.containsKey('unit_price'), isFalse);
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // OrderModel
  // ────────────────────────────────────────────────────────────────────────────
  group('OrderModel', () {
    group('fromJson — standard cases', () {
      test('parses all required fields', () {
        final model = OrderModel.fromJson(_orderJson());
        expect(model.id, 1001);
        expect(model.reference, 'ORD-2024-001');
        expect(model.status, 'pending');
        expect(model.paymentMode, 'platform');
        expect(model.totalAmount, 5000.0);
        expect(model.deliveryAddress, 'Plateau, Abidjan');
      });

      test('parses id from String', () {
        final json = _orderJson()..['id'] = '99';
        expect(OrderModel.fromJson(json).id, 99);
      });

      test('parses total_amount from String', () {
        final model = OrderModel.fromJson(_orderJson(totalAmount: '7500.00'));
        expect(model.totalAmount, 7500.0);
      });

      test('parses subtotal and delivery_fee from String', () {
        final model = OrderModel.fromJson(
          _orderJson(subtotal: '4000.00', deliveryFee: '1000.00'),
        );
        expect(model.subtotal, 4000.0);
        expect(model.deliveryFee, 1000.0);
      });

      test('defaults paymentStatus to pending when absent', () {
        final json = _orderJson();
        json.remove('payment_status');
        expect(OrderModel.fromJson(json).paymentStatus, 'pending');
      });

      test('defaults currency to XOF when absent', () {
        expect(OrderModel.fromJson(_orderJson()).currency, 'XOF');
      });

      test('parses delivery_latitude and longitude from String', () {
        final model = OrderModel.fromJson(
          _orderJson(
            deliveryLatitude: '5.3599517',
            deliveryLongitude: '-4.0082563',
          ),
        );
        expect(model.deliveryLatitude, closeTo(5.35, 0.01));
        expect(model.deliveryLongitude, closeTo(-4.00, 0.01));
      });

      test('parses pharmacy_id from String', () {
        final json = _orderJson(pharmacyId: null);
        json['pharmacy_id'] = '3';
        expect(OrderModel.fromJson(json).pharmacyId, 3);
      });
    });

    group('fromJson — pharmacy embedding', () {
      test('parses embedded pharmacy', () {
        final model = OrderModel.fromJson(
          _orderJson(
            pharmacy: _pharmacyBasicJson(
              id: 7,
              name: 'Cocody',
              phone: '+225111',
            ),
          ),
        );
        expect(model.pharmacy?.id, 7);
        expect(model.pharmacy?.name, 'Cocody');
        expect(model.pharmacy?.phone, '+225111');
      });

      test('handles pharmacy id from String', () {
        final pharmacyJson = _pharmacyBasicJson()..['id'] = '5';
        final model = OrderModel.fromJson(_orderJson(pharmacy: pharmacyJson));
        expect(model.pharmacy?.id, 5);
      });
    });

    group('fromJson — items', () {
      test('parses list of items', () {
        final model = OrderModel.fromJson(
          _orderJson(
            items: [
              _orderItemJson(name: 'Doliprane'),
              _orderItemJson(productId: 11, name: 'Aspirine', quantity: 1),
            ],
          ),
        );
        expect(model.items.length, 2);
        expect(model.items.first.name, 'Doliprane');
      });

      test('defaults items to empty list when absent', () {
        final json = _orderJson();
        json.remove('items');
        expect(OrderModel.fromJson(json).items, isEmpty);
      });
    });

    group('toEntity — status mapping', () {
      for (final entry in {
        'pending': OrderStatus.pending,
        'confirmed': OrderStatus.confirmed,
        'processing': OrderStatus.preparing,
        'preparing': OrderStatus.preparing,
        'ready': OrderStatus.ready,
        'delivering': OrderStatus.delivering,
        'delivered': OrderStatus.delivered,
        'cancelled': OrderStatus.cancelled,
        'failed': OrderStatus.failed,
        'unknown_xyz': OrderStatus.pending, // default
      }.entries) {
        test('maps "${entry.key}" → ${entry.value}', () {
          final entity = OrderModel.fromJson(
            _orderJson(status: entry.key),
          ).toEntity();
          expect(entity.status, entry.value);
        });
      }
    });

    group('toEntity — payment mode mapping', () {
      test('maps platform → PaymentMode.platform', () {
        final entity = OrderModel.fromJson(
          _orderJson(paymentMode: 'platform'),
        ).toEntity();
        expect(entity.paymentMode, PaymentMode.platform);
      });

      test('maps on_delivery → PaymentMode.onDelivery', () {
        final entity = OrderModel.fromJson(
          _orderJson(paymentMode: 'on_delivery'),
        ).toEntity();
        expect(entity.paymentMode, PaymentMode.onDelivery);
      });

      test('maps cash → PaymentMode.onDelivery', () {
        final entity = OrderModel.fromJson(
          _orderJson(paymentMode: 'cash'),
        ).toEntity();
        expect(entity.paymentMode, PaymentMode.onDelivery);
      });
    });

    group('toEntity — computed properties', () {
      test('converts to OrderEntity', () {
        final entity = OrderModel.fromJson(_orderJson()).toEntity();
        expect(entity, isA<OrderEntity>());
        expect(entity.id, 1001);
        expect(entity.reference, 'ORD-2024-001');
        expect(entity.totalAmount, 5000.0);
      });

      test('isPending uses status field', () {
        final entity = OrderModel.fromJson(
          _orderJson(status: 'pending'),
        ).toEntity();
        expect(entity.isPending, isTrue);
        expect(entity.isConfirmed, isFalse);
      });

      test('isCancelled uses cancelled status', () {
        final entity = OrderModel.fromJson(
          _orderJson(status: 'cancelled'),
        ).toEntity();
        expect(entity.isCancelled, isTrue);
        expect(entity.canCancel, isFalse);
      });

      test('canCancel is true for pending', () {
        final entity = OrderModel.fromJson(
          _orderJson(status: 'pending'),
        ).toEntity();
        expect(entity.canCancel, isTrue);
      });

      test('canCancel is true for confirmed', () {
        final entity = OrderModel.fromJson(
          _orderJson(status: 'confirmed'),
        ).toEntity();
        expect(entity.canCancel, isTrue);
      });

      test('isPaid uses paymentStatus', () {
        final json = _orderJson();
        json['payment_status'] = 'paid';
        final entity = OrderModel.fromJson(json).toEntity();
        expect(entity.isPaid, isTrue);
      });

      test('needsPayment is true for platform unpaid non-cancelled', () {
        final entity = OrderModel.fromJson(
          _orderJson(paymentMode: 'platform', paymentStatus: 'pending'),
        ).toEntity();
        expect(entity.needsPayment, isTrue);
      });

      test('deliveryAddress maps city', () {
        final entity = OrderModel.fromJson(
          _orderJson(deliveryAddress: '12 rue A', deliveryCity: 'Abidjan'),
        ).toEntity();
        expect(entity.deliveryAddress.city, 'Abidjan');
        expect(entity.deliveryAddress.fullAddress, '12 rue A, Abidjan');
      });

      test('itemCount prefers items list length over itemsCount', () {
        final model = OrderModel.fromJson(
          _orderJson(items: [_orderItemJson(name: 'P')]),
        );
        final entity = model.toEntity();
        expect(entity.itemCount, 1);
      });

      test('createdAt is parsed from ISO string', () {
        final entity = OrderModel.fromJson(_orderJson()).toEntity();
        expect(entity.createdAt, DateTime.parse('2024-06-01T10:00:00.000Z'));
      });
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // OrderEntity computed properties
  // ────────────────────────────────────────────────────────────────────────────
  group('OrderEntity', () {
    const delivery = DeliveryAddressEntity(address: 'Plateau');

    OrderEntity makeEntity({
      OrderStatus status = OrderStatus.pending,
      String paymentStatus = 'pending',
      PaymentMode paymentMode = PaymentMode.platform,
    }) => OrderEntity(
      id: 1,
      reference: 'REF',
      status: status,
      paymentStatus: paymentStatus,
      paymentMode: paymentMode,
      pharmacyId: 1,
      pharmacyName: 'Ph',
      items: const [],
      subtotal: 1000.0,
      deliveryFee: 500.0,
      totalAmount: 1500.0,
      deliveryAddress: delivery,
      createdAt: DateTime(2024),
    );

    test('statusLabel matches all statuses', () {
      expect(
        makeEntity(status: OrderStatus.pending).statusLabel,
        'En attente',
      );
      expect(
        makeEntity(status: OrderStatus.confirmed).statusLabel,
        'Confirmée',
      );
      expect(
        makeEntity(status: OrderStatus.preparing).statusLabel,
        'En préparation',
      );
      expect(makeEntity(status: OrderStatus.ready).statusLabel, 'Prête');
      expect(
        makeEntity(status: OrderStatus.delivering).statusLabel,
        'En livraison',
      );
      expect(makeEntity(status: OrderStatus.delivered).statusLabel, 'Livrée');
      expect(makeEntity(status: OrderStatus.cancelled).statusLabel, 'Annulée');
      expect(makeEntity(status: OrderStatus.failed).statusLabel, 'Échouée');
    });

    test('total == totalAmount', () {
      expect(makeEntity().total, 1500.0);
    });

    test('PaymentMode displayName', () {
      expect(PaymentMode.platform.displayName, 'Paiement en ligne');
      expect(PaymentMode.onDelivery.displayName, 'Paiement à la livraison');
    });
  });
}
