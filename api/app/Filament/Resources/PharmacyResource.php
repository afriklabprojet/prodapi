<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PharmacyResource\Pages;
use App\Models\Pharmacy;
use App\Models\DutyZone;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class PharmacyResource extends Resource
{
    protected static ?string $model = Pharmacy::class;

    protected static ?string $navigationIcon = 'heroicon-o-building-storefront';

    protected static ?string $navigationLabel = 'Pharmacies';

    protected static ?string $modelLabel = 'Pharmacie';

    protected static ?string $pluralModelLabel = 'Pharmacies';

    protected static ?string $navigationGroup = 'Partenaires';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Group::make()
                    ->schema([
                        Forms\Components\Section::make('Informations générales')
                            ->schema([
                                Forms\Components\TextInput::make('name')
                                    ->label('Nom de la pharmacie')
                                    ->required()
                                    ->maxLength(255),
                                Forms\Components\TextInput::make('owner_name')
                                    ->label('Nom du propriétaire')
                                    ->maxLength(255),
                                Forms\Components\TextInput::make('phone')
                                    ->label('Téléphone')
                                    ->tel()
                                    ->required()
                                    ->maxLength(20),
                                Forms\Components\TextInput::make('email')
                                    ->label('Email')
                                    ->email()
                                    ->maxLength(255),
                                Forms\Components\TextInput::make('license_number')
                                    ->label('Numéro de licence')
                                    ->maxLength(100),
                            ])->columns(2),

                        Forms\Components\Section::make('Adresse')
                            ->schema([
                                Forms\Components\TextInput::make('address')
                                    ->label('Adresse')
                                    ->required()
                                    ->columnSpanFull(),
                                Forms\Components\TextInput::make('city')
                                    ->label('Ville')
                                    ->required()
                                    ->maxLength(100),
                                Forms\Components\TextInput::make('region')
                                    ->label('Région')
                                    ->maxLength(100),
                                Forms\Components\Select::make('duty_zone_id')
                                    ->label('Zone de garde')
                                    ->relationship('dutyZone', 'name')
                                    ->searchable()
                                    ->preload(),
                                Forms\Components\TextInput::make('latitude')
                                    ->label('Latitude')
                                    ->numeric()
                                    ->step(0.000001),
                                Forms\Components\TextInput::make('longitude')
                                    ->label('Longitude')
                                    ->numeric()
                                    ->step(0.000001),
                            ])->columns(2),

                        Forms\Components\Section::make('Commissions')
                            ->schema([
                                Forms\Components\TextInput::make('commission_rate_platform')
                                    ->label('Commission plateforme (%)')
                                    ->numeric()
                                    ->suffix('%')
                                    ->step(0.01)
                                    ->minValue(0)
                                    ->maxValue(100)
                                    ->default(5),
                                Forms\Components\TextInput::make('commission_rate_pharmacy')
                                    ->label('Commission pharmacie (%)')
                                    ->numeric()
                                    ->suffix('%')
                                    ->step(0.01)
                                    ->minValue(0)
                                    ->maxValue(100)
                                    ->default(90),
                                Forms\Components\TextInput::make('commission_rate_courier')
                                    ->label('Commission livreur (%)')
                                    ->numeric()
                                    ->suffix('%')
                                    ->step(0.01)
                                    ->minValue(0)
                                    ->maxValue(100)
                                    ->default(5),
                            ])->columns(3),

                        Forms\Components\Section::make('Paramètres de retrait')
                            ->schema([
                                Forms\Components\TextInput::make('withdrawal_threshold')
                                    ->label('Seuil de retrait (FCFA)')
                                    ->numeric()
                                    ->prefix('FCFA')
                                    ->default(5000),
                                Forms\Components\Toggle::make('auto_withdraw_enabled')
                                    ->label('Retrait automatique activé')
                                    ->default(false),
                            ])->columns(2),
                    ])->columnSpan(['lg' => 2]),

                Forms\Components\Group::make()
                    ->schema([
                        Forms\Components\Section::make('Statut')
                            ->schema([
                                Forms\Components\Select::make('status')
                                    ->label('Statut d\'approbation')
                                    ->options([
                                        'pending' => 'En attente',
                                        'approved' => 'Approuvée',
                                        'rejected' => 'Rejetée',
                                        'suspended' => 'Suspendue',
                                    ])
                                    ->default('pending')
                                    ->required(),
                                Forms\Components\Textarea::make('rejection_reason')
                                    ->label('Raison du rejet')
                                    ->rows(3)
                                    ->visible(fn ($get) => $get('status') === 'rejected'),
                                Forms\Components\Toggle::make('is_active')
                                    ->label('Active')
                                    ->default(true),
                                Forms\Components\Toggle::make('is_open')
                                    ->label('Ouverte')
                                    ->default(true),
                                Forms\Components\Toggle::make('is_featured')
                                    ->label('Mise en avant')
                                    ->default(false),
                                Forms\Components\DateTimePicker::make('approved_at')
                                    ->label('Date d\'approbation')
                                    ->disabled(),
                            ]),

                        Forms\Components\Section::make('Documents')
                            ->schema([
                                Forms\Components\FileUpload::make('license_document')
                                    ->label('Document de licence')
                                    ->directory('pharmacies/licenses')
                                    ->acceptedFileTypes(['application/pdf', 'image/*']),
                                Forms\Components\FileUpload::make('id_card_document')
                                    ->label('Carte d\'identité')
                                    ->directory('pharmacies/id-cards')
                                    ->acceptedFileTypes(['application/pdf', 'image/*']),
                            ]),
                    ])->columnSpan(['lg' => 1]),
            ])->columns(3);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('Nom')
                    ->searchable()
                    ->sortable()
                    ->description(fn (Pharmacy $record): string => $record->owner_name ?? ''),
                Tables\Columns\TextColumn::make('phone')
                    ->label('Téléphone')
                    ->searchable(),
                Tables\Columns\TextColumn::make('city')
                    ->label('Ville')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('dutyZone.name')
                    ->label('Zone')
                    ->sortable()
                    ->toggleable(),
                Tables\Columns\TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'approved' => 'success',
                        'rejected' => 'danger',
                        'suspended' => 'gray',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pending' => 'En attente',
                        'approved' => 'Approuvée',
                        'rejected' => 'Rejetée',
                        'suspended' => 'Suspendue',
                        default => $state,
                    })
                    ->sortable(),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('Active')
                    ->boolean()
                    ->sortable(),
                Tables\Columns\IconColumn::make('is_open')
                    ->label('Ouverte')
                    ->boolean()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('products_count')
                    ->label('Produits')
                    ->counts('products')
                    ->sortable(),
                Tables\Columns\TextColumn::make('orders_count')
                    ->label('Commandes')
                    ->counts('orders')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Inscrite le')
                    ->dateTime('d/m/Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('Statut')
                    ->options([
                        'pending' => 'En attente',
                        'approved' => 'Approuvée',
                        'rejected' => 'Rejetée',
                        'suspended' => 'Suspendue',
                    ]),
                Tables\Filters\SelectFilter::make('duty_zone_id')
                    ->label('Zone de garde')
                    ->relationship('dutyZone', 'name')
                    ->searchable()
                    ->preload(),
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Active'),
                Tables\Filters\TernaryFilter::make('is_open')
                    ->label('Ouverte'),
                Tables\Filters\TernaryFilter::make('is_featured')
                    ->label('Mise en avant'),
            ])
            ->actions([
                Tables\Actions\Action::make('approve')
                    ->label('Approuver')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->visible(fn (Pharmacy $record) => $record->status === 'pending')
                    ->action(fn (Pharmacy $record) => $record->update([
                        'status' => 'approved',
                        'approved_at' => now(),
                    ])),
                Tables\Actions\Action::make('reject')
                    ->label('Rejeter')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->visible(fn (Pharmacy $record) => $record->status === 'pending')
                    ->form([
                        Forms\Components\Textarea::make('rejection_reason')
                            ->label('Raison du rejet')
                            ->required(),
                    ])
                    ->action(fn (Pharmacy $record, array $data) => $record->update([
                        'status' => 'rejected',
                        'rejection_reason' => $data['rejection_reason'],
                    ])),
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPharmacies::route('/'),
            'create' => Pages\CreatePharmacy::route('/create'),
            'edit' => Pages\EditPharmacy::route('/{record}/edit'),
        ];
    }

    public static function getGloballySearchableAttributes(): array
    {
        return ['name', 'phone', 'email', 'owner_name', 'license_number', 'city'];
    }
}
