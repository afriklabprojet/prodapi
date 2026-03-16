import '../../../domain/entities/order_entity.dart';

/// Statuts possibles de la liste de commandes
enum OrderStatus { initial, loading, loaded, error }

/// État de la liste de commandes
class OrderListState {
  final OrderStatus status;
  final List<OrderEntity> orders;
  final String? errorMessage;
  final String activeFilter;

  const OrderListState({
    this.status = OrderStatus.initial,
    this.orders = const [],
    this.errorMessage,
    this.activeFilter = 'pending',
  });

  OrderListState copyWith({
    OrderStatus? status,
    List<OrderEntity>? orders,
    String? errorMessage,
    String? activeFilter,
  }) {
    return OrderListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      errorMessage: errorMessage,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  /// Nombre de commandes en attente
  int get pendingCount => orders.where((o) => o.status == 'pending').length;

  /// Nombre de commandes confirmées
  int get confirmedCount => orders.where((o) => o.status == 'confirmed').length;

  /// Nombre de commandes prêtes
  int get readyCount => orders.where((o) => o.status == 'ready').length;

  /// Nombre de commandes livrées
  int get deliveredCount => orders.where((o) => o.status == 'delivered').length;

  @override
  String toString() =>
      'OrderListState(status: $status, orders: ${orders.length}, filter: $activeFilter)';
}
