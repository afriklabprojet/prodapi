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
use App\Jobs\DispatchDeliveryJob;
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
        
        $user = $request->user();

        $orders = $user->orders()
            ->withCount('items')
            ->withSum('items', 'quantity')
            ->withCount(['ratings as has_rating' => fn ($q) => $q->where('user_id', $user->id)])
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
                'subtotal' => (float) $order->subtotal,
                'total_amount' => (float) $order->total_amount,
                'currency' => $order->currency,
                'delivery_address' => $order->delivery_address,
                'items_count' => (int) $order->items_count,
                'total_quantity' => (int) ($order->items_sum_quantity ?? $order->items_count),
                'is_rated' => $order->has_rating > 0,
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

        // Calcul COMPLET du pricing AVANT la transaction (appel externe Google Maps possible).
        // calculateFullPricing = SOURCE UNIQUE partagée avec /pricing/calculate.
        // Garantit : total UI == total DB == total JEKO. Aucune duplication possible.
        Log::info('[OrderController::store] 📍 Pricing request', [
            'pharmacy_id'        => $validated['pharmacy_id'],
            'delivery_latitude'  => $validated['delivery_latitude'] ?? null,
            'delivery_longitude' => $validated['delivery_longitude'] ?? null,
            'delivery_address'   => $validated['delivery_address'] ?? null,
            'payment_mode'       => $validated['payment_mode'],
            'user_id'            => $request->user()?->id,
        ]);

        $pricing = app(\App\Services\PricingService::class)->calculateFullPricing(
            (int) $validated['pharmacy_id'],
            $items,
            $validated['delivery_latitude'] ?? null,
            $validated['delivery_longitude'] ?? null,
            $validated['payment_mode'],
            $validated['delivery_address'] ?? null
        );

        Log::info('[OrderController::store] 📍 Pricing result', [
            'delivery_fee' => $pricing['delivery_fee'] ?? null,
            'total_amount' => $pricing['total_amount'] ?? null,
            'distance_km'  => $pricing['distance_km'] ?? null,
        ]);

        try {
            $order = DB::transaction(function () use ($request, $validated, $items, $pricing) {
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

                // Pricing calculé par calculateFullPricing() — avant la transaction.
                // UNE SEULE SOURCE DE CALCUL, identique à /pricing/calculate.
                $subtotal    = $pricing['subtotal'];
                $deliveryFee = $pricing['delivery_fee'];
                $serviceFee  = $pricing['service_fee'];
                $paymentFee  = $pricing['payment_fee'];
                $totalAmount = $pricing['total_amount'];

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

                // ── Mismatch guard ────────────────────────────────────────────────────────
                // Après promo, total_amount ne doit pas diverger de pricing['total_amount'] au-delà
                // du montant de la remise. Vérification de cohérence stricte.
                if ($totalAmount !== $pricing['total_amount'] - ($promoDiscount ?? 0)) {
                    Log::error('[OrderController::store] Pricing mismatch DÉTECTÉ', [
                        'pricing_total'  => $pricing['total_amount'],
                        'order_total'    => $totalAmount,
                        'promo_discount' => $promoDiscount ?? 0,
                    ]);
                    throw new \Exception(
                        "Pricing mismatch: order={$totalAmount}, pricing={$pricing['total_amount']}, promo={$promoDiscount}"
                    );
                }
                Log::info('[OrderController::store] Pricing appliqué', [
                    'pricing_total'   => $pricing['total_amount'],
                    'order_total'     => $totalAmount,
                    'subtotal'        => $subtotal,
                    'delivery_fee'    => $deliveryFee,
                    'service_fee'     => $serviceFee,
                    'payment_fee'     => $paymentFee,
                    'distance_km'     => $pricing['distance_km'],
                    'delivery_source' => $pricing['delivery_source'],
                ]);

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
                    'delivery_distance_km' => $pricing['distance_km'] ?? null,
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

            // === NOTIFICATION PHARMACIE ===
            // Tous les paiements se font en ligne : la notification est envoyée
            // uniquement apres confirmation du paiement (JekoPaymentService / ProcessPaymentResultJob).
            // On ne notifie JAMAIS a la creation de la commande — seulement quand le paiement reussit.

            // Track order creation
            BusinessEventService::orderCreated(
                $request->user()->id,
                $order->id,
                (float) $order->total_amount,
                $order->payment_mode
            );

            // Pour les commandes cash/on_delivery : dispatcher immédiatement le livreur.
            // Pour les autres modes : le dispatch se fait après confirmation du paiement
            // via ProcessPaymentResultJob.
            if (in_array($order->payment_mode, ['cash', 'on_delivery'])) {
                DispatchDeliveryJob::dispatch($order)->delay(now()->addSeconds(5));
            }

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
                    'product_id' => $item->product_id,
                    'name' => $item->product_name,
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
            // Capturer le statut avant annulation pour savoir si la pharmacie avait pris en charge.
            $previousStatus = $order->status;

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

            // 4. Notifier la pharmacie uniquement si :
            //    - elle avait deja pris en charge la commande (confirmed/processing), ET
            //    - la commande est/etait reellement payee.
            // Pas de notif pour les commandes non payees (online pending, cash jamais encaisse).
            if (
                $order->pharmacy
                && in_array($previousStatus, ['confirmed', 'processing'], true)
                && $order->isPaid()
            ) {
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
}
