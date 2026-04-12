<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CourierShiftResource\Pages;
use App\Models\CourierShift;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class CourierShiftResource extends Resource
{
    protected static ?string $model = CourierShift::class;

    protected static ?string $navigationIcon = 'heroicon-o-calendar-days';
    
    protected static ?string $navigationLabel = 'Créneaux livreurs';
    
    protected static ?string $modelLabel = 'Créneau';
    
    protected static ?string $pluralModelLabel = 'Créneaux livreurs';
    
    protected static ?string $navigationGroup = 'Dispatch';
    
    protected static ?int $navigationSort = 2;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Informations du créneau')
                    ->schema([
                        Forms\Components\Select::make('courier_id')
                            ->label('Livreur')
                            ->relationship('courier.user', 'name')
                            ->searchable()
                            ->preload()
                            ->required(),
                            
                        Forms\Components\Select::make('slot_id')
                            ->label('Créneau type')
                            ->relationship('slot', 'name')
                            ->searchable()
                            ->preload(),
                            
                        Forms\Components\DatePicker::make('date')
                            ->label('Date')
                            ->required()
                            ->default(today()),
                    ])->columns(3),
                    
                Forms\Components\Section::make('Horaires')
                    ->schema([
                        Forms\Components\TimePicker::make('start_time')
                            ->label('Début prévu')
                            ->required(),
                            
                        Forms\Components\TimePicker::make('end_time')
                            ->label('Fin prévue')
                            ->required(),
                            
                        Forms\Components\TimePicker::make('actual_start_time')
                            ->label('Début réel'),
                            
                        Forms\Components\TimePicker::make('actual_end_time')
                            ->label('Fin réelle'),
                    ])->columns(4),
                    
                Forms\Components\Section::make('Statut & Performance')
                    ->schema([
                        Forms\Components\Select::make('status')
                            ->label('Statut')
                            ->options([
                                CourierShift::STATUS_CONFIRMED => '✅ Confirmé',
                                CourierShift::STATUS_IN_PROGRESS => '🚀 En cours',
                                CourierShift::STATUS_COMPLETED => '✔️ Terminé',
                                CourierShift::STATUS_CANCELLED => '❌ Annulé',
                                CourierShift::STATUS_NO_SHOW => '⚠️ No-show',
                            ])
                            ->required()
                            ->default(CourierShift::STATUS_CONFIRMED),
                            
                        Forms\Components\TextInput::make('guaranteed_bonus')
                            ->label('Bonus garanti')
                            ->numeric()
                            ->suffix('FCFA')
                            ->default(0),
                            
                        Forms\Components\TextInput::make('earned_bonus')
                            ->label('Bonus gagné')
                            ->numeric()
                            ->suffix('FCFA')
                            ->default(0),
                            
                        Forms\Components\TextInput::make('deliveries_completed')
                            ->label('Livraisons effectuées')
                            ->numeric()
                            ->default(0),
                    ])->columns(4),
                    
                Forms\Components\Section::make('Violations')
                    ->schema([
                        Forms\Components\TextInput::make('violations_count')
                            ->label('Nombre de violations')
                            ->numeric()
                            ->default(0),
                            
                        Forms\Components\TagsInput::make('violations')
                            ->label('Types de violations')
                            ->suggestions([
                                CourierShift::VIOLATION_NOT_ACTIVE => 'Non actif',
                                CourierShift::VIOLATION_GPS_STALE => 'GPS obsolète',
                                CourierShift::VIOLATION_OUT_OF_ZONE => 'Hors zone',
                                CourierShift::VIOLATION_LOW_ACCEPTANCE => 'Acceptation faible',
                            ]),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('courier.user.name')
                    ->label('Livreur')
                    ->searchable()
                    ->sortable()
                    ->icon('heroicon-o-user'),
                    
                Tables\Columns\TextColumn::make('date')
                    ->label('Date')
                    ->date('d/m/Y')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('start_time')
                    ->label('Horaires')
                    ->formatStateUsing(fn ($state, $record) => 
                        $record->start_time?->format('H:i') . ' - ' . $record->end_time?->format('H:i')
                    ),
                    
                Tables\Columns\TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        CourierShift::STATUS_CONFIRMED => 'info',
                        CourierShift::STATUS_IN_PROGRESS => 'success',
                        CourierShift::STATUS_COMPLETED => 'gray',
                        CourierShift::STATUS_CANCELLED => 'danger',
                        CourierShift::STATUS_NO_SHOW => 'warning',
                        default => 'gray',
                    })
                    ->icon(fn (string $state): ?string => match ($state) {
                        CourierShift::STATUS_CONFIRMED => 'heroicon-o-check-circle',
                        CourierShift::STATUS_IN_PROGRESS => 'heroicon-o-play',
                        CourierShift::STATUS_COMPLETED => 'heroicon-o-check-badge',
                        CourierShift::STATUS_CANCELLED => 'heroicon-o-x-circle',
                        CourierShift::STATUS_NO_SHOW => 'heroicon-o-exclamation-triangle',
                        default => null,
                    })
                    ->formatStateUsing(fn ($state) => match($state) {
                        CourierShift::STATUS_CONFIRMED => 'Confirmé',
                        CourierShift::STATUS_IN_PROGRESS => 'En cours',
                        CourierShift::STATUS_COMPLETED => 'Terminé',
                        CourierShift::STATUS_CANCELLED => 'Annulé',
                        CourierShift::STATUS_NO_SHOW => 'No-show',
                        default => $state,
                    }),
                    
                Tables\Columns\TextColumn::make('deliveries_completed')
                    ->label('Livraisons')
                    ->badge()
                    ->color('success')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('violations_count')
                    ->label('Violations')
                    ->badge()
                    ->color(fn ($state) => $state >= 3 ? 'danger' : ($state >= 1 ? 'warning' : 'success'))
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('guaranteed_bonus')
                    ->label('Bonus garanti')
                    ->formatStateUsing(fn ($state) => number_format($state) . ' FCFA')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('calculated_bonus')
                    ->label('Bonus final')
                    ->formatStateUsing(fn ($state) => number_format($state) . ' FCFA')
                    ->color(fn ($state, $record) => $state < $record->guaranteed_bonus ? 'danger' : 'success'),
                    
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Créé le')
                    ->dateTime('d/m/Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('Statut')
                    ->options([
                        CourierShift::STATUS_CONFIRMED => 'Confirmé',
                        CourierShift::STATUS_IN_PROGRESS => 'En cours',
                        CourierShift::STATUS_COMPLETED => 'Terminé',
                        CourierShift::STATUS_CANCELLED => 'Annulé',
                        CourierShift::STATUS_NO_SHOW => 'No-show',
                    ]),
                    
                Tables\Filters\Filter::make('today')
                    ->label('Aujourd\'hui')
                    ->query(fn (Builder $query) => $query->whereDate('date', today()))
                    ->toggle()
                    ->default(true),
                    
                Tables\Filters\Filter::make('has_violations')
                    ->label('Avec violations')
                    ->query(fn (Builder $query) => $query->where('violations_count', '>', 0))
                    ->toggle(),
                    
                Tables\Filters\SelectFilter::make('courier_id')
                    ->label('Livreur')
                    ->relationship('courier.user', 'name')
                    ->searchable()
                    ->preload(),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('start')
                    ->label('Démarrer')
                    ->icon('heroicon-o-play')
                    ->color('success')
                    ->visible(fn ($record) => $record->status === CourierShift::STATUS_CONFIRMED)
                    ->action(fn ($record) => $record->update([
                        'status' => CourierShift::STATUS_IN_PROGRESS,
                        'actual_start_time' => now(),
                    ])),
                Tables\Actions\Action::make('complete')
                    ->label('Terminer')
                    ->icon('heroicon-o-check')
                    ->color('success')
                    ->visible(fn ($record) => $record->status === CourierShift::STATUS_IN_PROGRESS)
                    ->action(function ($record) {
                        $record->update([
                            'status' => CourierShift::STATUS_COMPLETED,
                            'actual_end_time' => now(),
                            'earned_bonus' => $record->calculated_bonus,
                        ]);
                    }),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->defaultSort('date', 'desc');
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCourierShifts::route('/'),
            'create' => Pages\CreateCourierShift::route('/create'),
            'edit' => Pages\EditCourierShift::route('/{record}/edit'),
        ];
    }
    
    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::where('status', CourierShift::STATUS_IN_PROGRESS)->count() ?: null;
    }
    
    public static function getNavigationBadgeColor(): ?string
    {
        return 'success';
    }
}
