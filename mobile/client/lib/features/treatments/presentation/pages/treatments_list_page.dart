import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../orders/presentation/providers/cart_provider.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../domain/entities/treatment_entity.dart';
import '../providers/treatments_provider.dart';
import '../providers/treatments_state.dart';
import '../widgets/widgets.dart';

class TreatmentsListPage extends ConsumerStatefulWidget {
  const TreatmentsListPage({super.key});

  @override
  ConsumerState<TreatmentsListPage> createState() => _TreatmentsListPageState();
}

class _TreatmentsListPageState extends ConsumerState<TreatmentsListPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  List<TreatmentEntity> _filteredTreatments = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(treatmentsProvider.notifier).loadTreatments();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterTreatments(List<TreatmentEntity> allTreatments, String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTreatments = allTreatments;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredTreatments = allTreatments.where((treatment) {
        return treatment.productName.toLowerCase().contains(lowerQuery) ||
            (treatment.dosage?.toLowerCase().contains(lowerQuery) ?? false) ||
            (treatment.frequency?.toLowerCase().contains(lowerQuery) ??
                false) ||
            (treatment.notes?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? _buildSearchField(state.treatments)
            : const Text('Mes traitements'),
        backgroundColor: AppColors.primary,
        actions: [
          if (state.treatments.length > 3)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              tooltip: _isSearching ? 'Fermer la recherche' : 'Rechercher',
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _filteredTreatments = state.treatments;
                  } else {
                    _animationController.forward();
                  }
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'À propos',
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addTreatment),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        heroTag: 'add_treatment',
      ),
    );
  }

  Widget _buildSearchField(List<TreatmentEntity> allTreatments) {
    return FadeTransition(
      opacity: _animationController,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Rechercher un traitement...',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
        onChanged: (value) => _filterTreatments(allTreatments, value),
      ),
    );
  }

  Widget _buildBody(TreatmentsState state) {
    // État de chargement avec skeleton
    if (state.status == TreatmentsStatus.loading) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: 3,
        itemBuilder: (context, index) => const TreatmentCardSkeleton(),
      );
    }

    // État d'erreur
    if (state.status == TreatmentsStatus.error) {
      return TreatmentsErrorState(
        message: state.errorMessage ?? 'Une erreur est survenue',
        onRetry: () => ref.read(treatmentsProvider.notifier).loadTreatments(),
      );
    }

    // État vide
    if (state.treatments.isEmpty) {
      return TreatmentsEmptyState(
        onAdd: () => context.push(AppRoutes.addTreatment),
      );
    }

    // Utiliser les traitements filtrés si recherche active
    final treatmentsToDisplay =
        _isSearching && _searchController.text.isNotEmpty
        ? _filteredTreatments
        : state.treatments;

    // Liste avec animations
    return RefreshIndicator(
      onRefresh: () => ref.read(treatmentsProvider.notifier).loadTreatments(),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        children: [
          // Message si recherche active sans résultats
          if (_isSearching &&
              _searchController.text.isNotEmpty &&
              treatmentsToDisplay.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun traitement trouvé',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Section urgente si nécessaire
          if (state.treatmentsNeedingRenewal.isNotEmpty && !_isSearching) ...[
            _buildSectionHeader(
              'À renouveler',
              Icons.warning_amber_rounded,
              AppColors.warning,
              state.treatmentsNeedingRenewal.length,
            ),
            ...List.generate(
              state.treatmentsNeedingRenewal.length,
              (index) => _buildTreatmentCard(
                state.treatmentsNeedingRenewal[index],
                index * 50,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
          ],

          // Tous les traitements (ou résultats de recherche)
          if (!_isSearching)
            _buildSectionHeader(
              'Tous mes traitements',
              Icons.medication_rounded,
              AppColors.primary,
              treatmentsToDisplay.length,
            ),

          if (_isSearching && _searchController.text.isNotEmpty)
            _buildSectionHeader(
              'Résultats',
              Icons.search,
              AppColors.primary,
              treatmentsToDisplay.length,
            ),

          ...List.generate(
            treatmentsToDisplay.length,
            (index) => _buildTreatmentCard(
              treatmentsToDisplay[index],
              _isSearching
                  ? 0
                  : (state.treatmentsNeedingRenewal.length + index) * 50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(TreatmentEntity treatment, int delay) {
    return TreatmentCard(
      treatment: treatment,
      animationDelay: delay,
      onTap: () => _showTreatmentDetails(treatment),
      onOrder: () => _orderTreatment(treatment),
      onDelete: () => _deleteTreatment(treatment),
      onReminderToggle: (enabled) => _toggleReminder(treatment, enabled),
    );
  }

  void _showTreatmentDetails(TreatmentEntity treatment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (sheetCtx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Hero(
                    tag: 'treatment_icon_${treatment.id}',
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      treatment.productName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (treatment.dosage != null) ...[
                _buildDetailRow('Dosage', treatment.dosage!),
                const SizedBox(height: 12),
              ],
              if (treatment.frequency != null) ...[
                _buildDetailRow('Fréquence', treatment.frequency!),
                const SizedBox(height: 12),
              ],
              _buildDetailRow(
                'Renouvellement',
                'Tous les ${treatment.renewalPeriodDays} jours',
              ),
              if (treatment.quantityPerRenewal != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Quantité',
                  '${treatment.quantityPerRenewal} unités',
                ),
              ],
              if (treatment.notes != null && treatment.notes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(treatment.notes!),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        if (mounted) context.push(AppRoutes.editTreatment, extra: treatment);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _orderTreatment(treatment);
                      },
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Commander'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Future<void> _orderTreatment(TreatmentEntity treatment) async {
    // Charger le produit et l'ajouter au panier
    await ref
        .read(productsProvider.notifier)
        .loadProductDetails(treatment.productId);
    final product = ref.read(productsProvider).selectedProduct;

    if (product == null) {
      if (mounted) {
        AppSnackbar.error(context, 'Produit non trouvé');
      }
      return;
    }

    // Ajouter au panier
    final quantity = treatment.quantityPerRenewal ?? 1;
    final success = await ref
        .read(cartProvider.notifier)
        .addItem(product, quantity: quantity);

    if (success && mounted) {
      // Marquer comme commandé
      await ref.read(treatmentsProvider.notifier).markAsOrdered(treatment.id);

      if (!mounted) return;
      AppSnackbar.success(
        context,
        '${treatment.productName} ajouté au panier',
        actionLabel: 'Voir panier',
        onAction: () => context.push(AppRoutes.cart),
      );
    }
  }

  Future<void> _deleteTreatment(TreatmentEntity treatment) async {
    await ref.read(treatmentsProvider.notifier).deleteTreatment(treatment.id);
    if (mounted) {
      AppSnackbar.success(context, 'Traitement supprimé');
    }
  }

  Future<void> _toggleReminder(TreatmentEntity treatment, bool enabled) async {
    await ref
        .read(treatmentsProvider.notifier)
        .toggleReminder(treatment.id, enabled);
    if (mounted) {
      AppSnackbar.info(
        context,
        enabled
            ? 'Rappels activés pour ${treatment.productName}'
            : 'Rappels désactivés pour ${treatment.productName}',
      );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.medication_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Mes traitements'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajoutez vos médicaments récurrents pour :',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            _InfoItem(
              icon: Icons.notifications_active,
              text: 'Recevoir des rappels de renouvellement',
            ),
            SizedBox(height: 8),
            _InfoItem(icon: Icons.shopping_cart, text: 'Commander en un clic'),
            SizedBox(height: 8),
            _InfoItem(icon: Icons.history, text: 'Suivre votre historique'),
            SizedBox(height: 8),
            _InfoItem(
              icon: Icons.search,
              text: 'Rechercher facilement vos traitements',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
