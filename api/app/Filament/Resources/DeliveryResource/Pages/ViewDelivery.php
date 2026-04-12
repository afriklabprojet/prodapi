<?php

namespace App\Filament\Resources\DeliveryResource\Pages;

use App\Filament\Resources\DeliveryResource;
use Filament\Actions;
use Filament\Infolists\Infolist;
use Filament\Infolists\Components;
use Filament\Resources\Pages\ViewRecord;

class ViewDelivery extends ViewRecord
{
    protected static string $resource = DeliveryResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\EditAction::make(),
            Actions\Action::make('reassign')
                ->label('Réassigner')
                ->icon('heroicon-o-arrow-path')
                ->color('warning')
                ->visible(fn () => !in_array($this->record->status, ['delivered', 'cancelled', 'failed']))
                ->form([
                    \Filament\Forms\Components\Select::make('courier_id')
                        ->label('Nouveau livreur')
                        ->options(function () {
                            return \App\Models\Courier::with('user')
                                ->where('status', 'approved')
                                ->where('is_available', true)
                                ->get()
                                ->pluck('user.name', 'id');
                        })
                        ->required()
                        ->searchable(),
                    \Filament\Forms\Components\Textarea::make('reason')
                        ->label('Raison du changement'),
                ])
                ->action(function (array $data) {
                    $this->record->update([
                        'courier_id' => $data['courier_id'],
                        'status' => 'assigned',
                        'assigned_at' => now(),
                    ]);
                }),
        ];
    }
    
    public function infolist(Infolist $infolist): Infolist
    {
        return $infolist
            ->schema([
                Components\Section::make('Informations générales')
                    ->schema([
                        Components\TextEntry::make('id')
                            ->label('ID'),
                        Components\TextEntry::make('order.id')
                            ->label('Commande')
                            ->formatStateUsing(fn ($state) => "#{$state}"),
                        Components\TextEntry::make('courier.user.name')
                            ->label('Livreur')
                            ->placeholder('Non assigné'),
                        Components\TextEntry::make('status')
                            ->label('Statut')
                            ->badge()
                            ->formatStateUsing(fn (string $state): string => match ($state) {
                                'pending' => '⏳ En attente',
                                'assigned' => '📋 Assignée',
                                'accepted' => '✅ Acceptée',
                                'picked_up' => '📦 Récupérée',
                                'in_transit' => '🚗 En cours',
                                'arrived' => '📍 Arrivé',
                                'delivered' => '✔️ Livrée',
                                'failed' => '❌ Échouée',
                                'cancelled' => '🚫 Annulée',
                                default => $state,
                            })
                            ->color(fn (string $state): string => match ($state) {
                                'pending' => 'gray',
                                'assigned' => 'info',
                                'accepted' => 'primary',
                                'picked_up', 'in_transit' => 'warning',
                                'arrived' => 'info',
                                'delivered' => 'success',
                                'failed', 'cancelled' => 'danger',
                                default => 'gray',
                            }),
                    ])->columns(4),
                    
                Components\Section::make('Adresses')
                    ->schema([
                        Components\TextEntry::make('pickup_address')
                            ->label('Récupération')
                            ->icon('heroicon-o-building-storefront'),
                        Components\TextEntry::make('delivery_address')
                            ->label('Livraison')
                            ->icon('heroicon-o-map-pin'),
                    ])->columns(2),
                    
                Components\Section::make('Détails')
                    ->schema([
                        Components\TextEntry::make('delivery_fee')
                            ->label('Frais')
                            ->formatStateUsing(fn ($state) => number_format($state ?? 0, 0, ',', ' ') . ' FCFA'),
                        Components\TextEntry::make('estimated_distance')
                            ->label('Distance')
                            ->formatStateUsing(fn ($state) => $state ? number_format($state, 1) . ' km' : '-'),
                        Components\TextEntry::make('estimated_duration')
                            ->label('Durée estimée')
                            ->formatStateUsing(fn ($state) => $state ? $state . ' min' : '-'),
                        Components\TextEntry::make('customer_rating')
                            ->label('Note client')
                            ->formatStateUsing(fn ($state) => $state ? "⭐ {$state}/5" : 'Non noté'),
                    ])->columns(4),
                    
                Components\Section::make('Chronologie')
                    ->schema([
                        Components\TextEntry::make('created_at')
                            ->label('Créée')
                            ->dateTime('d/m/Y H:i'),
                        Components\TextEntry::make('assigned_at')
                            ->label('Assignée')
                            ->dateTime('d/m/Y H:i')
                            ->placeholder('-'),
                        Components\TextEntry::make('accepted_at')
                            ->label('Acceptée')
                            ->dateTime('d/m/Y H:i')
                            ->placeholder('-'),
                        Components\TextEntry::make('picked_up_at')
                            ->label('Récupérée')
                            ->dateTime('d/m/Y H:i')
                            ->placeholder('-'),
                        Components\TextEntry::make('delivered_at')
                            ->label('Livrée')
                            ->dateTime('d/m/Y H:i')
                            ->placeholder('-'),
                    ])->columns(5),
                    
                Components\Section::make('Notes')
                    ->schema([
                        Components\TextEntry::make('delivery_notes')
                            ->label('Notes de livraison')
                            ->placeholder('Aucune note'),
                        Components\TextEntry::make('cancellation_reason')
                            ->label('Raison d\'annulation')
                            ->placeholder('-')
                            ->visible(fn ($record) => in_array($record->status, ['cancelled', 'failed'])),
                        Components\TextEntry::make('customer_rating_comment')
                            ->label('Commentaire client')
                            ->placeholder('-'),
                    ])->columns(1),
            ]);
    }
}
