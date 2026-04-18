<?php

namespace App\Filament\Resources\CommissionResource\Pages;

use App\Models\Commission;
use App\Models\CommissionLine;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class CommissionStatsWidget extends BaseWidget
{
    protected function getStats(): array
    {
        // Total commissions plateforme (all time)
        $totalPlatform = CommissionLine::where('actor_type', 'platform')->sum('amount');

        // Commissions plateforme ce mois
        $monthPlatform = CommissionLine::where('actor_type', 'platform')
            ->whereHas('commission', fn ($q) => $q
                ->whereMonth('calculated_at', now()->month)
                ->whereYear('calculated_at', now()->year))
            ->sum('amount');

        // Commissions plateforme mois dernier
        $lastMonthPlatform = CommissionLine::where('actor_type', 'platform')
            ->whereHas('commission', fn ($q) => $q
                ->whereMonth('calculated_at', now()->subMonth()->month)
                ->whereYear('calculated_at', now()->subMonth()->year))
            ->sum('amount');

        $platformChange = $lastMonthPlatform > 0
            ? round(($monthPlatform - $lastMonthPlatform) / $lastMonthPlatform * 100, 1)
            : ($monthPlatform > 0 ? 100 : 0);

        // Total reversé aux pharmacies (all time)
        $totalPharmacy = CommissionLine::where('actor_type', 'App\Models\Pharmacy')->sum('amount');

        // Total reversé aux pharmacies ce mois
        $monthPharmacy = CommissionLine::where('actor_type', 'App\Models\Pharmacy')
            ->whereHas('commission', fn ($q) => $q
                ->whereMonth('calculated_at', now()->month)
                ->whereYear('calculated_at', now()->year))
            ->sum('amount');

        // Total livreurs ce mois
        $monthCourier = CommissionLine::where('actor_type', 'App\Models\Courier')
            ->whereHas('commission', fn ($q) => $q
                ->whereMonth('calculated_at', now()->month)
                ->whereYear('calculated_at', now()->year))
            ->sum('amount');

        // Nombre de commissions
        $totalCommissions = Commission::count();
        $monthCommissions = Commission::whereMonth('calculated_at', now()->month)
            ->whereYear('calculated_at', now()->year)
            ->count();

        return [
            Stat::make('Revenus plateforme (ce mois)', number_format($monthPlatform, 0, ',', ' ') . ' FCFA')
                ->description(
                    ($platformChange >= 0 ? "+{$platformChange}%" : "{$platformChange}%") .
                    ' vs mois dernier | Total: ' . number_format($totalPlatform, 0, ',', ' ') . ' FCFA'
                )
                ->descriptionIcon($platformChange >= 0
                    ? 'heroicon-m-arrow-trending-up'
                    : 'heroicon-m-arrow-trending-down')
                ->color($platformChange >= 0 ? 'success' : 'danger')
                ->chart([3, 5, 4, 7, 6, 8, max(1, $monthPlatform > 0 ? 10 : 2)]),

            Stat::make('Reversé aux pharmacies (ce mois)', number_format($monthPharmacy, 0, ',', ' ') . ' FCFA')
                ->description('Total: ' . number_format($totalPharmacy, 0, ',', ' ') . ' FCFA')
                ->descriptionIcon('heroicon-m-building-storefront')
                ->color('info'),

            Stat::make('Part livreurs (ce mois)', number_format($monthCourier, 0, ',', ' ') . ' FCFA')
                ->description('Commissionnée aux livreurs')
                ->descriptionIcon('heroicon-m-truck')
                ->color('warning'),

            Stat::make('Commissions (ce mois)', $monthCommissions)
                ->description('Total: ' . number_format($totalCommissions) . ' commissions')
                ->descriptionIcon('heroicon-m-calculator')
                ->color('gray'),
        ];
    }
}
