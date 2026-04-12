import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/adaptive_picker.dart';

import '../providers/inventory_di_providers.dart';
import 'stock_alert_card.dart';
import 'stock_alert_model.dart';
import '../../../../l10n/app_localizations.dart';

/// Shows reorder dialog for out-of-stock or low-stock products
void showStockReorderDialog(BuildContext context, StockAlert alert) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Commander du stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produit: ${alert.productName}'),
          const SizedBox(height: 8),
          Text('Stock actuel: ${alert.currentStock}'),
          if (alert.threshold != null)
            Text('Seuil d\'alerte: ${alert.threshold}'),
          const SizedBox(height: 16),
          const Text('Quantité à commander:'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: '${(alert.threshold ?? 20) * 2}',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixText: 'unités',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).orderSentToSupplier),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            AppLocalizations.of(context).order,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

/// Shows expiration options bottom sheet
void showStockExpirationOptions(
  BuildContext context,
  WidgetRef ref,
  StockAlert alert, {
  required VoidCallback onDismissAlert,
  required VoidCallback onReloadAlerts,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            alert.productName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            alert.type == StockAlertType.expired
                ? 'Ce produit est expiré'
                : 'Ce produit expire bientôt',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          StockAlertActionTile(
            icon: Icons.discount,
            iconColor: Colors.orange,
            title: 'Appliquer une promotion',
            subtitle: 'Réduire le prix pour écouler le stock',
            onTap: () {
              Navigator.of(context).pop();
              showStockPromotionDialog(
                context,
                ref,
                alert,
                onReloadAlerts: onReloadAlerts,
              );
            },
          ),
          StockAlertActionTile(
            icon: Icons.delete_outline,
            iconColor: Colors.red,
            title: 'Retirer du stock',
            subtitle: 'Marquer comme perte',
            onTap: () {
              Navigator.of(context).pop();
              showStockLossDialog(
                context,
                ref,
                alert,
                onReloadAlerts: onReloadAlerts,
              );
            },
          ),
          if (alert.type == StockAlertType.expiring)
            StockAlertActionTile(
              icon: Icons.access_time,
              iconColor: Colors.orange,
              title: 'Reporter le rappel',
              subtitle: 'Rappeler dans 7 jours',
              onTap: () {
                Navigator.of(context).pop();
                onDismissAlert();
              },
            ),
        ],
      ),
    ),
  );
}

/// Shows promotion dialog for expiring products
void showStockPromotionDialog(
  BuildContext context,
  WidgetRef ref,
  StockAlert alert, {
  required VoidCallback onReloadAlerts,
}) {
  double discountPercentage = 10.0;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 7));

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.discount, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Appliquer une promotion'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.medication, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Discount percentage
              const Text(
                'Réduction',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: discountPercentage,
                      min: 5,
                      max: 70,
                      divisions: 13,
                      label: '${discountPercentage.toInt()}%',
                      onChanged: (value) {
                        setDialogState(() {
                          discountPercentage = value;
                        });
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${discountPercentage.toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date range
              const Text(
                'Période de promotion',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await AdaptivePicker.showDate(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        );
                        if (date != null) {
                          setDialogState(() {
                            startDate = date;
                            if (endDate.isBefore(startDate)) {
                              endDate = startDate.add(const Duration(days: 7));
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Début',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${startDate.day}/${startDate.month}/${startDate.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await AdaptivePicker.showDate(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: DateTime.now().add(
                            const Duration(days: 180),
                          ),
                        );
                        if (date != null) {
                          setDialogState(() {
                            endDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fin',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${endDate.day}/${endDate.month}/${endDate.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _applyPromotion(
                context,
                ref,
                int.tryParse(alert.productId) ?? 0,
                discountPercentage,
                startDate,
                endDate,
                onReloadAlerts: onReloadAlerts,
              );
            },
            icon: const Icon(Icons.check, color: Colors.white, size: 18),
            label: const Text(
              'Appliquer',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    ),
  );
}

/// Shows loss/removal dialog for expired or damaged products
void showStockLossDialog(
  BuildContext context,
  WidgetRef ref,
  StockAlert alert, {
  required VoidCallback onReloadAlerts,
}) {
  final quantityController = TextEditingController(
    text: '${alert.currentStock}',
  );
  String selectedReason = 'Produit expiré';
  final notesController = TextEditingController();

  final reasons = [
    'Produit expiré',
    'Produit endommagé',
    'Erreur d\'inventaire',
    'Vol/Perte',
    'Rappel fournisseur',
    'Autre',
  ];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Retirer du stock'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.medication, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Stock actuel: ${alert.currentStock}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quantity
              const Text(
                'Quantité à retirer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'unités',
                  hintText: 'Quantité',
                ),
              ),
              const SizedBox(height: 16),

              // Reason
              const Text(
                'Raison de la perte',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reasons.map((reason) {
                  final isSelected = selectedReason == reason;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedReason = reason;
                      });
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        reason,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.red.shade800
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Notes
              const Text(
                'Notes (optionnel)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Ajouter des détails...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              if (quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer une quantité valide'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              _markAsLoss(
                context,
                ref,
                int.tryParse(alert.productId) ?? 0,
                quantity,
                selectedReason,
                notesController.text.isNotEmpty ? notesController.text : null,
                onReloadAlerts: onReloadAlerts,
              );
            },
            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
            label: const Text('Retirer', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    quantityController.dispose();
    notesController.dispose();
  });
}

Future<void> _applyPromotion(
  BuildContext context,
  WidgetRef ref,
  int productId,
  double discountPercentage,
  DateTime startDate,
  DateTime endDate, {
  required VoidCallback onReloadAlerts,
}) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Text('Application de la promotion...'),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ),
  );

  try {
    final result = await ref
        .read(inventoryRepositoryProvider)
        .applyPromotion(productId, discountPercentage, endDate: endDate);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${failure.message}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Promotion de ${discountPercentage.toInt()}% appliquée'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        onReloadAlerts();
      },
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _markAsLoss(
  BuildContext context,
  WidgetRef ref,
  int productId,
  int quantity,
  String reason,
  String? notes, {
  required VoidCallback onReloadAlerts,
}) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Text('Mise à jour du stock...'),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ),
  );

  try {
    final result = await ref
        .read(inventoryRepositoryProvider)
        .markAsLoss(productId, quantity, reason);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${failure.message}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('$quantity unité(s) retirée(s) du stock'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        onReloadAlerts();
      },
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
