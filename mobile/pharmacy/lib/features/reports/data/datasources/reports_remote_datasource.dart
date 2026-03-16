import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';

/// Source de données pour les rapports et analytics
abstract class ReportsRemoteDataSource {
  /// Récupère la vue d'ensemble du tableau de bord
  Future<Map<String, dynamic>> getOverview({String period = 'week'});
  
  /// Récupère le rapport des ventes
  Future<Map<String, dynamic>> getSalesReport({String period = 'week'});
  
  /// Récupère le rapport des commandes
  Future<Map<String, dynamic>> getOrdersReport({String period = 'week'});
  
  /// Récupère le rapport d'inventaire
  Future<Map<String, dynamic>> getInventoryReport();
  
  /// Récupère les alertes de stock
  Future<Map<String, dynamic>> getStockAlerts();
  
  /// Exporte un rapport
  Future<Map<String, dynamic>> exportReport({
    required String type,
    String format = 'json',
    String period = 'month',
  });
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final ApiClient _apiClient;

  ReportsRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Map<String, dynamic>> getOverview({String period = 'week'}) async {
    final response = await _apiClient.get(
      '/pharmacy/reports/overview',
      queryParameters: {'period': period},
    );
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> getSalesReport({String period = 'week'}) async {
    final response = await _apiClient.get(
      '/pharmacy/reports/sales',
      queryParameters: {'period': period},
    );
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> getOrdersReport({String period = 'week'}) async {
    final response = await _apiClient.get(
      '/pharmacy/reports/orders',
      queryParameters: {'period': period},
    );
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> getInventoryReport() async {
    final response = await _apiClient.get('/pharmacy/reports/inventory');
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> getStockAlerts() async {
    final response = await _apiClient.get('/pharmacy/reports/stock-alerts');
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> exportReport({
    required String type,
    String format = 'json',
    String period = 'month',
  }) async {
    final response = await _apiClient.get(
      '/pharmacy/reports/export',
      queryParameters: {
        'type': type,
        'format': format,
        'period': period,
      },
    );
    return _extractData(response.data);
  }

  /// Extrait les données de la réponse API
  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw Exception('Format de réponse invalide');
    }
    
    if (responseData['success'] == true && responseData['data'] != null) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    
    throw Exception(
      responseData['message']?.toString() ?? 
      responseData['error']?.toString() ?? 
      'Erreur lors du chargement'
    );
  }
}

/// Provider pour la datasource des rapports
final reportsRemoteDataSourceProvider = Provider<ReportsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportsRemoteDataSourceImpl(apiClient);
});
