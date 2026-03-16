import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/features/reports/domain/entities/reports_entity.dart';

void main() {
  group('DashboardOverview', () {
    test('should create DashboardOverview with all fields', () {
      const overview = DashboardOverview(
        period: 'week',
        sales: SalesMetrics(
          today: 50000,
          yesterday: 45000,
          periodTotal: 350000,
          growth: 11.1,
        ),
        orders: OrdersMetrics(
          total: 100,
          pending: 10,
          completed: 85,
          cancelled: 5,
        ),
        inventory: InventoryMetrics(
          totalProducts: 500,
          lowStock: 20,
          outOfStock: 5,
          expiringSoon: 10,
        ),
      );

      expect(overview.period, 'week');
      expect(overview.sales, isNotNull);
      expect(overview.orders, isNotNull);
      expect(overview.inventory, isNotNull);
    });
  });

  group('SalesMetrics', () {
    late SalesMetrics sales;

    setUp(() {
      sales = const SalesMetrics(
        today: 50000,
        yesterday: 45000,
        periodTotal: 350000,
        growth: 11.1,
      );
    });

    test('isGrowthPositive should return true for positive growth', () {
      expect(sales.isGrowthPositive, true);
    });

    test('isGrowthPositive should return false for negative growth', () {
      const negativeSales = SalesMetrics(
        today: 30000,
        yesterday: 45000,
        periodTotal: 200000,
        growth: -15.5,
      );
      expect(negativeSales.isGrowthPositive, false);
    });

    test('growthFormatted should include + for positive growth', () {
      expect(sales.growthFormatted, '+11.1%');
    });

    test('growthFormatted should format negative growth correctly', () {
      const negativeSales = SalesMetrics(
        today: 30000,
        yesterday: 45000,
        periodTotal: 200000,
        growth: -15.5,
      );
      expect(negativeSales.growthFormatted, '-15.5%');
    });
  });

  group('OrdersMetrics', () {
    late OrdersMetrics orders;

    setUp(() {
      orders = const OrdersMetrics(
        total: 100,
        pending: 10,
        completed: 85,
        cancelled: 5,
      );
    });

    test('completionRate should calculate correctly', () {
      expect(orders.completionRate, 85.0);
    });

    test('completionRate should return 0 when total is 0', () {
      const emptyOrders = OrdersMetrics(
        total: 0,
        pending: 0,
        completed: 0,
        cancelled: 0,
      );
      expect(emptyOrders.completionRate, 0);
    });
  });

  group('InventoryMetrics', () {
    late InventoryMetrics inventory;

    setUp(() {
      inventory = const InventoryMetrics(
        totalProducts: 500,
        lowStock: 20,
        outOfStock: 5,
        expiringSoon: 10,
      );
    });

    test('alertCount should sum all alert types', () {
      expect(inventory.alertCount, 35);
    });

    test('hasCriticalAlerts should return true when outOfStock > 0', () {
      expect(inventory.hasCriticalAlerts, true);
    });

    test('hasCriticalAlerts should return true when expiringSoon > 0', () {
      const expiringInventory = InventoryMetrics(
        totalProducts: 500,
        lowStock: 20,
        outOfStock: 0,
        expiringSoon: 10,
      );
      expect(expiringInventory.hasCriticalAlerts, true);
    });

    test('hasCriticalAlerts should return false when no critical alerts', () {
      const healthyInventory = InventoryMetrics(
        totalProducts: 500,
        lowStock: 20,
        outOfStock: 0,
        expiringSoon: 0,
      );
      expect(healthyInventory.hasCriticalAlerts, false);
    });
  });

  group('SalesReport', () {
    test('should create SalesReport with all fields', () {
      const report = SalesReport(
        totalRevenue: 1000000,
        averageOrderValue: 10000,
        totalOrders: 100,
        dailyBreakdown: [],
        topProducts: [],
      );

      expect(report.totalRevenue, 1000000);
      expect(report.averageOrderValue, 10000);
      expect(report.totalOrders, 100);
    });
  });

  group('DailySales', () {
    test('should create DailySales with all fields', () {
      final sales = DailySales(
        date: DateTime(2024, 3, 10),
        amount: 50000,
        orderCount: 10,
      );

      expect(sales.date, DateTime(2024, 3, 10));
      expect(sales.amount, 50000);
      expect(sales.orderCount, 10);
    });
  });

  group('TopProduct', () {
    test('should create TopProduct with all fields', () {
      const product = TopProduct(
        productId: 1,
        name: 'Doliprane 1000mg',
        quantitySold: 150,
        revenue: 75000,
      );

      expect(product.productId, 1);
      expect(product.name, 'Doliprane 1000mg');
      expect(product.quantitySold, 150);
      expect(product.revenue, 75000);
    });
  });

  group('StockAlert', () {
    test('should create StockAlert for out of stock', () {
      const alert = StockAlert(
        productId: 1,
        productName: 'Doliprane 1000mg',
        type: StockAlertType.outOfStock,
        currentQuantity: 0,
      );

      expect(alert.type, StockAlertType.outOfStock);
      expect(alert.currentQuantity, 0);
    });

    test('should create StockAlert for low stock', () {
      const alert = StockAlert(
        productId: 2,
        productName: 'Paracétamol 500mg',
        type: StockAlertType.lowStock,
        currentQuantity: 5,
        threshold: 10,
      );

      expect(alert.type, StockAlertType.lowStock);
      expect(alert.threshold, 10);
    });

    test('should create StockAlert for expiring soon', () {
      final alert = StockAlert(
        productId: 3,
        productName: 'Amoxicilline 500mg',
        type: StockAlertType.expiringSoon,
        currentQuantity: 50,
        expiryDate: DateTime(2024, 4, 10),
      );

      expect(alert.type, StockAlertType.expiringSoon);
      expect(alert.expiryDate, isNotNull);
    });
  });

  group('StockAlertType', () {
    test('should have all expected values', () {
      expect(StockAlertType.values.length, 3);
      expect(StockAlertType.values, contains(StockAlertType.outOfStock));
      expect(StockAlertType.values, contains(StockAlertType.lowStock));
      expect(StockAlertType.values, contains(StockAlertType.expiringSoon));
    });
  });
}
