<?php

namespace App\Services;

use App\Models\Delivery;
use Illuminate\Support\Carbon;

/**
 * Service de calcul des frais d'attente pour les livraisons.
 *
 * Gère le minuteur d'attente du livreur et les frais facturés
 * au client après expiration des minutes gratuites.
 */
class WaitingFeeService
{
    /**
     * Get waiting information for a delivery.
     *
     * @return array{
     *     is_waiting: bool,
     *     waiting_started_at: ?string,
     *     waiting_minutes: int,
     *     free_minutes: int,
     *     fee_per_minute: int,
     *     timeout_minutes: int,
     *     waiting_fee: int,
     *     is_timed_out: bool,
     *     remaining_free_minutes: int,
     *     remaining_timeout_minutes: int,
     * }
     */
    public function getWaitingInfo(Delivery $delivery): array
    {
        $settings = $this->getSettings();
        $isWaiting = $delivery->waiting_started_at !== null;
        $waitingMinutes = 0;
        $waitingFee = 0;
        $isTimedOut = false;
        $remainingFreeMinutes = $settings['free_minutes'];
        $remainingTimeoutMinutes = $settings['timeout_minutes'];

        if ($isWaiting && $delivery->waiting_started_at) {
            $startedAt = Carbon::parse($delivery->waiting_started_at);
            $waitingMinutes = (int) $startedAt->diffInMinutes(now());

            // Calculate fee: only charged after free minutes expire
            $chargeableMinutes = max(0, $waitingMinutes - $settings['free_minutes']);
            $waitingFee = $chargeableMinutes * $settings['fee_per_minute'];

            $isTimedOut = $waitingMinutes >= $settings['timeout_minutes'];
            $remainingFreeMinutes = max(0, $settings['free_minutes'] - $waitingMinutes);
            $remainingTimeoutMinutes = max(0, $settings['timeout_minutes'] - $waitingMinutes);
        }

        return [
            'is_waiting' => $isWaiting,
            'waiting_started_at' => $delivery->waiting_started_at?->toIso8601String(),
            'waiting_minutes' => $waitingMinutes,
            'free_minutes' => $settings['free_minutes'],
            'fee_per_minute' => $settings['fee_per_minute'],
            'timeout_minutes' => $settings['timeout_minutes'],
            'waiting_fee' => $waitingFee,
            'is_timed_out' => $isTimedOut,
            'remaining_free_minutes' => $remainingFreeMinutes,
            'remaining_timeout_minutes' => $remainingTimeoutMinutes,
        ];
    }

    /**
     * Get the global waiting fee settings.
     *
     * @return array{timeout_minutes: int, fee_per_minute: int, free_minutes: int}
     */
    public function getSettings(): array
    {
        return [
            'timeout_minutes' => (int) config('services.waiting_fee.timeout_minutes', 15),
            'fee_per_minute' => (int) config('services.waiting_fee.fee_per_minute', 100),
            'free_minutes' => (int) config('services.waiting_fee.free_minutes', 5),
        ];
    }

    /**
     * Alias for getSettings - used in Pharmacy OrderController.
     */
    public function getWaitingSettings(): array
    {
        return $this->getSettings();
    }

    /**
     * Calculate total waiting fee for a delivery.
     */
    public function calculateFee(Delivery $delivery): int
    {
        $info = $this->getWaitingInfo($delivery);
        return $info['waiting_fee'];
    }
}
