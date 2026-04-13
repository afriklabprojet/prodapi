import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/broadcast_offers_provider.dart';
import 'broadcast_offer_card.dart';
import 'incoming_order_card.dart';

/// Widget qui affiche les offres broadcast en overlay sur la carte.
/// Si des offres broadcast sont disponibles, elles sont affichées en priorité.
/// Sinon, on fallback sur l'ancien IncomingOrderCard (polling pending).
class BroadcastOffersOverlay extends ConsumerWidget {
  const BroadcastOffersOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersState = ref.watch(broadcastOffersProvider);

    // Si des offres broadcast existent, les afficher
    if (offersState.hasOffers) {
      final topOffer = offersState.topOffer!;

      return Positioned(
        top: 100,
        left: 16,
        right: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BroadcastOfferCard(
              key: ValueKey('broadcast_offer_${topOffer.id}'),
              offer: topOffer,
            ),
            // Badge indiquant les offres restantes
            if (offersState.offers.length > 1)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${offersState.offers.length - 1} autre${offersState.offers.length > 2 ? 's' : ''} offre${offersState.offers.length > 2 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Fallback : ancien système de polling
    return const IncomingOrderCard();
  }
}
