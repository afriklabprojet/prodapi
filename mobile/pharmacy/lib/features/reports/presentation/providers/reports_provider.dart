import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reports_repository.dart';
import '../../domain/entities/reports_entity.dart';

/// State pour les rapports avec domain entities
class ReportsState {
  final bool isLoading;
  final String? error;
  final String selectedPeriod;
  final DashboardOverview? overview;
  final SalesReport? salesReport;
  final Map<String, dynamic>? orders;
  final Map<String, dynamic>? inventory;
  final List<StockAlert>? stockAlerts;

  const ReportsState({
    this.isLoading = false,
    this.error,
    this.selectedPeriod = 'week',
    this.overview,
    this.salesReport,
    this.orders,
    this.inventory,
    this.stockAlerts,
  });

  ReportsState copyWith({
    bool? isLoading,
    String? error,
    String? selectedPeriod,
    DashboardOverview? overview,
    SalesReport? salesReport,
    Map<String, dynamic>? orders,
    Map<String, dynamic>? inventory,
    List<StockAlert>? stockAlerts,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      overview: overview ?? this.overview,
      salesReport: salesReport ?? this.salesReport,
      orders: orders ?? this.orders,
      inventory: inventory ?? this.inventory,
      stockAlerts: stockAlerts ?? this.stockAlerts,
    );
  }
}

/// Notifier pour gérer l'état des rapports
class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsRepositoryImpl _repository;

  ReportsNotifier(this._repository) : super(const ReportsState());

  /// Load all dashboard data
  Future<void> loadDashboard({String? period}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final selectedPeriod = period ?? state.selectedPeriod;
    
    final result = await _repository.getOverview(period: selectedPeriod);
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (overview) => state = state.copyWith(
        isLoading: false,
        selectedPeriod: selectedPeriod,
        overview: overview,
      ),
    );
  }

  /// Load sales data
  Future<void> loadSales({String? period}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final selectedPeriod = period ?? state.selectedPeriod;
    final result = await _repository.getSalesReport(period: selectedPeriod);
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (salesReport) => state = state.copyWith(
        isLoading: false,
        selectedPeriod: selectedPeriod,
        salesReport: salesReport,
      ),
    );
  }

  /// Load orders data
  Future<void> loadOrders({String? period}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final selectedPeriod = period ?? state.selectedPeriod;
    final result = await _repository.getOrdersReport(period: selectedPeriod);
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (orders) => state = state.copyWith(
        isLoading: false,
        selectedPeriod: selectedPeriod,
        orders: orders,
      ),
    );
  }

  /// Load inventory data
  Future<void> loadInventory() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.getInventoryReport();
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (inventory) => state = state.copyWith(
        isLoading: false,
        inventory: inventory,
      ),
    );
  }

  /// Load stock alerts
  Future<void> loadStockAlerts() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.getStockAlerts();
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (alerts) => state = state.copyWith(
        isLoading: false,
        stockAlerts: alerts,
      ),
    );
  }

  /// Change selected period
  void setPeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
  }

  /// Export report
  Future<Map<String, dynamic>?> exportReport({
    required String type,
    String format = 'json',
  }) async {
    final result = await _repository.exportReport(
      type: type,
      format: format,
      period: state.selectedPeriod,
    );
    
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return null;
      },
      (data) => data,
    );
  }
}

/// Provider principal pour les rapports
final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final repository = ref.watch(reportsRepositoryProvider);
  return ReportsNotifier(repository);
});

/// Provider pour les alertes de stock uniquement
final stockAlertsProvider = FutureProvider<List<StockAlert>>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final result = await repository.getStockAlerts();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (alerts) => alerts,
  );
});
