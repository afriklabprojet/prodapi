import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/inventory_provider.dart';
import 'add_product_sheet.dart';

class ProductDetailsSheet extends ConsumerWidget {
  final ProductEntity product;
  final String? imageUrl; // Optional, might be in product entity in future

  /// Si true, affiche le contenu sans décoration modale (pour panneau latéral tablette)
  final bool embedded;

  const ProductDetailsSheet({
    super.key,
    required this.product,
    this.imageUrl,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Attempt to parse date or other fields if available

    // En mode embedded, pas de décoration modale
    if (embedded) {
      return _buildContent(context, ref);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Image Header
          if (product.imageUrl != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(product.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildDetailsContent(context, ref),
          ),
        ],
      ),
    );
  }

  /// Contenu pour le mode embedded (panneau latéral tablette)
  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.cardColor(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header en mode embedded
            if (product.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(product.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            if (product.imageUrl != null) const SizedBox(height: 24),
            _buildDetailsContent(context, ref),
          ],
        ),
      ),
    );
  }

  /// Contenu partagé entre les modes modal et embedded
  Widget _buildDetailsContent(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(product.name, style: AppTextStyles.h2)),
            Text(
              NumberFormat.currency(
                locale: 'fr_FR',
                symbol: 'FCFA',
                decimalDigits: 0,
              ).format(product.price),
              style: AppTextStyles.h3.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          product.category,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),

        // Info badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildBadge(
              label: product.stockQuantity > 0
                  ? "En stock: ${product.stockQuantity}"
                  : "Rupture",
              color: product.stockQuantity > 0 ? Colors.green : Colors.red,
              isOutline: true,
            ),
            if (product.requiresPrescription)
              _buildBadge(
                label: "Ordonnance Requise",
                color: Colors.orange,
                isOutline: false,
              ),
            if (product.barcode != null && product.barcode!.isNotEmpty)
              _buildBadge(
                label: "Code: ${product.barcode}",
                color: Colors.blueGrey,
                isOutline: true,
              ),
            // Date de péremption
            if (product.expiryDate != null)
              _buildExpiryBadge(product.expiryDate!),
          ],
        ),

        const SizedBox(height: 24),

        Text("Description", style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(product.description, style: AppTextStyles.bodyMedium),

        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // DELETE
                  _showDeleteConfirmation(context, ref);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  "Supprimer",
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // EDIT - en mode embedded, pas besoin de pop
                  if (!embedded) Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (c) => AddProductSheet(productToEdit: product),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text("Modifier"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required bool isOutline,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutline ? color.withValues(alpha: 0.1) : color,
        border: isOutline ? Border.all(color: color) : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isOutline ? color : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Badge intelligent pour la date de péremption
  Widget _buildExpiryBadge(DateTime expiryDate) {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    final dateStr = DateFormat('dd/MM/yyyy').format(expiryDate);

    // Déjà expiré
    if (daysUntilExpiry < 0) {
      return _buildBadge(
        label: "⚠️ Expiré le $dateStr",
        color: Colors.red,
        isOutline: false,
      );
    }

    // Expire dans moins de 30 jours
    if (daysUntilExpiry <= 30) {
      return _buildBadge(
        label: "⏰ Expire dans $daysUntilExpiry j",
        color: Colors.orange,
        isOutline: false,
      );
    }

    // Expire dans moins de 90 jours
    if (daysUntilExpiry <= 90) {
      return _buildBadge(
        label: "📅 Exp: $dateStr",
        color: Colors.amber.shade700,
        isOutline: true,
      );
    }

    // Date normale
    return _buildBadge(
      label: "Exp: $dateStr",
      color: Colors.teal,
      isOutline: true,
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text("Voulez-vous vraiment supprimer '${product.name}' ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              ref.read(inventoryProvider.notifier).deleteProduct(product.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close sheet
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Produit supprimé")));
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
