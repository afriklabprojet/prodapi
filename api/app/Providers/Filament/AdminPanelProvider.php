<?php

namespace App\Providers\Filament;

use App\Models\User;
use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Pages;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\Widgets;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->login()
            ->brandName('DR-PHARMA Admin')
            ->favicon(asset('favicon.ico'))
            ->colors([
                'primary' => Color::Emerald,
                'danger' => Color::Rose,
                'warning' => Color::Amber,
                'success' => Color::Green,
                'info' => Color::Sky,
            ])
            ->font('Inter')
            ->sidebarCollapsibleOnDesktop()
            ->navigationGroups([
                'Gestion',
                'Clients',
                'Logistique',
                'Finance',
                'Inventaire',
                'Gardes',
                'Analytics',
                'Support',
                'Administration',
                'Configuration',
            ])
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\\Filament\\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\\Filament\\Pages')
            ->pages([
                Pages\Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\\Filament\\Widgets')
            ->widgets([
                // Stats principales
                \App\Filament\Widgets\StatsOverview::class,
                \App\Filament\Widgets\FinanceOverviewWidget::class,
                // Graphiques
                \App\Filament\Widgets\OrdersChart::class,
                \App\Filament\Widgets\RevenueChart::class,
                \App\Filament\Widgets\DeliveryPerformanceChart::class,
                \App\Filament\Widgets\CourierStatusChart::class,
                // Tables urgentes
                \App\Filament\Widgets\PendingWithdrawalsWidget::class,
                \App\Filament\Widgets\PendingSupportWidget::class,
                // Top performers
                \App\Filament\Widgets\TopPharmaciesWidget::class,
                \App\Filament\Widgets\TopCouriersWidget::class,
                // Autres
                \App\Filament\Widgets\OnDutyStatsWidget::class,
                \App\Filament\Widgets\CurrentOnDutyPharmaciesWidget::class,
                \App\Filament\Widgets\LatestOrdersWidget::class,
                \App\Filament\Widgets\StockAlertsWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
                \App\Http\Middleware\EnsureUserIsAdmin::class,
                \App\Http\Middleware\ForcePasswordChange::class,
            ])
            ->databaseNotifications()
            ->databaseNotificationsPolling('30s');
    }
}
