<?php

namespace App\Filament\Widgets;

use App\Models\Delivery;
use App\Models\DeliveryOffer;
use App\Models\CourierShift;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Support\Facades\Cache;

/**
 * Widget affichant les statistiques du dispatch en temps réel.
 */
class DispatchStatsWidget extends BaseWidget
{
    protected static ?int $sort = 1;
    
    protected static ?string $pollingInterval = '30s';

    protected function getStats(): array
    {
        // Cache de 20 secondes pour éviter les requêtes redondantes
        return Cache::remember('dispatch_stats_overview', 20, function () {
            return $this->computeStats();
        });
    }

    protected function computeStats(): array
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

        // Stats d'aujourd'hui en 1 seule requête (au lieu de 3)
        $todayStats = DeliveryOffer::query()
            ->selectRaw('COUNT(*) as total')
            ->selectRaw('SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as accepted', [DeliveryOffer::STATUS_ACCEPTED])
            ->selectRaw('SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as no_courier', [DeliveryOffer::STATUS_NO_COURIER])
            ->whereDate('created_at', today())
            ->first();

        $todayOffers = (int) $todayStats->total;
        $acceptedToday = (int) $todayStats->accepted;
        $noCourierToday = (int) $todayStats->no_courier;
        $acceptanceRate = $todayOffers > 0 ? round(($acceptedToday / $todayOffers) * 100) : 0;
        
        // Temps moyen d'acceptation
        $avgAcceptTime = DeliveryOffer::whereDate('created_at', today())
            ->where('status', DeliveryOffer::STATUS_ACCEPTED)
            ->whereNotNull('accepted_at')
            ->selectRaw('AVG(TIMESTAMPDIFF(SECOND, created_at, accepted_at)) as avg_time')
            ->value('avg_time');
        $avgAcceptTimeFormatted = $avgAcceptTime ? round($avgAcceptTime) . 's' : '-';

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
