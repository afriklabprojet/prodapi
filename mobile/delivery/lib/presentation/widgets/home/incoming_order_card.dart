import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/delivery.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../providers/delivery_providers.dart';

/// Carte d'alerte pour une nouvelle commande entrante
class IncomingOrderCard extends ConsumerWidget {
  const IncomingOrderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveriesAsync = ref.watch(deliveriesProvider('pending'));

    return deliveriesAsync.when(
      data: (deliveries) {
        if (deliveries.isEmpty) return const SizedBox.shrink();

        final delivery = deliveries.first;

        return Positioned(
          top: 100,
          left: 16,
          right: 16,
          child: _buildCard(context, ref, delivery),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, Delivery delivery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(delivery),
              const SizedBox(height: 20),
              _buildAddressInfo(delivery),
              const SizedBox(height: 20),
              _buildActionButtons(context, ref, delivery),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Delivery delivery) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_active, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOUVELLE COURSE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Commande prête !',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '${delivery.totalAmount} F',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF1B5E20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressInfo(Delivery delivery) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.store, size: 18, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  delivery.pharmacyName,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  delivery.deliveryAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, height: 1.3, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Delivery delivery) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _rejectDelivery(context, ref, delivery.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('IGNORER', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => _acceptDelivery(context, ref, delivery.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B5E20),
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('ACCEPTER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                SizedBox(width: 8),
                Icon(Icons.check_circle, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _rejectDelivery(BuildContext context, WidgetRef ref, int deliveryId) async {
    try {
      await ref.read(deliveryRepositoryProvider).rejectDelivery(deliveryId);
      ref.invalidate(deliveriesProvider('pending'));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course ignorée')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _acceptDelivery(BuildContext context, WidgetRef ref, int deliveryId) async {
    try {
      await ref.read(deliveryRepositoryProvider).acceptDelivery(deliveryId);
      ref.invalidate(deliveriesProvider('pending'));
      ref.invalidate(deliveriesProvider('active'));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course acceptée !'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
