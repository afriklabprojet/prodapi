import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/error_display.dart';
import '../../../../core/presentation/widgets/skeleton_screens.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/reports_provider.dart';
import 'reports_tabs.dart';
import 'reports_ui_components.dart';

export 'reports_ui_components.dart' show safeInt, safeDouble;

/// Page du tableau de bord des rapports et analytics
class ReportsDashboardPage extends ConsumerStatefulWidget {
  const ReportsDashboardPage({super.key});

  @override
  ConsumerState<ReportsDashboardPage> createState() =>
      _ReportsDashboardPageState();
}

class _ReportsDashboardPageState extends ConsumerState<ReportsDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await ref
        .read(reportsProvider.notifier)
        .loadDashboard(period: _selectedPeriod);
    await ref.read(reportsProvider.notifier).loadSales(period: _selectedPeriod);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);

    final salesData = _buildSalesData(reportsState);
    final ordersData = _buildOrdersData(reportsState);
    final inventoryData = _buildInventoryData(reportsState);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).reportsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportReport,
            tooltip: AppLocalizations.of(context).exportButton,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadData();
            },
            tooltip: AppLocalizations.of(context).refreshButton,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: AppLocalizations.of(context).overviewTab),
            Tab(text: AppLocalizations.of(context).salesTab),
            Tab(text: AppLocalizations.of(context).ordersTab),
            Tab(text: AppLocalizations.of(context).inventoryTab),
          ],
        ),
      ),
      body: reportsState.isLoading
          ? const DashboardStatsSkeleton()
          : reportsState.error != null
          ? _buildErrorView(reportsState.error!)
          : TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(
                  salesData: salesData,
                  ordersData: ordersData,
                  inventoryData: inventoryData,
                  selectedPeriod: _selectedPeriod,
                  salesReport: reportsState.salesReport,
                  onRefresh: _loadData,
                  onPeriodChanged: (period) {
                    setState(() => _selectedPeriod = period);
                    ref
                        .read(reportsProvider.notifier)
                        .loadDashboard(period: period);
                    ref
                        .read(reportsProvider.notifier)
                        .loadSales(period: period);
                  },
                ),
                SalesTab(
                  salesData: salesData,
                  dailyBreakdown: reportsState.salesReport?.dailyBreakdown,
                  onRefresh: _loadData,
                ),
                OrdersTab(ordersData: ordersData, onRefresh: _loadData),
                InventoryTab(
                  inventoryData: inventoryData,
                  onRefresh: _loadData,
                ),
              ],
            ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).loadingError,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context).retryButton),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildSalesData(ReportsState state) {
    final overview = state.overview;
    if (overview != null && overview.sales != null) {
      final sales = overview.sales!;
      return {
        'today': sales.today,
        'yesterday': sales.yesterday,
        'week': sales.periodTotal,
        'month': sales.periodTotal,
        'growth': sales.growth,
      };
    }
    return {
      'today': 0.0,
      'yesterday': 0.0,
      'week': 0.0,
      'month': 0.0,
      'growth': 0.0,
    };
  }

  Map<String, dynamic> _buildOrdersData(ReportsState state) {
    final overview = state.overview;
    if (overview != null && overview.orders != null) {
      final orders = overview.orders!;
      return {
        'total': orders.total,
        'pending': orders.pending,
        'completed': orders.completed,
        'cancelled': orders.cancelled,
      };
    }
    return {'total': 0, 'pending': 0, 'completed': 0, 'cancelled': 0};
  }

  Map<String, dynamic> _buildInventoryData(ReportsState state) {
    final overview = state.overview;
    if (overview != null && overview.inventory != null) {
      final inventory = overview.inventory!;
      return {
        'totalProducts': inventory.totalProducts,
        'lowStock': inventory.lowStock,
        'expiringSoon': inventory.expiringSoon,
        'outOfStock': inventory.outOfStock,
      };
    }
    return {
      'totalProducts': 0,
      'lowStock': 0,
      'expiringSoon': 0,
      'outOfStock': 0,
    };
  }

  void _exportReport() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exporter le rapport',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ReportsExportOption(
              icon: Icons.picture_as_pdf,
              title: 'PDF',
              subtitle: 'Rapport complet en PDF',
              onTap: () => _doExport('pdf'),
            ),
            const SizedBox(height: 12),
            ReportsExportOption(
              icon: Icons.table_chart,
              title: 'Excel',
              subtitle: 'Données en format tableur',
              onTap: () => _doExport('excel'),
            ),
            const SizedBox(height: 12),
            ReportsExportOption(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'Envoyer par email',
              onTap: () => _doExport('email'),
            ),
          ],
        ),
      ),
    );
  }

  void _doExport(String format) async {
    Navigator.pop(context);
    ErrorSnackBar.showInfo(context, 'Export $format en cours...');

    try {
      final result = await ref
          .read(reportsProvider.notifier)
          .exportReport(type: 'sales', format: format);

      if (result != null && mounted) {
        ErrorSnackBar.showSuccess(context, 'Export généré avec succès !');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.showError(context, 'Erreur lors de l\'export : $e');
      }
    }
  }
}
