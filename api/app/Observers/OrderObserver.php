<?php

namespace App\Observers;

use App\Mail\AdminAlertMail;
use App\Models\Order;
use App\Models\User;
use App\Notifications\DeliveryAssignedNotification;
use App\Notifications\NewOrderNotification;
use App\Notifications\OrderStatusNotification;
use App\Services\CourierAssignmentService;
use App\Services\CommissionService;
use App\Services\CacheService;
use App\Services\FirestoreService;
use App\Services\LoyaltyService;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class OrderObserver
{
    protected CourierAssignmentService $assignmentService;
    protected CommissionService $commissionService;
    protected FirestoreService $firestoreService;
    protected LoyaltyService $loyaltyService;

    public function __construct(
        CourierAssignmentService $assignmentService,
        CommissionService $commissionService,
        FirestoreService $firestoreService,
        LoyaltyService $loyaltyService,
    ) {
        $this->assignmentService = $assignmentService;
        $this->commissionService = $commissionService;
        $this->firestoreService = $firestoreService;
        $this->loyaltyService = $loyaltyService;
    }

    /**
     * Handle the Order "created" event.
     */
    public function created(Order $order): void
    {
        // Notify pharmacy of new order
        $pharmacyUser = $order->pharmacy->users()->wherePivot('role', 'owner')->first();
        if ($pharmacyUser) {
            $pharmacyUser->notify(new NewOrderNotification($order));
            Log::info("New order notification sent to pharmacy", [
                'order_id' => $order->id,
                'pharmacy_id' => $order->pharmacy_id,
            ]);
        }
    }

    /**
     * Handle the Order "updated" event.
     * Auto-assign courier and send notifications when status changes
     */
    public function updated(Order $order): void
    {
        // Check if status changed
        if ($order->isDirty('status')) {
            $oldStatus = $order->getOriginal('status');
            $newStatus = $order->status;

            Log::info("Order status changed", [
                'order_id' => $order->id,
                'old_status' => $oldStatus,
                'new_status' => $newStatus,
            ]);

            // Notify customer of status change
            if ($order->customer) {
                $order->customer->notify(new OrderStatusNotification($order, $newStatus));
            }

            // Sync vers Firestore pour le tracking temps réel
            // Le client écoute deliveries/{orderId} dans Firestore
            if (in_array($newStatus, ['confirmed', 'ready', 'assigned', 'in_delivery', 'delivered', 'cancelled'])) {
                $delivery = $order->delivery;
                $this->firestoreService->updateDeliveryStatus(
                    $order->id,
                    $newStatus,
                    $delivery?->courier_id,
                    $delivery?->id
                );
            }

            // Handle specific status changes
            match ($newStatus) {
                'confirmed' => $this->handleConfirmed($order),
                'ready' => $this->handleReady($order),
                'delivered' => $this->handleDelivered($order),
                default => null,
            };
        }
        
        // Invalidate order cache
        CacheService::forgetOrder($order->id);
    }

    /**
     * Handle order confirmed status
     */
    protected function handleConfirmed(Order $order): void
    {
        Log::info("Order {$order->reference} confirmed by pharmacy");
    }

    /**
     * Handle order ready status - Auto-assign courier
     */
    protected function handleReady(Order $order): void
    {
        Log::info("Order {$order->reference} marked as ready. Attempting auto-assignment...");
        
        // Auto-assign courier if not already assigned
        if (!$order->delivery()->exists()) {
            
            $delivery = $this->assignmentService->assignCourier($order);
            
            if ($delivery) {
                Log::info("Order {$order->reference} automatically assigned to courier {$delivery->courier_id}");
                
                // Notify courier
                $courier = $delivery->courier;
                if ($courier && $courier->user) {
                    $courier->user->notify(new DeliveryAssignedNotification($delivery));
                    Log::info("Delivery notification sent to courier", [
                        'delivery_id' => $delivery->id,
                        'courier_id' => $courier->id,
                    ]);
                }
                
                // Notify customer that courier is assigned
                if ($order->customer) {
                    $order->customer->notify(new OrderStatusNotification($order, 'assigned'));
                }
            } else {
                Log::warning("Failed to auto-assign courier for order {$order->reference}. No available courier found.");
                
                // Notify admin that no courier is available
                $this->notifyAdminNoCourier($order);
            }
        }
    }

    /**
     * Notify admin when no courier is available for an order
     */
    protected function notifyAdminNoCourier(Order $order): void
    {
        try {
            $adminEmails = config('mail.admin_emails', []);
            
            // Fallback: get all admin users
            if (empty($adminEmails)) {
                $adminEmails = User::where('role', 'admin')
                    ->whereNotNull('email')
                    ->pluck('email')
                    ->toArray();
            }
            
            if (empty($adminEmails)) {
                Log::warning('No admin emails configured for alerts');
                return;
            }

            $data = [
                'order_id' => $order->id,
                'order_reference' => $order->reference,
                'pharmacy_name' => $order->pharmacy?->name ?? 'N/A',
                'delivery_address' => $order->delivery_address ?? 'N/A',
                'total_amount' => $order->total_amount,
                'customer_name' => $order->customer?->name ?? 'N/A',
                'customer_phone' => $order->customer?->phone ?? 'N/A',
            ];

            foreach ($adminEmails as $email) {
                Mail::to($email)->queue(new AdminAlertMail('no_courier_available', $data));
            }

            Log::info('Admin notified about no courier available', [
                'order_id' => $order->id,
                'admins_notified' => count($adminEmails),
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to notify admin about no courier', [
                'order_id' => $order->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Handle order delivered status - Distribute commissions
     */
    protected function handleDelivered(Order $order): void
    {
        Log::info("Order {$order->reference} delivered. Distributing commissions...");
        try {
            $this->commissionService->calculateAndDistribute($order);
        } catch (\Exception $e) {
            Log::error("Error distributing commissions for order {$order->id}: " . $e->getMessage());
        }

        // Award loyalty points
        try {
            $loyaltyPoint = $this->loyaltyService->awardPointsForOrder($order);
            Log::info("Loyalty points awarded for order {$order->reference}", [
                'points' => $loyaltyPoint->points,
                'customer_id' => $order->customer_id,
            ]);
        } catch (\Exception $e) {
            Log::error("Error awarding loyalty points for order {$order->id}: " . $e->getMessage());
        }
    }

    /**
     * Handle the Order "deleted" event.
     */
    public function deleted(Order $order): void
    {
        //
    }

    /**
     * Handle the Order "restored" event.
     */
    public function restored(Order $order): void
    {
        //
    }

    /**
     * Handle the Order "force deleted" event.
     */
    public function forceDeleted(Order $order): void
    {
        //
    }
}
