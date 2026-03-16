<?php

namespace App\Filament\Widgets;

use App\Models\Courier;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Prescription;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        // Commandes du jour
        $todayOrders = Order::whereDate('created_at', today())->count();
        $yesterdayOrders = Order::whereDate('created_at', today()->subDay())->count();
        $ordersChange = $yesterdayOrders > 0 
            ? round((($todayOrders - $yesterdayOrders) / $yesterdayOrders) * 100, 1) 
            : 0;

        // Chiffre d'affaires du jour
        $todayRevenue = Order::whereDate('created_at', today())
            ->where('status', 'delivered')
            ->sum('total_amount');
        
        // Chiffre d'affaires du mois
        $monthRevenue = Order::whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->where('status', 'delivered')
            ->sum('total_amount');

        // Pharmacies
        $totalPharmacies = Pharmacy::count();
        $pendingPharmacies = Pharmacy::where('status', 'pending')->count();
        $approvedPharmacies = Pharmacy::where('status', 'approved')->count();

        // Livreurs
        $totalCouriers = Courier::count();
        $availableCouriers = Courier::where('status', 'available')->count();
        
        // KYC en attente
        $pendingKYC = Courier::where('kyc_status', 'pending_review')->count();
        $pendingApprovalCouriers = Courier::where('status', 'pending_approval')->count();

        // Utilisateurs
        $totalUsers = User::count();
        $newUsersToday = User::whereDate('created_at', today())->count();

        // Commandes en attente
        $pendingOrders = Order::where('status', 'pending')->count();
        $preparingOrders = Order::whereIn('status', ['confirmed', 'preparing', 'ready_for_pickup'])->count();
        $inDeliveryOrders = Order::where('status', 'on_the_way')->count();
        
        // Ordonnances en attente
        $pendingPrescriptions = Prescription::where('status', 'pending')->count();

        return [
            Stat::make('Commandes aujourd\'hui', $todayOrders)
                ->description($ordersChange >= 0 ? "+{$ordersChange}% vs hier" : "{$ordersChange}% vs hier")
                ->descriptionIcon($ordersChange >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color($ordersChange >= 0 ? 'success' : 'danger')
                ->chart([7, 3, 4, 5, 6, $yesterdayOrders, $todayOrders]),

            Stat::make('CA du jour', number_format($todayRevenue, 0, ',', ' ') . ' FCFA')
                ->description('Ce mois: ' . number_format($monthRevenue, 0, ',', ' ') . ' FCFA')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('success'),
                
            Stat::make('Ordonnances en attente', $pendingPrescriptions)
                ->description('À traiter')
                ->descriptionIcon('heroicon-m-document-text')
                ->color($pendingPrescriptions > 0 ? 'warning' : 'success')
                ->url(route('filament.admin.resources.prescriptions.index', ['tableFilters[status][value]' => 'pending'])),

            Stat::make('Pharmacies', $approvedPharmacies . ' / ' . $totalPharmacies)
                ->description($pendingPharmacies . ' en attente d\'approbation')
                ->descriptionIcon('heroicon-m-clock')
                ->color($pendingPharmacies > 0 ? 'warning' : 'success'),

            Stat::make('Livreurs disponibles', $availableCouriers . ' / ' . $totalCouriers)
                ->description('Prêts pour livraison')
                ->descriptionIcon('heroicon-m-truck')
                ->color($availableCouriers > 0 ? 'success' : 'danger'),
                
            Stat::make('KYC en attente', $pendingKYC)
                ->description($pendingApprovalCouriers . ' livreurs en attente d\'approbation')
                ->descriptionIcon('heroicon-m-identification')
                ->color($pendingKYC > 0 ? 'warning' : 'success')
                ->url(route('filament.admin.resources.couriers.index', ['tableFilters[kyc_status][value]' => 'pending_review'])),

            Stat::make('Commandes en attente', $pendingOrders)
                ->description($preparingOrders . ' en préparation, ' . $inDeliveryOrders . ' en livraison')
                ->descriptionIcon('heroicon-m-shopping-cart')
                ->color($pendingOrders > 5 ? 'danger' : ($pendingOrders > 0 ? 'warning' : 'success')),

            Stat::make('Utilisateurs', $totalUsers)
                ->description('+' . $newUsersToday . ' aujourd\'hui')
                ->descriptionIcon('heroicon-m-users')
                ->color('info'),
        ];
    }
}
