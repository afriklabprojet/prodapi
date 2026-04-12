<?php

namespace App\Filament\Widgets;

use App\Models\Courier;
use App\Models\Delivery;
use App\Services\DeliveryTrackingService;
use Filament\Widgets\Widget;

class LiveDeliveryMapWidget extends Widget
{
    protected static string $view = 'filament.widgets.live-delivery-map-widget';

    protected int | string | array $columnSpan = 'full';

    protected static ?int $sort = 0;

    public function getActiveDeliveries(): array
    {
        $trackingService = app(DeliveryTrackingService::class);

        return $trackingService->getActiveDeliveryPositions()->toArray();
    }

    public function getAvailableCouriers(): array
    {
        return Courier::available()
            ->whereNotNull('last_latitude')
            ->whereNotNull('last_longitude')
            ->whereNotNull('last_location_update')
            ->where('last_location_update', '>=', now()->subMinutes(15))
            ->with('user')
            ->get()
            ->map(fn ($courier) => [
                'id' => $courier->id,
                'name' => $courier->user?->name ?? 'N/A',
                'latitude' => $courier->last_latitude,
                'longitude' => $courier->last_longitude,
                'is_stale' => $courier->last_location_update->diffInMinutes(now()) > 5,
                'updated_at' => $courier->last_location_update->diffForHumans(),
            ])
            ->toArray();
    }

    public function getMapStats(): array
    {
        return [
            'active_deliveries' => Delivery::inProgress()->count(),
            'available_couriers' => Courier::available()
                ->where('last_location_update', '>=', now()->subMinutes(15))
                ->count(),
            'stale_gps' => Courier::available()
                ->where('last_location_update', '<', now()->subMinutes(5))
                ->where('last_location_update', '>=', now()->subMinutes(15))
                ->count(),
        ];
    }
}
