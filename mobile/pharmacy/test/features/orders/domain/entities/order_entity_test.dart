import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_pharmacy/features/orders/domain/enums/order_status.dart';

import '../../../../test_helpers.dart';

void main() {
  group('OrderEntity', () {
    test('should create OrderEntity with required fields', () {
      final order = OrderEntity(
        id: 1,
        reference: 'DR-TEST001',
        status: OrderStatus.pending,
        paymentMode: 'platform',
        totalAmount: 5000.0,
        customerName: 'John Doe',
        customerPhone: '+225 07 00 00 00 00',
        createdAt: DateTime(2026, 2, 5),
      );

      expect(order.id, 1);
      expect(order.reference, 'DR-TEST001');
      expect(order.status, OrderStatus.pending);
      expect(order.paymentMode, 'platform');
      expect(order.totalAmount, 5000.0);
      expect(order.customerName, 'John Doe');
      expect(order.customerPhone, '+225 07 00 00 00 00');
      expect(order.deliveryAddress, isNull);
      expect(order.items, isNull);
    });

    test('should create OrderEntity with all fields', () {
      final items = [
        const OrderItemEntity(
          name: 'Paracétamol',
          quantity: 2,
          unitPrice: 500.0,
          totalPrice: 1000.0,
        ),
        const OrderItemEntity(
          name: 'Ibuprofène',
          quantity: 1,
          unitPrice: 1500.0,
          totalPrice: 1500.0,
        ),
      ];

      final order = OrderEntity(
        id: 1,
        reference: 'DR-TEST001',
        status: OrderStatus.confirmed,
        paymentMode: 'delivery',
        totalAmount: 3500.0,
        customerName: 'John Doe',
        customerPhone: '+225 07 00 00 00 00',
        createdAt: DateTime(2026, 2, 5),
        deliveryAddress: 'Cocody, Abidjan',
        customerNotes: 'Livrer avant 18h',
        pharmacyNotes: 'Client fidèle',
        items: items,
        itemsCount: 2,
        deliveryFee: 1000.0,
        subtotal: 2500.0,
      );

      expect(order.deliveryAddress, 'Cocody, Abidjan');
      expect(order.customerNotes, 'Livrer avant 18h');
      expect(order.pharmacyNotes, 'Client fidèle');
      expect(order.items?.length, 2);
      expect(order.itemsCount, 2);
      expect(order.deliveryFee, 1000.0);
      expect(order.subtotal, 2500.0);
    });

    test('should copy OrderEntity with new values', () {
      final original = TestDataFactory.createOrder(
        status: OrderStatus.pending,
        totalAmount: 5000.0,
      );

      final updated = original.copyWith(
        status: OrderStatus.confirmed,
        pharmacyNotes: 'En préparation',
      );

      expect(updated.id, original.id);
      expect(updated.reference, original.reference);
      expect(updated.status, OrderStatus.confirmed);
      expect(updated.pharmacyNotes, 'En préparation');
      expect(updated.totalAmount, original.totalAmount);
    });

    test('should create OrderEntity list using factory', () {
      final orders = TestDataFactory.createOrderList(count: 5);

      expect(orders.length, 5);
      expect(orders[0].status, OrderStatus.pending);
      expect(orders[1].status, OrderStatus.confirmed);
      expect(orders[2].status, OrderStatus.ready);
      expect(orders[3].status, OrderStatus.delivered);
      expect(orders[4].status, OrderStatus.cancelled);
    });
  });

  group('OrderItemEntity', () {
    test('should create OrderItemEntity correctly', () {
      const item = OrderItemEntity(
        name: 'Paracétamol 500mg',
        quantity: 3,
        unitPrice: 500.0,
        totalPrice: 1500.0,
      );

      expect(item.name, 'Paracétamol 500mg');
      expect(item.quantity, 3);
      expect(item.unitPrice, 500.0);
      expect(item.totalPrice, 1500.0);
    });

    test('should create OrderItemEntity using factory', () {
      final item = TestDataFactory.createOrderItem(
        name: 'Amoxicilline',
        quantity: 2,
        unitPrice: 2500.0,
      );

      expect(item.name, 'Amoxicilline');
      expect(item.quantity, 2);
      expect(item.unitPrice, 2500.0);
      expect(item.totalPrice, 5000.0); // Auto-calculated
    });
  });

  group('Order Status Tests', () {
    test('should identify different order statuses', () {
      final pendingOrder = TestDataFactory.createOrder(status: OrderStatus.pending);
      final confirmedOrder = TestDataFactory.createOrder(status: OrderStatus.confirmed);
      final readyOrder = TestDataFactory.createOrder(status: OrderStatus.ready);
      final deliveredOrder = TestDataFactory.createOrder(status: OrderStatus.delivered);
      final cancelledOrder = TestDataFactory.createOrder(status: OrderStatus.cancelled);

      expect(pendingOrder.status, OrderStatus.pending);
      expect(confirmedOrder.status, OrderStatus.confirmed);
      expect(readyOrder.status, OrderStatus.ready);
      expect(deliveredOrder.status, OrderStatus.delivered);
      expect(cancelledOrder.status, OrderStatus.cancelled);
    });
  });

  group('Payment Mode Tests', () {
    test('should handle different payment modes', () {
      final platformPayment = TestDataFactory.createOrder(paymentMode: 'platform');
      final deliveryPayment = TestDataFactory.createOrder(paymentMode: 'delivery');

      expect(platformPayment.paymentMode, 'platform');
      expect(deliveryPayment.paymentMode, 'delivery');
    });
  });
}
