<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use App\Models\Delivery;
use Filament\Widgets\ChartWidget;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class DeliveryPerformanceChart extends ChartWidget
{
    protected static ?string $heading = 'Performance des livraisons (7 derniers jours)';
    
    protected static ?int $sort = 4;
    
    protected static ?string $pollingInterval = '60s';
    
    protected int | string | array $columnSpan = 'full';

    protected function getData(): array
    {
        $startDate = Carbon::now()->subDays(6)->startOfDay();
        $endDate = Carbon::now()->endOfDay();

        // 1 seule requête pour delivered + cancelled (au lieu de 14)
        $orderStats = Order::query()
            ->selectRaw('DATE(updated_at) as date')
            ->selectRaw('SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as delivered_count', ['delivered'])
            ->selectRaw('SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) as cancelled_count', ['cancelled'])
            ->whereBetween('updated_at', [$startDate, $endDate])
            ->whereIn('status', ['delivered', 'cancelled'])
            ->groupBy('date')
            ->get()
            ->keyBy('date');

        // Construire les séries avec les 7 jours (même si certains n'ont pas de données)
        $dates = collect();
        $delivered = collect();
        $cancelled = collect();

        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i);
            $dateKey = $date->format('Y-m-d');
            $dates->push($date->format('d/m'));

            $dayStats = $orderStats->get($dateKey);
            $delivered->push((int) ($dayStats->delivered_count ?? 0));
            $cancelled->push((int) ($dayStats->cancelled_count ?? 0));
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
