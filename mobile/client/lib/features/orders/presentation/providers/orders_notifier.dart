import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/entities/delivery_address_entity.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../../domain/usecases/get_order_details_usecase.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/cancel_order_usecase.dart';
import 'orders_state.dart';

class OrdersNotifier extends StateNotifier<OrdersState> {
  final GetOrdersUseCase getOrdersUseCase;
  final GetOrderDetailsUseCase getOrderDetailsUseCase;
  final CreateOrderUseCase createOrderUseCase;
  final CancelOrderUseCase cancelOrderUseCase;

  OrdersNotifier({
    required this.getOrdersUseCase,
    required this.getOrderDetailsUseCase,
    required this.createOrderUseCase,
    required this.cancelOrderUseCase,
  }) : super(const OrdersState.initial());

  int _currentPage = 1;
  bool _hasMorePages = true;

  // Load orders list (first page)
  Future<void> loadOrders({String? status}) async {
    _currentPage = 1;
    _hasMorePages = true;
    state = state.copyWith(status: OrdersStatus.loading);

    final result = await getOrdersUseCase(status: status, page: 1);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: OrdersStatus.error,
          errorMessage: failure.message,
        );
      },
      (orders) {
        _hasMorePages = orders.length >= AppConstants.defaultPageSize; // match perPage in datasource
        state = state.copyWith(
          status: OrdersStatus.loaded,
          orders: orders,
          errorMessage: null,
        );
      },
    );
  }

  // Load more orders (next page)
  Future<void> loadMoreOrders({String? status}) async {
    if (!_hasMorePages) return;
    _currentPage++;

    final result = await getOrdersUseCase(status: status, page: _currentPage);

    result.fold(
      (failure) {
        _currentPage--; // rollback
      },
      (orders) {
        _hasMorePages = orders.length >= AppConstants.defaultPageSize;
        state = state.copyWith(
          orders: [...state.orders, ...orders],
        );
      },
    );
  }

  // Load order details
  Future<void> loadOrderDetails(int orderId) async {
    state = state.copyWith(status: OrdersStatus.loading);

    final result = await getOrderDetailsUseCase(orderId);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: OrdersStatus.error,
          errorMessage: failure.message,
        );
      },
      (order) {
        state = state.copyWith(
          status: OrdersStatus.loaded,
          selectedOrder: order,
          errorMessage: null,
        );
      },
    );
  }

  // Create order
  Future<void> createOrder({
    required int pharmacyId,
    required List<OrderItemEntity> items,
    required DeliveryAddressEntity deliveryAddress,
    required String paymentMode,
    String? prescriptionImage,
    String? customerNotes,
    int? prescriptionId, // ID de la prescription uploadée via checkout
    String? promoCode,
  }) async {
    state = state.copyWith(status: OrdersStatus.loading);

    final result = await createOrderUseCase(
      pharmacyId: pharmacyId,
      items: items,
      deliveryAddress: deliveryAddress,
      paymentMode: paymentMode,
      prescriptionImage: prescriptionImage,
      customerNotes: customerNotes,
      prescriptionId: prescriptionId,
      promoCode: promoCode,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: OrdersStatus.error,
          errorMessage: failure.message,
        );
      },
      (order) {
        state = state.copyWith(
          status: OrdersStatus.loaded,
          createdOrder: order,
          orders: [order, ...state.orders],
          errorMessage: null,
        );
      },
    );
  }

  // Cancel order
  // Returns error message on failure, null on success
  Future<String?> cancelOrder(int orderId, String reason) async {
    // Keep the current order details visible (don't set loading state)
    final result = await cancelOrderUseCase(orderId, reason);

    return result.fold(
      (failure) {
        // Return error message instead of replacing the page with error state
        return failure.message;
      },
      (_) {
        // Refresh orders list in background (UI will pop immediately)
        loadOrders();
        return null;
      },
    );
  }

  // Clear error
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(
        errorMessage: null,
        status: state.orders.isEmpty
            ? OrdersStatus.initial
            : OrdersStatus.loaded,
      );
    }
  }
}
