import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_logger.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

class OrdersRemoteDataSource {
  final ApiClient apiClient;

  OrdersRemoteDataSource(this.apiClient);

  /// Get all orders for the current user
  Future<List<OrderModel>> getOrders({
    String? status,
    int page = 1,
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await apiClient.get(
      ApiConstants.orders,
      queryParameters: queryParams,
    );

    final rawData = response.data['data'];
    if (rawData == null || rawData is! List) return [];
    return rawData
        .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get order details by ID
  Future<OrderModel> getOrderDetails(int orderId) async {
    AppLogger.debug('[GetOrderDetails] Fetching order $orderId');
    final response = await apiClient.get(ApiConstants.orderDetails(orderId));
    final rawData = response.data['data'];
    if (rawData == null || rawData is! Map<String, dynamic>) {
      throw Exception('Réponse invalide du serveur');
    }
    AppLogger.debug('[GetOrderDetails] Order loaded successfully');
    return OrderModel.fromJson(rawData);
  }

  /// Create a new order
  Future<OrderModel> createOrder({
    required int pharmacyId,
    required List<OrderItemModel> items,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMode,
    String? prescriptionImage,
    String? customerNotes,
    int? prescriptionId, // ID de la prescription uploadée via checkout
    String? promoCode,
  }) async {
    // Ensure customer_phone is present (required by API)
    // toJson() uses 'customer_phone' key, but also check 'phone' for safety
    final customerPhone = (deliveryAddress['customer_phone'] ?? deliveryAddress['phone']) as String?;
    if (customerPhone == null || customerPhone.isEmpty) {
      throw ValidationException(
        errors: {'customer_phone': ['Le numéro de téléphone est requis']},
      );
    }

    final data = {
      'pharmacy_id': pharmacyId,
      'items': items.map((item) => item.toJson()).toList(),
      // toJson() outputs 'delivery_address', fallback to 'address'
      'delivery_address': deliveryAddress['delivery_address'] ?? deliveryAddress['address'],
      'customer_phone': customerPhone,
      if ((deliveryAddress['delivery_city'] ?? deliveryAddress['city']) != null)
        'delivery_city': deliveryAddress['delivery_city'] ?? deliveryAddress['city'],
      if ((deliveryAddress['delivery_latitude'] ?? deliveryAddress['latitude']) != null)
        'delivery_latitude': deliveryAddress['delivery_latitude'] ?? deliveryAddress['latitude'],
      if ((deliveryAddress['delivery_longitude'] ?? deliveryAddress['longitude']) != null)
        'delivery_longitude': deliveryAddress['delivery_longitude'] ?? deliveryAddress['longitude'],
      'payment_mode': paymentMode,
      if (prescriptionImage != null) 'prescription_image': prescriptionImage,
      if (prescriptionId != null) 'prescription_id': prescriptionId,
      if (customerNotes != null) 'customer_notes': customerNotes,
      if (promoCode != null) 'promo_code': promoCode,
    };

    AppLogger.debug('[CreateOrder] Creating order for pharmacy $pharmacyId with ${items.length} items');
    AppLogger.debug('[CreateOrder] Request data: pharmacy=$pharmacyId, items=${items.length}, payment=$paymentMode');
    final response = await apiClient.post(ApiConstants.orders, data: data);

    // API returns simplified response on creation
    final rawResponseData = response.data['data'];
    if (rawResponseData == null || rawResponseData is! Map<String, dynamic>) {
      AppLogger.error('[CreateOrder] Invalid response from server: ${response.data}');
      throw Exception('Réponse invalide du serveur lors de la création');
    }
    
    // Safe extraction of order_id (may come as int or String)
    final rawOrderId = rawResponseData['order_id'];
    final int orderId;
    if (rawOrderId is int) {
      orderId = rawOrderId;
    } else if (rawOrderId is num) {
      orderId = rawOrderId.toInt();
    } else if (rawOrderId is String) {
      orderId = int.tryParse(rawOrderId) ?? 0;
    } else {
      AppLogger.error('[CreateOrder] Invalid order_id type: ${rawOrderId.runtimeType} = $rawOrderId');
      throw Exception('Identifiant de commande invalide');
    }
    AppLogger.info('[CreateOrder] Order created successfully with ID: $orderId');

    // Fetch full order details — if this fails, build a minimal order from the store response
    try {
      return await getOrderDetails(orderId);
    } catch (e) {
      AppLogger.warning('[CreateOrder] Failed to fetch order details after creation, building minimal order', error: e);
      
      // Build a minimal OrderModel from the store response data
      return OrderModel(
        id: orderId,
        reference: rawResponseData['reference']?.toString() ?? '',
        status: rawResponseData['status']?.toString() ?? 'pending',
        paymentMode: paymentMode,
        totalAmount: _safeToDouble(rawResponseData['total_amount']),
        deliveryAddress: deliveryAddress['address']?.toString() ?? '',
        deliveryCode: rawResponseData['delivery_code']?.toString(),
        createdAt: DateTime.now().toIso8601String(),
        items: items.map((item) => OrderItemModel(
          productId: item.productId,
          name: item.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          totalPrice: item.totalPrice,
        )).toList(),
        customerPhone: customerPhone,
      );
    }
  }

  /// Safely convert dynamic value to double
  static double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Cancel an order
  Future<void> cancelOrder(int orderId, String reason) async {
    await apiClient.post(
      ApiConstants.cancelOrder(orderId),
      data: {'reason': reason},
    );
  }

  /// Initiate payment for an order
  Future<Map<String, dynamic>> initiatePayment({
    required int orderId,
    required String provider,
    String? paymentMethod,
  }) async {
    final response = await apiClient.post(
      ApiConstants.paymentInitiate, // /customer/payments/initiate
      data: {
        'type': 'order',
        'order_id': orderId,
        if (paymentMethod != null) 'payment_method': paymentMethod,
      },
    );

    final rawPaymentData = response.data['data'];
    if (rawPaymentData == null || rawPaymentData is! Map<String, dynamic>) {
      throw Exception('Réponse paiement invalide');
    }

    // Map redirect_url → payment_url for downstream compatibility
    if (rawPaymentData.containsKey('redirect_url') &&
        !rawPaymentData.containsKey('payment_url')) {
      rawPaymentData['payment_url'] = rawPaymentData['redirect_url'];
    }

    return rawPaymentData;
  }

  /// Get tracking info manually (returns raw json for delivery part)
  Future<Map<String, dynamic>?> getTrackingInfo(int orderId) async {
    final response = await apiClient.get(ApiConstants.orderDetails(orderId));
    final rawData = response.data['data'];
    if (rawData == null || rawData is! Map<String, dynamic>) return null;
    final data = rawData;
    if (data['delivery'] != null) {
      return data['delivery'] as Map<String, dynamic>;
    }
    return null;
  }
}
