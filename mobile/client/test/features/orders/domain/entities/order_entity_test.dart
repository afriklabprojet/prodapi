import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_item_entity.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // PaymentMode
  // ────────────────────────────────────────────────────────────────────────────
  group('PaymentMode.displayName', () {
    test('platform → Paiement en ligne', () {
      expect(PaymentMode.platform.displayName, 'Paiement en ligne');
    });
    test('onDelivery → Paiement à la livraison', () {
      expect(PaymentMode.onDelivery.displayName, 'Paiement à la livraison');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // OrderStatus.displayName (via extension)
  // ────────────────────────────────────────────────────────────────────────────
  group('OrderStatusExtension.displayName', () {
    test(
      'pending → En attente',
      () => expect(OrderStatus.pending.displayName, 'En attente'),
    );
    test(
      'confirmed → Confirmée',
      () => expect(OrderStatus.confirmed.displayName, 'Confirmée'),
    );
    test(
      'preparing → En préparation',
      () => expect(OrderStatus.preparing.displayName, 'En préparation'),
    );
    test('ready → Prête', () => expect(OrderStatus.ready.displayName, 'Prête'));
    test(
      'delivering → En livraison',
      () => expect(OrderStatus.delivering.displayName, 'En livraison'),
    );
    test(
      'delivered → Livrée',
      () => expect(OrderStatus.delivered.displayName, 'Livrée'),
    );
    test(
      'cancelled → Annulée',
      () => expect(OrderStatus.cancelled.displayName, 'Annulée'),
    );
    test(
      'failed → Échouée',
      () => expect(OrderStatus.failed.displayName, 'Échouée'),
    );
  });

  // ────────────────────────────────────────────────────────────────────────────
  // OrderItemEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('OrderItemEntity', () {
    const item = OrderItemEntity(
      id: 1,
      productId: 42,
      name: 'Paracétamol 500mg',
      quantity: 2,
      unitPrice: 500,
      totalPrice: 1000,
    );

    test('props include all fields', () {
      expect(item.props, [1, 42, 'Paracétamol 500mg', 2, 500.0, 1000.0]);
    });

    test('copyWith updates only specified fields', () {
      final copy = item.copyWith(quantity: 3, totalPrice: 1500);
      expect(copy.quantity, 3);
      expect(copy.totalPrice, 1500);
      expect(copy.name, 'Paracétamol 500mg');
    });

    test('props equality', () {
      const same = OrderItemEntity(
        id: 1,
        productId: 42,
        name: 'Paracétamol 500mg',
        quantity: 2,
        unitPrice: 500,
        totalPrice: 1000,
      );
      expect(item, equals(same));
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // DeliveryAddressEntity
  // ────────────────────────────────────────────────────────────────────────────
  group('DeliveryAddressEntity', () {
    test('fullAddress includes city when present', () {
      const a = DeliveryAddressEntity(address: 'Rue 12', city: 'Abidjan');
      expect(a.fullAddress, 'Rue 12, Abidjan');
    });

    test('fullAddress returns only address when city is null', () {
      const a = DeliveryAddressEntity(address: 'Cocody');
      expect(a.fullAddress, 'Cocody');
    });

    test('fullAddress returns only address when city is empty string', () {
      const a = DeliveryAddressEntity(address: 'Marcory', city: '');
      expect(a.fullAddress, 'Marcory');
    });

    test('toJson includes all non-null fields', () {
      const a = DeliveryAddressEntity(
        address: 'Rue 5',
        city: 'Bouaké',
        latitude: 7.69,
        longitude: -5.03,
        phone: '+2250700000000',
      );
      final json = a.toJson();
      expect(json['delivery_address'], 'Rue 5');
      expect(json['delivery_city'], 'Bouaké');
      expect(json['delivery_latitude'], 7.69);
      expect(json['delivery_longitude'], -5.03);
      expect(json['customer_phone'], '+2250700000000');
    });

    test('toJson omits null optional fields', () {
      const a = DeliveryAddressEntity(address: 'Plateaux');
      final json = a.toJson();
      expect(json.containsKey('delivery_city'), isFalse);
      expect(json.containsKey('delivery_latitude'), isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      const a = DeliveryAddressEntity(address: 'Rue 1', city: 'Abidjan');
      final b = a.copyWith(city: 'Yamoussoukro');
      expect(b.address, 'Rue 1');
      expect(b.city, 'Yamoussoukro');
    });
  });

  // ────────────────────────────────────────────────────────────────────────────
  // OrderEntity computed properties
  // ────────────────────────────────────────────────────────────────────────────
  group('OrderEntity', () {
    const addr = DeliveryAddressEntity(address: 'Rue test');

    OrderEntity makeOrder({
      OrderStatus status = OrderStatus.pending,
      String paymentStatus = 'unpaid',
      PaymentMode paymentMode = PaymentMode.platform,
      List<OrderItemEntity> items = const [],
      int itemsCount = 0,
    }) {
      return OrderEntity(
        id: 1,
        reference: 'CMD-001',
        status: status,
        paymentStatus: paymentStatus,
        paymentMode: paymentMode,
        pharmacyId: 1,
        pharmacyName: 'Pharmacie Test',
        items: items,
        itemsCount: itemsCount,
        subtotal: 5000,
        deliveryFee: 500,
        totalAmount: 5500,
        deliveryAddress: addr,
        createdAt: DateTime(2024, 1, 1),
      );
    }

    group('status booleans', () {
      test('isPending true for pending status', () {
        expect(makeOrder(status: OrderStatus.pending).isPending, isTrue);
      });
      test('isConfirmed true for confirmed status', () {
        expect(makeOrder(status: OrderStatus.confirmed).isConfirmed, isTrue);
      });
      test('isPreparing true for preparing status', () {
        expect(makeOrder(status: OrderStatus.preparing).isPreparing, isTrue);
      });
      test('isDelivering true for delivering status', () {
        expect(makeOrder(status: OrderStatus.delivering).isDelivering, isTrue);
      });
      test('isDelivered true for delivered status', () {
        expect(makeOrder(status: OrderStatus.delivered).isDelivered, isTrue);
      });
      test('isCancelled true for cancelled status', () {
        expect(makeOrder(status: OrderStatus.cancelled).isCancelled, isTrue);
      });
    });

    group('isPaid', () {
      test('isPaid true when paymentStatus == paid', () {
        expect(makeOrder(paymentStatus: 'paid').isPaid, isTrue);
      });
      test('isPaid false when paymentStatus == unpaid', () {
        expect(makeOrder(paymentStatus: 'unpaid').isPaid, isFalse);
      });
    });

    group('canCancel / canBeCancelled', () {
      test('canCancel true for pending', () {
        expect(makeOrder(status: OrderStatus.pending).canCancel, isTrue);
      });
      test('canCancel true for confirmed', () {
        expect(makeOrder(status: OrderStatus.confirmed).canCancel, isTrue);
      });
      test('canCancel true for preparing', () {
        expect(makeOrder(status: OrderStatus.preparing).canCancel, isTrue);
      });
      test('canCancel false for delivering', () {
        expect(makeOrder(status: OrderStatus.delivering).canCancel, isFalse);
      });
      test('canCancel false for delivered', () {
        expect(makeOrder(status: OrderStatus.delivered).canCancel, isFalse);
      });
      test('canCancel false for cancelled', () {
        expect(makeOrder(status: OrderStatus.cancelled).canCancel, isFalse);
      });
      test('canBeCancelled equals canCancel', () {
        final o = makeOrder(status: OrderStatus.confirmed);
        expect(o.canBeCancelled, o.canCancel);
      });
    });

    group('needsPayment', () {
      test('true when platform payment mode and unpaid and not cancelled', () {
        expect(
          makeOrder(
            paymentMode: PaymentMode.platform,
            paymentStatus: 'unpaid',
            status: OrderStatus.pending,
          ).needsPayment,
          isTrue,
        );
      });
      test('false when onDelivery payment mode', () {
        expect(
          makeOrder(
            paymentMode: PaymentMode.onDelivery,
            paymentStatus: 'unpaid',
          ).needsPayment,
          isFalse,
        );
      });
      test('false when already paid', () {
        expect(
          makeOrder(
            paymentMode: PaymentMode.platform,
            paymentStatus: 'paid',
          ).needsPayment,
          isFalse,
        );
      });
      test('false when cancelled', () {
        expect(
          makeOrder(
            paymentMode: PaymentMode.platform,
            paymentStatus: 'unpaid',
            status: OrderStatus.cancelled,
          ).needsPayment,
          isFalse,
        );
      });
    });

    group('itemCount', () {
      test('returns items.length when items list is non-empty', () {
        const items = [
          OrderItemEntity(
            name: 'P1',
            quantity: 1,
            unitPrice: 100,
            totalPrice: 100,
          ),
          OrderItemEntity(
            name: 'P2',
            quantity: 2,
            unitPrice: 200,
            totalPrice: 400,
          ),
        ];
        expect(makeOrder(items: items).itemCount, 2);
      });

      test('returns itemsCount when items list is empty', () {
        expect(makeOrder(items: const [], itemsCount: 5).itemCount, 5);
      });
    });

    group('statusLabel', () {
      test('matches OrderStatus.displayName for each status', () {
        for (final s in OrderStatus.values) {
          final label = makeOrder(status: s).statusLabel;
          expect(label, s.displayName);
        }
      });
    });

    group('total alias', () {
      test('total == totalAmount', () {
        final o = makeOrder();
        expect(o.total, o.totalAmount);
      });
    });
  });
}
