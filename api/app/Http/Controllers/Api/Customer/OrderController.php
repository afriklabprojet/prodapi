<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Prescription;
use App\Models\Setting;
use App\Notifications\NewOrderReceivedNotification;
use App\Notifications\OrderStatusNotification;
use App\Enums\JekoPaymentMethod;
use App\Services\BusinessEventService;
use App\Services\JekoPaymentService;
use App\Services\WalletService;
use App\Services\WaitingFeeService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class OrderController extends Controller
{
    protected WaitingFeeService $waitingFeeService;

    public function __construct(WaitingFeeService $waitingFeeService, private JekoPaymentService $jekoService)
    {
        $this->waitingFeeService = $waitingFeeService;
    }

    /**
     * Get customer orders
     */
    public function index(Request $request)
    {
        $perPage = min($request->input('per_page', 15), 50); // Max 50 par page
        
        $orders = $request->user()->orders()
            ->withCount('items')
            ->with(['pharmacy:id,name,phone', 'delivery', 'payments'])
            ->latest()
            ->paginate($perPage);

        $formattedOrders = $orders->getCollection()->map(function ($order) {
            return [
                'id' => (int) $order->id,
                'reference' => $order->reference,
                'pharmacy' => [
                    'id' => (int) ($order->pharmacy->id ?? 0),
                    'name' => $order->pharmacy->name ?? 'Pharmacie supprimée',
                    'phone' => $order->pharmacy->phone ?? '',
                ],
                'status' => $order->status,
                'payment_status' => $order->payment_status ?? 'pending',
                'delivery_code' => $order->delivery_code,
                'payment_mode' => $order->payment_mode,
                'total_amount' => (float) $order->total_amount,
                'currency' => $order->currency,
                'delivery_address' => $order->delivery_address,
                'items_count' => (int) $order->items_count,
                'created_at' => $order->created_at,
                'paid_at' => $order->paid_at,
                'delivered_at' => $order->delivered_at,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $formattedOrders,
            'meta' => [
                'current_page' => $orders->currentPage(),
                'last_page' => $orders->lastPage(),
                'per_page' => $orders->perPage(),
                'total' => $orders->total(),
            ],
        ]);
    }

    /**
     * Create a new order
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'pharmacy_id' => 'required|exists:pharmacies,id',
            'items' => 'required|array|min:1',
            'items.*.id' => 'nullable|exists:products,id',
            'items.*.name' => 'required|string',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.price' => 'required_without:items.*.unit_price|numeric|min:0',
            'items.*.unit_price' => 'required_without:items.*.price|numeric|min:0',
            'items.*.total_price' => 'nullable|numeric|min:0',
            'prescription_image' => 'nullable|string',
            'prescription_id' => 'nullable|exists:prescriptions,id', // ID de la prescription uploadée via checkout
            'customer_notes' => 'nullable|string',
            'delivery_address' => 'required|string',
            'delivery_city' => 'nullable|string',
            'delivery_latitude' => 'nullable|numeric',
            'delivery_longitude' => 'nullable|numeric',
            'customer_phone' => 'required|string',
            'payment_mode' => 'required|in:mobile_money,card,platform,cash,on_delivery',
            'promo_code' => 'nullable|string|max:50',
        ]);

        // Vérifier que le mode de paiement est activé dans les paramètres
        $modeMap = [
            'platform' => 'payment_mode_platform_enabled',
            'mobile_money' => 'payment_mode_platform_enabled',
            'card' => 'payment_mode_platform_enabled',
            'cash' => 'payment_mode_cash_enabled',
            'on_delivery' => 'payment_mode_cash_enabled',
        ];
        $settingKey = $modeMap[$validated['payment_mode']] ?? 'payment_mode_platform_enabled';
        if (!Setting::get($settingKey, true)) {
            return $this->error('Ce mode de paiement n\'est pas disponible actuellement.', 422);
        }

        // Normaliser le payment_mode
        $paymentMode = match($validated['payment_mode']) {
            'platform' => 'mobile_money',
            'on_delivery' => 'cash',
            default => $validated['payment_mode'],
        };
        $validated['payment_mode'] = $paymentMode;

        // Normaliser les items pour accepter price ou unit_price
        $items = collect($validated['items'])->map(function ($item) {
            if (isset($item['unit_price']) && !isset($item['price'])) {
                $item['price'] = $item['unit_price'];
            }
            return $item;
        })->toArray();

        try {
            $order = DB::transaction(function () use ($request, $validated, $items) {
                // Preload all products at once with lock to prevent race condition
                $productIds = collect($items)->pluck('id')->filter()->unique()->values()->toArray();
                $products = !empty($productIds) 
                    ? \App\Models\Product::whereIn('id', $productIds)->lockForUpdate()->get()->keyBy('id') 
                    : collect();

                // Validate stock INSIDE transaction (atomic)
                foreach ($items as $item) {
                    if (isset($item['id']) && $products->has($item['id'])) {
                        $product = $products->get($item['id']);
                        if (!$product->is_available) {
                            throw new \Exception("Le produit {$product->name} n'est pas disponible");
                        }
                        if ($product->stock_quantity < $item['quantity']) {
                            throw new \Exception("Stock insuffisant pour le produit {$product->name}");
                        }
                    }
                }

                // Calculate totals
                $subtotal = 0;
                foreach ($items as $item) {
                    $price = $item['price'];
                    if (isset($item['id']) && $products->has($item['id'])) {
                        $price = $products->get($item['id'])->price;
                    }
                    $subtotal += $item['quantity'] * $price;
                }

                // Récupérer les frais de livraison calculés selon la distance
                $deliveryFee = $this->calculateDeliveryFee(
                    $validated['pharmacy_id'],
                    $validated['delivery_latitude'] ?? null,
                    $validated['delivery_longitude'] ?? null
                );
                
                // Calculer tous les frais (service + paiement)
                $allFees = WalletService::calculateAllFees($subtotal, $deliveryFee, $validated['payment_mode']);
                
                $serviceFee = $allFees['service_fee'];
                $paymentFee = $allFees['payment_fee'];
                $totalAmount = $allFees['total_amount'];

                // Appliquer le code promo si fourni
                $promoDiscount = 0;
                $promoCodeId = null;
                if (!empty($validated['promo_code'])) {
                    $promoResult = \App\Http\Controllers\Api\PromoCodeController::applyPromoCode(
                        $validated['promo_code'],
                        $request->user()->id,
                        $subtotal
                    );
                    if ($promoResult) {
                        $promoDiscount = $promoResult['discount'];
                        $promoCodeId = $promoResult['promo_code_id'];
                        $totalAmount = max(0, $totalAmount - $promoDiscount);
                    }
}

                // Create order
                $order = Order::create([
                    'reference' => Order::generateReference(),
                    'pharmacy_id' => $validated['pharmacy_id'],
                    'customer_id' => $request->user()->id,
                    'status' => 'pending',
                    'payment_mode' => $validated['payment_mode'],
                    'subtotal' => $subtotal,
                    'delivery_fee' => $deliveryFee,
                    'service_fee' => $serviceFee,
                    'payment_fee' => $paymentFee,
                    'total_amount' => $totalAmount,
                    'currency' => 'XOF',
                    'customer_notes' => $validated['customer_notes'] ?? null,
                    'prescription_image' => $validated['prescription_image'] ?? null,
                    'delivery_address' => $validated['delivery_address'],
                    'delivery_city' => $validated['delivery_city'] ?? null,
                    'delivery_latitude' => $validated['delivery_latitude'] ?? null,
                    'delivery_longitude' => $validated['delivery_longitude'] ?? null,
                    'customer_phone' => $validated['customer_phone'],
                    'promo_code_id' => $promoCodeId,
                    'promo_discount' => $promoDiscount,
                ]);

                // Create order items using preloaded products + decrement stock
                foreach ($items as $item) {
                    $price = $item['price'];
                    if (isset($item['id']) && $products->has($item['id'])) {
                        $price = $products->get($item['id'])->price;
                    }
                    $order->items()->create([
                        'product_id' => $item['id'] ?? null,
                        'product_name' => $item['name'],
                        'quantity' => $item['quantity'],
                        'unit_price' => $price,
                        'total_price' => $item['quantity'] * $price,
                    ]);

                    // Décrémenter le stock (atomic, dans la transaction)
                    if (isset($item['id']) && $products->has($item['id'])) {
                        $products->get($item['id'])->decrement('stock_quantity', $item['quantity']);
                    }
                }

                // === LIER LA PRESCRIPTION À LA COMMANDE (DANS LA TRANSACTION) ===
                if (!empty($validated['prescription_id'])) {
                    $prescription = Prescription::where('id', $validated['prescription_id'])
                        ->where('customer_id', $request->user()->id)
                        ->whereNull('order_id') // S'assurer qu'elle n'est pas déjà liée
                        ->first();
                    
                    if ($prescription) {
                        $prescription->update([
                            'order_id' => $order->id,
                            'status' => 'processing', // En cours de traitement avec la commande
                        ]);
                        
                        Log::info('Prescription liée à la commande', [
                            'prescription_id' => $prescription->id,
                            'order_id' => $order->id,
                            'order_reference' => $order->reference,
                        ]);
                    } else {
                        Log::warning('Prescription non trouvée ou déjà liée', [
                            'prescription_id' => $validated['prescription_id'],
                            'customer_id' => $request->user()->id,
                        ]);
                    }
                }

                return $order;
            });

            // === NOTIFIER LA PHARMACIE POUR PAIEMENT CASH ===
            // Pour les paiements en ligne, la notification est envoyée après confirmation du paiement
            // Pour les paiements cash, on notifie immédiatement car la commande est valide
            if ($order->payment_mode === 'cash') {
                $order->load(['items', 'customer', 'pharmacy.users']);
                
                // Notifier tous les utilisateurs de la pharmacie
                foreach ($order->pharmacy?->users ?? [] as $pharmacyUser) {
                    $pharmacyUser->notify(new NewOrderReceivedNotification($order));
                }
                
                Log::info('Notification nouvelle commande cash envoyée à la pharmacie', [
                    'order_id' => $order->id,
                    'order_reference' => $order->reference,
                    'pharmacy_id' => $order->pharmacy_id,
                ]);
            }

            // Track order creation
            BusinessEventService::orderCreated(
                $request->user()->id,
                $order->id,
                (float) $order->total_amount,
                $order->payment_mode
            );

            return response()->json([
                'success' => true,
                'message' => 'Commande créée avec succès',
                'data' => [
                    'order_id' => $order->id,
                    'reference' => $order->reference,
                    'total_amount' => (float) $order->total_amount,
                    'currency' => 'XOF',
                    'status' => $order->status,
                    'payment_mode' => $order->payment_mode,
                    'delivery_code' => $order->delivery_code,
                    'next_step' => $order->payment_mode === 'cash'
                        ? 'Votre commande a été envoyée à la pharmacie.'
                        : 'Procédez au paiement pour confirmer votre commande.',
                ],
            ], 201);

        } catch (\Exception $e) {
            // Stock/disponibilité errors → 422, autres → 500
            $isStockError = str_contains($e->getMessage(), 'Stock insuffisant') 
                         || str_contains($e->getMessage(), "n'est pas disponible");

            if ($isStockError) {
                return response()->json([
                    'success' => false,
                    'message' => $e->getMessage(),
                    'errors' => ['items' => [$e->getMessage()]],
                ], 422);
            }

            Log::error('Order creation failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => $request->user()->id,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de la commande',
            ], 500);
        }
    }

    /**
     * Get order details
     */
    public function show(Request $request, $id)
    {
        $order = $request->user()->orders()
            ->with(['pharmacy', 'items', 'delivery.courier.user', 'payments'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => (int) $order->id,
                'reference' => $order->reference,
                'status' => $order->status,
                'payment_status' => $order->payment_status ?? 'pending',
                'delivery_code' => $order->delivery_code,
                'payment_mode' => $order->payment_mode,
                'pharmacy' => [
                    'id' => (int) ($order->pharmacy->id ?? 0),
                    'name' => $order->pharmacy->name ?? 'Pharmacie supprimée',
                    'phone' => $order->pharmacy->phone ?? '',
                    'address' => $order->pharmacy->address ?? '',
                ],
                'items' => $order->items->map(fn($item) => [
                    'product_name' => $item->product_name,
                    'quantity' => (int) $item->quantity,
                    'unit_price' => (float) $item->unit_price,
                    'total_price' => (float) $item->total_price,
                ])->values(),
                'subtotal' => (float) $order->subtotal,
                'delivery_fee' => (float) $order->delivery_fee,
                'total_amount' => (float) $order->total_amount,
                'currency' => $order->currency,
                'delivery_address' => $order->delivery_address,
                'customer_phone' => $order->customer_phone,
                'customer_notes' => $order->customer_notes,
                'prescription_image' => $order->prescription_image,
                'delivery' => $order->delivery ? [
                    'id' => $order->delivery->id,
                    'status' => $order->delivery->status,
                    'estimated_distance' => (float) $order->delivery->estimated_distance,
                    'estimated_duration' => $order->delivery->estimated_duration, // e.g., "15 min" or integer
                    'courier' => $order->delivery->courier ? [
                        'id' => (int) $order->delivery->courier->id,
                        'name' => $order->delivery->courier->user->name ?? 'Coursier',
                        'phone' => $order->delivery->courier->user->phone ?? '', 
                        'phone_courier' => $order->delivery->courier->phone,
                        'avatar' => $order->delivery->courier->user->avatar ?? null, 
                        'vehicle_type' => $order->delivery->courier->vehicle_type,
                        'vehicle_number' => $order->delivery->courier->vehicle_number,
                        'rating' => (float) $order->delivery->courier->rating,
                        'completed_deliveries' => (int) $order->delivery->courier->completed_deliveries,
                        'latitude' => (float) $order->delivery->courier->latitude,
                        'longitude' => (float) $order->delivery->courier->longitude,
                    ] : null,
                ] : null,
                'created_at' => $order->created_at,
                'confirmed_at' => $order->confirmed_at,
                'paid_at' => $order->paid_at,
                'delivered_at' => $order->delivered_at,
                'cancelled_at' => $order->cancelled_at,
                'cancellation_reason' => $order->cancellation_reason,
            ],
        ]);
    }

    /**
     * Initiate payment for an order
     */
    public function initiatePayment(Request $request, $id)
    {
        $validated = $request->validate([
            'provider' => 'required|in:jeko',
            'payment_method' => ['required', 'in:wave,orange,mtn,moov,djamo'],
        ]);

        $order = $request->user()->orders()->findOrFail($id);

        if ($order->payment_status === 'paid' || $order->paid_at !== null) {
            return response()->json(['success' => false, 'message' => 'Cette commande est déjà payée'], 400);
        }

        if ($order->status === 'cancelled') {
            return response()->json(['success' => false, 'message' => 'Cette commande a été annulée'], 400);
        }

        try {
            $method = JekoPaymentMethod::from($validated['payment_method']);
            $amountCents = (int) ($order->total_amount * 100);

            $payment = $this->jekoService->createRedirectPayment(
                $order,
                $amountCents,
                $method,
                $request->user(),
                "Paiement commande #{$order->id}"
            );

            return response()->json([
                'success' => true,
                'message' => 'Paiement initié',
                'data' => [
                    'reference'    => $payment->reference,
                    'redirect_url' => $payment->redirect_url,
                    'payment_url'  => $payment->redirect_url,
                    'amount'       => $payment->amount,
                    'currency'     => $payment->currency,
                    'payment_method' => $payment->payment_method->value,
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Payment initiation failed', [
                'order_id' => $order->id,
                'error'    => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'initialisation du paiement',
            ], 500);
        }
    }

    /**
     * Cancel an order — full cancellation:
     * 1. Cancel order status
     * 2. Cancel associated delivery
     * 3. Update payment status
     * 4. Notify pharmacy & courier
     */
    public function cancel(Request $request, $id)
    {
        $validated = $request->validate([
            'reason' => 'required|string|max:500',
        ]);

        $order = Order::with(['delivery', 'pharmacy', 'customer'])->findOrFail($id);

        // SECURITY: Vérifier que le client est bien le propriétaire de la commande
        if ((int) $order->customer_id !== (int) $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'êtes pas autorisé à annuler cette commande',
            ], 403);
        }

        if (!in_array($order->status, ['pending', 'processing', 'confirmed'])) {
            return response()->json([
                'success' => false,
                'message' => 'Cette commande ne peut pas être annulée',
            ], 400);
        }

        DB::beginTransaction();
        try {
            // 1. Cancel the order
            $order->update([
                'status' => 'cancelled',
                'cancellation_reason' => $validated['reason'],
                'cancelled_at' => now(),
            ]);

            // 2. Cancel associated delivery if exists
            if ($order->delivery) {
                $order->delivery->update([
                    'status' => 'cancelled',
                    'cancellation_reason' => 'Annulée par le client: ' . $validated['reason'],
                    'auto_cancelled_at' => now(),
                ]);
            }

            // 3. Mark pending payments as cancelled
            $order->payments()
                ->whereIn('status', ['pending', 'initiated'])
                ->update(['status' => 'cancelled']);

            $order->paymentIntents()
                ->where('status', 'pending')
                ->update(['status' => 'cancelled']);

            DB::commit();

            // 4. Notify pharmacy users
            if ($order->pharmacy) {
                try {
                    foreach ($order->pharmacy->users as $pharmacyUser) {
                        $pharmacyUser->notify(new OrderStatusNotification(
                            $order,
                            'cancelled',
                            "Le client a annulé la commande {$order->reference}. Raison: {$validated['reason']}"
                        ));
                    }
                } catch (\Throwable $e) {
                    Log::warning('Failed to notify pharmacy about cancellation', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage(),
                    ]);
                }
            }

            // 5. Notify courier if one was assigned
            if ($order->delivery && $order->delivery->courier_id) {
                try {
                    $courier = $order->delivery->courier;
                    if ($courier?->user) {
                        $courier->user->notify(new OrderStatusNotification(
                            $order,
                            'cancelled',
                            "La commande {$order->reference} a été annulée par le client."
                        ));
                    }
                } catch (\Throwable $e) {
                    Log::warning('Failed to notify courier about cancellation', [
                        'order_id' => $order->id,
                        'courier_id' => $order->delivery->courier_id,
                        'error' => $e->getMessage(),
                    ]);
                }
            }

            Log::info('Order fully cancelled', [
                'order_id' => $order->id,
                'reference' => $order->reference,
                'reason' => $validated['reason'],
                'had_delivery' => (bool) $order->delivery,
                'had_courier' => (bool) $order->delivery?->courier_id,
            ]);

            // Track cancellation
            BusinessEventService::orderCancelled(
                $request->user()->id,
                $order->id,
                $validated['reason'],
                'customer'
            );

            return response()->json([
                'success' => true,
                'message' => 'Commande annulée avec succès',
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();
            Log::error('Failed to cancel order', [
                'order_id' => $id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'annulation de la commande',
            ], 500);
        }
    }

    /**
     * Backward-compatible alias for the routed delivery waiting status endpoint.
     */
    public function deliveryWaitingStatus(Request $request, $id)
    {
        return $this->waitingStatus($request, $id);
    }

    /**
     * Obtenir le statut de la minuterie d'attente pour une commande
     * 
     * GET /api/customer/orders/{id}/waiting-status
     * 
     * Permet au client de voir le décompte en temps réel quand le livreur est arrivé
     */
    public function waitingStatus(Request $request, $id)
    {
        $order = $request->user()->orders()->with('delivery')->findOrFail($id);

        if (!$order->delivery) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune livraison associée à cette commande',
            ], 404);
        }

        $waitingInfo = $this->waitingFeeService->getWaitingInfo($order->delivery);

        // Message d'avertissement pour le client
        $warningMessage = null;
        if ($waitingInfo['is_waiting']) {
            $freeMinutes = $waitingInfo['free_minutes'];
            $feePerMinute = $waitingInfo['fee_per_minute'];
            $remainingFree = max(0, $freeMinutes - $waitingInfo['waiting_minutes']);
            
            if ($remainingFree > 0) {
                $warningMessage = "⏱️ Il vous reste {$remainingFree} minute(s) gratuite(s). Après cela, des frais de {$feePerMinute} FCFA/min seront facturés.";
            } else {
                $currentFee = $waitingInfo['waiting_fee'];
                $warningMessage = "⚠️ Frais d'attente en cours: {$currentFee} FCFA (+{$feePerMinute} FCFA/min)";
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'order_id' => $order->id,
                'delivery_id' => $order->delivery->id,
                'status' => $order->delivery->status,
                'waiting_info' => $waitingInfo,
                'warning_message' => $warningMessage,
            ],
        ]);
    }

    /**
     * Calculer les frais de livraison selon la distance pharmacie -> client
     * 
     * @param int $pharmacyId ID de la pharmacie
     * @param float|null $deliveryLat Latitude de livraison
     * @param float|null $deliveryLng Longitude de livraison
     * @return int Frais de livraison en FCFA
     */
    private function calculateDeliveryFee(int $pharmacyId, ?float $deliveryLat, ?float $deliveryLng): int
    {
        // Si pas de coordonnées de livraison, utiliser le minimum
        if ($deliveryLat === null || $deliveryLng === null) {
            return WalletService::getDeliveryFeeMin();
        }

        // Récupérer les coordonnées de la pharmacie
        $pharmacy = \App\Models\Pharmacy::find($pharmacyId);
        if (!$pharmacy || !$pharmacy->latitude || !$pharmacy->longitude) {
            return WalletService::getDeliveryFeeMin();
        }

        // Calculer la distance (formule Haversine)
        $distanceKm = $this->calculateDistance(
            $pharmacy->latitude,
            $pharmacy->longitude,
            $deliveryLat,
            $deliveryLng
        );

        // Calculer les frais selon la distance
        return WalletService::calculateDeliveryFee($distanceKm);
    }

    /**
     * Calculer la distance entre deux points GPS (formule Haversine)
     * 
     * @param float $lat1 Latitude point 1
     * @param float $lng1 Longitude point 1
     * @param float $lat2 Latitude point 2
     * @param float $lng2 Longitude point 2
     * @return float Distance en kilomètres
     */
    private function calculateDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadius = 6371; // Rayon de la Terre en km

        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLng / 2) * sin($dLng / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}
