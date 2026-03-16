import '../../../../core/network/api_client.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getOrders({String? status});
  Future<OrderModel> getOrderDetails(int id);
  Future<void> confirmOrder(int id);
  Future<void> markOrderReady(int id);
  Future<void> markOrderDelivered(int id);
  Future<void> rejectOrder(int id, {String? reason});
  Future<void> addNotes(int id, String notes);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient apiClient;

  OrderRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<OrderModel>> getOrders({String? status}) async {
    final response = await apiClient.get(
      '/pharmacy/orders',
      queryParameters: status != null ? {'status': status} : null,
      // Token is injected automatically by the ApiClient interceptor
    );

    return (response.data['data'] as List)
        .map((e) => OrderModel.fromJson(e))
        .toList();
  }

  @override
  Future<OrderModel> getOrderDetails(int id) async {
    final response = await apiClient.get(
      '/pharmacy/orders/$id',
    );

    return OrderModel.fromJson(response.data['data']);
  }

  @override
  Future<void> confirmOrder(int id) async {
    await apiClient.post('/pharmacy/orders/$id/confirm');
  }

  @override
  Future<void> markOrderReady(int id) async {
    await apiClient.post('/pharmacy/orders/$id/ready');
  }

  @override
  Future<void> markOrderDelivered(int id) async {
    await apiClient.post('/pharmacy/orders/$id/delivered');
  }

  @override
  Future<void> rejectOrder(int id, {String? reason}) async {
    await apiClient.post(
      '/pharmacy/orders/$id/reject',
      data: reason != null ? {'reason': reason} : null,
    );
  }

  @override
  Future<void> addNotes(int id, String notes) async {
    await apiClient.post(
      '/pharmacy/orders/$id/notes',
      data: {'notes': notes},
    );
  }
}
