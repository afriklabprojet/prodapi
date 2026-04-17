import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/kyc_guard_service.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/delivery_offer.dart';
import '../../providers/broadcast_offers_provider.dart';

/// Carte d'offre broadcast avec countdown serveur et bonus progressif.
/// Remplace IncomingOrderCard quand le système de broadcast est actif.
class BroadcastOfferCard extends ConsumerStatefulWidget {
  final DeliveryOffer offer;

  const BroadcastOfferCard({super.key, required this.offer});

  @override
  ConsumerState<BroadcastOfferCard> createState() => _BroadcastOfferCardState();
}

class _BroadcastOfferCardState extends ConsumerState<BroadcastOfferCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  late int _totalSeconds;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initCountdown();
  }

  void _initCountdown() {
    try {
      final expiresAt = DateTime.parse(widget.offer.expiresAt);
      final now = DateTime.now();
      _remainingSeconds = expiresAt.difference(now).inSeconds;
      if (_remainingSeconds < 0) _remainingSeconds = 0;

      // Calcul durée totale selon le niveau broadcast
      _totalSeconds = _getTotalSecondsForLevel(widget.offer.broadcastLevel);
    } catch (_) {
      _remainingSeconds = 30;
      _totalSeconds = 30;
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        _countdownTimer?.cancel();
        // Notifier le provider que l'offre a expiré
        ref
            .read(broadcastOffersProvider.notifier)
            .removeExpiredOffer(widget.offer.id);
      }
    });
  }

  int _getTotalSecondsForLevel(int level) {
    // Doit matcher BroadcastDispatchService::broadcastLevels côté backend
    const levelTimeouts = [45, 45, 60, 90];
    if (level >= 0 && level < levelTimeouts.length) {
      return levelTimeouts[level];
    }
    return 45;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  double get _progress =>
      _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0;

  Color get _countdownColor {
    if (_progress > 0.5) return Colors.white.withValues(alpha: 0.8);
    if (_progress > 0.25) return Colors.orange.shade300;
    return Colors.red.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final acceptingId = ref.watch(broadcastOffersProvider).acceptingOfferId;
    _isAccepting = acceptingId == offer.id;

    final totalFee = offer.baseFee + offer.bonusFee;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: offer.bonusFee > 0
              ? [const Color(0xFFE65100), const Color(0xFFFF8F00)]
              : [const Color(0xFF1B5E20), const Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (offer.bonusFee > 0 ? Colors.orange : Colors.green)
                .withValues(alpha: 0.4),
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
            _buildCountdownBar(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(offer, totalFee),
                  if (offer.bonusFee > 0) ...[
                    const SizedBox(height: 10),
                    _buildBonusBadge(offer),
                  ],
                  const SizedBox(height: 16),
                  _buildAddressInfo(offer),
                  if (offer.distanceKm != null && offer.distanceKm! > 0) ...[
                    const SizedBox(height: 12),
                    _buildDistanceInfo(offer),
                  ],
                  const SizedBox(height: 8),
                  _buildCountdownText(),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, offer),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownBar() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _progress + 0.03, end: _progress),
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
      builder: (context, value, _) {
        return LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 5,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(_countdownColor),
        );
      },
    );
  }

  Widget _buildHeader(DeliveryOffer offer, double totalFee) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.15 + (_pulseController.value * 0.1),
                ),
                shape: BoxShape.circle,
              ),
              child: child,
            );
          },
          child: Icon(
            offer.bonusFee > 0
                ? Icons.local_fire_department
                : Icons.delivery_dining,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.bonusFee > 0 ? 'OFFRE BOOST' : 'NOUVELLE OFFRE',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                offer.pharmacyName ?? 'Course disponible',
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                totalFee > 0 ? totalFee.formatCurrency(symbol: 'F') : '---',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: offer.bonusFee > 0
                      ? const Color(0xFFE65100)
                      : const Color(0xFF1B5E20),
                ),
              ),
              const Text(
                'pour vous',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Badge animé quand il y a un bonus (niveau 2+)
  Widget _buildBonusBadge(DeliveryOffer offer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.yellow.shade300.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 16, color: Colors.yellow.shade200),
          const SizedBox(width: 6),
          Text(
            '+${offer.bonusFee.toInt()} F bonus',
            style: TextStyle(
              color: Colors.yellow.shade100,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '(niveau ${offer.broadcastLevel + 1})',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInfo(DeliveryOffer offer) {
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
                  offer.pharmacyName ?? 'Pharmacie',
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
                  offer.deliveryAddress ?? 'Adresse de livraison',
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

  Widget _buildDistanceInfo(DeliveryOffer offer) {
    final km = offer.distanceKm!;
    final estimatedMinutes = offer.estimatedDuration ?? (km * 3).round();

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

  Widget _buildCountdownText() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final formatted = minutes > 0
        ? '${minutes}m ${seconds.toString().padLeft(2, '0')}s'
        : '${seconds}s';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer_outlined, size: 16, color: _countdownColor),
        const SizedBox(width: 6),
        Text(
          'Expire dans $formatted',
          style: TextStyle(
            color: _countdownColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, DeliveryOffer offer) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isAccepting
                ? null
                : () => _showRejectDialog(context, offer),
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
              'REFUSER',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isAccepting ? null : () => _acceptOffer(context, offer),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: offer.bonusFee > 0
                  ? const Color(0xFFE65100)
                  : const Color(0xFF1B5E20),
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isAccepting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ACCEPTER',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
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

  Future<void> _acceptOffer(BuildContext context, DeliveryOffer offer) async {
    if (!await KycGuard.ensureVerified(context, ref)) return;

    HapticFeedback.heavyImpact();

    try {
      final success = await ref
          .read(broadcastOffersProvider.notifier)
          .acceptOffer(offer.id);

      if (context.mounted && success) {
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

  /// Dialog de refus avec raison
  Future<void> _showRejectDialog(
    BuildContext context,
    DeliveryOffer offer,
  ) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RejectReasonSheet(),
    );

    if (reason != null && context.mounted) {
      HapticFeedback.mediumImpact();
      await ref
          .read(broadcastOffersProvider.notifier)
          .rejectOffer(offer.id, reason: reason);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Offre refusée')));
      }
    }
  }
}

/// Bottom sheet pour sélectionner la raison de refus
class _RejectReasonSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Pourquoi refuser ?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...OfferRejectionReason.labels.entries.map((entry) {
            return ListTile(
              leading: Icon(
                _getReasonIcon(entry.key),
                color: Colors.grey.shade600,
              ),
              title: Text(entry.value),
              onTap: () => Navigator.pop(context, entry.key),
            );
          }),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  IconData _getReasonIcon(String reason) {
    switch (reason) {
      case OfferRejectionReason.tooFar:
        return Icons.map_outlined;
      case OfferRejectionReason.lowFee:
        return Icons.money_off;
      case OfferRejectionReason.busy:
        return Icons.work_outline;
      case OfferRejectionReason.badWeather:
        return Icons.cloud;
      case OfferRejectionReason.vehicleIssue:
        return Icons.two_wheeler;
      default:
        return Icons.help_outline;
    }
  }
}
