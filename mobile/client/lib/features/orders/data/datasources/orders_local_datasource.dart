import '../models/order_model.dart';

/// Data source locale pour les commandes (cache)
abstract class OrdersLocalDataSource {
  Future<void> cacheOrders(List<OrderModel> orders);
  List<OrderModel>? getCachedOrders();
  Future<void> cacheOrder(OrderModel order);
  OrderModel? getCachedOrder(int orderId);
  Future<void> clearCache();
}

class OrdersLocalDataSourceImpl implements OrdersLocalDataSource {
  List<OrderModel>? _cachedOrders;
  final Map<int, OrderModel> _cachedOrderDetails = {};

  @override
  Future<void> cacheOrders(List<OrderModel> orders) async {
    _cachedOrders = orders;
  }

  @override
  List<OrderModel>? getCachedOrders() {
    return _cachedOrders;
  }

  @override
  Future<void> cacheOrder(OrderModel order) async {
    _cachedOrderDetails[order.id] = order;
  }

  @override
  OrderModel? getCachedOrder(int orderId) {
    return _cachedOrderDetails[orderId];
  }

  @override
  Future<void> clearCache() async {
    _cachedOrders = null;
    _cachedOrderDetails.clear();
  }
}
