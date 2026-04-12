<?php

namespace App\Filament\Resources\DeliveryOfferResource\Pages;

use App\Filament\Resources\DeliveryOfferResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;
use Filament\Resources\Components\Tab;
use Illuminate\Database\Eloquent\Builder;
use App\Models\DeliveryOffer;

class ListDeliveryOffers extends ListRecords
{
    protected static string $resource = DeliveryOfferResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
    
    public function getTabs(): array
    {
        return [
            'pending' => Tab::make('En attente')
                ->icon('heroicon-o-clock')
                ->badge(DeliveryOffer::where('status', DeliveryOffer::STATUS_PENDING)->count())
                ->badgeColor('warning')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', DeliveryOffer::STATUS_PENDING)),
                
            'accepted' => Tab::make('Acceptées')
                ->icon('heroicon-o-check')
                ->badge(DeliveryOffer::where('status', DeliveryOffer::STATUS_ACCEPTED)->whereDate('created_at', today())->count())
                ->badgeColor('success')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', DeliveryOffer::STATUS_ACCEPTED)),
                
            'expired' => Tab::make('Expirées')
                ->icon('heroicon-o-x-circle')
                ->badge(DeliveryOffer::where('status', DeliveryOffer::STATUS_EXPIRED)->whereDate('created_at', today())->count())
                ->badgeColor('gray')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', DeliveryOffer::STATUS_EXPIRED)),
                
            'no_courier' => Tab::make('Sans livreur')
                ->icon('heroicon-o-exclamation-triangle')
                ->badge(DeliveryOffer::where('status', DeliveryOffer::STATUS_NO_COURIER)->whereDate('created_at', today())->count())
                ->badgeColor('danger')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', DeliveryOffer::STATUS_NO_COURIER)),
                
            'all' => Tab::make('Toutes')
                ->icon('heroicon-o-squares-2x2'),
        ];
    }
    
    public function getDefaultActiveTab(): string
    {
        return 'pending';
    }
}
