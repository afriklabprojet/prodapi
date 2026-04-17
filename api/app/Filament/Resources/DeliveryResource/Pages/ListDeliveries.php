<?php

namespace App\Filament\Resources\DeliveryResource\Pages;

use App\Filament\Resources\DeliveryResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;
use Filament\Resources\Components\Tab;
use Illuminate\Database\Eloquent\Builder;
use Filament\Widgets\StatsOverviewWidget\Stat;

class ListDeliveries extends ListRecords
{
    protected static string $resource = DeliveryResource::class;

    protected function getHeaderActions(): array
    {
        // Couriers disponibles = status 'available' + KYC approuvé
        $availableCouriers = \App\Models\Courier::where('status', 'available')
            ->where('kyc_status', 'approved')
            ->count();
        $totalCouriers = \App\Models\Courier::where('kyc_status', 'approved')->count();
        
        return [
            Actions\Action::make('couriers_status')
                ->label("Livreurs: {$availableCouriers} dispo")
                ->icon('heroicon-o-users')
                ->color($availableCouriers > 0 ? 'success' : 'danger')
                ->disabled(),
            Actions\CreateAction::make()
                ->label('Créer'),
        ];
    }
    
    protected function getHeaderWidgets(): array
    {
        return [
            DeliveryResource\Widgets\DeliveryStatsWidget::class,
        ];
    }
    
    public function getTabs(): array
    {
        return [
            'all' => Tab::make('Toutes')
                ->icon('heroicon-o-list-bullet')
                ->badge(fn () => \App\Models\Delivery::count() ?: null),
                
            'pending' => Tab::make('En attente')
                ->icon('heroicon-o-clock')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', 'pending'))
                ->badge(fn () => \App\Models\Delivery::where('status', 'pending')->count() ?: null)
                ->badgeColor('gray'),
            
            'assigned' => Tab::make('Assignées')
                ->icon('heroicon-o-user')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', 'assigned'))
                ->badge(fn () => \App\Models\Delivery::where('status', 'assigned')->count() ?: null)
                ->badgeColor('info'),
                
            'in_progress' => Tab::make('En cours')
                ->icon('heroicon-o-truck')
                ->modifyQueryUsing(fn (Builder $query) => $query->whereIn('status', ['accepted', 'picked_up', 'in_transit', 'arrived']))
                ->badge(fn () => \App\Models\Delivery::whereIn('status', ['accepted', 'picked_up', 'in_transit', 'arrived'])->count() ?: null)
                ->badgeColor('warning'),
                
            'delivered' => Tab::make('Livrées')
                ->icon('heroicon-o-check-circle')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', 'delivered'))
                ->badge(fn () => \App\Models\Delivery::where('status', 'delivered')->count() ?: null)
                ->badgeColor('success'),
                
            'cancelled' => Tab::make('Annulées')
                ->icon('heroicon-o-x-circle')
                ->modifyQueryUsing(fn (Builder $query) => $query->whereIn('status', ['failed', 'cancelled']))
                ->badge(fn () => \App\Models\Delivery::whereIn('status', ['failed', 'cancelled'])->count() ?: null)
                ->badgeColor('danger'),
        ];
    }
}
