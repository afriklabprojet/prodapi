import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/statistics/statistics_widgets.dart';

/// Écran de statistiques avancées pour le livreur.
/// Affiche 3 onglets : Aperçu, Livraisons, Revenus.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mes Statistiques'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Aperçu'),
            Tab(text: 'Livraisons'),
            Tab(text: 'Revenus'),
          ],
        ),
      ),
      body: Column(
        children: [
          PeriodSelector(
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: (period) =>
                setState(() => _selectedPeriod = period),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(selectedPeriod: _selectedPeriod),
                DeliveriesTab(selectedPeriod: _selectedPeriod),
                RevenueTab(selectedPeriod: _selectedPeriod),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
