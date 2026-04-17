<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CourierShiftSlotResource\Pages;
use App\Models\CourierShiftSlot;
use App\Models\DeliveryZone;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class CourierShiftSlotResource extends Resource
{
    protected static ?string $model = CourierShiftSlot::class;

    protected static ?string $navigationIcon = 'heroicon-o-clock';

    protected static ?string $navigationLabel = 'Créneaux types';

    protected static ?string $modelLabel = 'Créneau type';

    protected static ?string $pluralModelLabel = 'Créneaux types';

    protected static ?string $navigationGroup = 'Dispatch';

    protected static ?int $navigationSort = 3;

    public static function getNavigationBadge(): ?string
    {
        return (string) CourierShiftSlot::available()->count();
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'success';
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Configuration du créneau')
                    ->schema([
                        Forms\Components\Select::make('zone_id')
                            ->label('Zone')
                            ->options(fn () => DeliveryZone::pluck('name', 'id'))
                            ->searchable()
                            ->required(),

                        Forms\Components\DatePicker::make('date')
                            ->label('Date')
                            ->required()
                            ->minDate(today()),

                        Forms\Components\Select::make('shift_type')
                            ->label('Type de shift')
                            ->options([
                                'morning' => 'Matin (06h-12h)',
                                'lunch' => 'Déjeuner (11h-15h)',
                                'afternoon' => 'Après-midi (14h-19h)',
                                'dinner' => 'Dîner (18h-23h)',
                                'night' => 'Nuit (22h-02h)',
                            ])
                            ->required()
                            ->reactive()
                            ->afterStateUpdated(function ($state, Forms\Set $set) {
                                if ($state && isset(CourierShiftSlot::SHIFT_TYPES[$state])) {
                                    $config = CourierShiftSlot::SHIFT_TYPES[$state];
                                    $set('start_time', $config['start']);
                                    $set('end_time', $config['end']);
                                    $set('bonus_amount', $config['bonus']);
                                }
                            }),
                    ])->columns(3),

                Forms\Components\Section::make('Horaires & Capacité')
                    ->schema([
                        Forms\Components\TimePicker::make('start_time')
                            ->label('Début')
                            ->required()
                            ->seconds(false),

                        Forms\Components\TimePicker::make('end_time')
                            ->label('Fin')
                            ->required()
                            ->seconds(false),

                        Forms\Components\TextInput::make('capacity')
                            ->label('Capacité')
                            ->numeric()
                            ->required()
                            ->minValue(1)
                            ->maxValue(100)
                            ->default(10),

                        Forms\Components\TextInput::make('bonus_amount')
                            ->label('Bonus (FCFA)')
                            ->numeric()
                            ->default(0)
                            ->suffix('FCFA'),

                        Forms\Components\Select::make('status')
                            ->label('Statut')
                            ->options([
                                CourierShiftSlot::STATUS_OPEN => 'Ouvert',
                                CourierShiftSlot::STATUS_FULL => 'Complet',
                                CourierShiftSlot::STATUS_CLOSED => 'Fermé',
                            ])
                            ->default(CourierShiftSlot::STATUS_OPEN)
                            ->required(),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('date')
                    ->label('Date')
                    ->date('d/m/Y')
                    ->sortable(),

                Tables\Columns\TextColumn::make('zone_id')
                    ->label('Zone')
                    ->sortable(),

                Tables\Columns\TextColumn::make('shift_label')
                    ->label('Type')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'Matin' => 'info',
                        'Déjeuner' => 'warning',
                        'Après-midi' => 'success',
                        'Dîner' => 'danger',
                        'Nuit' => 'gray',
                        default => 'gray',
                    }),

                Tables\Columns\TextColumn::make('start_time')
                    ->label('Début')
                    ->time('H:i'),

                Tables\Columns\TextColumn::make('end_time')
                    ->label('Fin')
                    ->time('H:i'),

                Tables\Columns\TextColumn::make('booked_count')
                    ->label('Réservés')
                    ->formatStateUsing(fn ($record) => "{$record->booked_count}/{$record->capacity}")
                    ->color(fn ($record) => $record->fill_rate > 80 ? 'danger' : ($record->fill_rate > 50 ? 'warning' : 'success')),

                Tables\Columns\TextColumn::make('fill_rate')
                    ->label('Remplissage')
                    ->suffix('%')
                    ->sortable(query: fn (Builder $query, string $direction) => $query->orderByRaw("(booked_count * 100 / NULLIF(capacity, 0)) {$direction}")),

                Tables\Columns\TextColumn::make('bonus_amount')
                    ->label('Bonus')
                    ->money('XOF')
                    ->sortable(),

                Tables\Columns\TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'open' => 'success',
                        'full' => 'warning',
                        'closed' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'open' => 'Ouvert',
                        'full' => 'Complet',
                        'closed' => 'Fermé',
                        default => $state,
                    }),
            ])
            ->defaultSort('date', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('Statut')
                    ->options([
                        'open' => 'Ouvert',
                        'full' => 'Complet',
                        'closed' => 'Fermé',
                    ]),

                Tables\Filters\SelectFilter::make('shift_type')
                    ->label('Type')
                    ->options([
                        'morning' => 'Matin',
                        'lunch' => 'Déjeuner',
                        'afternoon' => 'Après-midi',
                        'dinner' => 'Dîner',
                        'night' => 'Nuit',
                    ]),

                Tables\Filters\Filter::make('upcoming')
                    ->label('À venir')
                    ->query(fn (Builder $query): Builder => $query->where('date', '>=', today()))
                    ->default(),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('close')
                    ->label('Fermer')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->visible(fn ($record) => $record->status === CourierShiftSlot::STATUS_OPEN)
                    ->action(fn ($record) => $record->close()),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
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
            'index' => Pages\ListCourierShiftSlots::route('/'),
            'create' => Pages\CreateCourierShiftSlot::route('/create'),
            'edit' => Pages\EditCourierShiftSlot::route('/{record}/edit'),
        ];
    }
}
