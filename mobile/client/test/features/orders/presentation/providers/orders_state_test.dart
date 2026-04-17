import 'package:flutter_test/flutter_test.dart';

import 'package:drpharma_client/features/orders/presentation/providers/orders_state.dart';
import 'package:drpharma_client/features/orders/domain/entities/order_entity.dart';
import 'package:drpharma_client/features/orders/domain/entities/delivery_address_entity.dart';

void main() {
  group('OrdersState.initial()', () {
    test('status is initial', () {
      const s = OrdersState.initial();
      expect(s.status, OrdersStatus.initial);
    });

    test('orders list is empty', () {
      const s = OrdersState.initial();
      expect(s.orders, isEmpty);
    });

    test('selectedOrder is null', () {
      const s = OrdersState.initial();
      expect(s.selectedOrder, isNull);
    });

    test('createdOrder is null', () {
      const s = OrdersState.initial();
      expect(s.createdOrder, isNull);
    });

    test('errorMessage is null', () {
      const s = OrdersState.initial();
      expect(s.errorMessage, isNull);
    });
  });

  group('OrdersState — copyWith', () {
    test('updates status', () {
      const s = OrdersState.initial();
      expect(
        s.copyWith(status: OrdersStatus.loading).status,
        OrdersStatus.loading,
      );
    });

    test('clearSelectedOrder sets selectedOrder to null', () {
      final s = OrdersState(
        status: OrdersStatus.loaded,
        orders: const [],
        selectedOrder: _makeOrder(),
      );
      expect(s.copyWith(clearSelectedOrder: true).selectedOrder, isNull);
    });

    test('clearCreatedOrder sets createdOrder to null', () {
      final s = OrdersState(
        status: OrdersStatus.loaded,
        orders: const [],
        createdOrder: _makeOrder(),
      );
      expect(s.copyWith(clearCreatedOrder: true).createdOrder, isNull);
    });

    test('errorMessage always overwritten (null clears)', () {
      const s = OrdersState(
        status: OrdersStatus.error,
        orders: [],
        errorMessage: 'err',
      );
      // copyWith without errorMessage → null (design choice in this class)
      expect(s.copyWith(status: OrdersStatus.loaded).errorMessage, isNull);
    });
  });

  group('OrdersState — props equality', () {
    test('two initial states are equal', () {
      const a = OrdersState.initial();
      const b = OrdersState.initial();
      expect(a, equals(b));
    });

    test('different status makes states unequal', () {
      const a = OrdersState.initial();
      const b = OrdersState(status: OrdersStatus.loading, orders: []);
      expect(a, isNot(equals(b)));
    });
  });
}

OrderEntity _makeOrder() => OrderEntity(
  id: 1,
  reference: 'CMD-001',
  status: OrderStatus.pending,
  paymentStatus: 'pending',
  paymentMode: PaymentMode.onDelivery,
  pharmacyId: 1,
  pharmacyName: 'Pharmacie Test',
  totalAmount: 5000,
  subtotal: 4500,
  deliveryFee: 500,
  items: const [],
  createdAt: DateTime(2024),
  itemsCount: 0,
  deliveryAddress: const DeliveryAddressEntity(address: '123 Rue Test'),
);
