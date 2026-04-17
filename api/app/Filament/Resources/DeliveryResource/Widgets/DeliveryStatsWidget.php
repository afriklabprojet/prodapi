<?php

namespace App\Filament\Resources\DeliveryResource\Widgets;

use App\Models\Courier;
use App\Models\Delivery;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class DeliveryStatsWidget extends BaseWidget
{
    protected static ?string $pollingInterval = '30s';
    
    protected function getStats(): array
    {
        $pendingCount = Delivery::where('status', 'pending')->count();
        $inProgressCount = Delivery::whereIn('status', ['assigned', 'accepted', 'picked_up', 'in_transit', 'arrived'])->count();
        $deliveredTodayCount = Delivery::where('status', 'delivered')
            ->whereDate('delivered_at', today())
            ->count();
        
        // Couriers disponibles = status 'available' + KYC approuvé
        $availableCouriers = Courier::where('status', 'available')
            ->where('kyc_status', 'approved')
            ->count();
        $totalCouriers = Courier::where('kyc_status', 'approved')->count();
        $onDeliveryCouriers = Courier::where('kyc_status', 'approved')
            ->whereHas('deliveries', function ($q) {
                $q->whereIn('status', ['accepted', 'picked_up', 'in_transit', 'arrived']);
            })
            ->count();
        
        return [
            Stat::make('En attente', $pendingCount)
                ->description('Livraisons non assignées')
                ->descriptionIcon('heroicon-o-clock')
                ->color('gray')
                ->chart($this->getChartData('pending', 7)),
                
            Stat::make('En cours', $inProgressCount)
                ->description('Assignées ou en livraison')
                ->descriptionIcon('heroicon-o-truck')
                ->color('warning')
                ->chart($this->getChartData('in_progress', 7)),
                
            Stat::make('Livrées aujourd\'hui', $deliveredTodayCount)
                ->description('Livraisons terminées')
                ->descriptionIcon('heroicon-o-check-circle')
                ->color('success')
                ->chart($this->getChartData('delivered', 7)),
                
            Stat::make('Livreurs disponibles', "{$availableCouriers} / {$totalCouriers}")
                ->description("{$onDeliveryCouriers} en course")
                ->descriptionIcon('heroicon-o-users')
                ->color($availableCouriers > 0 ? 'success' : 'danger'),
        ];
    }
    
    private function getChartData(string $type, int $days): array
    {
        $data = [];
        
        for ($i = $days - 1; $i >= 0; $i--) {
            $date = now()->subDays($i)->toDateString();
            
            $query = Delivery::whereDate('created_at', $date);
            
            if ($type === 'pending') {
                $count = Delivery::where('status', 'pending')
                    ->whereDate('created_at', '<=', $date)
                    ->count();
            } elseif ($type === 'in_progress') {
                $count = Delivery::whereIn('status', ['assigned', 'accepted', 'picked_up', 'in_transit', 'arrived'])
                    ->whereDate('created_at', '<=', $date)
                    ->count();
            } elseif ($type === 'delivered') {
                $count = Delivery::where('status', 'delivered')
                    ->whereDate('delivered_at', $date)
                    ->count();
            } else {
                $count = $query->count();
            }
            
            $data[] = $count;
        }
        
        return $data;
    }
}
