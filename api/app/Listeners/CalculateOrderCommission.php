<?php

namespace App\Listeners;

use App\Actions\CalculateCommissionAction;
use App\Events\PaymentConfirmed;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Log;

class CalculateOrderCommission implements ShouldQueue
{
    public function __construct(
        private CalculateCommissionAction $action
    ) {}

    public function handle(PaymentConfirmed $event): void
    {
        $order = $event->payment->order;

        Log::info('Calculating commission for order', [
            'order_id' => $order?->id,
        ]);

        try {
            if ($order) {
                $this->action->execute($order);
            }

            Log::info('Commission calculated successfully', [
                'order_id' => $order?->id,
            ]);
        } catch (\Throwable $e) {
            Log::error('Failed to calculate commission', [
                'payment_id' => $event->payment->id,
                'error' => $e->getMessage(),
            ]);

            throw $e;
        }
    }
}
