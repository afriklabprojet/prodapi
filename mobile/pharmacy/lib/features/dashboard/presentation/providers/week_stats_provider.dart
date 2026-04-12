import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';

/// Statistiques hebdomadaires retournées par GET /pharmacy/stats/week.
class WeekStatsData {
  final int thisWeekOrders;
  final int lastWeekOrders;
  final int? trendPercent;
  final String? peakDayLabel;
  final int criticalProductsCount;
  final int expiringProductsCount;
  final int expiredProductsCount;

  const WeekStatsData({
    required this.thisWeekOrders,
    required this.lastWeekOrders,
    required this.trendPercent,
    required this.peakDayLabel,
    required this.criticalProductsCount,
    required this.expiringProductsCount,
    required this.expiredProductsCount,
  });

  factory WeekStatsData.fromJson(Map<String, dynamic> json) {
    return WeekStatsData(
      thisWeekOrders: (json['this_week_orders'] as num?)?.toInt() ?? 0,
      lastWeekOrders: (json['last_week_orders'] as num?)?.toInt() ?? 0,
      trendPercent: (json['trend_percent'] as num?)?.toInt(),
      peakDayLabel: json['peak_day_label'] as String?,
      criticalProductsCount:
          (json['critical_products_count'] as num?)?.toInt() ?? 0,
      expiringProductsCount:
          (json['expiring_products_count'] as num?)?.toInt() ?? 0,
      expiredProductsCount:
          (json['expired_products_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// FutureProvider qui interroge l'API pour les stats de la semaine.
/// Rafraîchi automatiquement à chaque réouverture de l'écran (autoDispose).
final weekStatsProvider =
    FutureProvider.autoDispose<WeekStatsData>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get('/pharmacy/stats/week');
    final data = response.data as Map<String, dynamic>;
    return WeekStatsData.fromJson(data);
  } catch (e, st) {
    debugPrint('⚠️ [weekStatsProvider] Failed to load weekly stats: $e');
    debugPrintStack(stackTrace: st, label: 'weekStatsProvider');
    // Retourner des données vides plutôt que crasher le dashboard
    return const WeekStatsData(
      thisWeekOrders: 0,
      lastWeekOrders: 0,
      trendPercent: null,
      peakDayLabel: null,
      criticalProductsCount: 0,
      expiringProductsCount: 0,
      expiredProductsCount: 0,
    );
  }
});
