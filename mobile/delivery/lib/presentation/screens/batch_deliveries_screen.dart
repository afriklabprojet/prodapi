import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/delivery.dart';
import '../../data/repositories/delivery_repository.dart';
import '../providers/delivery_providers.dart';
import '../widgets/common/common_widgets.dart';

class BatchDeliveriesScreen extends ConsumerStatefulWidget {
  const BatchDeliveriesScreen({super.key});

  @override
  ConsumerState<BatchDeliveriesScreen> createState() => _BatchDeliveriesScreenState();
}

class _BatchDeliveriesScreenState extends ConsumerState<BatchDeliveriesScreen> {
  final Set<int> _selectedIds = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final pendingDeliveriesAsync = ref.watch(deliveriesProvider('pending'));
    final currencyFormat = NumberFormat("#,##0", "fr_FR");

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Courses Disponibles'),
        backgroundColor: context.cardBackground,
        foregroundColor: context.primaryText,
        elevation: 0,
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _selectedIds.clear()),
              icon: const Icon(Icons.clear_all, size: 20),
              label: const Text('Effacer'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header with selection info
          if (_selectedIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_selectedIds.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedIds.length} course${_selectedIds.length > 1 ? 's' : ''} sélectionnée${_selectedIds.length > 1 ? 's' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Maximum 5 courses à la fois',
                          style: TextStyle(fontSize: 12, color: context.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // List of deliveries
          Expanded(
            child: AsyncValueWidget<List<Delivery>>(
              value: pendingDeliveriesAsync,
              onRetry: () => ref.invalidate(deliveriesProvider('pending')),
              data: (deliveries) {
                if (deliveries.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: deliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = deliveries[index];
                    final isSelected = _selectedIds.contains(delivery.id);
                    return _DeliverySelectCard(
                      delivery: delivery,
                      isSelected: isSelected,
                      onToggle: () => _toggleSelection(delivery.id),
                      currencyFormat: currencyFormat,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? _buildBottomBar(currencyFormat, pendingDeliveriesAsync)
          : null,
    );
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else if (_selectedIds.length < 5) {
        _selectedIds.add(id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 5 courses à la fois'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: context.dividerColor),
          const SizedBox(height: 16),
          Text(
            'Aucune course disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: context.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revenez plus tard ou activez-vous en ligne',
            style: TextStyle(color: context.tertiaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(NumberFormat currencyFormat, AsyncValue<List<Delivery>> deliveriesAsync) {
    // Calculate total estimated earnings
    double totalEarnings = 0;
    if (deliveriesAsync.hasValue) {
      for (final delivery in deliveriesAsync.value!) {
        if (_selectedIds.contains(delivery.id)) {
          totalEarnings += delivery.estimatedEarnings ?? 
              ((delivery.deliveryFee ?? 500) - (delivery.commission ?? 200));
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Earnings summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Gains estimés',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    '${currencyFormat.format(totalEarnings)} FCFA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Accept button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _acceptSelectedDeliveries,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isLoading
                      ? 'Acceptation...'
                      : 'Accepter ${_selectedIds.length} course${_selectedIds.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptSelectedDeliveries() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(deliveryRepositoryProvider);
      final result = await repo.batchAcceptDeliveries(_selectedIds.toList());

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 50),
                ),
                const SizedBox(height: 20),
                Text(
                  '${result['accepted_count']} Course${(result['accepted_count'] ?? 1) > 1 ? 's' : ''} Acceptée${(result['accepted_count'] ?? 1) > 1 ? 's' : ''} !',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Gains: ~${NumberFormat("#,##0", "fr_FR").format(result['total_estimated_earnings'] ?? 0)} FCFA',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to home
                      ref.invalidate(deliveriesProvider('active'));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Voir mes courses'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _DeliverySelectCard extends StatelessWidget {
  final Delivery delivery;
  final bool isSelected;
  final VoidCallback onToggle;
  final NumberFormat currencyFormat;

  const _DeliverySelectCard({
    required this.delivery,
    required this.isSelected,
    required this.onToggle,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final estimatedEarnings = delivery.estimatedEarnings ?? 
        ((delivery.deliveryFee ?? 500) - (delivery.commission ?? 200));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Checkbox
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : context.dividerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Delivery info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            delivery.pharmacyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: context.iconColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  delivery.deliveryAddress,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.secondaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Earnings
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${currencyFormat.format(estimatedEarnings)} F',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (delivery.distanceKm != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${delivery.distanceKm!.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Additional info
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _InfoChip(
                        icon: Icons.person_outline,
                        label: delivery.customerName,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.shopping_bag_outlined,
                        label: '${currencyFormat.format(delivery.totalAmount)} F',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.secondaryText),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.primaryText),
        ),
      ],
    );
  }
}
