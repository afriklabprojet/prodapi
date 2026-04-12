<?php

namespace App\Filament\Pages\PayoutOverview;

use App\Models\Wallet;
use App\Models\WithdrawalRequest;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class PayoutStatsWidget extends BaseWidget
{
    protected function getStats(): array
    {
        // Total dû aux pharmacies
        $pharmacyTotal = Wallet::where('walletable_type', 'App\Models\Pharmacy')
            ->where('balance', '>', 0)
            ->sum('balance');
        $pharmacyCount = Wallet::where('walletable_type', 'App\Models\Pharmacy')
            ->where('balance', '>', 0)
            ->count();

        // Total dû aux livreurs
        $courierTotal = Wallet::where('walletable_type', 'App\Models\Courier')
            ->where('balance', '>', 0)
            ->sum('balance');
        $courierCount = Wallet::where('walletable_type', 'App\Models\Courier')
            ->where('balance', '>', 0)
            ->count();

        // Retraits en attente
        $pendingWithdrawals = WithdrawalRequest::whereIn('status', ['pending', 'processing'])
            ->sum('amount');
        $pendingCount = WithdrawalRequest::whereIn('status', ['pending', 'processing'])
            ->count();

        // Solde plateforme
        $platformBalance = Wallet::platform()->balance;

        return [
            Stat::make('Dû aux pharmacies', number_format($pharmacyTotal, 0, ',', ' ') . ' FCFA')
                ->description($pharmacyCount . ' pharmacie(s) à payer')
                ->descriptionIcon('heroicon-m-building-storefront')
                ->color('danger'),

            Stat::make('Dû aux livreurs', number_format($courierTotal, 0, ',', ' ') . ' FCFA')
                ->description($courierCount . ' livreur(s) à payer')
                ->descriptionIcon('heroicon-m-truck')
                ->color('warning'),

            Stat::make('Retraits en attente', number_format($pendingWithdrawals, 0, ',', ' ') . ' FCFA')
                ->description($pendingCount . ' demande(s) en cours')
                ->descriptionIcon('heroicon-m-clock')
                ->color('info'),

            Stat::make('Solde plateforme', number_format($platformBalance, 0, ',', ' ') . ' FCFA')
                ->description('Wallet DR-PHARMA')
                ->descriptionIcon('heroicon-m-wallet')
                ->color('success'),
        ];
    }
}
