<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use App\Models\Delivery;
use Filament\Widgets\ChartWidget;
use Carbon\Carbon;

class DeliveryPerformanceChart extends ChartWidget
{
    protected static ?string $heading = 'Performance des livraisons (7 derniers jours)';
    
    protected static ?int $sort = 4;
    
    protected static ?string $pollingInterval = '60s';
    
    protected int | string | array $columnSpan = 'full';

    protected function getData(): array
    {
        $dates = collect();
        $delivered = collect();
        $cancelled = collect();
        $avgTime = collect();

        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i);
            $dates->push($date->format('d/m'));
            
            // Commandes livrées
            $deliveredCount = Order::whereDate('updated_at', $date)
                ->where('status', 'delivered')
                ->count();
            $delivered->push($deliveredCount);
            
            // Commandes annulées
            $cancelledCount = Order::whereDate('updated_at', $date)
                ->where('status', 'cancelled')
                ->count();
            $cancelled->push($cancelledCount);
            
            // Temps moyen de livraison (en minutes) - Compatible MySQL
            $avgDeliveryTime = Delivery::whereDate('delivered_at', $date)
                ->whereNotNull('delivered_at')
                ->whereNotNull('accepted_at')
                ->selectRaw('AVG(' . db_timestampdiff('MINUTE', 'accepted_at', 'delivered_at') . ') as avg_time')
                ->value('avg_time') ?? 0;
            $avgTime->push(round($avgDeliveryTime));
        }

        return [
            'datasets' => [
                [
                    'label' => 'Livrées',
                    'data' => $delivered->toArray(),
                    'backgroundColor' => 'rgba(34, 197, 94, 0.5)',
                    'borderColor' => 'rgb(34, 197, 94)',
                    'borderWidth' => 2,
                ],
                [
                    'label' => 'Annulées',
                    'data' => $cancelled->toArray(),
                    'backgroundColor' => 'rgba(239, 68, 68, 0.5)',
                    'borderColor' => 'rgb(239, 68, 68)',
                    'borderWidth' => 2,
                ],
            ],
            'labels' => $dates->toArray(),
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }
    
    protected function getOptions(): array
    {
        return [
            'plugins' => [
                'legend' => [
                    'display' => true,
                    'position' => 'top',
                ],
            ],
            'scales' => [
                'y' => [
                    'beginAtZero' => true,
                ],
            ],
        ];
    }
}
