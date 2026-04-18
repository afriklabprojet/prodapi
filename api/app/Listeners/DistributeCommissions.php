<?php

namespace App\Listeners;

use App\Events\PaymentConfirmed;
use App\Services\CommissionService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;

class DistributeCommissions implements ShouldQueue
{
    use InteractsWithQueue;

    public function __construct(
        protected CommissionService $commissionService
    ) {}

    public function handle(PaymentConfirmed $event): void
    {
        $order = $event->payment->order;

        if (!$order) {
            Log::warning('No order found for payment', [
                'payment_id' => $event->payment->id,
            ]);
            return;
        }

        try {
            $this->commissionService->calculateAndDistribute($order);
        } catch (\Throwable $e) {
            Log::error('Failed to distribute commissions', [
                'payment_id' => $event->payment->id,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
