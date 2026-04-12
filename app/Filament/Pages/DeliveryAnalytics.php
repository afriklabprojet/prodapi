<?php

namespace App\Filament\Pages;

use App\Models\Delivery;
use App\Models\DeliveryOffer;
use App\Models\Order;
use Filament\Pages\Page;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class DeliveryAnalytics extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-presentation-chart-line';

    protected static string $view = 'filament.pages.delivery-analytics';

    protected static ?string $navigationLabel = 'Analytics livraisons';

    protected static ?string $title = 'Analytics livraisons';

    protected static ?string $navigationGroup = 'Analytics';

    protected static ?int $navigationSort = 2;

    public string $period = '7';

    public function getDateRange(): array
    {
        $end = now();
        $start = now()->subDays((int) $this->period);
        return [$start, $end];
    }

    public function getOverviewStats(): array
    {
        [$start, $end] = $this->getDateRange();

        $deliveries = Delivery::whereBetween('created_at', [$start, $end]);
        $previousStart = $start->copy()->subDays((int) $this->period);

        $total = $deliveries->clone()->count();
        $completed = $deliveries->clone()->where('status', 'delivered')->count();
        $cancelled = $deliveries->clone()->whereNotNull('auto_cancelled_at')->count();

        $prevTotal = Delivery::whereBetween('created_at', [$previousStart, $start])->count();
        $growth = $prevTotal > 0 ? round((($total - $prevTotal) / $prevTotal) * 100, 1) : 0;

        $avgDuration = $deliveries->clone()
            ->where('status', 'delivered')
            ->whereNotNull('assigned_at')
            ->whereNotNull('delivered_at')
            ->selectRaw('AVG(TIMESTAMPDIFF(MINUTE, assigned_at, delivered_at)) as avg_min')
            ->value('avg_min');

        $totalRevenue = $deliveries->clone()
            ->where('status', 'delivered')
            ->sum('delivery_fee');

        $avgRating = $deliveries->clone()
            ->whereNotNull('customer_rating')
            ->avg('customer_rating');

        return [
            'total' => $total,
            'completed' => $completed,
            'cancelled' => $cancelled,
            'completion_rate' => $total > 0 ? round(($completed / $total) * 100, 1) : 0,
            'growth' => $growth,
            'avg_duration_min' => round($avgDuration ?? 0),
            'total_revenue' => $totalRevenue,
            'avg_rating' => round($avgRating ?? 0, 1),
        ];
    }

    public function getDailyChart(): array
    {
        [$start, $end] = $this->getDateRange();

        $data = Delivery::whereBetween('created_at', [$start, $end])
            ->selectRaw('DATE(created_at) as date, COUNT(*) as total, SUM(CASE WHEN status = "delivered" THEN 1 ELSE 0 END) as completed')
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        return [
            'labels' => $data->pluck('date')->map(fn ($d) => Carbon::parse($d)->format('d/m'))->toArray(),
            'total' => $data->pluck('total')->toArray(),
            'completed' => $data->pluck('completed')->toArray(),
        ];
    }

    public function getHourlyDistribution(): array
    {
        [$start, $end] = $this->getDateRange();

        $data = Delivery::whereBetween('created_at', [$start, $end])
            ->selectRaw('HOUR(created_at) as hour, COUNT(*) as total')
            ->groupBy('hour')
            ->orderBy('hour')
            ->pluck('total', 'hour');

        $hours = [];
        $counts = [];
        for ($h = 6; $h <= 23; $h++) {
            $hours[] = sprintf('%02d:00', $h);
            $counts[] = $data->get($h, 0);
        }

        return ['labels' => $hours, 'data' => $counts];
    }

    public function getOfferFunnel(): array
    {
        [$start, $end] = $this->getDateRange();

        $offers = DeliveryOffer::whereBetween('created_at', [$start, $end]);

        return [
            'created' => $offers->clone()->count(),
            'accepted' => $offers->clone()->where('status', DeliveryOffer::STATUS_ACCEPTED)->count(),
            'expired' => $offers->clone()->where('status', DeliveryOffer::STATUS_EXPIRED)->count(),
            'no_courier' => $offers->clone()->where('status', DeliveryOffer::STATUS_NO_COURIER)->count(),
        ];
    }

    public function getTopPharmacies(): array
    {
        [$start, $end] = $this->getDateRange();

        return Delivery::whereBetween('deliveries.created_at', [$start, $end])
            ->join('orders', 'deliveries.order_id', '=', 'orders.id')
            ->join('pharmacies', 'orders.pharmacy_id', '=', 'pharmacies.id')
            ->selectRaw('pharmacies.name, COUNT(*) as delivery_count, AVG(deliveries.delivery_fee) as avg_fee')
            ->groupBy('pharmacies.id', 'pharmacies.name')
            ->orderByDesc('delivery_count')
            ->limit(10)
            ->get()
            ->toArray();
    }
}
