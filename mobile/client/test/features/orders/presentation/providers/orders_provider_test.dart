import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drpharma_client/features/orders/presentation/providers/orders_provider.dart';
import 'package:drpharma_client/features/orders/presentation/providers/orders_state.dart';

void main() {
  group('OrdersProvider Tests', () {
    test('ordersProvider should be defined', () {
      expect(ordersProvider, isNotNull);
    });

    test('ordersProvider should be a StateNotifierProvider', () {
      expect(ordersProvider, isA<StateNotifierProvider>());
    });

    test('OrdersState should have initial state', () {
      const state = OrdersState.initial();
      expect(state.status, OrdersStatus.initial);
      expect(state.orders, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('OrdersState should support copyWith for loading', () {
      final state = const OrdersState.initial().copyWith(
        status: OrdersStatus.loading,
      );
      expect(state.status, OrdersStatus.loading);
    });

    test('OrdersState should support copyWith for error', () {
      final state = const OrdersState.initial().copyWith(
        status: OrdersStatus.error,
        errorMessage: 'Test error',
      );
      expect(state.errorMessage, 'Test error');
    });
  });
}
