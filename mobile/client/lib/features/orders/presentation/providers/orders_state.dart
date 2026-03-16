import 'package:equatable/equatable.dart';
import '../../domain/entities/order_entity.dart';

enum OrdersStatus {
  initial,
  loading,
  loaded,
  error,
}

class OrdersState extends Equatable {
  final OrdersStatus status;
  final List<OrderEntity> orders;
  final OrderEntity? selectedOrder;
  final OrderEntity? createdOrder;
  final String? errorMessage;

  const OrdersState({
    required this.status,
    required this.orders,
    this.selectedOrder,
    this.createdOrder,
    this.errorMessage,
  });

  const OrdersState.initial()
      : status = OrdersStatus.initial,
        orders = const [],
        selectedOrder = null,
        createdOrder = null,
        errorMessage = null;

  OrdersState copyWith({
    OrdersStatus? status,
    List<OrderEntity>? orders,
    OrderEntity? selectedOrder,
    bool clearSelectedOrder = false,
    OrderEntity? createdOrder,
    bool clearCreatedOrder = false,
    String? errorMessage,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      selectedOrder: clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
      createdOrder: clearCreatedOrder ? null : (createdOrder ?? this.createdOrder),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        selectedOrder,
        createdOrder,
        errorMessage,
      ];
}
