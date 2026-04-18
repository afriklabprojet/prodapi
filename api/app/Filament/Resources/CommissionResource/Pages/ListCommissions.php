<?php

namespace App\Filament\Resources\CommissionResource\Pages;

use App\Filament\Resources\CommissionResource;
use App\Models\Commission;
use App\Models\CommissionLine;
use Filament\Resources\Pages\ListRecords;
use Filament\Resources\Components\Tab;
use Illuminate\Database\Eloquent\Builder;

class ListCommissions extends ListRecords
{
    protected static string $resource = CommissionResource::class;

    protected function getHeaderWidgets(): array
    {
        return [
            CommissionStatsWidget::class,
        ];
    }

    public function getTabs(): array
    {
        return [
            'all' => Tab::make('Toutes')
                ->badge(Commission::count()),
            'today' => Tab::make('Aujourd\'hui')
                ->modifyQueryUsing(fn (Builder $query) => $query->whereDate('calculated_at', today()))
                ->badge(Commission::whereDate('calculated_at', today())->count()),
            'this_week' => Tab::make('Cette semaine')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('calculated_at', '>=', now()->startOfWeek()))
                ->badge(Commission::where('calculated_at', '>=', now()->startOfWeek())->count()),
            'this_month' => Tab::make('Ce mois')
                ->modifyQueryUsing(fn (Builder $query) => $query->whereMonth('calculated_at', now()->month)->whereYear('calculated_at', now()->year))
                ->badge(Commission::whereMonth('calculated_at', now()->month)->whereYear('calculated_at', now()->year)->count()),
        ];
    }
}
