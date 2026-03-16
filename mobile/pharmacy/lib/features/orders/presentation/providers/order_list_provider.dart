import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/order_repository.dart';
import '../providers/order_di_providers.dart';
import 'state/order_list_state.dart';

class OrderListNotifier extends StateNotifier<OrderListState> {
  final OrderRepository _repository;

  OrderListNotifier(this._repository) : super(const OrderListState()) {
    fetchOrders();
  }

  Future<void> fetchOrders({String? status}) async {
    // If status passed, update filter, otherwise use current active filter
    if (status != null) {
      state = state.copyWith(activeFilter: status);
    }

    state = state.copyWith(status: OrderStatus.loading, errorMessage: null);

    // If filter is 'all', pass null to repository
    final filterToSend = state.activeFilter == 'all'
        ? null
        : state.activeFilter;

    final result = await _repository.getOrders(status: filterToSend);

    result.fold(
      (failure) => state = state.copyWith(
        status: OrderStatus.error,
        errorMessage: failure.message,
      ),
      (orders) =>
          state = state.copyWith(status: OrderStatus.loaded, orders: orders),
    );
  }

  void setFilter(String filter) {
    if (state.activeFilter != filter) {
      fetchOrders(status: filter);
    }
  }

  Future<bool> confirmOrder(int orderId) async {
    final result = await _repository.confirmOrder(orderId);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        fetchOrders();
        return true;
      },
    );
  }

  Future<bool> markOrderReady(int orderId) async {
    final result = await _repository.markOrderReady(orderId);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        fetchOrders();
        return true;
      },
    );
  }

  Future<bool> rejectOrder(int orderId, {String? reason}) async {
    final result = await _repository.rejectOrder(orderId, reason: reason);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        fetchOrders();
        return true;
      },
    );
  }

  Future<bool> markOrderDelivered(int orderId) async {
    final result = await _repository.markOrderDelivered(orderId);
    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        fetchOrders();
        return true;
      },
    );
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
      // General purpose update if repository supports it, 
      // or map string status to specific methods
      if (status == 'ready') {
          await markOrderReady(orderId);
      } else if (status == 'confirmed') {
          await confirmOrder(orderId);
      } else if (status == 'rejected') {
          await rejectOrder(orderId);
      } else if (status == 'delivered') {
          await markOrderDelivered(orderId);
      } else {
        // Fallback or other status not implemented on repo yet
        // For now, reload orders to reflect changes made elsewhere
        await fetchOrders(); 
      }
  }
}

final orderListProvider =
    StateNotifierProvider.autoDispose<OrderListNotifier, OrderListState>((ref) {
      return OrderListNotifier(ref.watch(orderRepositoryProvider));
    });
