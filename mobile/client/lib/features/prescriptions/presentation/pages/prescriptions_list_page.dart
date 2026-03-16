import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/prescriptions_provider.dart';
import '../providers/prescriptions_state.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

class PrescriptionsListPage extends ConsumerStatefulWidget {
  const PrescriptionsListPage({super.key});

  @override
  ConsumerState<PrescriptionsListPage> createState() => _PrescriptionsListPageState();
}

class _PrescriptionsListPageState extends ConsumerState<PrescriptionsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() => ref.read(prescriptionsProvider.notifier).loadPrescriptions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<PrescriptionEntity> _filterPrescriptions(List<PrescriptionEntity> prescriptions, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return prescriptions;
      case 1:
        return prescriptions.where((p) => p.status == 'pending').toList();
      case 2:
        return prescriptions.where((p) => p.status == 'quoted').toList();
      case 3:
        return prescriptions.where((p) => ['processing', 'validated', 'paid', 'rejected'].contains(p.status)).toList();
      default:
        return prescriptions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prescriptionsProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(state),
        ],
        body: TabBarView(
          controller: _tabController,
          children: List.generate(4, (index) => _buildPrescriptionsList(state, index)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToUpload,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Nouvelle'),
      ),
    );
  }

  Widget _buildSliverAppBar(PrescriptionsState state) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary.withBlue(180)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes Ordonnances',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gérez vos prescriptions médicales',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsRow(state),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: [
              _buildTab('Toutes', state.prescriptions.length),
              _buildTab('Attente', state.prescriptions.where((p) => p.status == 'pending').length),
              _buildTab('Devis', state.prescriptions.where((p) => p.status == 'quoted').length),
              _buildTab('Terminées', state.prescriptions.where((p) => ['processing', 'validated', 'paid', 'rejected'].contains(p.status)).length),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(count.toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(PrescriptionsState state) {
    final pending = state.prescriptions.where((p) => p.status == 'pending').length;
    final quoted = state.prescriptions.where((p) => p.status == 'quoted').length;
    return Row(
      children: [
        _buildStatChip(Icons.description, '${state.prescriptions.length}'),
        const SizedBox(width: 12),
        _buildStatChip(Icons.pending_actions, '$pending'),
        const SizedBox(width: 12),
        _buildStatChip(Icons.receipt_long, '$quoted'),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsList(PrescriptionsState state, int tabIndex) {
    if (state.status.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(state.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(prescriptionsProvider.notifier).loadPrescriptions(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final filtered = _filterPrescriptions(state.prescriptions, tabIndex);
    if (filtered.isEmpty) {
      return _buildEmptyState(tabIndex);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(prescriptionsProvider.notifier).loadPrescriptions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildPrescriptionCard(filtered[index], index),
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionEntity prescription, int index) {
    final config = _getStatusConfig(prescription.status);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToDetails(prescription),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: config['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(config['icon'], color: config['color'], size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Ordonnance #${prescription.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (prescription.isLinkedToOrder) ...[
                                  const SizedBox(width: 8),
                                  _buildOrderBadge(prescription),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(DateFormat('dd MMM yyyy - HH:mm').format(prescription.createdAt), style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: config['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(config['label'], style: TextStyle(color: config['color'], fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ],
                  ),
                  if (prescription.status == 'quoted' && prescription.quoteAmount != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade100]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.monetization_on, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Devis disponible', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                Text(NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(prescription.quoteAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _navigateToDetails(prescription),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            child: const Text('Payer'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (prescription.status == 'rejected' && prescription.rejectionReason != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(prescription.rejectionReason!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (prescription.imageUrls.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text('${prescription.imageUrls.length} photo${prescription.imageUrls.length > 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700)),
                            ],
                          ),
                        ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _navigateToDetails(prescription),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Voir détails'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'pending': return {'color': Colors.orange, 'icon': Icons.hourglass_empty, 'label': 'En attente'};
      case 'processing': return {'color': Colors.blue, 'icon': Icons.sync, 'label': 'En traitement'};
      case 'quoted': return {'color': Colors.blue, 'icon': Icons.receipt_long, 'label': 'Devis reçu'};
      case 'paid': return {'color': Colors.teal, 'icon': Icons.payment, 'label': 'Payé'};
      case 'validated': return {'color': Colors.green, 'icon': Icons.check_circle, 'label': 'Validée'};
      case 'rejected': return {'color': Colors.red, 'icon': Icons.cancel, 'label': 'Refusée'};
      default: return {'color': Colors.grey, 'icon': Icons.info, 'label': status};
    }
  }

  /// Badge indiquant que la prescription est liée à une commande
  Widget _buildOrderBadge(PrescriptionEntity prescription) {
    return Tooltip(
      message: prescription.orderReference != null 
          ? 'Commande ${prescription.orderReference}'
          : 'Liée à une commande',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              prescription.orderReference ?? 'CMD',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    final configs = [
      {'title': 'Aucune ordonnance', 'subtitle': 'Envoyez votre première ordonnance', 'icon': Icons.description_outlined},
      {'title': 'Aucune en attente', 'subtitle': 'Toutes vos ordonnances ont été traitées', 'icon': Icons.hourglass_empty},
      {'title': 'Aucun devis', 'subtitle': 'Les devis apparaîtront ici', 'icon': Icons.receipt_long_outlined},
      {'title': 'Aucune terminée', 'subtitle': 'Les ordonnances finalisées apparaîtront ici', 'icon': Icons.check_circle_outline},
    ];
    final config = configs[tabIndex];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(config['icon'] as IconData, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(config['title'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(config['subtitle'] as String, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600)),
          if (tabIndex == 0) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToUpload,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Envoyer une ordonnance'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToDetails(PrescriptionEntity prescription) {
    context.goToPrescriptionDetails(prescription.id);
  }

  Future<void> _navigateToUpload() async {
    context.goToPrescriptionUpload();
    // Note: Le rechargement sera géré par le retour de la page ou un listener
  }
}
