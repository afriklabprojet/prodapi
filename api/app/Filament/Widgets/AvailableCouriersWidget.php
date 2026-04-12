<?php

namespace App\Filament\Widgets;

use App\Models\Courier;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;
use Illuminate\Database\Eloquent\Builder;

/**
 * Widget affichant les livreurs disponibles en temps réel sur le dashboard.
 * Permet de voir d'un coup d'œil qui est prêt à prendre des livraisons.
 */
class AvailableCouriersWidget extends BaseWidget
{
    protected static ?int $sort = 3;
    
    protected int | string | array $columnSpan = 'full';
    
    protected static ?string $heading = '🚴 Livreurs disponibles';
    
    protected static ?string $pollingInterval = '30s';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                Courier::query()
                    ->with('user')
                    ->where('status', 'available')
                    ->where('kyc_status', 'approved')
                    ->orderByDesc('last_location_update')
            )
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Nom')
                    ->searchable()
                    ->sortable()
                    ->weight('bold')
                    ->icon('heroicon-o-user'),
                    
                Tables\Columns\TextColumn::make('phone')
                    ->label('Téléphone')
                    ->searchable()
                    ->copyable()
                    ->icon('heroicon-o-phone'),
                    
                Tables\Columns\TextColumn::make('vehicle_type')
                    ->label('Véhicule')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'motorcycle' => 'warning',
                        'car' => 'info',
                        'bicycle' => 'success',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'motorcycle' => '🏍️ Moto',
                        'car' => '🚗 Voiture',
                        'bicycle' => '🚲 Vélo',
                        default => $state,
                    }),
                    
                Tables\Columns\TextColumn::make('completed_deliveries')
                    ->label('Livraisons')
                    ->numeric()
                    ->sortable()
                    ->icon('heroicon-o-check-circle')
                    ->color('success'),
                    
                Tables\Columns\TextColumn::make('rating')
                    ->label('Note')
                    ->formatStateUsing(fn ($state): string => $state ? "⭐ {$state}" : '—')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('last_location_update')
                    ->label('Dernière position')
                    ->since()
                    ->sortable()
                    ->color(function ($state) {
                        if (!$state) return 'danger';
                        $minutes = now()->diffInMinutes($state);
                        if ($minutes < 5) return 'success';
                        if ($minutes < 15) return 'warning';
                        return 'danger';
                    })
                    ->icon('heroicon-o-map-pin'),
                    
                Tables\Columns\TextColumn::make('latitude')
                    ->label('Position GPS')
                    ->formatStateUsing(function ($record) {
                        if (!$record->latitude || !$record->longitude) {
                            return '—';
                        }
                        return "📍 " . number_format($record->latitude, 4) . ", " . number_format($record->longitude, 4);
                    })
                    ->url(function ($record) {
                        if (!$record->latitude || !$record->longitude) {
                            return null;
                        }
                        return "https://www.google.com/maps?q={$record->latitude},{$record->longitude}";
                    })
                    ->openUrlInNewTab(),
            ])
            ->actions([
                Tables\Actions\Action::make('call')
                    ->label('Appeler')
                    ->icon('heroicon-o-phone')
                    ->color('success')
                    ->url(fn (Courier $record): string => "tel:{$record->phone}")
                    ->openUrlInNewTab(),
                    
                Tables\Actions\Action::make('view')
                    ->label('Voir')
                    ->icon('heroicon-o-eye')
                    ->color('info')
                    ->url(fn (Courier $record): string => route('filament.admin.resources.couriers.edit', $record)),
            ])
            ->emptyStateHeading('Aucun livreur disponible')
            ->emptyStateDescription('Tous les livreurs sont occupés ou hors ligne.')
            ->emptyStateIcon('heroicon-o-truck')
            ->paginated([5, 10, 25])
            ->defaultPaginationPageOption(5);
    }
}
