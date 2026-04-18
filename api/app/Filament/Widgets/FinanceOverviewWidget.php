<?php

namespace App\Filament\Widgets;

use App\Models\Commission;
use App\Models\Payment;
use App\Models\WalletTransaction;
use App\Models\WithdrawalRequest;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Carbon\Carbon;

class FinanceOverviewWidget extends BaseWidget
{
    protected static ?string $pollingInterval = '30s';
    
    protected static ?int $sort = 2;
    
    protected int | string | array $columnSpan = 'full';

    protected function getStats(): array
    {
        // Commissions du mois
        $monthCommissions = Commission::whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->sum('total_amount');
        
        $lastMonthCommissions = Commission::whereMonth('created_at', now()->subMonth()->month)
            ->whereYear('created_at', now()->subMonth()->year)
            ->sum('total_amount');
        
        $commissionsChange = $lastMonthCommissions > 0 
            ? round((($monthCommissions - $lastMonthCommissions) / $lastMonthCommissions) * 100, 1) 
            : 100;

        // Paiements en attente
        $pendingPayments = Payment::where('status', 'pending')->count();
        $pendingPaymentsAmount = Payment::where('status', 'pending')->sum('amount');

        // Demandes de retrait en attente
        $pendingWithdrawals = WithdrawalRequest::where('status', 'pending')->count();
        $pendingWithdrawalsAmount = WithdrawalRequest::where('status', 'pending')->sum('amount');

        // Transactions du jour
        $todayTransactions = WalletTransaction::whereDate('created_at', today())->count();
        $todayTransactionsAmount = WalletTransaction::whereDate('created_at', today())
            ->where('type', 'credit')
            ->sum('amount');

        return [
            Stat::make('Commissions du mois', number_format($monthCommissions, 0, ',', ' ') . ' FCFA')
                ->description($commissionsChange >= 0 ? "+{$commissionsChange}% vs mois dernier" : "{$commissionsChange}% vs mois dernier")
                ->descriptionIcon($commissionsChange >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color($commissionsChange >= 0 ? 'success' : 'danger')
                ->chart([4, 5, 6, 8, 7, 9, $commissionsChange > 0 ? 12 : 6]),

            Stat::make('Paiements en attente', $pendingPayments)
                ->description(number_format($pendingPaymentsAmount, 0, ',', ' ') . ' FCFA à traiter')
                ->descriptionIcon('heroicon-m-credit-card')
                ->color($pendingPayments > 10 ? 'danger' : ($pendingPayments > 0 ? 'warning' : 'success')),

            Stat::make('Retraits en attente', $pendingWithdrawals)
                ->description(number_format($pendingWithdrawalsAmount, 0, ',', ' ') . ' FCFA demandés')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color($pendingWithdrawals > 5 ? 'danger' : ($pendingWithdrawals > 0 ? 'warning' : 'success')),

            Stat::make('Transactions aujourd\'hui', $todayTransactions)
                ->description(number_format($todayTransactionsAmount, 0, ',', ' ') . ' FCFA crédités')
                ->descriptionIcon('heroicon-m-arrow-path')
                ->color('info'),
        ];
    }
}
