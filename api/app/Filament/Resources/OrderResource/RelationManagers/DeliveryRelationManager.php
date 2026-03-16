<?php

namespace App\Filament\Resources\OrderResource\RelationManagers;

use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class DeliveryRelationManager extends RelationManager
{
    protected static string $relationship = 'delivery';

    protected static ?string $title = 'Livraison';

    protected static ?string $recordTitleAttribute = 'status';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('courier_id')
                    ->label('Coursier')
                    ->relationship('courier.user', 'name')
                    ->searchable()
                    ->preload(),
                Forms\Components\Select::make('status')
                    ->label('Statut')
                    ->options([
                        'pending' => 'En attente',
                        'assigned' => 'Assignée',
                        'accepted' => 'Acceptée',
                        'picked_up' => 'Récupérée',
                        'in_transit' => 'En transit',
                        'delivered' => 'Livrée',
                        'failed' => 'Échouée',
                        'cancelled' => 'Annulée',
                    ])
                    ->required(),
                Forms\Components\TextInput::make('delivery_fee')
                    ->label('Frais de livraison (FCFA)')
                    ->numeric(),
                Forms\Components\Textarea::make('delivery_notes')
                    ->label('Notes')
                    ->rows(2)
                    ->columnSpanFull(),
                Forms\Components\Textarea::make('failure_reason')
                    ->label('Raison d\'échec')
                    ->rows(2)
                    ->columnSpanFull(),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('courier.user.name')
                    ->label('Coursier')
                    ->default('Non assigné'),
                Tables\Columns\TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'gray',
                        'assigned' => 'info',
                        'accepted' => 'primary',
                        'picked_up' => 'warning',
                        'in_transit' => 'warning',
                        'delivered' => 'success',
                        'failed' => 'danger',
                        'cancelled' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pending' => 'En attente',
                        'assigned' => 'Assignée',
                        'accepted' => 'Acceptée',
                        'picked_up' => 'Récupérée',
                        'in_transit' => 'En transit',
                        'delivered' => 'Livrée',
                        'failed' => 'Échouée',
                        'cancelled' => 'Annulée',
                        default => $state,
                    }),
                Tables\Columns\TextColumn::make('pickup_address')
                    ->label('Adresse récup.')
                    ->limit(25)
                    ->tooltip(fn ($record) => $record->pickup_address),
                Tables\Columns\TextColumn::make('delivery_address')
                    ->label('Adresse livr.')
                    ->limit(25)
                    ->tooltip(fn ($record) => $record->delivery_address),
                Tables\Columns\TextColumn::make('delivery_fee')
                    ->label('Frais')
                    ->suffix(' FCFA')
                    ->numeric(0, ',', ' '),
                Tables\Columns\TextColumn::make('estimated_distance')
                    ->label('Distance')
                    ->suffix(' km'),
                Tables\Columns\TextColumn::make('estimated_duration')
                    ->label('Durée est.')
                    ->suffix(' min'),
                Tables\Columns\TextColumn::make('assigned_at')
                    ->label('Assignée')
                    ->dateTime('H:i'),
                Tables\Columns\TextColumn::make('delivered_at')
                    ->label('Livrée')
                    ->dateTime('d/m H:i'),
                Tables\Columns\ImageColumn::make('delivery_proof_image')
                    ->label('Preuve')
                    ->circular(),
            ])
            ->filters([])
            ->headerActions([])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([]);
    }
}
