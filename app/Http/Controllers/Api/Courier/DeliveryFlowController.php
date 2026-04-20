<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use App\Models\Order;
use App\Services\WalletService;
use App\Services\WaitingFeeService;
use App\Services\FirestoreService;
use App\Actions\CalculateCommissionAction;
use App\Events\DeliveryFlowEvent;
use App\Notifications\CourierArrivedNotification;
use App\Notifications\OrderDeliveredToPharmacyNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

/**
 * Full driver delivery flow with granular states and OTP validation.
 *
 * States: pending → accepted → en_route_pickup → arrived_pickup → picked_up → en_route_delivery → arrived_client → delivered
 *
 * OTP codes:
 * - pickup_code: 4 digits, generated on accept, validated at pickup
 * - delivery_code: 4 digits (existing on Order), validated at delivery
 */
class DeliveryFlowController extends Controller
{
    public function __construct(
        private WalletService $walletService,
        private WaitingFeeService $waitingFeeService,
        private CalculateCommissionAction $calculateCommission,
        private FirestoreService $firestoreService
    ) {}

    // ─── ACCEPT ─────────────────────────────────────────────────

    /**
     * Accept a delivery and generate pickup OTP.
     * pending → accepted
     */
    public function accept(Request $request, $id)
    {
        $courier = $this->getCourier($request);

        $delivery = DB::transaction(function () use ($id, $courier) {
            $delivery = Delivery::where('status', 'pending')
                ->lockForUpdate()
                ->findOrFail($id);

            // Generate 4-digit pickup code
            $pickupCode = str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);

            $metadata = $delivery->metadata ?? [];
            $metadata['pickup_code'] = $pickupCode;

            $delivery->update([
                'courier_id' => $courier->id,
                'status' => 'accepted',
                'accepted_at' => now(),
                'metadata' => $metadata,
            ]);

            return $delivery->fresh(['order.pharmacy', 'order.customer']);
        });

        // Firestore sync
        $this->firestoreService->updateDeliveryStatus(
            $delivery->order_id, 'accepted', $courier->id, $delivery->id
        );

        // Broadcast event
        DeliveryFlowEvent::dispatch($delivery, 'accepted', $courier->id);

        $commissionAmount = WalletService::getCommissionAmount();
        $deliveryFee = (float) ($delivery->order->delivery_fee ?? WalletService::getDeliveryFeeBase());

        return response()->json([
            'success' => true,
            'message' => 'Livraison acceptée ! Dirigez-vous vers la pharmacie.',
            'data' => [
                'delivery_id' => $delivery->id,
                'order_id' => $delivery->order_id, // Pour synchronisation Firestore
                'status' => 'accepted',
                'pickup_code' => $delivery->metadata['pickup_code'],
                'delivery_code' => $delivery->order->delivery_code,
                'estimated_earnings' => max(0, $deliveryFee - $commissionAmount),
                'pharmacy' => [
                    'name' => $delivery->order->pharmacy->name ?? 'Pharmacie',
                    'address' => $delivery->order->pharmacy->address ?? '',
                    'phone' => $delivery->order->pharmacy->phone ?? '',
                    'latitude' => (float) ($delivery->pickup_latitude ?? 0),
                    'longitude' => (float) ($delivery->pickup_longitude ?? 0),
                ],
                'customer' => [
                    'name' => $delivery->order->customer->name ?? 'Client',
                    'address' => $delivery->order->delivery_address ?? '',
                    'latitude' => (float) ($delivery->dropoff_latitude ?? 0),
                    'longitude' => (float) ($delivery->dropoff_longitude ?? 0),
                ],
            ],
        ]);
    }

    // ─── EN ROUTE PICKUP ────────────────────────────────────────

    /**
     * Driver starts navigating to pharmacy.
     * accepted → en_route_pickup
     */
    public function startNavigation(Request $request, $id)
    {
        $courier = $this->getCourier($request);
        $delivery = $this->getDelivery($courier, $id, ['accepted']);

        $delivery->update(['status' => 'en_route_pickup']);

        $this->firestoreService->updateDeliveryStatus(
            $delivery->order_id, 'en_route_pickup', $courier->id, $delivery->id
        );

        DeliveryFlowEvent::dispatch($delivery, 'en_route_pickup', $courier->id);

        return response()->json([
            'success' => true,
            'message' => 'Navigation démarrée vers la pharmacie.',
            'data' => ['status' => 'en_route_pickup'],
        ]);
    }

    // ─── ARRIVED PICKUP ─────────────────────────────────────────

    /**
     * Driver arrived at pharmacy.
     * en_route_pickup → arrived_pickup
     */
    public function arrivedPickup(Request $request, $id)
    {
        $courier = $this->getCourier($request);
        $delivery = $this->getDelivery($courier, $id, ['en_route_pickup', 'accepted']);

        $delivery->update(['status' => 'arrived_pickup']);

        $this->firestoreService->updateDeliveryStatus(
            $delivery->order_id, 'arrived_pickup', $courier->id, $delivery->id
        );

        DeliveryFlowEvent::dispatch($delivery, 'arrived_pickup', $courier->id);

        return response()->json([
            'success' => true,
            'message' => 'Arrivé à la pharmacie. Utilisez le code pour récupérer la commande.',
            'data' => [
                'status' => 'arrived_pickup',
                'pickup_code' => $delivery->metadata['pickup_code'] ?? null,
            ],
        ]);
    }

    // ─── CONFIRM PICKUP (OTP) ───────────────────────────────────

    /**
     * Confirm pickup with OTP code from pharmacy.
     * arrived_pickup → picked_up
     */
    public function confirmPickup(Request $request, $id)
    {
        $validated = $request->validate([
            'pickup_code' => 'required|string|size:4',
        ], [
            'pickup_code.required' => 'Le code de retrait est requis',
            'pickup_code.size' => 'Le code doit contenir 4 chiffres',
        ]);

        $courier = $this->getCourier($request);
        $delivery = $this->getDelivery($courier, $id, ['arrived_pickup', 'en_route_pickup', 'accepted']);

        $storedCode = $delivery->metadata['pickup_code'] ?? null;

        if (!$storedCode || $storedCode !== $validated['pickup_code']) {
            return response()->json([
                'success' => false,
                'message' => 'Code de retrait incorrect.',
            ], 400);
        }

        $delivery->update([
            'status' => 'picked_up',
            'picked_up_at' => now(),
        ]);

        $delivery->order->update(['status' => 'in_delivery']);

        $this->firestoreService->updateDeliveryStatus(
            $delivery->order_id, 'picked_up', $courier->id, $delivery->id
        );

        DeliveryFlowEvent::dispatch($delivery, 'picked_up', $courier->id);

        return response()->json([
            'success' => true,
            'message' => 'Commande récupérée ! Dirigez-vous vers le client.',
            'data' => ['status' => 'picked_up'],
        ]);
    }

    // ─── EN ROUTE DELIVERY ──────────────────────────────────────

    /**
     * Driver starts navigating to customer.
     * picked_up → en_route_delivery
     */
    public function startDeliveryNavigation(Request $request, $id)
    {
        $courier = $this->getCourier($request);
        $delivery = $this->getDelivery($courier, $id, ['picked_up']);

        $delivery->update(['status' => 'in_transit']);

        $this->firestoreService->updateDeliveryStatus(
            $delivery->order_id, 'en_route_delivery', $courier->id, $delivery->id
        );

        DeliveryFlowEvent::dispatch($delivery, 'en_route_delivery', $courier->id);

        return response()->json([
            'success' => true,
            'message' => 'Navigation démarrée vers le client.',
            'data' => ['status' => 'en_route_delivery'],
        ]);
    }

    // ─── ARRIVED CLIENT ─────────────────────────────────────────

    /**
     * Driver arrived at customer location.
     * in_transit → arrived_client
     */
    public function arrivedClient(Request $request, $id)
    {
        $courier = $this->getCourier($request);
        $delivery = $this->getDelivery($courier, $id, ['in_transit', 'picked_up']);

        $delivery->update([
            'waiting_started_at' => $delivery->waiting_started_at ?? now(),
        ]);

        $delivery = $delivery->fresh();
        $waitingInfo = $this->waitingFeeService->getWaitingInfo($delivery);

        // Notify customer
        if ($delivery->order->user) {
            $delivery->order->user->notify(new CourierArrivedNotification(
                $delivery,
                $waitingInfo['timeout_minutes'],
                $waitingInfo['free_minutes'],
                $waitingInfo['fee_per_minute'],
                'customer'
            ));
        }

        $this->firestoreService->updateDeliveryStatus(
            $delivery->order_id, 'arrived_client', $courier->id, $delivery->id
        );

        DeliveryFlowEvent::dispatch($delivery, 'arrived_client', $courier->id);

        return response()->json([
            'success' => true,
            'message' => 'Arrivé chez le client. Demandez le code de livraison.',
            'data' => [
                'status' => 'arrived_client',
                'delivery_code_hint' => 'Demandez le code 4 chiffres au client.',
            ],
        ]);
    }

    // ─── CONFIRM DELIVERY (OTP) ─────────────────────────────────

    /**
     * Confirm delivery with OTP code from customer.
     * arrived_client / in_transit / picked_up → delivered
     */
    public function confirmDelivery(Request $request, $id)
    {
        $validated = $request->validate([
            'confirmation_code' => 'required|string|size:4',
            'delivery_proof_image' => 'nullable|string',
        ], [
            'confirmation_code.required' => 'Le code de confirmation est requis',
            'confirmation_code.size' => 'Le code doit contenir 4 chiffres',
        ]);

        $courier = $this->getCourier($request);

        try {
            $result = DB::transaction(function () use ($id, $validated, $courier) {
                $delivery = $courier->deliveries()
                    ->with('order')
                    ->lockForUpdate()
                    ->find($id);

                if (!$delivery) {
                    throw new \Exception('Livraison introuvable', 404);
                }

                if ($delivery->status === 'delivered') {
                    throw new \Exception('Cette livraison a déjà été validée', 409);
                }

                $allowedStatuses = ['picked_up', 'in_transit', 'arrived_client'];
                if (!in_array($delivery->status, $allowedStatuses)) {
                    throw new \Exception('Statut invalide: ' . $delivery->status, 400);
                }

                if ($delivery->order->delivery_code !== $validated['confirmation_code']) {
                    throw new \Exception('Code de confirmation incorrect', 400);
                }

                if (!$this->walletService->canCompleteDelivery($courier)) {
                    throw new \Exception('Solde insuffisant. Veuillez recharger.', 402);
                }

                $delivery->update([
                    'status' => 'delivered',
                    'delivered_at' => now(),
                    'delivery_proof_image' => $validated['delivery_proof_image'] ?? null,
                    'waiting_ended_at' => $delivery->waiting_started_at ? now() : null,
                ]);

                $delivery->order->update([
                    'status' => 'delivered',
                    'delivered_at' => now(),
                ]);

                $deliveryFee = $delivery->order->delivery_fee ?? 0;
                $earningTransaction = null;

                if ($deliveryFee > 0) {
                    $earningTransaction = $this->walletService->creditDeliveryEarning($courier, $delivery, $deliveryFee);
                }

                $commissionTransaction = $this->walletService->deductCommission($courier, $delivery);

                // Notify pharmacy
                $pharmacy = $delivery->order->pharmacy;
                if ($pharmacy) {
                    foreach ($pharmacy->users as $pharmacyUser) {
                        \App\Jobs\SendNotificationJob::dispatch(
                            $pharmacyUser,
                            new OrderDeliveredToPharmacyNotification($delivery->order, $delivery),
                            ['order_id' => $delivery->order->id]
                        )->onQueue('notifications');
                    }
                }

                try {
                    $this->calculateCommission->execute($delivery->order);
                } catch (\Exception $e) {
                    Log::error('Commission calculation error', [
                        'order_id' => $delivery->order->id,
                        'error' => $e->getMessage(),
                    ]);
                }

                return [
                    'commission' => $commissionTransaction,
                    'earning' => $earningTransaction,
                    'delivery_fee' => $deliveryFee,
                    'delivery' => $delivery,
                ];
            });

            $this->firestoreService->updateDeliveryStatus(
                $result['delivery']->order_id, 'delivered', $courier->id, $result['delivery']->id
            );

            DeliveryFlowEvent::dispatch($result['delivery'], 'delivered', $courier->id);

            $balance = $this->walletService->getBalance($courier);
            $commissionAmount = WalletService::getCommissionAmount();

            return response()->json([
                'success' => true,
                'message' => 'Livraison effectuée avec succès !',
                'data' => [
                    'status' => 'delivered',
                    'earning' => [
                        'amount' => $result['delivery_fee'],
                        'reference' => $result['earning']?->reference,
                    ],
                    'commission' => [
                        'amount' => $commissionAmount,
                        'reference' => $result['commission']->reference,
                    ],
                    'net_earning' => $result['delivery_fee'] - $commissionAmount,
                    'wallet' => [
                        'balance' => $balance['balance'],
                        'currency' => $balance['currency'],
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            $code = $e->getCode();
            if ($code < 100 || $code > 599) $code = 400;

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], $code);
        }
    }

    // ─── FLOW STATUS ────────────────────────────────────────────

    /**
     * Get current flow status with all context needed for the driver UI.
     */
    public function flowStatus(Request $request, $id)
    {
        $courier = $this->getCourier($request);
        $delivery = $courier->deliveries()
            ->with(['order.pharmacy', 'order.customer'])
            ->findOrFail($id);

        $commissionAmount = WalletService::getCommissionAmount();
        $deliveryFee = (float) ($delivery->order->delivery_fee ?? WalletService::getDeliveryFeeBase());

        // Map internal statuses to flow states
        $flowState = match ($delivery->status) {
            'pending' => 'pending',
            'accepted' => 'accepted',
            'assigned' => 'accepted',
            'en_route_pickup' => 'en_route_pickup',
            'arrived_pickup' => 'arrived_pickup',
            'picked_up' => 'picked_up',
            'in_transit' => 'en_route_delivery',
            'arrived_client' => 'arrived_client',
            'delivered' => 'delivered',
            default => $delivery->status,
        };

        return response()->json([
            'success' => true,
            'data' => [
                'delivery_id' => $delivery->id,
                'order_id' => $delivery->order_id, // Pour synchronisation Firestore
                'flow_state' => $flowState,
                'raw_status' => $delivery->status,
                'pickup_code' => $delivery->metadata['pickup_code'] ?? null,
                'has_delivery_code' => !empty($delivery->order->delivery_code),
                'estimated_earnings' => max(0, $deliveryFee - $commissionAmount),
                'delivery_fee' => $deliveryFee,
                'distance_km' => (float) ($delivery->estimated_distance ?? 0),
                'estimated_duration' => (int) ($delivery->estimated_duration ?? 0),
                'pharmacy' => [
                    'name' => $delivery->order->pharmacy->name ?? 'Pharmacie',
                    'address' => $delivery->order->pharmacy->address ?? '',
                    'phone' => $delivery->order->pharmacy->phone ?? '',
                    'latitude' => (float) ($delivery->pickup_latitude ?? 0),
                    'longitude' => (float) ($delivery->pickup_longitude ?? 0),
                ],
                'customer' => [
                    'name' => $delivery->order->customer->name ?? 'Client',
                    'phone' => $delivery->order->customer->phone ?? '',
                    'address' => $delivery->order->delivery_address ?? '',
                    'latitude' => (float) ($delivery->dropoff_latitude ?? 0),
                    'longitude' => (float) ($delivery->dropoff_longitude ?? 0),
                ],
                'timestamps' => [
                    'accepted_at' => $delivery->accepted_at?->toIso8601String(),
                    'picked_up_at' => $delivery->picked_up_at?->toIso8601String(),
                    'delivered_at' => $delivery->delivered_at?->toIso8601String(),
                    'waiting_started_at' => $delivery->waiting_started_at?->toIso8601String(),
                ],
            ],
        ]);
    }

    // ─── HELPERS ────────────────────────────────────────────────

    private function getCourier(Request $request)
    {
        $courier = $request->user()->courier;
        if (!$courier) {
            abort(403, 'Profil livreur non trouvé');
        }
        return $courier;
    }

    private function getDelivery($courier, $id, array $allowedStatuses)
    {
        $delivery = $courier->deliveries()->with(['order.pharmacy', 'order.customer', 'order.user'])->findOrFail($id);

        if (!in_array($delivery->status, $allowedStatuses)) {
            abort(400, "Action impossible. Statut actuel: {$delivery->status}");
        }

        return $delivery;
    }
}
