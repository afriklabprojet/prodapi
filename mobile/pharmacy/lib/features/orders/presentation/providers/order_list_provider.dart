import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/repositories/order_repository.dart';
import '../providers/order_di_providers.dart';
import 'state/order_list_state.dart';

/// Gère la liste des commandes avec pagination cursor-based.
class OrderListNotifier extends AutoDisposeNotifier<OrderListState> {
  late final OrderRepository _repository;

  @override
  OrderListState build() {
    _repository = ref.watch(orderRepositoryProvider);
    // Defer initial fetch to avoid "Bad state: uninitialized" error
    Future.microtask(fetchOrders);
    return const OrderListState();
  }

  // ============================================================
  // FETCH & PAGINATION
  // ============================================================

  Future<void> fetchOrders({OrderStatusFilter? filter}) async {
    if (filter != null) {
      state = state.copyWith(activeFilter: filter);
    }

    state = state.copyWith(
      status: OrderLoadStatus.loading,
      errorMessage: null,
      pagination: const PaginationMeta(),
    );

    final result = await _repository.getOrders(
      status: state.activeFilter.apiValueOrNull,
    );

    _handlePaginatedResult(result, replace: true);
  }

  /// Charge la page suivante (infinite scroll) via cursor
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(status: OrderLoadStatus.loadingMore);

    final result = await _repository.getOrders(
      status: state.activeFilter.apiValueOrNull,
      cursor: state.pagination.nextCursor,
    );

    _handlePaginatedResult(result, replace: false);
  }

  /// Gère le résultat paginé - `replace: true` remplace, `false` ajoute
  void _handlePaginatedResult(
    Either<Failure, PaginatedOrdersResult> result, {
    required bool replace,
  }) {
    result.fold(
      (failure) => state = state.copyWith(
        status: replace ? OrderLoadStatus.error : OrderLoadStatus.loaded,
        errorMessage: failure.message,
      ),
      (paginated) {
        state = state.copyWith(
          status: OrderLoadStatus.loaded,
          orders: replace
              ? paginated.orders
              : [...state.orders, ...paginated.orders],
          pagination: PaginationMeta(
            nextCursor: paginated.nextCursor,
            perPage: paginated.perPage,
            total: paginated.total,
            hasMore: paginated.hasMore,
          ),
        );
      },
    );
  }

  void setFilter(OrderStatusFilter filter) {
    if (state.activeFilter != filter) {
      fetchOrders(filter: filter);
    }
  }

  // ============================================================
  // ORDER ACTIONS
  // ============================================================

  /// Helper générique pour les actions sur une commande
  Future<bool> _executeAction(Future<Either<Failure, dynamic>> action) async {
    final result = await action;
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

  Future<bool> confirmOrder(int orderId) =>
      _executeAction(_repository.confirmOrder(orderId));

  Future<bool> markOrderReady(int orderId) =>
      _executeAction(_repository.markOrderReady(orderId));

  Future<bool> rejectOrder(int orderId, {String? reason}) =>
      _executeAction(_repository.rejectOrder(orderId, reason: reason));

  Future<bool> markOrderDelivered(int orderId) =>
      _executeAction(_repository.markOrderDelivered(orderId));

  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    switch (status) {
      case OrderStatus.ready:
        await markOrderReady(orderId);
      case OrderStatus.confirmed:
        await confirmOrder(orderId);
      case OrderStatus.rejected:
        await rejectOrder(orderId);
      case OrderStatus.delivered:
        await markOrderDelivered(orderId);
      default:
        await fetchOrders();
    }
  }
}

// ============================================================
// PROVIDER
// ============================================================

final orderListProvider =
    NotifierProvider.autoDispose<OrderListNotifier, OrderListState>(
      OrderListNotifier.new,
    );
