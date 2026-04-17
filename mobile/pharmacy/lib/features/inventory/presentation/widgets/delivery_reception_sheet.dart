import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/error_display.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../pages/enhanced_scanner_page.dart';
import '../providers/inventory_provider.dart';
import 'product_picker_sheet.dart';
import 'reception_item.dart';
import 'reception_item_card.dart';

/// Feuille modale de réception de livraison en masse.
/// Le pharmacien scanne/sélectionne produits et saisit les quantités reçues,
/// puis valide tout en un seul geste.
class DeliveryReceptionSheet extends ConsumerStatefulWidget {
  const DeliveryReceptionSheet({super.key});

  @override
  ConsumerState<DeliveryReceptionSheet> createState() =>
      _DeliveryReceptionSheetState();
}

class _DeliveryReceptionSheetState
    extends ConsumerState<DeliveryReceptionSheet> {
  final List<ReceptionItem> _items = [];
  bool _isValidating = false;

  /// Scan avec mode continu pour scanner plusieurs produits d'un coup
  Future<void> _scanProduct() async {
    final String? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EnhancedScannerPage(continuousMode: true),
      ),
    );

    if (result == null || result == '-1' || !mounted) return;

    // En mode continu, on reçoit une liste de codes séparés par des virgules
    final codes = result.split(',');

    int addedCount = 0;
    int unknownCount = 0;

    for (final barcode in codes) {
      if (barcode.isEmpty) continue;

      // Skip voice results
      if (barcode.startsWith('voice:')) {
        continue;
      }

      final product = ref
          .read(inventoryProvider.notifier)
          .findProductByBarcode(barcode);

      if (product == null) {
        unknownCount++;
        continue;
      }

      setState(() {
        final existing = _items
            .where((i) => i.product.id == product.id)
            .firstOrNull;
        if (existing != null) {
          existing.quantityToAdd++;
        } else {
          _items.add(ReceptionItem(product: product));
        }
      });
      addedCount++;
    }

    if (!mounted) return;

    // Feedback summary
    if (addedCount > 0 || unknownCount > 0) {
      String message = '';
      if (addedCount > 0) {
        message =
            '$addedCount produit${addedCount > 1 ? 's' : ''} ajouté${addedCount > 1 ? 's' : ''}';
      }
      if (unknownCount > 0) {
        if (message.isNotEmpty) message += ', ';
        message +=
            '$unknownCount code${unknownCount > 1 ? 's' : ''} inconnu${unknownCount > 1 ? 's' : ''}';
      }

      if (unknownCount > 0 && addedCount == 0) {
        ErrorSnackBar.showWarning(context, message);
      } else {
        ErrorSnackBar.showSuccess(context, message);
      }
    }
  }

  Future<void> _selectFromList() async {
    final invState = ref.read(inventoryProvider);
    final products = invState.products;

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductPickerSheet(
        products: products,
        alreadyAdded: _items.map((e) => e.product.id).toSet(),
        onPicked: (p) {
          setState(() {
            _items.add(ReceptionItem(product: p));
          });
        },
      ),
    );
  }

  Future<void> _validate() async {
    if (_items.isEmpty) return;

    setState(() => _isValidating = true);

    int successCount = 0;
    for (final item in _items) {
      final newQty = item.product.stockQuantity + item.quantityToAdd;
      await ref
          .read(inventoryProvider.notifier)
          .updateStock(item.product.id, newQty);
      successCount++;
    }

    if (!mounted) return;
    setState(() => _isValidating = false);

    ErrorSnackBar.showSuccess(
      context,
      '$successCount produit${successCount > 1 ? 's' : ''} mis à jour avec succès.',
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final totalItems = _items.fold<int>(0, (s, i) => s + i.quantityToAdd);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Réception de livraison',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          _items.isEmpty
                              ? 'Scannez ou sélectionnez les produits reçus'
                              : '${_items.length} référence${_items.length > 1 ? 's' : ''} · $totalItems unité${totalItems > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                    tooltip: AppLocalizations.of(context).close,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scan / Sélection actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanProduct,
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Scanner'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectFromList,
                      icon: const Icon(Icons.list_rounded, size: 18),
                      label: const Text('Sélectionner'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.info,
                        side: BorderSide(color: AppColors.info),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Items list
            Expanded(
              child: _items.isEmpty
                  ? const EmptyReceptionState()
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ReceptionItemCard(
                          item: item,
                          isDark: isDark,
                          onRemove: () =>
                              setState(() => _items.removeAt(index)),
                          onDecrement: () => setState(() {
                            if (item.quantityToAdd > 1) {
                              item.quantityToAdd--;
                            }
                          }),
                          onIncrement: () => setState(() {
                            item.quantityToAdd++;
                          }),
                          onEdit: (qty) => setState(() {
                            item.quantityToAdd = qty;
                          }),
                          onLotChanged: (lot) => setState(() {
                            item.lotNumber = lot;
                          }),
                          onExpiryChanged: (expiry) => setState(() {
                            item.expiryDate = expiry;
                          }),
                        );
                      },
                    ),
            ),

            // Validate button
            if (_items.isNotEmpty) _buildValidateButton(totalItems, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildValidateButton(int totalItems, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor(context),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isValidating ? null : _validate,
          icon: _isValidating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_rounded),
          label: Text(
            _isValidating
                ? 'Mise à jour...'
                : 'Réceptionner · $totalItems unité${totalItems > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

/// Widget d'état vide pour la réception de livraison
class EmptyReceptionState extends StatelessWidget {
  const EmptyReceptionState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 48,
              color: Colors.teal.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun produit ajouté',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scannez les codes-barres ou\nsélectionnez dans la liste',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
