import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../domain/usecases/cancel_order_usecase.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/get_order_details_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import 'orders_notifier.dart';
import 'orders_state.dart';

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final repository = ref.watch(ordersRepositoryProvider);

  return OrdersNotifier(
    getOrdersUseCase: GetOrdersUseCase(repository),
    getOrderDetailsUseCase: GetOrderDetailsUseCase(repository),
    createOrderUseCase: CreateOrderUseCase(repository),
    cancelOrderUseCase: CancelOrderUseCase(repository),
  );
});

final activeOrdersCountProvider = Provider<int>((ref) {
  final orders = ref.watch(ordersProvider.select((state) => state.orders));
  return orders.where((order) => order.isActive).length;
});
