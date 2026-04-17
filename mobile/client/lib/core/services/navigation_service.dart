import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/chat/presentation/pages/chat_page.dart';

/// Global navigation key for accessing navigation from anywhere
/// Including background notification handlers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Navigation service for handling deep links and notification navigation
class NavigationService {
  /// Navigate to order details
  static Future<void> navigateToOrderDetails(int orderId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    context.push('/orders/$orderId');
  }

  /// Navigate to order tracking
  static Future<void> navigateToOrderTracking(int orderId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    context.push('/orders/$orderId/tracking');
  }

  /// Navigate to orders list
  static Future<void> navigateToOrdersList() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    context.push('/orders');
  }

  /// Navigate to notifications
  static Future<void> navigateToNotifications() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    context.push('/notifications');
  }

  /// Navigate to courier/pharmacy chat from a notification
  static Future<void> navigateToCourierChat({
    required int orderId,
    required int deliveryId,
    required int participantId,
    required String participantName,
    required String participantType,
    String? participantPhone,
  }) async {
    // Utilise currentState.push() car navigatorKey EST le Navigator GoRouter,
    // et Navigator.of(navigatorKey.currentContext) chercherait un parent qui n'existe pas.
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          orderId: orderId,
          deliveryId: deliveryId,
          participantId: participantId,
          participantName: participantName,
          participantType: participantType,
          participantPhone: participantPhone,
        ),
      ),
    );
  }

  /// Handle notification tap based on type
  static Future<void> handleNotificationTap({
    required String? type,
    required Map<String, dynamic> data,
  }) async {
    if (type == null) return;

    switch (type) {
      case 'delivery_assigned':
      case 'in_delivery':
        // Delivery-related → go to live tracking
        final orderId = data['order_id'];
        if (orderId != null) {
          await navigateToOrderTracking(
            orderId is int ? orderId : int.parse(orderId.toString()),
          );
        }
        break;

      case 'order_status':
      case 'payment_confirmed':
      case 'order_delivered':
        final orderId = data['order_id'];
        if (orderId != null) {
          await navigateToOrderDetails(
            orderId is int ? orderId : int.parse(orderId.toString()),
          );
        }
        break;

      case 'new_order':
        await navigateToOrdersList();
        break;

      case 'chat_message':
        final orderId = data['order_id'];
        final deliveryId = data['delivery_id'];
        final senderType = data['sender_type'] as String? ?? 'courier';
        final senderName = data['sender_name'] as String? ?? 'Livreur';
        if (orderId != null && deliveryId != null) {
          await navigateToCourierChat(
            orderId: orderId is int ? orderId : int.parse(orderId.toString()),
            deliveryId: deliveryId is int ? deliveryId : int.parse(deliveryId.toString()),
            participantId: 0,
            participantName: senderName,
            participantType: senderType,
          );
        } else if (orderId != null) {
          await navigateToOrderDetails(
            orderId is int ? orderId : int.parse(orderId.toString()),
          );
        }
        break;

      default:
        await navigateToNotifications();
    }
  }
}
