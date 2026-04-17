<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Product;
use App\Models\Pharmacy;
use App\Models\User;
use App\Notifications\NewOrderReceivedNotification;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Service pour la gestion des commandes
 * 
 * Security Audit Week 3 - Refactoring
 * Centralise la logique métier des commandes
 */
class OrderService
{
    protected WalletService $walletService;

    public function __construct(WalletService $walletService)
    {
        $this->walletService = $walletService;
    }

    /**
     * Valider la disponibilité des produits
     *
     * @param array $items
     * @return array|null Erreur ou null si valide
     */
    public function validateProductsAvailability(array $items): ?array
    {
        foreach ($items as $item) {
            if (isset($item['id'])) {
                $product = Product::find($item['id']);
                if ($product) {
                    if (!$product->is_available) {
                        return [
                            'success' => false,
                            'message' => "Le produit {$product->name} n'est pas disponible",
                            'errors' => ['items' => ["Le produit {$product->name} n'est pas disponible"]]
                        ];
                    }
                    if ($product->stock_quantity < $item['quantity']) {
                        return [
                            'success' => false,
                            'message' => "Stock insuffisant pour le produit {$product->name}",
                            'errors' => ['items' => ["Stock insuffisant pour le produit {$product->name}"]]
                        ];
                    }
                }
            }
        }
        return null;
    }

    /**
     * Calculer le sous-total de la commande
     *
     * @param array $items
     * @return float
     */
    public function calculateSubtotal(array $items): float
    {
        $subtotal = 0;
        foreach ($items as $item) {
            $price = $item['price'];
            if (isset($item['id'])) {
                $product = Product::find($item['id']);
                if ($product) {
                    $price = $product->price;
                }
            }
            $subtotal += $item['quantity'] * $price;
        }
        return $subtotal;
    }

    /**
     * Calculer les totaux de la commande
     *
     * @param array $items
     * @return array
     */
    public function calculateOrderTotals(array $items): array
    {
        $subtotal = $this->calculateSubtotal($items);
        $deliveryFee = WalletService::getDeliveryFeeBase();
        $totalAmount = $subtotal + $deliveryFee;

        return [
            'subtotal' => $subtotal,
            'delivery_fee' => $deliveryFee,
            'total_amount' => $totalAmount,
        ];
    }

    /**
     * Créer une commande
     *
     * @param User $customer
     * @param array $data
     * @return Order
     */
    public function createOrder(User $customer, array $data): Order
    {
        $totals = $this->calculateOrderTotals($data['items']);

        return Order::create([
            'reference' => Order::generateReference(),
            'pharmacy_id' => $data['pharmacy_id'],
            'customer_id' => $customer->id,
            'status' => 'pending',
            'payment_mode' => $data['payment_mode'],
            'subtotal' => $totals['subtotal'],
            'delivery_fee' => $totals['delivery_fee'],
            'total_amount' => $totals['total_amount'],
            'currency' => 'XOF',
            'customer_notes' => $data['customer_notes'] ?? null,
            'prescription_image' => $data['prescription_image'] ?? null,
            'delivery_address' => $data['delivery_address'],
            'delivery_city' => $data['delivery_city'] ?? null,
            'delivery_latitude' => $data['delivery_latitude'] ?? null,
            'delivery_longitude' => $data['delivery_longitude'] ?? null,
            'customer_phone' => $data['customer_phone'],
        ]);
    }

    /**
     * Créer les articles de la commande
     *
     * @param Order $order
     * @param array $items
     * @return void
     */
    public function createOrderItems(Order $order, array $items): void
    {
        foreach ($items as $item) {
            $price = $item['price'];
            $productId = $item['id'] ?? null;
            
            if ($productId) {
                $product = Product::find($productId);
                if ($product) {
                    $price = $product->price;
                }
            }

            $order->items()->create([
                'product_id' => $productId,
                'product_name' => $item['name'],
                'quantity' => $item['quantity'],
                'unit_price' => $price,
                'total_price' => $item['quantity'] * $price,
            ]);
        }
    }

    /**
     * Mettre à jour le stock des produits
     *
     * @param array $items
     * @return void
     */
    public function updateProductStock(array $items): void
    {
        foreach ($items as $item) {
            if (isset($item['id'])) {
                $product = Product::find($item['id']);
                if ($product) {
                    $product->decrement('stock_quantity', $item['quantity']);
                }
            }
        }
    }

    /**
     * Notifier la pharmacie d'une nouvelle commande
     *
     * @param Order $order
     * @return void
     */
    public function notifyPharmacy(Order $order): void
    {
        try {
            $pharmacy = $order->pharmacy;
            if ($pharmacy && $pharmacy->users->isNotEmpty()) {
                foreach ($pharmacy->users as $pharmacyUser) {
                    $pharmacyUser->notify(new NewOrderReceivedNotification($order));
                }
            }
        } catch (\Exception $e) {
            Log::error('Failed to notify pharmacy of new order', [
                'order_id' => $order->id,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Annuler une commande
     *
     * @param Order $order
     * @param string|null $reason
     * @return Order
     */
    public function cancelOrder(Order $order, ?string $reason = null): Order
    {
        $order->update([
            'status' => 'cancelled',
            'cancellation_reason' => $reason,
            'cancelled_at' => now(),
        ]);

        // Restaurer le stock si nécessaire
        $this->restoreProductStock($order);

        return $order->fresh();
    }

    /**
     * Restaurer le stock des produits après annulation
     *
     * @param Order $order
     * @return void
     */
    protected function restoreProductStock(Order $order): void
    {
        foreach ($order->items as $item) {
            if ($item->product_id) {
                $product = Product::find($item->product_id);
                if ($product) {
                    $product->increment('stock_quantity', $item->quantity);
                }
            }
        }
    }

    /**
     * Vérifier si une commande peut être annulée
     *
     * @param Order $order
     * @return bool
     */
    public function canBeCancelled(Order $order): bool
    {
        return in_array($order->status, ['pending', 'confirmed', 'preparing']);
    }

    /**
     * Vérifier si une commande peut être payée
     *
     * @param Order $order
     * @return bool
     */
    public function canBePaid(Order $order): bool
    {
        return in_array($order->status, ['pending', 'confirmed']) && !$order->paid_at;
    }

    /**
     * Marquer une commande comme payée
     *
     * @param Order $order
     * @param string $paymentReference
     * @return Order
     */
    public function markAsPaid(Order $order, string $paymentReference): Order
    {
        $order->update([
            'paid_at' => now(),
            'payment_status' => 'paid',
            'payment_reference' => $paymentReference,
            // Do NOT auto-confirm: pharmacy must manually confirm paid orders
        ]);

        return $order->fresh();
    }

    /**
     * Obtenir les statistiques de commandes d'un client
     *
     * @param User $customer
     * @return array
     */
    public function getCustomerOrderStats(User $customer): array
    {
        $orders = $customer->orders();

        return [
            'total_orders' => $orders->count(),
            'pending_orders' => $orders->clone()->where('status', 'pending')->count(),
            'completed_orders' => $orders->clone()->where('status', 'delivered')->count(),
            'cancelled_orders' => $orders->clone()->where('status', 'cancelled')->count(),
            'total_spent' => $orders->clone()->where('status', 'delivered')->sum('total_amount'),
        ];
    }

    /**
     * Générer un code de livraison unique (4 chiffres)
     *
     * @return string
     */
    public function generateDeliveryCode(): string
    {
        do {
            $code = str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);
        } while (Order::where('delivery_code', $code)->exists());

        return $code;
    }
}
