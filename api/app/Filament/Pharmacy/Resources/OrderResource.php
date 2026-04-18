<?php

namespace App\Filament\Pharmacy\Resources;

use App\Filament\Pharmacy\Resources\OrderResource\Pages;
use App\Models\Order;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Auth;

class OrderResource extends Resource
{
    protected static ?string $model = Order::class;

    protected static ?string $navigationIcon = 'heroicon-o-shopping-cart';
    
    protected static ?string $navigationLabel = 'Commandes';

    public static function getEloquentQuery(): Builder
    {
        // Filter orders for the logged-in user's pharmacy
        return parent::getEloquentQuery()->whereHas('pharmacy', function ($query) {
            $query->whereIn('id', Auth::user()->pharmacies->pluck('id'));
        });
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Détails de la commande')
                    ->schema([
                        Forms\Components\TextInput::make('reference')
                            ->label('Référence')
                            ->disabled(),
                        Forms\Components\TextInput::make('status')
                            ->label('Statut')
                            ->disabled(),
                        Forms\Components\TextInput::make('total_amount')
                            ->label('Montant Total')
                            ->suffix('FCFA')
                            ->disabled(),
                        Forms\Components\TextInput::make('payment_mode')
                            ->label('Mode de paiement')
                            ->disabled(),
                    ])->columns(2),
                
                Forms\Components\Section::make('Client')
                    ->schema([
                        Forms\Components\TextInput::make('customer.name')
                            ->label('Nom du client')
                            ->disabled(),
                        Forms\Components\TextInput::make('customer_phone')
                            ->label('Téléphone')
                            ->disabled(),
                        Forms\Components\Textarea::make('delivery_address')
                            ->label('Adresse de livraison')
                            ->disabled()
                            ->columnSpanFull(),
                    ])->columns(2),

                Forms\Components\Section::make('Notes')
                    ->schema([
                        Forms\Components\Textarea::make('customer_notes')
                            ->label('Notes du client')
                            ->disabled(),
                        Forms\Components\Textarea::make('pharmacy_notes')
                            ->label('Notes de la pharmacie'),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('reference')
                    ->label('Référence')
                    ->searchable(),
                Tables\Columns\TextColumn::make('customer.name')
                    ->label('Client')
                    ->searchable(),
                Tables\Columns\TextColumn::make('status')
                    ->label('Statut')
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
                        'ready' => 'Prête',
                        'on_the_way' => 'En route',
                        'delivered' => 'Livrée',
                        'cancelled' => 'Annulée',
                        default => $state,
                    }),
                Tables\Columns\TextColumn::make('total_amount')
                    ->label('Montant')
                    ->money('XOF'),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Date')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'pending' => 'En attente',
                        'confirmed' => 'Confirmée',
                        'preparing' => 'En préparation',
                        'ready' => 'Prête',
                        'on_the_way' => 'En route',
                        'delivered' => 'Livrée',
                    ]),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\Action::make('confirm')
                    ->label('Confirmer')
                    ->color('success')
                    ->icon('heroicon-o-check')
                    ->requiresConfirmation()
                    ->visible(fn (Order $record) => $record->status === 'pending' && (
                        $record->paid_at !== null
                        || ($record->payment_status ?? 'pending') === 'paid'
                        || $record->payment_mode === 'cash'
                    ))
                    ->action(function (Order $record) {
                        // Décrémenter le stock
                        foreach ($record->items as $item) {
                            $product = \App\Models\Product::find($item->product_id); // Assuming product_id exists on OrderItem, need to check
                            if ($product) {
                                $product->decrement('stock_quantity', $item->quantity);
                            }
                        }
                        
                        $record->update(['status' => 'confirmed', 'confirmed_at' => now()]);
                    }),
                Tables\Actions\Action::make('ready')
                    ->label('Prête')
                    ->color('info')
                    ->icon('heroicon-o-cube')
                    ->requiresConfirmation()
                    ->visible(fn (Order $record) => in_array($record->status, ['confirmed', 'preparing']))
                    ->action(function (Order $record) {
                        $record->update(['status' => 'ready']);
                        
                        // Tenter d'assigner un livreur
                        $courierService = app(\App\Services\CourierAssignmentService::class);
                        $delivery = $courierService->assignCourier($record);
                        
                        if ($delivery) {
                            \Filament\Notifications\Notification::make()
                                ->title('Livreur assigné')
                                ->body("Le livreur a été notifié.")
                                ->success()
                                ->send();
                        } else {
                            \Filament\Notifications\Notification::make()
                                ->title('Aucun livreur disponible')
                                ->body("La commande est prête, mais aucun livreur n'a pu être assigné pour le moment.")
                                ->warning()
                                ->send();
                        }
                    }),
            ])
            ->bulkActions([
                //
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
            'index' => Pages\ListOrders::route('/'),
            'view' => Pages\ViewOrder::route('/{record}'),
        ];
    }
}
