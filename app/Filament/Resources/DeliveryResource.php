<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DeliveryResource\Pages;
use App\Filament\Resources\DeliveryResource\Widgets;
use App\Models\Delivery;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class DeliveryResource extends Resource
{
    protected static ?string $model = Delivery::class;

    protected static ?string $navigationIcon = 'heroicon-o-truck';
    
    protected static ?string $navigationLabel = 'Livraisons';
    
    protected static ?string $modelLabel = 'Livraison';
    
    protected static ?string $pluralModelLabel = 'Livraisons';
    
    protected static ?string $navigationGroup = 'Logistique';
    
    protected static ?int $navigationSort = 1;
    
    public static function getWidgets(): array
    {
        return [
            Widgets\DeliveryStatsWidget::class,
        ];
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Informations générales')
                    ->schema([
                        Forms\Components\Select::make('order_id')
                            ->label('Commande')
                            ->relationship('order', 'id')
                            ->searchable()
                            ->preload()
                            ->required(),
                            
                        Forms\Components\Select::make('courier_id')
                            ->label('Livreur')
                            ->relationship('courier.user', 'name')
                            ->searchable()
                            ->preload()
                            ->nullable(),
                            
                        Forms\Components\Select::make('status')
                            ->label('Statut')
                            ->options([
                                'pending' => '⏳ En attente',
                                'assigned' => '📋 Assignée',
                                'accepted' => '✅ Acceptée',
                                'picked_up' => '📦 Récupérée',
                                'in_transit' => '🚗 En cours',
                                'arrived' => '📍 Arrivé',
                                'delivered' => '✔️ Livrée',
                                'failed' => '❌ Échouée',
                                'cancelled' => '🚫 Annulée',
                            ])
                            ->required()
                            ->default('pending'),
                    ])->columns(3),
                    
                Forms\Components\Section::make('Adresses')
                    ->schema([
                        Forms\Components\Textarea::make('pickup_address')
                            ->label('Adresse de récupération')
                            ->rows(2),
                            
                        Forms\Components\Textarea::make('delivery_address')
                            ->label('Adresse de livraison')
                            ->rows(2),
                    ])->columns(2),
                    
                Forms\Components\Section::make('Détails')
                    ->schema([
                        Forms\Components\TextInput::make('delivery_fee')
                            ->label('Frais de livraison')
                            ->numeric()
                            ->suffix('FCFA'),
                            
                        Forms\Components\TextInput::make('estimated_distance')
                            ->label('Distance estimée')
                            ->numeric()
                            ->suffix('km'),
                            
                        Forms\Components\TextInput::make('estimated_duration')
                            ->label('Durée estimée')
                            ->numeric()
                            ->suffix('min'),
                            
                        Forms\Components\Textarea::make('delivery_notes')
                            ->label('Notes')
                            ->rows(2)
                            ->columnSpanFull(),
                    ])->columns(3),
                    
                Forms\Components\Section::make('Chronologie')
                    ->schema([
                        Forms\Components\DateTimePicker::make('assigned_at')
                            ->label('Assignée le'),
                        Forms\Components\DateTimePicker::make('accepted_at')
                            ->label('Acceptée le'),
                        Forms\Components\DateTimePicker::make('picked_up_at')
                            ->label('Récupérée le'),
                        Forms\Components\DateTimePicker::make('delivered_at')
                            ->label('Livrée le'),
                    ])->columns(4),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('order.id')
                    ->label('Réf. Commande')
                    ->formatStateUsing(fn ($state) => $state ? "CMD-{$state}" : '-')
                    ->url(fn ($record) => $record->order_id ? route('filament.admin.resources.orders.edit', $record->order_id) : null)
                    ->color('primary')
                    ->sortable()
                    ->searchable(),
                    
                Tables\Columns\TextColumn::make('order.user.name')
                    ->label('Client')
                    ->searchable()
                    ->placeholder('-')
                    ->icon('heroicon-o-user'),
                    
                Tables\Columns\TextColumn::make('order.pharmacy.name')
                    ->label('Pharmacie')
                    ->searchable()
                    ->placeholder('-')
                    ->limit(20)
                    ->icon('heroicon-o-building-storefront'),
                    
                Tables\Columns\TextColumn::make('courier.user.name')
                    ->label('Livreur')
                    ->searchable()
                    ->placeholder('Non assigné')
                    ->icon('heroicon-o-user'),
                    
                Tables\Columns\TextColumn::make('status')
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
                    
                Tables\Columns\TextColumn::make('order.total_amount')
                    ->label('Montant')
                    ->formatStateUsing(fn ($state) => number_format($state ?? 0, 0, ',', ' ') . ' F')
                    ->sortable()
                    ->color('success'),
                    
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Créée')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('delivered_at')
                    ->label('Livrée le')
                    ->dateTime('d/m/Y H:i')
                    ->sortable()
                    ->placeholder('-'),
                    
                Tables\Columns\TextColumn::make('delivery_fee')
                    ->label('Frais livraison')
                    ->formatStateUsing(fn ($state) => number_format($state ?? 0, 0, ',', ' ') . ' F')
                    ->toggleable(isToggledHiddenByDefault: true),
                    
                Tables\Columns\TextColumn::make('estimated_distance')
                    ->label('Distance')
                    ->formatStateUsing(fn ($state) => $state ? number_format($state, 1) . ' km' : '-')
                    ->toggleable(isToggledHiddenByDefault: true),
                    
                Tables\Columns\TextColumn::make('customer_rating')
                    ->label('Note')
                    ->formatStateUsing(fn ($state) => $state ? "⭐ {$state}/5" : '-')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('id', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('Statut')
                    ->multiple()
                    ->options([
                        'pending' => 'En attente',
                        'assigned' => 'Assignée',
                        'accepted' => 'Acceptée',
                        'picked_up' => 'Récupérée',
                        'in_transit' => 'En cours',
                        'arrived' => 'Arrivé',
                        'delivered' => 'Livrée',
                        'failed' => 'Échouée',
                        'cancelled' => 'Annulée',
                    ]),
                    
                Tables\Filters\SelectFilter::make('courier_id')
                    ->label('Livreur')
                    ->relationship('courier.user', 'name')
                    ->searchable()
                    ->preload(),
                    
                Tables\Filters\Filter::make('in_progress')
                    ->label('En cours')
                    ->query(fn (Builder $query) => $query->whereIn('status', ['assigned', 'accepted', 'picked_up', 'in_transit', 'arrived'])),
                    
                Tables\Filters\Filter::make('today')
                    ->label('Aujourd\'hui')
                    ->query(fn (Builder $query) => $query->whereDate('created_at', today())),
                    
                Tables\Filters\Filter::make('unassigned')
                    ->label('Non assignées')
                    ->query(fn (Builder $query) => $query->whereNull('courier_id')),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('assign')
                    ->label('Assigner')
                    ->icon('heroicon-o-user-plus')
                    ->color('primary')
                    ->visible(function ($record) {
                        // Vérifier si la commande peut être assignée
                        if ($record->courier_id !== null || $record->status !== 'pending') {
                            return false;
                        }
                        // Vérifier s'il y a au moins un livreur disponible
                        return \App\Models\Courier::where('status', 'available')
                            ->where('kyc_status', 'approved')
                            ->exists();
                    })
                    ->form([
                        Forms\Components\Select::make('courier_id')
                            ->label('Livreur disponible')
                            ->options(function () {
                                return \App\Models\Courier::with('user')
                                    ->where('status', 'available')
                                    ->where('kyc_status', 'approved')
                                    ->get()
                                    ->mapWithKeys(function ($courier) {
                                        $vehicle = match($courier->vehicle_type) {
                                            'motorcycle' => '🏍️',
                                            'car' => '🚗',
                                            'bicycle' => '🚲',
                                            default => '📦',
                                        };
                                        $rating = $courier->rating ? "⭐{$courier->rating}" : '';
                                        return [$courier->id => "{$vehicle} {$courier->user->name} {$rating}"];
                                    });
                            })
                            ->required()
                            ->searchable()
                            ->placeholder('Sélectionner un livreur')
                            ->helperText('Seuls les livreurs disponibles et vérifiés sont affichés'),
                    ])
                    ->action(function ($record, array $data) {
                        // Marquer le coursier comme occupé
                        \App\Models\Courier::where('id', $data['courier_id'])
                            ->update(['status' => 'busy']);
                        
                        $record->update([
                            'courier_id' => $data['courier_id'],
                            'status' => 'assigned',
                            'assigned_at' => now(),
                        ]);
                    }),
                // Message quand aucun livreur n'est disponible
                Tables\Actions\Action::make('no_courier')
                    ->label('Pas de livreur')
                    ->icon('heroicon-o-exclamation-triangle')
                    ->color('warning')
                    ->visible(function ($record) {
                        // Afficher seulement si la commande peut être assignée mais aucun livreur n'est disponible
                        if ($record->courier_id !== null || $record->status !== 'pending') {
                            return false;
                        }
                        return !\App\Models\Courier::where('status', 'available')
                            ->where('kyc_status', 'approved')
                            ->exists();
                    })
                    ->disabled()
                    ->tooltip('Aucun livreur disponible actuellement'),
                Tables\Actions\Action::make('cancel')
                    ->label('Annuler')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->visible(fn ($record) => !in_array($record->status, ['delivered', 'cancelled', 'failed']))
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\Textarea::make('cancellation_reason')
                            ->label('Raison')
                            ->required(),
                    ])
                    ->action(function ($record, array $data) {
                        $record->update([
                            'status' => 'cancelled',
                            'cancellation_reason' => $data['cancellation_reason'],
                        ]);
                    }),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListDeliveries::route('/'),
            'create' => Pages\CreateDelivery::route('/create'),
            'view' => Pages\ViewDelivery::route('/{record}'),
            'edit' => Pages\EditDelivery::route('/{record}/edit'),
        ];
    }
    
    public static function getNavigationBadge(): ?string
    {
        $inProgress = static::getModel()::whereIn('status', ['assigned', 'accepted', 'picked_up', 'in_transit', 'arrived'])->count();
        return $inProgress ?: null;
    }
    
    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }
    
    public static function getGloballySearchableAttributes(): array
    {
        return ['delivery_address', 'pickup_address', 'courier.user.name'];
    }
}
