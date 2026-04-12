import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../orders/presentation/providers/order_list_provider.dart';

/// Statistiques de performance quotidienne.
class DailyPerformance {
  final int ordersToday;
  final int ordersYesterday;
  final double revenueToday;
  final double revenueYesterday;
  final int prescriptionsToday;
  final int prescriptionsYesterday;
  final int dailyGoal;

  const DailyPerformance({
    required this.ordersToday,
    required this.ordersYesterday,
    required this.revenueToday,
    required this.revenueYesterday,
    required this.prescriptionsToday,
    required this.prescriptionsYesterday,
    this.dailyGoal = 20,
  });

  /// Différence commandes vs hier
  int get ordersDiff => ordersToday - ordersYesterday;
  
  /// Différence revenus vs hier
  double get revenueDiff => revenueToday - revenueYesterday;
  
  /// Pourcentage de progression vers l'objectif
  double get goalProgress => (ordersToday / dailyGoal).clamp(0.0, 1.0);
  
  /// Tendance positive ou négative
  bool get isOrdersTrendUp => ordersDiff >= 0;
  bool get isRevenueTrendUp => revenueDiff >= 0;

  factory DailyPerformance.fromJson(Map<String, dynamic> json) {
    return DailyPerformance(
      ordersToday: (json['orders_today'] as num?)?.toInt() ?? 0,
      ordersYesterday: (json['orders_yesterday'] as num?)?.toInt() ?? 0,
      revenueToday: (json['revenue_today'] as num?)?.toDouble() ?? 0.0,
      revenueYesterday: (json['revenue_yesterday'] as num?)?.toDouble() ?? 0.0,
      prescriptionsToday: (json['prescriptions_today'] as num?)?.toInt() ?? 0,
      prescriptionsYesterday: (json['prescriptions_yesterday'] as num?)?.toInt() ?? 0,
      dailyGoal: (json['daily_goal'] as num?)?.toInt() ?? 20,
    );
  }
  
  /// Génère des données de fallback à partir des commandes locales.
  factory DailyPerformance.fromLocalOrders({
    required List orders,
    int dailyGoal = 20,
  }) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    int ordersToday = 0;
    int ordersYesterday = 0;
    double revenueToday = 0;
    double revenueYesterday = 0;
    
    for (final order in orders) {
      final createdAt = order.createdAt;
      final amount = order.totalAmount ?? 0.0;
      
      if (createdAt.year == now.year && 
          createdAt.month == now.month && 
          createdAt.day == now.day) {
        ordersToday++;
        revenueToday += amount;
      } else if (createdAt.year == yesterday.year && 
                 createdAt.month == yesterday.month && 
                 createdAt.day == yesterday.day) {
        ordersYesterday++;
        revenueYesterday += amount;
      }
    }
    
    return DailyPerformance(
      ordersToday: ordersToday,
      ordersYesterday: ordersYesterday,
      revenueToday: revenueToday,
      revenueYesterday: revenueYesterday,
      prescriptionsToday: 0,
      prescriptionsYesterday: 0,
      dailyGoal: dailyGoal,
    );
  }
}

/// Provider pour les stats quotidiennes.
/// Tente d'abord l'API, sinon calcule localement.
final dailyPerformanceProvider = FutureProvider.autoDispose<DailyPerformance>((ref) async {
  try {
    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.get('/pharmacy/stats/daily');
    final data = response.data as Map<String, dynamic>;
    return DailyPerformance.fromJson(data);
  } catch (_) {
    // Fallback: calculer à partir des commandes locales
    final orderState = ref.watch(orderListProvider);
    return DailyPerformance.fromLocalOrders(orders: orderState.orders);
  }
});
