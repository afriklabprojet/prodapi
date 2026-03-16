import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/error_display.dart';
import '../providers/reports_provider.dart';

/// Helper pour parser les valeurs numériques de façon sécurisée
int _safeInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is num) return value.toInt();
  return 0;
}

double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  if (value is num) return value.toDouble();
  return 0.0;
}

/// Page du tableau de bord des rapports et analytics
class ReportsDashboardPage extends ConsumerStatefulWidget {
  const ReportsDashboardPage({super.key});

  @override
  ConsumerState<ReportsDashboardPage> createState() => _ReportsDashboardPageState();
}

class _ReportsDashboardPageState extends ConsumerState<ReportsDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await ref.read(reportsProvider.notifier).loadDashboard(period: _selectedPeriod);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);
    
    // Build data from API or use defaults
    final salesData = _buildSalesData(reportsState);
    final ordersData = _buildOrdersData(reportsState);
    final inventoryData = _buildInventoryData(reportsState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportReport,
            tooltip: 'Exporter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Vue d\'ensemble'),
            Tab(text: 'Ventes'),
            Tab(text: 'Commandes'),
            Tab(text: 'Inventaire'),
          ],
        ),
      ),
      body: reportsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportsState.error != null
              ? _buildErrorView(reportsState.error!)
              : TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  salesData: salesData,
                  ordersData: ordersData,
                  inventoryData: inventoryData,
                  selectedPeriod: _selectedPeriod,
                  onPeriodChanged: (period) {
                    setState(() => _selectedPeriod = period);
                    ref.read(reportsProvider.notifier).loadDashboard(period: period);
                  },
                ),
                _SalesTab(salesData: salesData),
                _OrdersTab(ordersData: ordersData),
                _InventoryTab(inventoryData: inventoryData),
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
            'Erreur de chargement',
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
            label: const Text('Réessayer'),
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
    // Default values
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
    return {
      'total': 0,
      'pending': 0,
      'completed': 0,
      'cancelled': 0,
    };
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _ExportOption(
              icon: Icons.picture_as_pdf,
              title: 'PDF',
              subtitle: 'Rapport complet en PDF',
              onTap: () => _doExport('pdf'),
            ),
            const SizedBox(height: 12),
            _ExportOption(
              icon: Icons.table_chart,
              title: 'Excel',
              subtitle: 'Données en format tableur',
              onTap: () => _doExport('excel'),
            ),
            const SizedBox(height: 12),
            _ExportOption(
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
      // Call export API
      final result = await ref.read(reportsProvider.notifier).exportReport(
        type: 'sales',
        format: format,
      );
      
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

/// Option d'export
class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Tab Vue d'ensemble
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> salesData;
  final Map<String, dynamic> ordersData;
  final Map<String, dynamic> inventoryData;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const _OverviewTab({
    required this.salesData,
    required this.ordersData,
    required this.inventoryData,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur de période
          _PeriodSelector(
            selectedPeriod: selectedPeriod,
            onPeriodChanged: onPeriodChanged,
          ),
          const SizedBox(height: 20),

          // Cartes de métriques principales
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Chiffre d\'affaires',
                  value: '${(_safeDouble(salesData['week']) / 1000).toStringAsFixed(0)}K',
                  suffix: 'FCFA',
                  growth: _safeDouble(salesData['growth']),
                  icon: Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Commandes',
                  value: '${ordersData['total']}',
                  suffix: 'total',
                  growth: 8.3,
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Produits',
                  value: '${inventoryData['totalProducts']}',
                  suffix: 'en stock',
                  growth: -2.1,
                  icon: Icons.inventory_2_outlined,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Alertes',
                  value: '${_safeInt(inventoryData['lowStock']) + _safeInt(inventoryData['expiringSoon'])}',
                  suffix: 'actives',
                  growth: 0,
                  icon: Icons.warning_amber_outlined,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Graphique des ventes
          _ChartCard(
            title: 'Évolution des ventes',
            subtitle: 'Cette semaine',
            child: _SalesChart(),
          ),

          const SizedBox(height: 16),

          // Répartition des commandes
          _ChartCard(
            title: 'Statut des commandes',
            subtitle: 'Répartition',
            child: _OrdersStatusChart(data: ordersData),
          ),

          const SizedBox(height: 16),

          // Top produits
          _TopProductsCard(),
        ],
      ),
    );
  }
}

/// Sélecteur de période
class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PeriodChip(label: 'Aujourd\'hui', value: 'today', 
              isSelected: selectedPeriod == 'today', onTap: () => onPeriodChanged('today')),
          _PeriodChip(label: 'Cette semaine', value: 'week', 
              isSelected: selectedPeriod == 'week', onTap: () => onPeriodChanged('week')),
          _PeriodChip(label: 'Ce mois', value: 'month', 
              isSelected: selectedPeriod == 'month', onTap: () => onPeriodChanged('month')),
          _PeriodChip(label: 'Ce trimestre', value: 'quarter', 
              isSelected: selectedPeriod == 'quarter', onTap: () => onPeriodChanged('quarter')),
          _PeriodChip(label: 'Cette année', value: 'year', 
              isSelected: selectedPeriod == 'year', onTap: () => onPeriodChanged('year')),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Carte de métrique
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String suffix;
  final double growth;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.suffix,
    required this.growth,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = growth > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (growth != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      Text(
                        '${growth.abs()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            suffix,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de graphique
class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                onSelected: (value) {
                  if (value == 'export') {
                    // Export functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export en cours...')),
                    );
                  } else if (value == 'refresh') {
                    // Refresh data
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('Exporter'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18),
                        SizedBox(width: 8),
                        Text('Actualiser'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Graphique des ventes (simplifié)
class _SalesChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final values = [0.6, 0.8, 0.5, 0.9, 0.7, 1.0, 0.4];

    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300 + index * 50),
                width: 30,
                height: 100 * values[index],
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                days[index],
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Graphique de statut des commandes
class _OrdersStatusChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const _OrdersStatusChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = _safeDouble(data['total']);
    if (total == 0) {
      return const Center(child: Text('Aucune commande'));
    }
    final completed = _safeDouble(data['completed']) / total;
    final pending = _safeDouble(data['pending']) / total;
    final cancelled = _safeDouble(data['cancelled']) / total;

    return Row(
      children: [
        // Mini pie chart simulé
        SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: _PieChartPainter(
              values: [completed, pending, cancelled],
              colors: [Colors.green, Colors.orange, Colors.red],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              _LegendItem(
                color: Colors.green,
                label: 'Livrées',
                value: '${data['completed']}',
                percentage: (completed * 100).toStringAsFixed(0),
              ),
              const SizedBox(height: 8),
              _LegendItem(
                color: Colors.orange,
                label: 'En attente',
                value: '${data['pending']}',
                percentage: (pending * 100).toStringAsFixed(0),
              ),
              const SizedBox(height: 8),
              _LegendItem(
                color: Colors.red,
                label: 'Annulées',
                value: '${data['cancelled']}',
                percentage: (cancelled * 100).toStringAsFixed(0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(width: 4),
        Text(
          '($percentage%)',
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Pie chart painter
class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    double startAngle = -1.5708; // -90 degrees in radians

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = values[i] * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Top produits
class _TopProductsCard extends StatelessWidget {
  final _products = const [
    {'name': 'Doliprane 1000mg', 'sales': 245, 'revenue': 48500},
    {'name': 'Efferalgan 500mg', 'sales': 189, 'revenue': 37800},
    {'name': 'Spasfon Lyoc', 'sales': 156, 'revenue': 54600},
    {'name': 'Gaviscon Menthe', 'sales': 134, 'revenue': 40200},
    {'name': 'Smecta Orange', 'sales': 98, 'revenue': 19600},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5 Produits',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_products.length, (index) {
            final product = _products[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name']?.toString() ?? '',
                          style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
                        ),
                        Text(
                          '${product['sales']} ventes',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_safeInt(product['revenue']) ~/ 1000}K FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Tab Ventes
class _SalesTab extends StatelessWidget {
  final Map<String, dynamic> salesData;

  const _SalesTab({required this.salesData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _DetailCard(
            title: 'Aujourd\'hui',
            value: '${_safeDouble(salesData['today']) ~/ 1000}K FCFA',
            icon: Icons.today,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Hier',
            value: '${_safeDouble(salesData['yesterday']) ~/ 1000}K FCFA',
            icon: Icons.history,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Cette semaine',
            value: '${_safeDouble(salesData['week']) ~/ 1000}K FCFA',
            icon: Icons.date_range,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Ce mois',
            value: '${_safeDouble(salesData['month']) ~/ 1000000}M FCFA',
            icon: Icons.calendar_month,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          _ChartCard(
            title: 'Tendance mensuelle',
            subtitle: 'Comparaison avec le mois précédent',
            child: _SalesChart(),
          ),
        ],
      ),
    );
  }
}

/// Tab Commandes
class _OrdersTab extends StatelessWidget {
  final Map<String, dynamic> ordersData;

  const _OrdersTab({required this.ordersData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  title: 'Total',
                  value: '${ordersData['total']}',
                  icon: Icons.shopping_bag,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCard(
                  title: 'En attente',
                  value: '${ordersData['pending']}',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  title: 'Livrées',
                  value: '${ordersData['completed']}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCard(
                  title: 'Annulées',
                  value: '${ordersData['cancelled']}',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ChartCard(
            title: 'Répartition par statut',
            subtitle: 'Vue détaillée',
            child: _OrdersStatusChart(data: ordersData),
          ),
        ],
      ),
    );
  }
}

/// Tab Inventaire
class _InventoryTab extends StatelessWidget {
  final Map<String, dynamic> inventoryData;

  const _InventoryTab({required this.inventoryData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _DetailCard(
            title: 'Total produits',
            value: '${inventoryData['totalProducts']}',
            icon: Icons.inventory,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Stock faible',
            value: '${inventoryData['lowStock']}',
            icon: Icons.warning_amber,
            color: Colors.orange,
            urgent: true,
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Expiration proche',
            value: '${inventoryData['expiringSoon']}',
            icon: Icons.access_time,
            color: Colors.red,
            urgent: true,
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Rupture de stock',
            value: '${inventoryData['outOfStock']}',
            icon: Icons.remove_shopping_cart,
            color: Colors.red,
            urgent: true,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Conseil: Vérifiez régulièrement les alertes de stock pour éviter les ruptures.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de détail
class _DetailCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool urgent;

  const _DetailCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: urgent
            ? Border.all(color: color.withValues(alpha: 0.5), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (urgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Action requise',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
