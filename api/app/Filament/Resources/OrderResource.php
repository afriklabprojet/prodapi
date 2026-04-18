<?php

namespace App\Filament\Resources;

use App\Filament\Resources\OrderResource\Pages;
use App\Filament\Resources\OrderResource\RelationManagers;
use App\Models\Order;
use Illuminate\Support\Facades\DB;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class OrderResource extends Resource
{
    protected static ?string $model = Order::class;

    protected static ?string $navigationIcon = 'heroicon-o-shopping-cart';
    
    protected static ?string $navigationLabel = 'Commandes';
    
    protected static ?string $navigationGroup = 'Gestion';
    
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('reference')
                    ->required(),
                Forms\Components\Select::make('pharmacy_id')
                    ->relationship('pharmacy', 'name')
                    ->required(),
                Forms\Components\Select::make('customer_id')
                    ->relationship('customer', 'name')
                    ->required(),
                Forms\Components\Select::make('status')
                    ->options([
                        'pending' => 'En attente',
                        'confirmed' => 'Confirmée',
                        'preparing' => 'En préparation',
                        'ready_for_pickup' => 'Prête pour ramassage',
                        'on_the_way' => 'En route',
                        'delivered' => 'Livrée',
                        'cancelled' => 'Annulée',
                    ])
                    ->required()
                    ->default('pending'),
                Forms\Components\Select::make('payment_mode')
                    ->options([
                        'cash' => 'Espèces',
                        'mobile_money' => 'Mobile Money',
                        'card' => 'Carte Bancaire',
                    ])
                    ->required(),
                Forms\Components\TextInput::make('subtotal')
                    ->required()
                    ->numeric(),
                Forms\Components\TextInput::make('delivery_fee')
                    ->required()
                    ->numeric()
                    ->default(0),
                Forms\Components\TextInput::make('total_amount')
                    ->required()
                    ->numeric(),
                Forms\Components\TextInput::make('currency')
                    ->required(),
                Forms\Components\Textarea::make('customer_notes')
                    ->columnSpanFull(),
                Forms\Components\Textarea::make('pharmacy_notes')
                    ->columnSpanFull(),
                Forms\Components\FileUpload::make('prescription_image')
                    ->image(),
                Forms\Components\TextInput::make('delivery_address')
                    ->required(),
                Forms\Components\TextInput::make('delivery_latitude')
                    ->numeric(),
                Forms\Components\TextInput::make('delivery_longitude')
                    ->numeric(),
                Forms\Components\TextInput::make('customer_phone')
                    ->tel()
                    ->required(),
                Forms\Components\DateTimePicker::make('confirmed_at'),
                Forms\Components\DateTimePicker::make('paid_at'),
                Forms\Components\DateTimePicker::make('delivered_at'),
                Forms\Components\DateTimePicker::make('cancelled_at'),
                Forms\Components\Textarea::make('cancellation_reason')
                    ->columnSpanFull(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('reference')
                    ->searchable(),
                Tables\Columns\TextColumn::make('pharmacy.name')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('customer.name')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'cancelled' => 'danger',
                        'pending' => 'warning',
                        'confirmed' => 'primary',
                        'preparing', 'ready_for_pickup', 'on_the_way' => 'info',
                        'delivered' => 'success',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pending' => 'En attente',
                        'confirmed' => 'Confirmée',
                        'preparing' => 'En préparation',
                        'ready_for_pickup' => 'Prête',
                        'on_the_way' => 'En route',
                        'delivered' => 'Livrée',
                        'cancelled' => 'Annulée',
                        default => $state,
                    })
                    ->searchable(),
                Tables\Columns\TextColumn::make('payment_mode')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'cash' => 'success',
                        'mobile_money' => 'warning',
                        'card' => 'primary',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'cash' => 'Espèces',
                        'mobile_money' => 'Mobile Money',
                        'card' => 'Carte',
                        default => $state,
                    })
                    ->searchable(),
                Tables\Columns\TextColumn::make('subtotal')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('delivery_fee')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('total_amount')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('currency')
                    ->searchable(),
                Tables\Columns\ImageColumn::make('prescription_image'),
                Tables\Columns\TextColumn::make('delivery_address')
                    ->searchable(),
                Tables\Columns\TextColumn::make('delivery_latitude')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('delivery_longitude')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('customer_phone')
                    ->searchable(),
                Tables\Columns\TextColumn::make('confirmed_at')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('paid_at')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('delivered_at')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('cancelled_at')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('deleted_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('Statut')
                    ->options([
                        'pending' => 'En attente',
                        'confirmed' => 'Confirmée',
                        'preparing' => 'En préparation',
                        'ready_for_pickup' => 'Prête pour ramassage',
                        'on_the_way' => 'En route',
                        'delivered' => 'Livrée',
                        'cancelled' => 'Annulée',
                    ]),
                Tables\Filters\SelectFilter::make('payment_mode')
                    ->label('Mode de paiement')
                    ->options([
                        'cash' => 'Espèces',
                        'mobile_money' => 'Mobile Money',
                        'card' => 'Carte Bancaire',
                    ]),
            ])
            ->actions([
                // Assignation AUTOMATIQUE - trouve le meilleur livreur
                Tables\Actions\Action::make('autoAssignCourier')
                    ->label('🤖 Auto-Assigner')
                    ->icon('heroicon-o-bolt')
                    ->color('success')
                    ->visible(fn ($record) => in_array($record->status, ['ready', 'ready_for_pickup', 'confirmed', 'preparing']) && !$record->delivery()->exists())
                    ->requiresConfirmation()
                    ->modalHeading('Assignation Automatique')
                    ->modalDescription('Le système va trouver le meilleur livreur disponible à proximité de la pharmacie (basé sur distance, note et expérience).')
                    ->modalSubmitActionLabel('Assigner automatiquement')
                    ->action(function ($record) {
                        $service = app(\App\Services\CourierAssignmentService::class);
                        $delivery = $service->assignCourier($record);
                        
                        if ($delivery) {
                            \Filament\Notifications\Notification::make()
                                ->title('✅ Livreur assigné automatiquement')
                                ->body("Livreur: {$delivery->courier->name} ({$delivery->courier->vehicle_type})")
                                ->success()
                                ->send();
                        } else {
                            \Filament\Notifications\Notification::make()
                                ->title('❌ Aucun livreur disponible')
                                ->body('Aucun livreur disponible dans un rayon de 20km. Essayez l\'assignation manuelle.')
                                ->danger()
                                ->send();
                        }
                    }),
                    
                // Assignation MANUELLE - l'admin choisit le livreur
                Tables\Actions\Action::make('assignCourier')
                    ->label('👤 Assigner Manuellement')
                    ->icon('heroicon-o-truck')
                    ->color('info')
                    ->visible(fn ($record) => in_array($record->status, ['ready', 'ready_for_pickup', 'confirmed', 'preparing']) && !$record->delivery()->exists())
                    ->form([
                        Forms\Components\Select::make('courier_id')
                            ->label('Choisir un Livreur')
                            ->options(fn () => \App\Models\Courier::where('status', 'available')
                                ->get()
                                ->mapWithKeys(fn ($c) => [$c->id => "{$c->name} ({$c->vehicle_type}) - ⭐ {$c->rating}"]))
                            ->required()
                            ->searchable()
                            ->preload()
                            ->helperText('Seuls les livreurs disponibles sont affichés'),
                    ])
                    ->action(function ($record, array $data) {
                        $courier = \App\Models\Courier::find($data['courier_id']);
                        if ($courier) {
                            $service = app(\App\Services\CourierAssignmentService::class);
                            $delivery = $service->assignSpecificCourier($record, $courier);
                            
                            if ($delivery) {
                                // Envoyer la notification au livreur
                                try {
                                    $courier->user->notify(new \App\Notifications\DeliveryAssignedNotification($delivery));
                                } catch (\Exception $e) {
                                    \Illuminate\Support\Facades\Log::error("Failed to notify courier: " . $e->getMessage());
                                }
                                
                                \Filament\Notifications\Notification::make()
                                    ->title('✅ Livreur assigné manuellement')
                                    ->body("Livreur: {$courier->name} - Notification envoyée")
                                    ->success()
                                    ->send();
                            } else {
                                \Filament\Notifications\Notification::make()
                                    ->title('❌ Erreur')
                                    ->body('Impossible d\'assigner ce livreur')
                                    ->danger()
                                    ->send();
                            }
                        }
                    }),
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('cancel')
                    ->label('Annuler')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->visible(fn ($record) => !in_array($record->status, ['delivered', 'cancelled']))
                    ->action(function ($record) {
                        $record->update([
                            'status' => 'cancelled',
                            'cancelled_at' => now(),
                        ]);
                    }),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
                Tables\Actions\BulkAction::make('exportCsv')
                    ->label('Exporter CSV')
                    ->icon('heroicon-o-arrow-down-tray')
                    ->action(function (\Illuminate\Database\Eloquent\Collection $records) {
                        $csvData = "Référence,Client,Pharmacie,Statut,Montant,Date\n";
                        foreach ($records as $record) {
                            $csvData .= "{$record->reference},{$record->customer?->name},{$record->pharmacy?->name},{$record->status},{$record->total_amount},{$record->created_at}\n";
                        }
                        
                        return response()->streamDownload(function () use ($csvData) {
                            echo $csvData;
                        }, 'orders_export_' . now()->format('Ymd_His') . '.csv');
                    }),
            ])->defaultSort('created_at', 'desc');
    }

    public static function getRelations(): array
    {
        return [
            RelationManagers\ItemsRelationManager::class,
            RelationManagers\DeliveryRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListOrders::route('/'),
            'create' => Pages\CreateOrder::route('/create'),
            'edit' => Pages\EditOrder::route('/{record}/edit'),
        ];
    }
}
