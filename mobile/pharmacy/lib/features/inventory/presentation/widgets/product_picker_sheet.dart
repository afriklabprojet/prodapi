import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/product_entity.dart';

/// Sélecteur de produit depuis la liste d'inventaire.
class ProductPickerSheet extends StatefulWidget {
  const ProductPickerSheet({
    super.key,
    required this.products,
    required this.alreadyAdded,
    required this.onPicked,
  });

  final List<ProductEntity> products;
  final Set<int> alreadyAdded;
  final ValueChanged<ProductEntity> onPicked;

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final filtered = widget.products
        .where((p) =>
            p.name.toLowerCase().contains(_query.toLowerCase()) ||
            (p.barcode?.contains(_query) ?? false))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Sélectionner un produit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final p = filtered[i];
                final alreadyIn = widget.alreadyAdded.contains(p.id);
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medication_rounded,
                        color: Colors.teal, size: 18),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Stock: ${p.stockQuantity}${p.barcode != null ? '  ·  ${p.barcode}' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: alreadyIn
                      ? const Icon(Icons.check_circle, color: Colors.teal)
                      : const Icon(Icons.add_circle_outline,
                          color: Colors.grey),
                  onTap: alreadyIn
                      ? null
                      : () {
                          widget.onPicked(p);
                          Navigator.of(ctx).pop();
                        },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// État vide pour la réception de livraison.
class EmptyReceptionState extends StatelessWidget {
  const EmptyReceptionState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucun produit ajouté',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scannez un code-barres ou\nsélectionnez dans la liste',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
