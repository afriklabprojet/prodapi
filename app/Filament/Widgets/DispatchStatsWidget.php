<?php

namespace App\Filament\Widgets;

use App\Models\Delivery;
use App\Models\DeliveryOffer;
use App\Models\CourierShift;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

/**
 * Widget affichant les statistiques du dispatch en temps réel.
 */
class DispatchStatsWidget extends BaseWidget
{
    protected static ?int $sort = 1;
    
    protected static ?string $pollingInterval = '10s';

    protected function getStats(): array
    {
        // Offres en attente
        $pendingOffers = DeliveryOffer::where('status', DeliveryOffer::STATUS_PENDING)
            ->where('expires_at', '>', now())
            ->count();
            
        // Livraisons en cours
        $activeDeliveries = Delivery::whereIn('status', ['assigned', 'accepted', 'picked_up', 'in_transit'])
            ->count();
            
        // Livreurs actifs (en shift)
        $activeShifts = CourierShift::where('status', CourierShift::STATUS_IN_PROGRESS)
            ->count();
            
        // Taux d'acceptation aujourd'hui
        $todayOffers = DeliveryOffer::whereDate('created_at', today())->count();
        $acceptedToday = DeliveryOffer::whereDate('created_at', today())
            ->where('status', DeliveryOffer::STATUS_ACCEPTED)
            ->count();
        $acceptanceRate = $todayOffers > 0 ? round(($acceptedToday / $todayOffers) * 100) : 0;
        
        // Temps moyen d'acceptation
        $avgAcceptTime = DeliveryOffer::whereDate('created_at', today())
            ->where('status', DeliveryOffer::STATUS_ACCEPTED)
            ->whereNotNull('accepted_at')
            ->selectRaw('AVG(TIMESTAMPDIFF(SECOND, created_at, accepted_at)) as avg_time')
            ->value('avg_time');
        $avgAcceptTimeFormatted = $avgAcceptTime ? round($avgAcceptTime) . 's' : '-';
        
        // Offres sans livreur aujourd'hui
        $noCourierToday = DeliveryOffer::whereDate('created_at', today())
            ->where('status', DeliveryOffer::STATUS_NO_COURIER)
            ->count();

        return [
            Stat::make('Offres en attente', $pendingOffers)
                ->description('Offres broadcast actives')
                ->descriptionIcon('heroicon-o-megaphone')
                ->color($pendingOffers > 10 ? 'danger' : ($pendingOffers > 5 ? 'warning' : 'success'))
                ->chart([7, 4, 6, 8, $pendingOffers]),
                
            Stat::make('Livraisons en cours', $activeDeliveries)
                ->description('En pickup ou transit')
                ->descriptionIcon('heroicon-o-truck')
                ->color('primary'),
                
            Stat::make('Livreurs actifs', $activeShifts)
                ->description('En shift maintenant')
                ->descriptionIcon('heroicon-o-user-group')
                ->color('success'),
                
            Stat::make('Taux d\'acceptation', $acceptanceRate . '%')
                ->description("Aujourd'hui ({$acceptedToday}/{$todayOffers})")
                ->descriptionIcon('heroicon-o-chart-bar')
                ->color($acceptanceRate >= 80 ? 'success' : ($acceptanceRate >= 60 ? 'warning' : 'danger')),
                
            Stat::make('Temps moyen accept', $avgAcceptTimeFormatted)
                ->description('Délai de réponse')
                ->descriptionIcon('heroicon-o-clock')
                ->color('info'),
                
            Stat::make('Sans livreur', $noCourierToday)
                ->description("Échecs aujourd'hui")
                ->descriptionIcon('heroicon-o-exclamation-triangle')
                ->color($noCourierToday > 0 ? 'danger' : 'success'),
        ];
    }
}
