<?php

namespace App\Filament\Widgets;

use App\Models\DeliveryOffer;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

/**
 * Widget affichant les offres broadcast en attente en temps réel.
 * Permet de voir les offres actives et leur état.
 */
class BroadcastOffersWidget extends BaseWidget
{
    protected static ?int $sort = 2;
    
    protected int | string | array $columnSpan = 'full';
    
    protected static ?string $heading = '📢 Offres Broadcast en attente';
    
    protected static ?string $pollingInterval = '5s';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                DeliveryOffer::query()
                    ->with(['order.pharmacy', 'order.client', 'targetedCouriers'])
                    ->where('status', DeliveryOffer::STATUS_PENDING)
                    ->where('expires_at', '>', now())
                    ->orderBy('expires_at')
            )
            ->columns([
                Tables\Columns\TextColumn::make('order.id')
                    ->label('Commande')
                    ->formatStateUsing(fn ($state) => "CMD-{$state}")
                    ->color('primary')
                    ->url(fn ($record) => route('filament.admin.resources.orders.edit', $record->order_id)),
                    
                Tables\Columns\TextColumn::make('order.pharmacy.name')
                    ->label('Pharmacie')
                    ->limit(25)
                    ->icon('heroicon-o-building-storefront'),
                    
                Tables\Columns\TextColumn::make('broadcast_level')
                    ->label('Niveau')
                    ->badge()
                    ->color(fn ($state) => match((int)$state) {
                        1 => 'success',
                        2 => 'info',
                        3 => 'warning',
                        4 => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn ($state) => "Niv. {$state}"),
                    
                Tables\Columns\TextColumn::make('targetedCouriers')
                    ->label('Livreurs')
                    ->formatStateUsing(function ($record) {
                        $total = $record->targetedCouriers->count();
                        $viewed = $record->targetedCouriers->where('pivot.status', 'viewed')->count();
                        return "{$viewed}/{$total} vus";
                    })
                    ->badge()
                    ->color('info'),
                    
                Tables\Columns\TextColumn::make('total_fee')
                    ->label('Montant')
                    ->formatStateUsing(fn ($state) => number_format($state) . ' F')
                    ->color('success')
                    ->weight('bold'),
                    
                Tables\Columns\TextColumn::make('expires_at')
                    ->label('Expire dans')
                    ->formatStateUsing(function ($state) {
                        $seconds = now()->diffInSeconds($state, false);
                        if ($seconds <= 0) return '⏰ Expiré';
                        return "⏳ {$seconds}s";
                    })
                    ->color(fn ($state) => now()->diffInSeconds($state, false) < 15 ? 'danger' : 'warning'),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('Créée')
                    ->since(),
            ])
            ->actions([
                Tables\Actions\Action::make('view')
                    ->label('Voir')
                    ->icon('heroicon-o-eye')
                    ->url(fn ($record) => route('filament.admin.resources.delivery-offers.view', $record)),
                    
                Tables\Actions\Action::make('cancel')
                    ->label('Annuler')
                    ->icon('heroicon-o-x-mark')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->action(fn ($record) => $record->update(['status' => DeliveryOffer::STATUS_CANCELLED])),
            ])
            ->emptyStateHeading('Aucune offre en attente')
            ->emptyStateDescription('Les nouvelles offres apparaîtront ici automatiquement')
            ->emptyStateIcon('heroicon-o-megaphone');
    }
}
