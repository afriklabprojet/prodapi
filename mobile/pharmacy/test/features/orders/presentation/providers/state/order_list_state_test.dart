import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/state/order_list_state.dart';
import '../../../../../test_helpers.dart';

void main() {
  group('OrderListState', () {
    test('should have initial values by default', () {
      const state = OrderListState();

      expect(state.status, OrderStatus.initial);
      expect(state.orders, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.activeFilter, 'pending');
    });

    test('should create state with specified values', () {
      final orders = TestDataFactory.createOrderList(count: 3);
      final state = OrderListState(
        status: OrderStatus.loaded,
        orders: orders,
        activeFilter: 'confirmed',
      );

      expect(state.status, OrderStatus.loaded);
      expect(state.orders.length, 3);
      expect(state.activeFilter, 'confirmed');
    });

    test('should create state with error', () {
      const state = OrderListState(
        status: OrderStatus.error,
        errorMessage: 'Failed to load orders',
      );

      expect(state.status, OrderStatus.error);
      expect(state.errorMessage, 'Failed to load orders');
    });
  });

  group('OrderListState copyWith', () {
    test('should copy state with new status', () {
      const state = OrderListState();
      final newState = state.copyWith(status: OrderStatus.loading);

      expect(newState.status, OrderStatus.loading);
      expect(newState.orders, isEmpty);
      expect(newState.activeFilter, 'pending');
    });

    test('should copy state with new orders', () {
      const state = OrderListState(status: OrderStatus.loading);
      final orders = TestDataFactory.createOrderList(count: 5);
      final newState = state.copyWith(
        status: OrderStatus.loaded,
        orders: orders,
      );

      expect(newState.status, OrderStatus.loaded);
      expect(newState.orders.length, 5);
    });

    test('should copy state with new filter', () {
      const state = OrderListState(activeFilter: 'pending');
      final newState = state.copyWith(activeFilter: 'ready');

      expect(newState.activeFilter, 'ready');
    });

    test('should copy state with error message', () {
      const state = OrderListState(status: OrderStatus.loading);
      final newState = state.copyWith(
        status: OrderStatus.error,
        errorMessage: 'Network error',
      );

      expect(newState.status, OrderStatus.error);
      expect(newState.errorMessage, 'Network error');
    });

    test('should preserve existing values when not specified', () {
      final orders = TestDataFactory.createOrderList(count: 2);
      final state = OrderListState(
        status: OrderStatus.loaded,
        orders: orders,
        activeFilter: 'confirmed',
      );
      final newState = state.copyWith(activeFilter: 'ready');

      expect(newState.status, OrderStatus.loaded);
      expect(newState.orders.length, 2);
      expect(newState.activeFilter, 'ready');
    });

    test('should handle empty orders list', () {
      final orders = TestDataFactory.createOrderList(count: 3);
      final state = OrderListState(
        status: OrderStatus.loaded,
        orders: orders,
      );
      final newState = state.copyWith(orders: []);

      expect(newState.orders, isEmpty);
    });
  });

  group('OrderStatus enum', () {
    test('should have all expected statuses', () {
      expect(OrderStatus.values, contains(OrderStatus.initial));
      expect(OrderStatus.values, contains(OrderStatus.loading));
      expect(OrderStatus.values, contains(OrderStatus.loaded));
      expect(OrderStatus.values, contains(OrderStatus.error));
    });

    test('should have exactly 4 statuses', () {
      expect(OrderStatus.values.length, 4);
    });
  });

  group('Filter values', () {
    test('should support all standard order filters', () {
      final filters = ['all', 'pending', 'confirmed', 'ready', 'picked_up', 'delivered', 'cancelled'];
      
      for (final filter in filters) {
        final state = OrderListState(activeFilter: filter);
        expect(state.activeFilter, filter);
      }
    });
  });
}
