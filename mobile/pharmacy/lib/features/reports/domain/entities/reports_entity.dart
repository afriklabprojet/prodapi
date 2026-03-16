/// Entités pour les rapports et analytics
library;

/// Résumé du tableau de bord
class DashboardOverview {
  final String period;
  final DateRange? dateRange;
  final SalesMetrics? sales;
  final OrdersMetrics? orders;
  final InventoryMetrics? inventory;

  const DashboardOverview({
    required this.period,
    this.dateRange,
    this.sales,
    this.orders,
    this.inventory,
  });
}

/// Plage de dates
class DateRange {
  final DateTime from;
  final DateTime to;

  const DateRange({required this.from, required this.to});
}

/// Métriques de ventes
class SalesMetrics {
  final double today;
  final double yesterday;
  final double periodTotal;
  final double growth;

  const SalesMetrics({
    required this.today,
    required this.yesterday,
    required this.periodTotal,
    required this.growth,
  });

  /// Croissance positive ?
  bool get isGrowthPositive => growth > 0;

  /// Pourcentage de croissance formaté
  String get growthFormatted => '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%';
}

/// Métriques de commandes
class OrdersMetrics {
  final int total;
  final int pending;
  final int completed;
  final int cancelled;

  const OrdersMetrics({
    required this.total,
    required this.pending,
    required this.completed,
    required this.cancelled,
  });

  /// Taux de complétion
  double get completionRate => total > 0 ? (completed / total) * 100 : 0;
}

/// Métriques d'inventaire
class InventoryMetrics {
  final int totalProducts;
  final int lowStock;
  final int outOfStock;
  final int expiringSoon;

  const InventoryMetrics({
    required this.totalProducts,
    required this.lowStock,
    required this.outOfStock,
    required this.expiringSoon,
  });

  /// Nombre de produits nécessitant attention
  int get alertCount => lowStock + outOfStock + expiringSoon;

  /// Y a-t-il des alertes critiques ?
  bool get hasCriticalAlerts => outOfStock > 0 || expiringSoon > 0;
}

/// Rapport de ventes détaillé
class SalesReport {
  final double totalRevenue;
  final double averageOrderValue;
  final int totalOrders;
  final List<DailySales> dailyBreakdown;
  final List<TopProduct> topProducts;

  const SalesReport({
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.totalOrders,
    this.dailyBreakdown = const [],
    this.topProducts = const [],
  });
}

/// Ventes journalières
class DailySales {
  final DateTime date;
  final double amount;
  final int orderCount;

  const DailySales({
    required this.date,
    required this.amount,
    required this.orderCount,
  });
}

/// Produit le plus vendu
class TopProduct {
  final int productId;
  final String name;
  final int quantitySold;
  final double revenue;

  const TopProduct({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });
}

/// Alerte de stock
class StockAlert {
  final int productId;
  final String productName;
  final StockAlertType type;
  final int currentQuantity;
  final int threshold;
  final DateTime? expiryDate;

  const StockAlert({
    required this.productId,
    required this.productName,
    required this.type,
    required this.currentQuantity,
    this.threshold = 0,
    this.expiryDate,
  });
}

/// Type d'alerte de stock
enum StockAlertType {
  outOfStock,
  lowStock,
  expiringSoon,
}
