import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/reports_entity.dart';

/// Interface abstraite du repository de rapports
abstract class ReportsRepositoryInterface {
  /// Récupère le résumé du tableau de bord
  Future<Either<Failure, DashboardOverview>> getOverview({String period = 'week'});
  
  /// Récupère le rapport de ventes
  Future<Either<Failure, SalesReport>> getSalesReport({String period = 'week'});
  
  /// Récupère le rapport de commandes
  Future<Either<Failure, Map<String, dynamic>>> getOrdersReport({String period = 'week'});
  
  /// Récupère le rapport d'inventaire
  Future<Either<Failure, Map<String, dynamic>>> getInventoryReport();
  
  /// Récupère les alertes de stock
  Future<Either<Failure, List<StockAlert>>> getStockAlerts();
}
