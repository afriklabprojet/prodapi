<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DeliveryZoneResource\Pages;
use App\Models\DeliveryZone;
use App\Models\Pharmacy;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Infolists;
use Filament\Infolists\Infolist;

class DeliveryZoneResource extends Resource
{
    protected static ?string $model = DeliveryZone::class;

    protected static ?string $navigationIcon = 'heroicon-o-map';

    protected static ?string $navigationLabel = 'Zones de livraison';

    protected static ?string $modelLabel = 'Zone de livraison';

    protected static ?string $pluralModelLabel = 'Zones de livraison';

    protected static ?string $navigationGroup = 'Logistique';

    protected static ?int $navigationSort = 5;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Informations de la zone')
                    ->schema([
                        Forms\Components\Select::make('pharmacy_id')
                            ->label('Pharmacie')
                            ->relationship('pharmacy', 'name')
                            ->searchable()
                            ->preload()
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->helperText('Une seule zone par pharmacie'),

                        Forms\Components\TextInput::make('name')
                            ->label('Nom de la zone')
                            ->default('Zone de livraison')
                            ->maxLength(100)
                            ->required(),

                        Forms\Components\TextInput::make('radius_km')
                            ->label('Rayon (km)')
                            ->numeric()
                            ->minValue(0.5)
                            ->maxValue(50)
                            ->step(0.5)
                            ->suffix('km')
                            ->helperText('Rayon indicatif de la zone de couverture'),

                        Forms\Components\Toggle::make('is_active')
                            ->label('Zone active')
                            ->default(true)
                            ->helperText('Désactiver la zone permet de livrer sans restriction géographique'),
                    ])
                    ->columns(2),

                Forms\Components\Section::make('Polygone de la zone')
                    ->schema([
                        Forms\Components\Textarea::make('polygon_display')
                            ->label('Coordonnées du polygone (JSON)')
                            ->disabled()
                            ->rows(4)
                            ->helperText('Le polygone est défini depuis l\'app pharmacie. Aperçu des coordonnées.')
                            ->formatStateUsing(function ($record) {
                                if (!$record || !$record->polygon) return 'Aucun polygone défini';
                                $points = is_array($record->polygon) ? $record->polygon : json_decode($record->polygon, true);
                                if (!$points) return 'Aucun polygone défini';
                                $count = count($points);
                                $first = $points[0] ?? null;
                                $last = end($points);
                                return "{$count} points\nPremier: ({$first['lat']}, {$first['lng']})\nDernier: ({$last['lat']}, {$last['lng']})";
                            }),
                    ])
                    ->collapsible()
                    ->collapsed(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('pharmacy.name')
                    ->label('Pharmacie')
                    ->searchable()
                    ->sortable()
                    ->icon('heroicon-o-building-storefront'),

                Tables\Columns\TextColumn::make('name')
                    ->label('Zone')
                    ->searchable(),

                Tables\Columns\TextColumn::make('points_count')
                    ->label('Points')
                    ->getStateUsing(fn ($record) => $record->points_count)
                    ->suffix(' pts')
                    ->badge()
                    ->color(fn ($state) => $state >= 3 ? 'success' : 'warning'),

                Tables\Columns\TextColumn::make('radius_km')
                    ->label('Rayon')
                    ->suffix(' km')
                    ->sortable()
                    ->placeholder('Non défini'),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('Active')
                    ->boolean()
                    ->sortable(),

                Tables\Columns\TextColumn::make('updated_at')
                    ->label('Dernière modification')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Statut')
                    ->trueLabel('Actives')
                    ->falseLabel('Inactives'),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('toggle_active')
                    ->label(fn ($record) => $record->is_active ? 'Désactiver' : 'Activer')
                    ->icon(fn ($record) => $record->is_active ? 'heroicon-o-pause-circle' : 'heroicon-o-play-circle')
                    ->color(fn ($record) => $record->is_active ? 'warning' : 'success')
                    ->requiresConfirmation()
                    ->action(fn ($record) => $record->update(['is_active' => !$record->is_active])),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->defaultSort('updated_at', 'desc')
            ->emptyStateHeading('Aucune zone de livraison')
            ->emptyStateDescription('Les pharmacies définissent leurs zones de livraison depuis leur application.')
            ->emptyStateIcon('heroicon-o-map');
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist
            ->schema([
                Infolists\Components\Section::make('Détails de la zone')
                    ->schema([
                        Infolists\Components\TextEntry::make('pharmacy.name')
                            ->label('Pharmacie')
                            ->icon('heroicon-o-building-storefront'),
                        Infolists\Components\TextEntry::make('name')
                            ->label('Nom'),
                        Infolists\Components\TextEntry::make('radius_km')
                            ->label('Rayon')
                            ->suffix(' km'),
                        Infolists\Components\IconEntry::make('is_active')
                            ->label('Active')
                            ->boolean(),
                        Infolists\Components\TextEntry::make('points_count')
                            ->label('Points du polygone')
                            ->getStateUsing(fn ($record) => $record->points_count . ' points'),
                        Infolists\Components\TextEntry::make('created_at')
                            ->label('Créée le')
                            ->dateTime('d/m/Y H:i'),
                        Infolists\Components\TextEntry::make('updated_at')
                            ->label('Modifiée le')
                            ->dateTime('d/m/Y H:i'),
                    ])
                    ->columns(3),
            ]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListDeliveryZones::route('/'),
            'view' => Pages\ViewDeliveryZone::route('/{record}'),
            'edit' => Pages\EditDeliveryZone::route('/{record}/edit'),
        ];
    }

    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::where('is_active', true)->count() ?: null;
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'success';
    }
}
