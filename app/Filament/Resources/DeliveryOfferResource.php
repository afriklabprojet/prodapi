<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DeliveryOfferResource\Pages;
use App\Models\DeliveryOffer;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Infolists;
use Filament\Infolists\Infolist;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class DeliveryOfferResource extends Resource
{
    protected static ?string $model = DeliveryOffer::class;

    protected static ?string $navigationIcon = 'heroicon-o-megaphone';
    
    protected static ?string $navigationLabel = 'Offres Broadcast';
    
    protected static ?string $modelLabel = 'Offre de livraison';
    
    protected static ?string $pluralModelLabel = 'Offres de livraison';
    
    protected static ?string $navigationGroup = 'Dispatch';
    
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Informations de l\'offre')
                    ->schema([
                        Forms\Components\Select::make('order_id')
                            ->label('Commande')
                            ->relationship('order', 'id')
                            ->getOptionLabelFromRecordUsing(fn ($record) => "CMD-{$record->id}")
                            ->searchable()
                            ->preload()
                            ->required(),
                            
                        Forms\Components\Select::make('status')
                            ->label('Statut')
                            ->options([
                                DeliveryOffer::STATUS_PENDING => '⏳ En attente',
                                DeliveryOffer::STATUS_ACCEPTED => '✅ Acceptée',
                                DeliveryOffer::STATUS_EXPIRED => '⏰ Expirée',
                                DeliveryOffer::STATUS_NO_COURIER => '❌ Aucun livreur',
                                DeliveryOffer::STATUS_CANCELLED => '🚫 Annulée',
                            ])
                            ->required()
                            ->default(DeliveryOffer::STATUS_PENDING),
                            
                        Forms\Components\Select::make('broadcast_level')
                            ->label('Niveau de broadcast')
                            ->options([
                                1 => 'Niveau 1 - 3km (3 livreurs)',
                                2 => 'Niveau 2 - 5km (5 livreurs)',
                                3 => 'Niveau 3 - 8km (10 livreurs)',
                                4 => 'Niveau 4 - 15km (tous)',
                            ])
                            ->required()
                            ->default(1),
                    ])->columns(3),
                    
                Forms\Components\Section::make('Tarification')
                    ->schema([
                        Forms\Components\TextInput::make('base_fee')
                            ->label('Frais de base')
                            ->numeric()
                            ->suffix('FCFA')
                            ->required(),
                            
                        Forms\Components\TextInput::make('bonus_fee')
                            ->label('Bonus')
                            ->numeric()
                            ->suffix('FCFA')
                            ->default(0),
                            
                        Forms\Components\Placeholder::make('total_fee')
                            ->label('Total')
                            ->content(fn ($record) => $record ? number_format($record->total_fee) . ' FCFA' : '-'),
                    ])->columns(3),
                    
                Forms\Components\Section::make('Timing')
                    ->schema([
                        Forms\Components\DateTimePicker::make('expires_at')
                            ->label('Expire le')
                            ->required(),
                            
                        Forms\Components\DateTimePicker::make('accepted_at')
                            ->label('Acceptée le'),
                            
                        Forms\Components\Select::make('accepted_by_courier_id')
                            ->label('Acceptée par')
                            ->relationship('acceptedByCourier.user', 'name')
                            ->searchable()
                            ->preload(),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('ID')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('order.id')
                    ->label('Commande')
                    ->formatStateUsing(fn ($state) => "CMD-{$state}")
                    ->url(fn ($record) => $record->order_id ? route('filament.admin.resources.orders.edit', $record->order_id) : null)
                    ->color('primary')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('order.pharmacy.name')
                    ->label('Pharmacie')
                    ->limit(20)
                    ->searchable(),
                    
                Tables\Columns\BadgeColumn::make('status')
                    ->label('Statut')
                    ->colors([
                        'warning' => DeliveryOffer::STATUS_PENDING,
                        'success' => DeliveryOffer::STATUS_ACCEPTED,
                        'gray' => DeliveryOffer::STATUS_EXPIRED,
                        'danger' => DeliveryOffer::STATUS_NO_COURIER,
                        'secondary' => DeliveryOffer::STATUS_CANCELLED,
                    ])
                    ->icons([
                        'heroicon-o-clock' => DeliveryOffer::STATUS_PENDING,
                        'heroicon-o-check' => DeliveryOffer::STATUS_ACCEPTED,
                        'heroicon-o-x-circle' => [DeliveryOffer::STATUS_EXPIRED, DeliveryOffer::STATUS_NO_COURIER],
                    ])
                    ->formatStateUsing(fn ($state) => match($state) {
                        DeliveryOffer::STATUS_PENDING => 'En attente',
                        DeliveryOffer::STATUS_ACCEPTED => 'Acceptée',
                        DeliveryOffer::STATUS_EXPIRED => 'Expirée',
                        DeliveryOffer::STATUS_NO_COURIER => 'Aucun livreur',
                        DeliveryOffer::STATUS_CANCELLED => 'Annulée',
                        default => $state,
                    }),
                    
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
                    ->label('Livreurs ciblés')
                    ->formatStateUsing(fn ($record) => $record->targetedCouriers->count())
                    ->badge()
                    ->color('primary'),
                    
                Tables\Columns\TextColumn::make('base_fee')
                    ->label('Frais')
                    ->formatStateUsing(fn ($state, $record) => number_format($record->total_fee) . ' FCFA')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('acceptedByCourier.user.name')
                    ->label('Acceptée par')
                    ->placeholder('-')
                    ->icon('heroicon-o-user'),
                    
                Tables\Columns\TextColumn::make('expires_at')
                    ->label('Expire')
                    ->dateTime('d/m H:i')
                    ->color(fn ($record) => $record->is_expired ? 'danger' : 'success')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Créée le')
                    ->dateTime('d/m/Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('Statut')
                    ->options([
                        DeliveryOffer::STATUS_PENDING => 'En attente',
                        DeliveryOffer::STATUS_ACCEPTED => 'Acceptée',
                        DeliveryOffer::STATUS_EXPIRED => 'Expirée',
                        DeliveryOffer::STATUS_NO_COURIER => 'Aucun livreur',
                        DeliveryOffer::STATUS_CANCELLED => 'Annulée',
                    ]),
                    
                Tables\Filters\SelectFilter::make('broadcast_level')
                    ->label('Niveau')
                    ->options([
                        1 => 'Niveau 1',
                        2 => 'Niveau 2',
                        3 => 'Niveau 3',
                        4 => 'Niveau 4',
                    ]),
                    
                Tables\Filters\Filter::make('pending_active')
                    ->label('En attente actives')
                    ->query(fn (Builder $query) => $query
                        ->where('status', DeliveryOffer::STATUS_PENDING)
                        ->where('expires_at', '>', now())
                    )
                    ->toggle(),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\Action::make('cancel')
                    ->label('Annuler')
                    ->icon('heroicon-o-x-mark')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->visible(fn ($record) => $record->status === DeliveryOffer::STATUS_PENDING)
                    ->action(fn ($record) => $record->update(['status' => DeliveryOffer::STATUS_CANCELLED])),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->defaultSort('created_at', 'desc')
            ->poll('10s');
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist
            ->schema([
                Infolists\Components\Section::make('Détails de l\'offre')
                    ->schema([
                        Infolists\Components\TextEntry::make('order.id')
                            ->label('Commande')
                            ->formatStateUsing(fn ($state) => "CMD-{$state}"),
                        Infolists\Components\TextEntry::make('status')
                            ->label('Statut')
                            ->badge(),
                        Infolists\Components\TextEntry::make('broadcast_level')
                            ->label('Niveau de broadcast'),
                        Infolists\Components\TextEntry::make('total_fee')
                            ->label('Total')
                            ->formatStateUsing(fn ($state) => number_format($state) . ' FCFA'),
                    ])->columns(4),
                    
                Infolists\Components\Section::make('Livreurs ciblés')
                    ->schema([
                        Infolists\Components\RepeatableEntry::make('targetedCouriers')
                            ->label('')
                            ->schema([
                                Infolists\Components\TextEntry::make('user.name')
                                    ->label('Nom'),
                                Infolists\Components\TextEntry::make('pivot.status')
                                    ->label('Statut')
                                    ->badge(),
                                Infolists\Components\TextEntry::make('pivot.notified_at')
                                    ->label('Notifié à')
                                    ->dateTime('H:i:s'),
                                Infolists\Components\TextEntry::make('pivot.viewed_at')
                                    ->label('Vu à')
                                    ->dateTime('H:i:s'),
                            ])
                            ->columns(4),
                    ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListDeliveryOffers::route('/'),
            'view' => Pages\ViewDeliveryOffer::route('/{record}'),
        ];
    }
    
    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::where('status', DeliveryOffer::STATUS_PENDING)->count() ?: null;
    }
    
    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }
}
