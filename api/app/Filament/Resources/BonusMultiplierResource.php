<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BonusMultiplierResource\Pages;
use App\Models\BonusMultiplier;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class BonusMultiplierResource extends Resource
{
    protected static ?string $model = BonusMultiplier::class;

    protected static ?string $navigationIcon = 'heroicon-o-gift';

    protected static ?string $navigationLabel = 'Bonus & Multiplicateurs';

    protected static ?string $modelLabel = 'Bonus';

    protected static ?string $pluralModelLabel = 'Bonus & Multiplicateurs';

    protected static ?string $navigationGroup = 'Finance';

    protected static ?int $navigationSort = 3;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Informations générales')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->label('Nom')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Textarea::make('description')
                            ->label('Description')
                            ->rows(2)
                            ->columnSpanFull(),
                        Forms\Components\Select::make('type')
                            ->label('Type')
                            ->options([
                                'peak_hours' => 'Heures de pointe',
                                'weekend' => 'Week-end',
                                'holiday' => 'Jour férié',
                                'rain' => 'Pluie',
                                'night' => 'Nuit',
                                'distance' => 'Distance',
                                'loyalty' => 'Fidélité',
                                'promotion' => 'Promotion',
                            ])
                            ->required()
                            ->native(false),
                    ])->columns(2),

                Forms\Components\Section::make('Valeurs')
                    ->schema([
                        Forms\Components\TextInput::make('multiplier')
                            ->label('Multiplicateur')
                            ->numeric()
                            ->step(0.01)
                            ->default(1.0)
                            ->suffix('x')
                            ->helperText('Ex: 1.5 = +50% du montant de base')
                            ->required(),
                        Forms\Components\TextInput::make('flat_bonus')
                            ->label('Bonus fixe (FCFA)')
                            ->numeric()
                            ->default(0)
                            ->suffix('FCFA')
                            ->helperText('Montant fixe ajouté en plus du multiplicateur'),
                    ])->columns(2),

                Forms\Components\Section::make('Conditions & Période')
                    ->schema([
                        Forms\Components\KeyValue::make('conditions')
                            ->label('Conditions')
                            ->keyLabel('Clé')
                            ->valueLabel('Valeur')
                            ->helperText('Conditions JSON pour déclencher le bonus (ex: min_distance, min_orders)')
                            ->columnSpanFull(),
                        Forms\Components\Toggle::make('is_active')
                            ->label('Actif')
                            ->default(true)
                            ->helperText('Désactiver pour suspendre sans supprimer'),
                        Forms\Components\DateTimePicker::make('starts_at')
                            ->label('Début')
                            ->native(false),
                        Forms\Components\DateTimePicker::make('ends_at')
                            ->label('Fin')
                            ->native(false)
                            ->after('starts_at'),
                    ])->columns(3),
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
                Tables\Columns\TextColumn::make('type')
                    ->label('Type')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'peak_hours' => 'danger',
                        'weekend' => 'warning',
                        'holiday' => 'success',
                        'rain' => 'info',
                        'night' => 'gray',
                        'promotion' => 'primary',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('multiplier')
                    ->label('Multiplicateur')
                    ->suffix('x')
                    ->sortable(),
                Tables\Columns\TextColumn::make('flat_bonus')
                    ->label('Bonus fixe')
                    ->suffix(' FCFA')
                    ->sortable(),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('Actif')
                    ->boolean()
                    ->sortable(),
                Tables\Columns\TextColumn::make('starts_at')
                    ->label('Début')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
                Tables\Columns\TextColumn::make('ends_at')
                    ->label('Fin')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Créé le')
                    ->dateTime('d/m/Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('type')
                    ->label('Type')
                    ->options([
                        'peak_hours' => 'Heures de pointe',
                        'weekend' => 'Week-end',
                        'holiday' => 'Jour férié',
                        'rain' => 'Pluie',
                        'night' => 'Nuit',
                        'distance' => 'Distance',
                        'loyalty' => 'Fidélité',
                        'promotion' => 'Promotion',
                    ]),
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Actif'),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('toggle_active')
                    ->label(fn ($record) => $record->is_active ? 'Désactiver' : 'Activer')
                    ->icon(fn ($record) => $record->is_active ? 'heroicon-o-x-circle' : 'heroicon-o-check-circle')
                    ->color(fn ($record) => $record->is_active ? 'danger' : 'success')
                    ->requiresConfirmation()
                    ->action(fn ($record) => $record->update(['is_active' => !$record->is_active])),
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
            'index' => Pages\ListBonusMultipliers::route('/'),
            'create' => Pages\CreateBonusMultiplier::route('/create'),
            'edit' => Pages\EditBonusMultiplier::route('/{record}/edit'),
        ];
    }
}
