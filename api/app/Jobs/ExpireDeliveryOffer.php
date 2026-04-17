<?php

namespace App\Jobs;

use App\Models\DeliveryOffer;
use App\Services\BroadcastDispatchService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ExpireDeliveryOffer implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $offerId;

    /**
     * Create a new job instance.
     */
    public function __construct(int $offerId)
    {
        $this->offerId = $offerId;
        $this->onQueue('delivery-offers');
    }

    /**
     * Execute the job.
     */
    public function handle(BroadcastDispatchService $dispatchService): void
    {
        $offer = DeliveryOffer::find($this->offerId);

        if (!$offer) {
            Log::warning("ExpireDeliveryOffer: Offer {$this->offerId} not found");
            return;
        }

        // Si l'offre est déjà traitée, ignorer
        if ($offer->status !== DeliveryOffer::STATUS_PENDING) {
            Log::info("ExpireDeliveryOffer: Offer {$this->offerId} already {$offer->status}");
            return;
        }

        // Expirer l'offre
        $offer->expire();

        Log::info("ExpireDeliveryOffer: Offer {$this->offerId} expired", [
            'order_id' => $offer->order_id,
            'broadcast_level' => $offer->broadcast_level,
        ]);

        // Déclencher l'escalade au niveau supérieur
        $dispatchService->handleExpiredOffer($offer);
    }
}
