<?php

namespace App\Filament\Pages;

use App\Filament\Widgets\DispatchStatsWidget;
use App\Filament\Widgets\BroadcastOffersWidget;
use App\Filament\Widgets\CourierShiftsWidget;
use App\Filament\Widgets\AvailableCouriersWidget;
use App\Filament\Widgets\LiveDeliveryMapWidget;
use Filament\Pages\Page;

class LiveDispatchDashboard extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-signal';
    
    protected static ?string $navigationLabel = 'Dispatch temps réel';
    
    protected static ?string $title = '🚀 Dispatch en temps réel';
    
    protected static ?string $navigationGroup = 'Dispatch';
    
    protected static ?int $navigationSort = 0;
    
    protected static ?string $slug = 'live-dispatch';
    
    protected static string $view = 'filament.pages.live-dispatch-dashboard';

    public static function canAccess(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }
    
    protected function getHeaderWidgets(): array
    {
        return [
            DispatchStatsWidget::class,
            LiveDeliveryMapWidget::class,
        ];
    }
    
    protected function getFooterWidgets(): array
    {
        return [
            BroadcastOffersWidget::class,
            CourierShiftsWidget::class,
            AvailableCouriersWidget::class,
        ];
    }
    
    public function getHeaderWidgetsColumns(): int|array
    {
        return 6;
    }
    
    public function getFooterWidgetsColumns(): int|array
    {
        return 1;
    }
}
