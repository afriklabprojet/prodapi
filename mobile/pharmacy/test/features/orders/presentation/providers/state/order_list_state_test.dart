import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/orders/presentation/providers/state/order_list_state.dart';
import 'package:drpharma_pharmacy/features/orders/domain/enums/order_status.dart';
import '../../../../../test_helpers.dart';

void main() {
  group('OrderListState', () {
    test('should have initial values by default', () {
      const state = OrderListState();

      expect(state.status, OrderLoadStatus.initial);
      expect(state.orders, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.activeFilter, OrderStatusFilter.pending);
    });

    test('should create state with specified values', () {
      final orders = TestDataFactory.createOrderList(count: 3);
      final state = OrderListState(
        status: OrderLoadStatus.loaded,
        orders: orders,
        activeFilter: OrderStatusFilter.confirmed,
      );

      expect(state.status, OrderLoadStatus.loaded);
      expect(state.orders.length, 3);
      expect(state.activeFilter, OrderStatusFilter.confirmed);
    });

    test('should create state with error', () {
      const state = OrderListState(
        status: OrderLoadStatus.error,
        errorMessage: 'Failed to load orders',
      );

      expect(state.status, OrderLoadStatus.error);
      expect(state.errorMessage, 'Failed to load orders');
    });
  });

  group('OrderListState copyWith', () {
    test('should copy state with new status', () {
      const state = OrderListState();
      final newState = state.copyWith(status: OrderLoadStatus.loading);

      expect(newState.status, OrderLoadStatus.loading);
      expect(newState.orders, isEmpty);
      expect(newState.activeFilter, OrderStatusFilter.pending);
    });

    test('should copy state with new orders', () {
      const state = OrderListState(status: OrderLoadStatus.loading);
      final orders = TestDataFactory.createOrderList(count: 5);
      final newState = state.copyWith(
        status: OrderLoadStatus.loaded,
        orders: orders,
      );

      expect(newState.status, OrderLoadStatus.loaded);
      expect(newState.orders.length, 5);
    });

    test('should copy state with new filter', () {
      const state = OrderListState(activeFilter: OrderStatusFilter.pending);
      final newState = state.copyWith(activeFilter: OrderStatusFilter.ready);

      expect(newState.activeFilter, OrderStatusFilter.ready);
    });

    test('should copy state with error message', () {
      const state = OrderListState(status: OrderLoadStatus.loading);
      final newState = state.copyWith(
        status: OrderLoadStatus.error,
        errorMessage: 'Network error',
      );

      expect(newState.status, OrderLoadStatus.error);
      expect(newState.errorMessage, 'Network error');
    });

    test('should preserve existing values when not specified', () {
      final orders = TestDataFactory.createOrderList(count: 2);
      final state = OrderListState(
        status: OrderLoadStatus.loaded,
        orders: orders,
        activeFilter: OrderStatusFilter.confirmed,
      );
      final newState = state.copyWith(activeFilter: OrderStatusFilter.ready);

      expect(newState.status, OrderLoadStatus.loaded);
      expect(newState.orders.length, 2);
      expect(newState.activeFilter, OrderStatusFilter.ready);
    });

    test('should handle empty orders list', () {
      final orders = TestDataFactory.createOrderList(count: 3);
      final state = OrderListState(
        status: OrderLoadStatus.loaded,
        orders: orders,
      );
      final newState = state.copyWith(orders: []);

      expect(newState.orders, isEmpty);
    });
  });

  group('OrderLoadStatus enum', () {
    test('should have all expected statuses', () {
      expect(OrderLoadStatus.values, contains(OrderLoadStatus.initial));
      expect(OrderLoadStatus.values, contains(OrderLoadStatus.loading));
      expect(OrderLoadStatus.values, contains(OrderLoadStatus.loaded));
      expect(OrderLoadStatus.values, contains(OrderLoadStatus.error));
    });

    test('should have exactly 5 statuses', () {
      // initial, loading, loadingMore, loaded, error
      expect(OrderLoadStatus.values.length, 5);
    });
  });

  group('Filter values', () {
    test('should support all standard order filters', () {
      for (final filter in OrderStatusFilter.values) {
        final state = OrderListState(activeFilter: filter);
        expect(state.activeFilter, filter);
      }
    });
  });
}
