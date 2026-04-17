import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/order_entity.dart';
import '../entities/order_item_entity.dart';
import '../entities/delivery_address_entity.dart';

abstract class OrdersRepository {
  /// Get all orders for the current user
  Future<Either<Failure, List<OrderEntity>>> getOrders({
    String? status,
    int page = 1,
    int perPage = 20,
  });

  /// Get order details by ID
  Future<Either<Failure, OrderEntity>> getOrderDetails(int orderId);

  /// Create a new order
  Future<Either<Failure, OrderEntity>> createOrder({
    required int pharmacyId,
    required List<OrderItemEntity> items,
    required DeliveryAddressEntity deliveryAddress,
    required String paymentMode,
    String? prescriptionImage,
    String? customerNotes,
    int? prescriptionId, // ID de la prescription uploadée via checkout
    String? promoCode,
  });

  /// Cancel an order
  Future<Either<Failure, void>> cancelOrder(int orderId, String reason);

  /// Initiate payment for an order
  Future<Either<Failure, Map<String, dynamic>>> initiatePayment({
    required int orderId,
    required String provider,
    String? paymentMethod,
  });

  /// Get tracking info (courier location etc)
  Future<Map<String, dynamic>?> getTrackingInfo(int orderId);
}
