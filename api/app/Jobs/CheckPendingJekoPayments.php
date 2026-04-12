<?php

namespace App\Jobs;

use App\Models\JekoPayment;
use App\Services\JekoPaymentService;
use Carbon\Carbon;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class CheckPendingJekoPayments implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $timeoutMinutes;

    public function __construct(int $timeoutMinutes = 5)
    {
        $this->timeoutMinutes = $timeoutMinutes;
    }

    public function handle(JekoPaymentService $service): void
    {
        $pendingPayments = JekoPayment::where('status', 'pending')
            ->where('initiated_at', '<=', Carbon::now()->subMinutes($this->timeoutMinutes))
            ->get();

        foreach ($pendingPayments as $payment) {
            try {
                $checked = $service->checkPaymentStatus($payment);

                if ($checked->isSuccess()) {
                    Log::info('Pending payment resolved as success', [
                        'reference' => $checked->reference ?? null,
                    ]);
                } elseif ($checked->isFailed()) {
                    Log::info('Pending payment resolved as failed', [
                        'reference' => $checked->reference ?? null,
                    ]);
                } elseif (!$checked->isFinal()) {
                    $checked->markAsExpired();
                    Log::info('Pending payment marked as expired', [
                        'reference' => $checked->reference ?? null,
                    ]);
                }
            } catch (\Throwable $e) {
                Log::error('Error checking pending payment', [
                    'payment_id' => $payment->id ?? null,
                    'error' => $e->getMessage(),
                ]);
            }
        }
    }
}
