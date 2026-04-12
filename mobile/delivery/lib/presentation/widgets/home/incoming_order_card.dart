import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/kyc_guard_service.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/delivery.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../providers/delivery_providers.dart';

/// Durée d'affichage de la carte (paramétrable côté serveur à terme)
const _kCardDisplayDuration = Duration(seconds: 20);

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
          child: _AnimatedOrderCard(
            key: ValueKey('order_${delivery.id}'),
            delivery: delivery,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

/// Carte avec countdown animé
class _AnimatedOrderCard extends ConsumerStatefulWidget {
  final Delivery delivery;

  const _AnimatedOrderCard({super.key, required this.delivery});

  @override
  ConsumerState<_AnimatedOrderCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends ConsumerState<_AnimatedOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _countdownController;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: _kCardDisplayDuration,
    )..forward();
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Countdown progress bar
            AnimatedBuilder(
              animation: _countdownController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1.0 - _countdownController.value,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _countdownController.value > 0.75
                        ? Colors.red.shade300
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(delivery),
                  const SizedBox(height: 16),
                  _buildAddressInfo(delivery),
                  if (delivery.distanceKm != null &&
                      delivery.distanceKm! > 0) ...[
                    const SizedBox(height: 12),
                    _buildDistanceInfo(delivery),
                  ],
                  const SizedBox(height: 20),
                  _buildActionButtons(context, delivery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Delivery delivery) {
    // Afficher les gains estimés du coursier (commission déduite)
    final earnings =
        delivery.estimatedEarnings ??
        ((delivery.deliveryFee ?? 0) - (delivery.commission ?? 0));

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_active,
            color: Colors.white,
            size: 24,
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                earnings > 0
                    ? earnings.formatCurrency(symbol: 'F')
                    : '${delivery.totalAmount.toInt()} F',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF1B5E20),
                ),
              ),
              if (earnings > 0)
                const Text(
                  'pour vous',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF388E3C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.2),
              height: 1,
            ),
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
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.3,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceInfo(Delivery delivery) {
    final km = delivery.distanceKm!;
    // Estimation : ~3 min par km en ville
    final estimatedMinutes = (km * 3).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.route, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            '${km.toStringAsFixed(1)} km',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.access_time, size: 16, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            '~$estimatedMinutes min',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Delivery delivery) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _rejectDelivery(context, delivery.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'IGNORER',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => _acceptDelivery(context, delivery.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B5E20),
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ACCEPTER',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                SizedBox(width: 8),
                Icon(Icons.check_circle, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _rejectDelivery(BuildContext context, int deliveryId) async {
    try {
      await ref.read(deliveryRepositoryProvider).rejectDelivery(deliveryId);
      ref.invalidate(deliveriesProvider('pending'));

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Course ignorée')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFriendlyError(e))));
      }
    }
  }

  Future<void> _acceptDelivery(BuildContext context, int deliveryId) async {
    // Bloquer si KYC non vérifié
    if (!await KycGuard.ensureVerified(context, ref)) return;

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
          SnackBar(
            content: Text(userFriendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
