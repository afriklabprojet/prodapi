import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../features/inventory/domain/entities/product_entity.dart';
import '../../../features/inventory/presentation/widgets/product_details_sheet.dart';
import '../../../features/orders/domain/entities/order_entity.dart';
import '../../../features/prescriptions/data/models/prescription_model.dart';
import '../../../features/dashboard/presentation/providers/dashboard_tab_provider.dart';
import '../../../features/dashboard/presentation/providers/activity_sub_tab_provider.dart';
import '../providers/global_search_provider.dart';

/// Sheet de recherche globale avec résultats typés
class GlobalSearchSheet extends ConsumerStatefulWidget {
  const GlobalSearchSheet({super.key});

  @override
  ConsumerState<GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends ConsumerState<GlobalSearchSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus sur le champ de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(globalSearchProvider.notifier).search(query);
  }

  void _onResultTap(GlobalSearchResult result) {
    HapticFeedback.selectionClick();
    Navigator.pop(context);

    switch (result.type) {
      case GlobalSearchResultType.product:
        final product = result.data as ProductEntity;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ProductDetailsSheet(product: product),
        );
        break;
      case GlobalSearchResultType.order:
        final order = result.data as OrderEntity;
        context.push('/orders/${order.id}');
        break;
      case GlobalSearchResultType.prescription:
        final prescription = result.data as PrescriptionModel;
        context.push('/prescriptions/${prescription.id}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(globalSearchProvider);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Rechercher produits, commandes, ordonnances...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(globalSearchProvider.notifier).clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onSearch,
                onSubmitted: _onSearch,
              ),
            ),
            // Results
            Expanded(child: _buildResults(searchState, l10n, scrollController)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    GlobalSearchState state,
    AppLocalizations l10n,
    ScrollController scrollController,
  ) {
    if (state.query.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_rounded,
        title: 'Recherche globale',
        subtitle:
            'Tapez pour rechercher dans tous vos produits,\ncommandes et ordonnances',
      );
    }

    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Erreur',
        subtitle: state.error!,
        isError: true,
      );
    }

    if (state.results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Aucun résultat',
        subtitle: 'Aucun élément ne correspond à "${state.query}"',
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Section Produits
        if (state.products.isNotEmpty) ...[
          _buildSectionHeader(
            'Produits',
            Icons.inventory_2_rounded,
            Colors.teal,
            state.products.length,
          ),
          ...state.products.take(5).map((r) => _buildProductTile(r)),
          if (state.products.length > 5)
            _buildShowMoreButton(state.products.length - 5, 'produits'),
        ],
        // Section Commandes
        if (state.orders.isNotEmpty) ...[
          if (state.products.isNotEmpty) const SizedBox(height: 16),
          _buildSectionHeader(
            'Commandes',
            Icons.shopping_bag_rounded,
            Colors.blue,
            state.orders.length,
          ),
          ...state.orders.take(5).map((r) => _buildOrderTile(r)),
          if (state.orders.length > 5)
            _buildShowMoreButton(state.orders.length - 5, 'commandes'),
        ],
        // Section Ordonnances
        if (state.prescriptions.isNotEmpty) ...[
          if (state.products.isNotEmpty || state.orders.isNotEmpty)
            const SizedBox(height: 16),
          _buildSectionHeader(
            'Ordonnances',
            Icons.receipt_long_rounded,
            Colors.purple,
            state.prescriptions.length,
          ),
          ...state.prescriptions.take(5).map((r) => _buildPrescriptionTile(r)),
          if (state.prescriptions.length > 5)
            _buildShowMoreButton(state.prescriptions.length - 5, 'ordonnances'),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(GlobalSearchResult result) {
    final product = result.data as ProductEntity;
    final isLowStock = product.stockQuantity <= 5;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _onResultTap(result),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.medication_rounded,
                      color: Colors.teal,
                    ),
                  ),
                )
              : const Icon(Icons.medication_rounded, color: Colors.teal),
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text(
              '${product.price.toStringAsFixed(0)} FCFA',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isLowStock
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${product.stockQuantity} en stock',
                style: TextStyle(
                  fontSize: 11,
                  color: isLowStock ? Colors.red : Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  Widget _buildOrderTile(GlobalSearchResult result) {
    final order = result.data as OrderEntity;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _onResultTap(result),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shopping_bag_rounded, color: Colors.blue),
        ),
        title: Text(
          order.reference,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(
                order.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: order.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                order.status.displayLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: order.status.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  Widget _buildPrescriptionTile(GlobalSearchResult result) {
    final prescription = result.data as PrescriptionModel;
    final customerName =
        prescription.customer?['name'] as String? ??
        'Client #${prescription.customerId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _onResultTap(result),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: prescription.images?.isNotEmpty == true
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    prescription.images!.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.purple,
                    ),
                  ),
                )
              : const Icon(Icons.receipt_long_rounded, color: Colors.purple),
        ),
        title: Text(
          'Ordonnance #${prescription.id}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(
                customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(
                  prescription.status,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getStatusLabel(prescription.status),
                style: TextStyle(
                  fontSize: 11,
                  color: _getStatusColor(prescription.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'validated':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'validated':
        return 'Validée';
      case 'rejected':
        return 'Rejetée';
      default:
        return status;
    }
  }

  Widget _buildShowMoreButton(int count, String type) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.pop(context);
          switch (type) {
            case 'produits':
              ref.read(dashboardTabProvider.notifier).state = 2;
            case 'commandes':
              ref.read(activitySubTabProvider.notifier).state = 0;
              ref.read(dashboardTabProvider.notifier).state = 1;
            case 'ordonnances':
              ref.read(activitySubTabProvider.notifier).state = 1;
              ref.read(dashboardTabProvider.notifier).state = 1;
          }
        },
        child: Text(
          '+ $count autres $type',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isError = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isError ? Colors.red.shade300 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isError ? Colors.red : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Affiche la recherche globale en modal
Future<void> showGlobalSearch(BuildContext context) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const GlobalSearchSheet(),
  );
}
