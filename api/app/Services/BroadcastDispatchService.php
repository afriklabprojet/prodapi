<?php

namespace App\Services;

use App\Events\DeliveryOfferBroadcast;
use App\Events\DeliveryOfferTaken;
use App\Events\NoCourierFoundEvent;
use App\Jobs\ExpireDeliveryOffer;
use App\Models\Courier;
use App\Models\DeliveryOffer;
use App\Models\Order;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class BroadcastDispatchService
{
    /**
     * Configuration du broadcast multi-niveaux
     */
    const BROADCAST_CONFIG = [
        // Niveau 1: 3 meilleurs livreurs proches
        1 => [
            'radius_km' => 3,
            'max_couriers' => 3,
            'timeout_seconds' => 45,
            'bonus' => 0,
        ],
        // Niveau 2: 5 livreurs, rayon élargi
        2 => [
            'radius_km' => 5,
            'max_couriers' => 5,
            'timeout_seconds' => 45,
            'bonus' => 100,
        ],
        // Niveau 3: 10 livreurs, rayon encore plus large
        3 => [
            'radius_km' => 8,
            'max_couriers' => 10,
            'timeout_seconds' => 60,
            'bonus' => 200,
        ],
        // Niveau 4: Tous les livreurs disponibles
        4 => [
            'radius_km' => 15,
            'max_couriers' => null, // Pas de limite
            'timeout_seconds' => 90,
            'bonus' => 350,
        ],
    ];

    protected DynamicPricingService $pricingService;
    protected EtaService $etaService;

    public function __construct(
        DynamicPricingService $pricingService,
        EtaService $etaService
    ) {
        $this->pricingService = $pricingService;
        $this->etaService = $etaService;
    }

    /**
     * Créer et diffuser une offre de livraison pour une commande
     */
    public function createOffer(Order $order, int $level = 1): ?DeliveryOffer
    {
        if (!isset(self::BROADCAST_CONFIG[$level])) {
            Log::warning("BroadcastDispatch: Invalid level {$level}");
            return null;
        }

        $config = self::BROADCAST_CONFIG[$level];
        
        // Calculer les frais avec surge pricing
        $baseFee = $order->delivery_fee;
        $surgeFee = $this->pricingService->calculateSurgeFee($order);
        $bonusFee = $config['bonus'];

        // Trouver les livreurs éligibles
        $couriers = $this->findEligibleCouriers($order, $config);

        if ($couriers->isEmpty()) {
            Log::info("BroadcastDispatch: No couriers found for order {$order->id} at level {$level}");
            return $this->escalateToNextLevel($order, $level);
        }

        return DB::transaction(function () use ($order, $couriers, $config, $level, $baseFee, $surgeFee, $bonusFee) {
            // Créer l'offre
            $offer = DeliveryOffer::create([
                'order_id' => $order->id,
                'status' => DeliveryOffer::STATUS_PENDING,
                'broadcast_level' => $level,
                'base_fee' => $baseFee + $surgeFee,
                'bonus_fee' => $bonusFee,
                'expires_at' => now()->addSeconds($config['timeout_seconds']),
            ]);

            // Attacher les livreurs ciblés
            $attachData = $couriers->mapWithKeys(function ($courier) {
                return [
                    $courier->id => [
                        'status' => 'notified',
                        'notified_at' => now(),
                    ]
                ];
            })->toArray();

            $offer->targetedCouriers()->attach($attachData);

            // Planifier l'expiration
            ExpireDeliveryOffer::dispatch($offer)
                ->delay(now()->addSeconds($config['timeout_seconds']));

            // Diffuser aux livreurs
            $this->broadcastToAllCouriers($offer, $couriers);

            Log::info("BroadcastDispatch: Created offer {$offer->id} for order {$order->id} at level {$level}, targeting " . $couriers->count() . " couriers");

            return $offer;
        });
    }

    /**
     * Trouver les livreurs éligibles pour une commande
     */
    protected function findEligibleCouriers(Order $order, array $config): Collection
    {
        $pharmacy = $order->pharmacy;
        
        if (!$pharmacy || !$pharmacy->latitude || !$pharmacy->longitude) {
            return collect();
        }

        $query = Courier::available()
            ->nearLocation($pharmacy->latitude, $pharmacy->longitude, $config['radius_km'])
            ->whereNotNull('last_location_update')
            ->where('last_location_update', '>=', now()->subMinutes(10))
            ->where('kyc_status', 'verified')
            ->orderByPriority();

        // Exclure les livreurs qui ont déjà refusé cette commande
        $previousOffer = DeliveryOffer::where('order_id', $order->id)
            ->where('status', DeliveryOffer::STATUS_EXPIRED)
            ->latest()
            ->first();

        if ($previousOffer) {
            $rejectedIds = $previousOffer->rejectedCouriers()->pluck('courier_id');
            $query->whereNotIn('id', $rejectedIds);
        }

        // Limiter le nombre si configuré
        if ($config['max_couriers']) {
            $query->limit($config['max_couriers']);
        }

        return $query->get();
    }

    /**
     * Passer au niveau suivant si aucun livreur n'est trouvé
     */
    protected function escalateToNextLevel(Order $order, int $currentLevel): ?DeliveryOffer
    {
        $nextLevel = $currentLevel + 1;

        if (!isset(self::BROADCAST_CONFIG[$nextLevel])) {
            Log::warning("BroadcastDispatch: No couriers available for order {$order->id} at any level");
            return null;
        }

        return $this->createOffer($order, $nextLevel);
    }

    /**
     * Diffuser l'offre à tous les livreurs ciblés
     */
    protected function broadcastToAllCouriers(DeliveryOffer $offer, Collection $couriers): void
    {
        foreach ($couriers as $courier) {
            event(new DeliveryOfferBroadcast($offer, $courier));
        }
    }

    /**
     * Accepter une offre
     */
    public function acceptOffer(DeliveryOffer $offer, Courier $courier): array
    {
        if ($offer->status !== DeliveryOffer::STATUS_PENDING) {
            return [
                'success' => false,
                'message' => 'Cette offre n\'est plus disponible',
            ];
        }

        if ($offer->is_expired) {
            return [
                'success' => false,
                'message' => 'Cette offre a expiré',
            ];
        }

        // Vérifier que le livreur fait partie des ciblés
        if (!$offer->targetedCouriers->contains($courier)) {
            return [
                'success' => false,
                'message' => 'Vous n\'êtes pas éligible pour cette offre',
            ];
        }

        // Accepter l'offre
        $accepted = $offer->accept($courier);

        if (!$accepted) {
            return [
                'success' => false,
                'message' => 'Impossible d\'accepter cette offre',
            ];
        }

        // Créer la livraison
        $delivery = app(CourierAssignmentService::class)->createDeliveryFromOffer($offer, $courier);

        // Notifier les autres livreurs que l'offre est prise
        $this->notifyOfferTaken($offer);

        // Mettre à jour les métriques du livreur
        $this->updateCourierAcceptanceMetrics($courier);

        return [
            'success' => true,
            'delivery' => $delivery,
            'total_fee' => $offer->total_fee,
        ];
    }

    /**
     * Refuser une offre
     */
    public function rejectOffer(DeliveryOffer $offer, Courier $courier, ?string $reason = null): void
    {
        $offer->reject($courier, $reason);
        
        // Mettre à jour les métriques (un refus impacte le taux d'acceptation)
        $this->updateCourierRejectionMetrics($courier);
    }

    /**
     * Marquer l'offre comme vue
     */
    public function markOfferViewed(DeliveryOffer $offer, Courier $courier): void
    {
        $offer->markAsViewed($courier);
    }

    /**
     * Gérer l'expiration d'une offre
     */
    public function handleExpiredOffer(DeliveryOffer $offer): void
    {
        if ($offer->status !== DeliveryOffer::STATUS_PENDING) {
            return;
        }

        $offer->markAsExpired();

        // Escalader au niveau suivant
        $nextLevel = $offer->broadcast_level + 1;

        if (isset(self::BROADCAST_CONFIG[$nextLevel])) {
            Log::info("BroadcastDispatch: Escalating order {$offer->order_id} to level {$nextLevel}");
            $this->createOffer($offer->order, $nextLevel);
        } else {
            // Aucun livreur trouvé après tous les niveaux
            $offer->update(['status' => DeliveryOffer::STATUS_NO_COURIER]);
            
            // Notifier l'équipe via event broadcast
            event(new NoCourierFoundEvent($offer));
            
            Log::error("BroadcastDispatch: No courier found for order {$offer->order_id} after all levels");
        }
    }

    /**
     * Notifier les autres livreurs que l'offre est prise
     */
    protected function notifyOfferTaken(DeliveryOffer $offer): void
    {
        $acceptedCourierId = $offer->accepted_by_courier_id;

        // Récupérer les IDs des livreurs qui ont été notifiés (sauf celui qui a accepté)
        $notifiedCourierIds = $offer->targetedCouriers()
            ->wherePivotIn('status', ['notified', 'viewed'])
            ->pluck('courier_id')
            ->toArray();

        // Broadcast via Laravel Broadcasting (Pusher/Reverb/Ably)
        if (!empty($notifiedCourierIds)) {
            broadcast(new DeliveryOfferTaken($offer, $notifiedCourierIds, $acceptedCourierId));
            
            Log::info("BroadcastDispatch: Notified " . count($notifiedCourierIds) . " couriers that offer {$offer->id} was taken");
        }

        // Mettre à jour le statut dans le pivot
        $offer->targetedCouriers()
            ->where('courier_id', '!=', $acceptedCourierId)
            ->wherePivotIn('status', ['notified', 'viewed'])
            ->each(function ($courier) use ($offer) {
                $offer->targetedCouriers()->updateExistingPivot($courier->id, [
                    'status' => 'offer_taken',
                    'updated_at' => now(),
                ]);
            });
    }

    /**
     * Mettre à jour les métriques d'acceptation
     */
    protected function updateCourierAcceptanceMetrics(Courier $courier): void
    {
        // Calculer le nouveau taux d'acceptation
        $totalOffers = $courier->deliveryOffers()->count();
        $acceptedOffers = $courier->acceptedOffers()->count();

        if ($totalOffers > 0) {
            $acceptanceRate = ($acceptedOffers / $totalOffers) * 100;
            $courier->update(['acceptance_rate' => round($acceptanceRate, 2)]);
        }

        // Mettre à jour le streak
        $courier->updateStreak();
    }

    /**
     * Mettre à jour les métriques de refus
     */
    protected function updateCourierRejectionMetrics(Courier $courier): void
    {
        // Recalculer le taux d'acceptation
        $totalOffers = $courier->deliveryOffers()->count();
        $acceptedOffers = $courier->acceptedOffers()->count();

        if ($totalOffers > 0) {
            $acceptanceRate = ($acceptedOffers / $totalOffers) * 100;
            $courier->update(['acceptance_rate' => round($acceptanceRate, 2)]);
        }
    }

    /**
     * Obtenir les offres en attente pour un livreur
     */
    public function getPendingOffersForCourier(Courier $courier): Collection
    {
        return DeliveryOffer::pending()
            ->forCourier($courier->id)
            ->with(['order.pharmacy', 'order.client'])
            ->whereHas('targetedCouriers', function ($q) use ($courier) {
                $q->where('courier_id', $courier->id)
                    ->whereIn('delivery_offer_courier.status', ['notified', 'viewed']);
            })
            ->get()
            ->map(function ($offer) use ($courier) {
                // Ajouter l'ETA estimé
                $offer->estimated_eta = $this->etaService->estimatePickupEta(
                    $courier,
                    $offer->order->pharmacy
                );
                return $offer;
            });
    }
}
