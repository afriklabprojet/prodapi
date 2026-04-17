<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CustomerAddressResource\Pages;
use App\Models\CustomerAddress;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CustomerAddressResource extends Resource
{
    protected static ?string $model = CustomerAddress::class;

    protected static ?string $navigationIcon = 'heroicon-o-map-pin';

    protected static ?string $navigationLabel = 'Adresses clients';

    protected static ?string $modelLabel = 'Adresse';

    protected static ?string $pluralModelLabel = 'Adresses clients';

    protected static ?string $navigationGroup = 'Clients';

    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Informations')
                    ->schema([
                        Forms\Components\Select::make('user_id')
                            ->label('Client')
                            ->relationship('user', 'name')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Forms\Components\Select::make('label')
                            ->label('Label')
                            ->options([
                                'Maison' => '🏠 Maison',
                                'Bureau' => '🏢 Bureau',
                                'Famille' => '👨‍👩‍👧 Famille',
                                'Autre' => '📍 Autre',
                            ])
                            ->required()
                            ->native(false),
                        Forms\Components\TextInput::make('address')
                            ->label('Adresse')
                            ->required()
                            ->maxLength(255)
                            ->columnSpanFull(),
                        Forms\Components\TextInput::make('city')
                            ->label('Ville')
                            ->maxLength(100),
                        Forms\Components\TextInput::make('district')
                            ->label('Quartier')
                            ->maxLength(100),
                        Forms\Components\TextInput::make('phone')
                            ->label('Téléphone')
                            ->tel()
                            ->maxLength(20),
                        Forms\Components\Textarea::make('instructions')
                            ->label('Instructions de livraison')
                            ->rows(2)
                            ->columnSpanFull(),
                    ])->columns(2),

                Forms\Components\Section::make('Coordonnées GPS')
                    ->schema([
                        Forms\Components\TextInput::make('latitude')
                            ->label('Latitude')
                            ->numeric()
                            ->step(0.0000001),
                        Forms\Components\TextInput::make('longitude')
                            ->label('Longitude')
                            ->numeric()
                            ->step(0.0000001),
                        Forms\Components\Toggle::make('is_default')
                            ->label('Adresse par défaut')
                            ->helperText('Sera utilisée automatiquement pour les commandes'),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Client')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('label')
                    ->label('Label')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'Maison' => '🏠 Maison',
                        'Bureau' => '🏢 Bureau',
                        'Famille' => '👨‍👩‍👧 Famille',
                        default => '📍 ' . $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'Maison' => 'success',
                        'Bureau' => 'info',
                        'Famille' => 'warning',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('address')
                    ->label('Adresse')
                    ->searchable()
                    ->limit(40)
                    ->tooltip(fn ($record) => $record->address),
                Tables\Columns\TextColumn::make('city')
                    ->label('Ville')
                    ->searchable(),
                Tables\Columns\TextColumn::make('district')
                    ->label('Quartier')
                    ->searchable(),
                Tables\Columns\TextColumn::make('phone')
                    ->label('Téléphone'),
                Tables\Columns\IconColumn::make('is_default')
                    ->label('Défaut')
                    ->boolean(),
                Tables\Columns\IconColumn::make('has_coordinates')
                    ->label('GPS')
                    ->boolean()
                    ->getStateUsing(fn ($record) => $record->latitude && $record->longitude),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Créée le')
                    ->dateTime('d/m/Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('label')
                    ->label('Type')
                    ->options([
                        'Maison' => 'Maison',
                        'Bureau' => 'Bureau',
                        'Famille' => 'Famille',
                        'Autre' => 'Autre',
                    ]),
                Tables\Filters\TernaryFilter::make('is_default')
                    ->label('Par défaut'),
                Tables\Filters\Filter::make('has_gps')
                    ->label('Avec GPS')
                    ->query(fn ($query) => $query->whereNotNull('latitude')->whereNotNull('longitude')),
            ])
            ->actions([
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
            'index' => Pages\ListCustomerAddresses::route('/'),
            'create' => Pages\CreateCustomerAddress::route('/create'),
            'edit' => Pages\EditCustomerAddress::route('/{record}/edit'),
        ];
    }
}
