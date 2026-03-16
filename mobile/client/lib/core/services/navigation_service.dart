import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

      default:
        await navigateToNotifications();
    }
  }
}
