import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/numeric_converters.dart';
import '../../domain/entities/reports_entity.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';

/// Normalise les données de l'overview pour éviter les erreurs de type
Map<String, dynamic> _normalizeOverviewData(Map<String, dynamic> data) {
  final sales = data['sales'] as Map<String, dynamic>?;
  final orders = data['orders'] as Map<String, dynamic>?;
  final inventory = data['inventory'] as Map<String, dynamic>?;
  
  return {
    'period': data['period']?.toString() ?? 'week',
    'date_range': data['date_range'],
    'sales': sales != null ? {
      'today': safeToDouble(sales['today']),
      'yesterday': safeToDouble(sales['yesterday']),
      'period_total': safeToDouble(sales['period_total']),
      'growth': safeToDouble(sales['growth']),
    } : null,
    'orders': orders != null ? {
      'total': safeToInt(orders['total']),
      'pending': safeToInt(orders['pending']),
      'completed': safeToInt(orders['completed']),
      'cancelled': safeToInt(orders['cancelled']),
    } : null,
    'inventory': inventory != null ? {
      'total_products': safeToInt(inventory['total_products']),
      'low_stock': safeToInt(inventory['low_stock']),
      'out_of_stock': safeToInt(inventory['out_of_stock']),
      'expiring_soon': safeToInt(inventory['expiring_soon']),
    } : null,
  };
}

/// Implémentation du repository des rapports
class ReportsRepositoryImpl implements ReportsRepositoryInterface {
  final ReportsRemoteDataSource _dataSource;
  
  ReportsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, DashboardOverview>> getOverview({String period = 'week'}) async {
    try {
      final data = await _dataSource.getOverview(period: period);
      final normalized = _normalizeOverviewData(data);
      return Right(_mapToDashboardOverview(normalized));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SalesReport>> getSalesReport({String period = 'week'}) async {
    try {
      final data = await _dataSource.getSalesReport(period: period);
      return Right(_mapToSalesReport(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getOrdersReport({String period = 'week'}) async {
    try {
      final data = await _dataSource.getOrdersReport(period: period);
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getInventoryReport() async {
    try {
      final data = await _dataSource.getInventoryReport();
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockAlert>>> getStockAlerts() async {
    try {
      final data = await _dataSource.getStockAlerts();
      final alerts = _mapToStockAlerts(data);
      return Right(alerts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Export a report
  Future<Either<Failure, Map<String, dynamic>>> exportReport({
    required String type,
    String format = 'json',
    String period = 'month',
  }) async {
    try {
      final data = await _dataSource.exportReport(
        type: type,
        format: format,
        period: period,
      );
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  DashboardOverview _mapToDashboardOverview(Map<String, dynamic> data) {
    final salesData = data['sales'] as Map<String, dynamic>?;
    final ordersData = data['orders'] as Map<String, dynamic>?;
    final inventoryData = data['inventory'] as Map<String, dynamic>?;

    return DashboardOverview(
      period: data['period']?.toString() ?? 'week',
      sales: salesData != null ? SalesMetrics(
        today: safeToDouble(salesData['today']),
        yesterday: safeToDouble(salesData['yesterday']),
        periodTotal: safeToDouble(salesData['period_total']),
        growth: safeToDouble(salesData['growth']),
      ) : null,
      orders: ordersData != null ? OrdersMetrics(
        total: safeToInt(ordersData['total']),
        pending: safeToInt(ordersData['pending']),
        completed: safeToInt(ordersData['completed']),
        cancelled: safeToInt(ordersData['cancelled']),
      ) : null,
      inventory: inventoryData != null ? InventoryMetrics(
        totalProducts: safeToInt(inventoryData['total_products']),
        lowStock: safeToInt(inventoryData['low_stock']),
        outOfStock: safeToInt(inventoryData['out_of_stock']),
        expiringSoon: safeToInt(inventoryData['expiring_soon']),
      ) : null,
    );
  }

  SalesReport _mapToSalesReport(Map<String, dynamic> data) {
    final dailyData = data['daily_breakdown'] as List? ?? [];
    final topProductsData = data['top_products'] as List? ?? [];

    return SalesReport(
      totalRevenue: safeToDouble(data['total_revenue']),
      averageOrderValue: safeToDouble(data['average_order_value']),
      totalOrders: safeToInt(data['total_orders']),
      dailyBreakdown: dailyData.map((d) => DailySales(
        date: DateTime.tryParse(d['date']?.toString() ?? '') ?? DateTime.now(),
        amount: safeToDouble(d['amount']),
        orderCount: safeToInt(d['order_count']),
      )).toList(),
      topProducts: topProductsData.map((p) => TopProduct(
        productId: safeToInt(p['product_id']),
        name: p['name']?.toString() ?? '',
        quantitySold: safeToInt(p['quantity_sold']),
        revenue: safeToDouble(p['revenue']),
      )).toList(),
    );
  }

  List<StockAlert> _mapToStockAlerts(Map<String, dynamic> data) {
    final alertsList = data['alerts'] as List? ?? [];
    return alertsList.map((a) {
      final type = a['type']?.toString();
      StockAlertType alertType;
      switch (type) {
        case 'out_of_stock':
          alertType = StockAlertType.outOfStock;
          break;
        case 'low_stock':
          alertType = StockAlertType.lowStock;
          break;
        case 'expiring_soon':
          alertType = StockAlertType.expiringSoon;
          break;
        default:
          alertType = StockAlertType.lowStock;
      }
      
      return StockAlert(
        productId: safeToInt(a['product_id']),
        productName: a['product_name']?.toString() ?? '',
        type: alertType,
        currentQuantity: safeToInt(a['current_quantity']),
        threshold: safeToInt(a['threshold']),
        expiryDate: a['expiry_date'] != null 
            ? DateTime.tryParse(a['expiry_date'].toString()) 
            : null,
      );
    }).toList();
  }
}

/// Provider pour le repository des rapports
final reportsRepositoryProvider = Provider<ReportsRepositoryImpl>((ref) {
  final dataSource = ref.watch(reportsRemoteDataSourceProvider);
  return ReportsRepositoryImpl(dataSource);
});
