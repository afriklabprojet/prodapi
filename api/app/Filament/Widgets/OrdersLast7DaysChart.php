<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Carbon\Carbon;
use Filament\Widgets\ChartWidget;

class OrdersLast7DaysChart extends ChartWidget
{
    protected static ?string $heading = 'Commandes (7 derniers jours)';
    
    protected static ?int $sort = 2;
    
    protected static ?string $pollingInterval = '60s';
    
    protected int | string | array $columnSpan = 'full';

    protected function getData(): array
    {
        $startDate = Carbon::now()->subDays(6)->startOfDay();
        $endDate = Carbon::now()->endOfDay();
        $pendingStatuses = ['pending', 'confirmed', 'preparing', 'ready_for_pickup', 'on_the_way'];

        // 1 seule requête pour total + delivered + pending (au lieu de 21)
        $orderStats = Order::query()
            ->selectRaw('DATE(created_at) as date')
            ->selectRaw('COUNT(*) as total_count')
            ->selectRaw('SUM(CASE WHEN status = "delivered" THEN 1 ELSE 0 END) as delivered_count')
            ->selectRaw('SUM(CASE WHEN status IN ("pending","confirmed","preparing","ready_for_pickup","on_the_way") THEN 1 ELSE 0 END) as pending_count')
            ->whereBetween('created_at', [$startDate, $endDate])
            ->groupBy('date')
            ->get()
            ->keyBy('date');

        $dates = collect();
        $totalOrders = collect();
        $pendingOrders = collect();
        $deliveredOrders = collect();

        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::now()->subDays($i);
            $dateKey = $date->format('Y-m-d');
            $dates->push($date->format('D d/m'));

            $dayStats = $orderStats->get($dateKey);
            $totalOrders->push((int) ($dayStats->total_count ?? 0));
            $deliveredOrders->push((int) ($dayStats->delivered_count ?? 0));
            $pendingOrders->push((int) ($dayStats->pending_count ?? 0));
        }

        return [
            'datasets' => [
                [
                    'label' => 'Total',
                    'data' => $totalOrders->toArray(),
                    'backgroundColor' => 'rgba(59, 130, 246, 0.3)',
                    'borderColor' => 'rgb(59, 130, 246)',
                    'borderWidth' => 2,
                    'fill' => true,
                    'tension' => 0.3,
                ],
                [
                    'label' => 'Livrées',
                    'data' => $deliveredOrders->toArray(),
                    'backgroundColor' => 'rgba(34, 197, 94, 0.3)',
                    'borderColor' => 'rgb(34, 197, 94)',
                    'borderWidth' => 2,
                    'fill' => true,
                    'tension' => 0.3,
                ],
                [
                    'label' => 'En cours',
                    'data' => $pendingOrders->toArray(),
                    'backgroundColor' => 'rgba(251, 191, 36, 0.3)',
                    'borderColor' => 'rgb(251, 191, 36)',
                    'borderWidth' => 2,
                    'fill' => true,
                    'tension' => 0.3,
                ],
            ],
            'labels' => $dates->toArray(),
        ];
    }

    protected function getType(): string
    {
        return 'line';
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
                    'ticks' => [
                        'stepSize' => 1,
                    ],
                ],
            ],
        ];
    }

    public function getDescription(): ?string
    {
        $weekTotal = Order::whereBetween('created_at', [
            Carbon::now()->subDays(6)->startOfDay(),
            Carbon::now()->endOfDay(),
        ])->count();
        
        $previousWeekTotal = Order::whereBetween('created_at', [
            Carbon::now()->subDays(13)->startOfDay(),
            Carbon::now()->subDays(7)->endOfDay(),
        ])->count();
        
        $trend = $previousWeekTotal > 0 
            ? round((($weekTotal - $previousWeekTotal) / $previousWeekTotal) * 100, 1)
            : 0;
        
        $trendIcon = $trend >= 0 ? '↑' : '↓';
        $trendText = abs($trend) . '% ' . $trendIcon . ' vs semaine précédente';
        
        return "Total: {$weekTotal} commandes • {$trendText}";
    }
}
