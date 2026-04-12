<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DutyZoneResource\Pages;
use App\Models\DutyZone;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class DutyZoneResource extends Resource
{
    protected static ?string $model = DutyZone::class;

    protected static ?string $navigationIcon = 'heroicon-o-map';

    protected static ?string $navigationLabel = 'Zones de garde';

    protected static ?string $modelLabel = 'Zone de garde';

    protected static ?string $pluralModelLabel = 'Zones de garde';

    protected static ?string $navigationGroup = 'Configuration';

    protected static ?int $navigationSort = 10;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Informations de la zone')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->label('Nom de la zone')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('city')
                            ->label('Ville')
                            ->required()
                            ->maxLength(100),
                        Forms\Components\Textarea::make('description')
                            ->label('Description')
                            ->rows(3)
                            ->columnSpanFull(),
                    ])->columns(2),

                Forms\Components\Section::make('Géolocalisation')
                    ->schema([
                        Forms\Components\TextInput::make('latitude')
                            ->label('Latitude (centre)')
                            ->numeric()
                            ->step(0.000001)
                            ->required(),
                        Forms\Components\TextInput::make('longitude')
                            ->label('Longitude (centre)')
                            ->numeric()
                            ->step(0.000001)
                            ->required(),
                        Forms\Components\TextInput::make('radius')
                            ->label('Rayon (km)')
                            ->numeric()
                            ->step(0.1)
                            ->default(5)
                            ->suffix('km')
                            ->helperText('Rayon de couverture de la zone'),
                    ])->columns(3),

                Forms\Components\Section::make('Options')
                    ->schema([
                        Forms\Components\Toggle::make('is_active')
                            ->label('Zone active')
                            ->default(true),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label('Nom')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('city')
                    ->label('Ville')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('radius')
                    ->label('Rayon')
                    ->suffix(' km')
                    ->sortable(),
                Tables\Columns\TextColumn::make('pharmacies_count')
                    ->label('Pharmacies')
                    ->counts('pharmacies')
                    ->sortable(),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('Active')
                    ->boolean()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Créée le')
                    ->dateTime('d/m/Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Statut'),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->defaultSort('name');
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListDutyZones::route('/'),
            'create' => Pages\CreateDutyZone::route('/create'),
            'edit' => Pages\EditDutyZone::route('/{record}/edit'),
        ];
    }
}
