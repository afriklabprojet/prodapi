import '../../../../core/network/api_client.dart';
import '../models/order_model.dart';

/// Réponse paginée des commandes (supporte cursor et offset pagination)
class PaginatedOrdersResponse {
  final List<OrderModel> orders;
  final int perPage;
  final int total;

  /// Curseur pour la page suivante (null = pas de page suivante)
  /// Compatible avec cursor-based et offset-based pagination
  final String? nextCursor;

  /// Indique s'il y a plus de données
  final bool hasMore;

  PaginatedOrdersResponse({
    required this.orders,
    required this.perPage,
    required this.total,
    this.nextCursor,
    required this.hasMore,
  });
}

abstract class OrderRemoteDataSource {
  /// Récupère les commandes avec pagination cursor-based
  /// [cursor] - cursor pour la page suivante (null pour la première page)
  Future<PaginatedOrdersResponse> getOrders({
    String? status,
    String? cursor,
    int perPage = 20,
  });
  Future<OrderModel> getOrderDetails(int id);
  Future<void> confirmOrder(int id);
  Future<void> markOrderReady(int id);
  Future<void> markOrderDelivered(int id);
  Future<void> rejectOrder(int id, {String? reason});
  Future<void> addNotes(int id, String notes);
  Future<void> rateCourier(
    int orderId, {
    required int rating,
    String? comment,
    List<String>? tags,
  });
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient apiClient;

  OrderRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PaginatedOrdersResponse> getOrders({
    String? status,
    String? cursor,
    int perPage = 20,
  }) async {
    final queryParams = <String, dynamic>{'per_page': perPage};

    // Support both cursor-based and offset-based pagination
    if (cursor != null) {
      // Si le cursor est un nombre, c'est un fallback offset
      final pageNumber = int.tryParse(cursor);
      if (pageNumber != null) {
        queryParams['page'] = pageNumber;
      } else {
        // Vrai cursor-based pagination
        queryParams['cursor'] = cursor;
      }
    }

    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await apiClient.get(
      '/pharmacy/orders',
      queryParameters: queryParams,
    );

    final data = response.data;
    final meta = data['meta'] ?? {};

    final orders = _extractList(
      data,
    ).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();

    // Support cursor-based pagination (Laravel: next_cursor)
    String? nextCursor = meta['next_cursor'] as String?;
    bool hasMore = false;

    // Fallback to offset-based pagination if cursor not available
    if (nextCursor == null && meta['current_page'] != null) {
      final currentPage = meta['current_page'] as int? ?? 1;
      final lastPage = meta['last_page'] as int? ?? 1;
      hasMore = currentPage < lastPage;
      if (hasMore) {
        nextCursor = '${currentPage + 1}';
      }
    } else {
      hasMore = nextCursor != null;
    }

    return PaginatedOrdersResponse(
      orders: orders,
      perPage: meta['per_page'] ?? perPage,
      total: meta['total'] ?? orders.length,
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }

  /// Extract a List from various API response shapes.
  static List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data['data'];
      if (inner is List) return inner;
      if (inner is Map && inner['data'] is List) return inner['data'] as List;
    }
    return [];
  }

  @override
  Future<OrderModel> getOrderDetails(int id) async {
    final response = await apiClient.get('/pharmacy/orders/$id');

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
    await apiClient.post('/pharmacy/orders/$id/notes', data: {'notes': notes});
  }

  @override
  Future<void> rateCourier(
    int orderId, {
    required int rating,
    String? comment,
    List<String>? tags,
  }) async {
    await apiClient.post(
      '/pharmacy/orders/$orderId/rate-courier',
      data: {
        'rating': rating,
        if (comment != null) 'comment': comment,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      },
    );
  }
}
