import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Période de filtrage
enum HistoryPeriod {
  today,
  week,
  month,
  quarter,
  year,
  custom,
}

/// Type de graphique
enum ChartType {
  earnings,
  deliveries,
  distance,
  rating,
}

/// Filtre d'historique
class HistoryFilter {
  final HistoryPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> statuses;
  final double? minAmount;
  final double? maxAmount;
  final String? pharmacyId;
  final String? searchQuery;
  final bool sortDescending;
  final String sortBy;

  const HistoryFilter({
    this.period = HistoryPeriod.month,
    this.startDate,
    this.endDate,
    this.statuses = const [],
    this.minAmount,
    this.maxAmount,
    this.pharmacyId,
    this.searchQuery,
    this.sortDescending = true,
    this.sortBy = 'date',
  });

  HistoryFilter copyWith({
    HistoryPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? statuses,
    double? minAmount,
    double? maxAmount,
    String? pharmacyId,
    String? searchQuery,
    bool? sortDescending,
    String? sortBy,
  }) {
    return HistoryFilter(
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      statuses: statuses ?? this.statuses,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      searchQuery: searchQuery ?? this.searchQuery,
      sortDescending: sortDescending ?? this.sortDescending,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  DateTimeRange get dateRange {
    final now = DateTime.now();
    switch (period) {
      case HistoryPeriod.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case HistoryPeriod.week:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case HistoryPeriod.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, now.day),
          end: now,
        );
      case HistoryPeriod.quarter:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 3, now.day),
          end: now,
        );
      case HistoryPeriod.year:
        return DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );
      case HistoryPeriod.custom:
        return DateTimeRange(
          start: startDate ?? now.subtract(const Duration(days: 30)),
          end: endDate ?? now,
        );
    }
  }
}

/// Provider pour le filtre
final historyFilterProvider = StateProvider<HistoryFilter>((ref) {
  return const HistoryFilter();
});

/// Écran d'historique avancé
class AdvancedHistoryScreen extends ConsumerStatefulWidget {
  const AdvancedHistoryScreen({super.key});

  @override
  ConsumerState<AdvancedHistoryScreen> createState() => _AdvancedHistoryScreenState();
}

class _AdvancedHistoryScreenState extends ConsumerState<AdvancedHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  ChartType _selectedChart = ChartType.earnings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(historyFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Liste', icon: Icon(Icons.list)),
            Tab(text: 'Graphiques', icon: Icon(Icons.bar_chart)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),
          
          // Chips de période
          _buildPeriodChips(filter),
          
          // Résumé rapide
          _buildQuickStats(),
          
          // Contenu principal
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListView(),
                _buildChartsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher une livraison...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(historyFilterProvider.notifier).update(
                      (state) => state.copyWith(searchQuery: ''),
                    );
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        onChanged: (value) {
          ref.read(historyFilterProvider.notifier).update(
            (state) => state.copyWith(searchQuery: value),
          );
        },
      ),
    );
  }

  Widget _buildPeriodChips(HistoryFilter filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: HistoryPeriod.values.map((period) {
          final isSelected = filter.period == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getPeriodLabel(period)),
              selected: isSelected,
              onSelected: (selected) {
                if (period == HistoryPeriod.custom) {
                  _showDateRangePicker();
                } else {
                  ref.read(historyFilterProvider.notifier).update(
                    (state) => state.copyWith(period: period),
                  );
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Livraisons', '24', Icons.delivery_dining),
          _buildStatItem('Gains', '45,000 F', Icons.payments),
          _buildStatItem('Distance', '120 km', Icons.route),
          _buildStatItem('Note', '4.8', Icons.star),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    // Liste simulée pour démonstration
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 20,
      itemBuilder: (context, index) {
        return _buildDeliveryCard(index);
      },
    );
  }

  Widget _buildDeliveryCard(int index) {
    final isDelivered = index % 5 != 0;
    final statusColor = isDelivered ? Colors.green : Colors.orange;
    final dateFormat = DateFormat('dd MMM HH:mm', 'fr_FR');
    final date = DateTime.now().subtract(Duration(hours: index * 3));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDeliveryDetails(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isDelivered ? 'Livrée' : 'Annulée',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.local_pharmacy, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pharmacie du Centre ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Client ${index + 1}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(Icons.route, '${(index + 1) * 1.5} km'),
                  _buildInfoChip(Icons.timer, '${(index + 1) * 10} min'),
                  _buildInfoChip(
                    Icons.payments,
                    '${(index + 1) * 1000 + 500} F',
                    highlight: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {bool highlight = false}) {
    final color = highlight 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.onSurfaceVariant;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildChartsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur de type de graphique
          _buildChartTypeSelector(),
          const SizedBox(height: 24),
          
          // Graphique principal
          SizedBox(
            height: 250,
            child: _buildChart(),
          ),
          const SizedBox(height: 24),
          
          // Statistiques détaillées
          _buildDetailedStats(),
          const SizedBox(height: 24),
          
          // Comparaison avec période précédente
          _buildComparisonCard(),
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return SegmentedButton<ChartType>(
      segments: const [
        ButtonSegment(
          value: ChartType.earnings,
          label: Text('Gains'),
          icon: Icon(Icons.payments),
        ),
        ButtonSegment(
          value: ChartType.deliveries,
          label: Text('Livraisons'),
          icon: Icon(Icons.delivery_dining),
        ),
        ButtonSegment(
          value: ChartType.distance,
          label: Text('Distance'),
          icon: Icon(Icons.route),
        ),
      ],
      selected: {_selectedChart},
      onSelectionChanged: (selected) {
        setState(() {
          _selectedChart = selected.first;
        });
      },
    );
  }

  Widget _buildChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()}',
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                    return Text(
                      days[value.toInt() % 7],
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: 30 + (i * 10) % 60,
                    color: Theme.of(context).colorScheme.primary,
                    width: 24,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques détaillées',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Meilleur jour', 'Vendredi', '8,500 F'),
            _buildStatRow('Moyenne journalière', '5 livraisons', '6,250 F'),
            _buildStatRow('Distance totale', '120 km', ''),
            _buildStatRow('Temps moyen/livraison', '18 min', ''),
            _buildStatRow('Note moyenne', '4.8 ⭐', ''),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value1, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              value1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (value2.isNotEmpty)
            Expanded(
              child: Text(
                value2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up),
                const SizedBox(width: 8),
                Text(
                  'Par rapport à la période précédente',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildComparisonItem('Gains', '+15%', true),
                _buildComparisonItem('Livraisons', '+8%', true),
                _buildComparisonItem('Distance', '-5%', false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonItem(String label, String value, bool positive) {
    final color = positive ? Colors.green : Colors.red;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _getPeriodLabel(HistoryPeriod period) {
    switch (period) {
      case HistoryPeriod.today:
        return "Aujourd'hui";
      case HistoryPeriod.week:
        return '7 jours';
      case HistoryPeriod.month:
        return '30 jours';
      case HistoryPeriod.quarter:
        return '3 mois';
      case HistoryPeriod.year:
        return '1 an';
      case HistoryPeriod.custom:
        return 'Personnalisé';
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _FilterSheet(scrollController: scrollController);
        },
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (result != null) {
      ref.read(historyFilterProvider.notifier).update(
        (state) => state.copyWith(
          period: HistoryPeriod.custom,
          startDate: result.start,
          endDate: result.end,
        ),
      );
    }
  }

  void _showDeliveryDetails(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _DeliveryDetailsSheet(
            index: index,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  void _exportHistory() {
    // Naviguer vers l'écran d'export dédié qui utilise DeliveryExportService
    Navigator.of(context).pushNamed('/history');
  }
}

/// Sheet de filtres
class _FilterSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const _FilterSheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(historyFilterProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtres',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  ref.read(historyFilterProvider.notifier).state = const HistoryFilter();
                },
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Statut
          Text(
            'Statut',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildStatusChip(context, ref, 'delivered', 'Livrée', filter),
              _buildStatusChip(context, ref, 'cancelled', 'Annulée', filter),
            ],
          ),
          const SizedBox(height: 24),
          
          // Montant
          Text(
            'Montant',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Min',
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    ref.read(historyFilterProvider.notifier).update(
                      (state) => state.copyWith(
                        minAmount: double.tryParse(value),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max',
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    ref.read(historyFilterProvider.notifier).update(
                      (state) => state.copyWith(
                        maxAmount: double.tryParse(value),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Tri
          Text(
            'Trier par',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'date', label: Text('Date')),
              ButtonSegment(value: 'amount', label: Text('Montant')),
              ButtonSegment(value: 'distance', label: Text('Distance')),
            ],
            selected: {filter.sortBy},
            onSelectionChanged: (selected) {
              ref.read(historyFilterProvider.notifier).update(
                (state) => state.copyWith(sortBy: selected.first),
              );
            },
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Ordre décroissant'),
            value: filter.sortDescending,
            onChanged: (value) {
              ref.read(historyFilterProvider.notifier).update(
                (state) => state.copyWith(sortDescending: value),
              );
            },
          ),
          
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    WidgetRef ref,
    String status,
    String label,
    HistoryFilter filter,
  ) {
    final isSelected = filter.statuses.contains(status);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        final statuses = List<String>.from(filter.statuses);
        if (selected) {
          statuses.add(status);
        } else {
          statuses.remove(status);
        }
        ref.read(historyFilterProvider.notifier).update(
          (state) => state.copyWith(statuses: statuses),
        );
      },
    );
  }
}

/// Sheet des détails de livraison
class _DeliveryDetailsSheet extends StatelessWidget {
  final int index;
  final ScrollController scrollController;

  const _DeliveryDetailsSheet({
    required this.index,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR');
    final date = DateTime.now().subtract(Duration(hours: index * 3));

    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                child: const Icon(Icons.check, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Livraison #${1000 + index}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      dateFormat.format(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Pharmacie
          _buildSection(
            context,
            'Pharmacie',
            Icons.local_pharmacy,
            [
              _buildDetailRow('Nom', 'Pharmacie du Centre ${index + 1}'),
              _buildDetailRow('Adresse', 'Plateau, Rue du Commerce'),
              _buildDetailRow('Téléphone', '+225 07 XX XX XX XX'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Client
          _buildSection(
            context,
            'Client',
            Icons.person,
            [
              _buildDetailRow('Nom', 'Client ${index + 1}'),
              _buildDetailRow('Adresse', 'Cocody, Rue des Jardins'),
              _buildDetailRow('Téléphone', '+225 05 XX XX XX XX'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Trajet
          _buildSection(
            context,
            'Trajet',
            Icons.route,
            [
              _buildDetailRow('Distance', '${(index + 1) * 1.5} km'),
              _buildDetailRow('Durée', '${(index + 1) * 10} min'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Paiement
          _buildSection(
            context,
            'Paiement',
            Icons.payments,
            [
              _buildDetailRow('Commission', '${(index + 1) * 1000} FCFA'),
              _buildDetailRow('Pourboire', '${(index + 1) * 100} FCFA'),
              _buildDetailRow(
                'Total',
                '${(index + 1) * 1100} FCFA',
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/report-problem');
                  },
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Support'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reçu téléchargé')),
                    );
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Reçu'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
