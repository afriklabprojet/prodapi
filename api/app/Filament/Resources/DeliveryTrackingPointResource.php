<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DeliveryTrackingPointResource\Pages;
use App\Models\DeliveryTrackingPoint;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class DeliveryTrackingPointResource extends Resource
{
    protected static ?string $model = DeliveryTrackingPoint::class;

    protected static ?string $navigationIcon = 'heroicon-o-map-pin';

    protected static ?string $navigationGroup = 'Dispatch';

    protected static ?int $navigationSort = 5;

    protected static ?string $navigationLabel = 'Tracking GPS';

    protected static ?string $modelLabel = 'Point de tracking';

    protected static ?string $pluralModelLabel = 'Points de tracking';

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Select::make('delivery_id')
                ->relationship('delivery', 'id')
                ->label('Livraison')
                ->searchable()
                ->preload()
                ->required(),

            Forms\Components\TextInput::make('latitude')
                ->numeric()
                ->required(),

            Forms\Components\TextInput::make('longitude')
                ->numeric()
                ->required(),

            Forms\Components\TextInput::make('speed')
                ->numeric()
                ->suffix('km/h')
                ->label('Vitesse'),

            Forms\Components\TextInput::make('heading')
                ->numeric()
                ->suffix('°')
                ->label('Direction'),

            Forms\Components\TextInput::make('accuracy')
                ->numeric()
                ->suffix('m')
                ->label('Précision'),

            Forms\Components\Select::make('event_type')
                ->options([
                    DeliveryTrackingPoint::EVENT_LOCATION_UPDATE => 'Mise à jour GPS',
                    DeliveryTrackingPoint::EVENT_PICKUP => 'Ramassage',
                    DeliveryTrackingPoint::EVENT_DROPOFF => 'Livraison',
                    DeliveryTrackingPoint::EVENT_PAUSE => 'Pause',
                    DeliveryTrackingPoint::EVENT_RESUME => 'Reprise',
                ])
                ->label('Type d\'événement'),

            Forms\Components\DateTimePicker::make('recorded_at')
                ->label('Enregistré à')
                ->required()
                ->default(now()),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('delivery_id')
                    ->label('Livraison #')
                    ->sortable()
                    ->searchable(),

                Tables\Columns\TextColumn::make('delivery.courier.user.name')
                    ->label('Livreur')
                    ->searchable()
                    ->placeholder('—'),

                Tables\Columns\TextColumn::make('event_type')
                    ->label('Événement')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        DeliveryTrackingPoint::EVENT_PICKUP => 'success',
                        DeliveryTrackingPoint::EVENT_DROPOFF => 'info',
                        DeliveryTrackingPoint::EVENT_PAUSE => 'warning',
                        DeliveryTrackingPoint::EVENT_RESUME => 'primary',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        DeliveryTrackingPoint::EVENT_LOCATION_UPDATE => 'GPS',
                        DeliveryTrackingPoint::EVENT_PICKUP => 'Ramassage',
                        DeliveryTrackingPoint::EVENT_DROPOFF => 'Livraison',
                        DeliveryTrackingPoint::EVENT_PAUSE => 'Pause',
                        DeliveryTrackingPoint::EVENT_RESUME => 'Reprise',
                        default => $state,
                    }),

                Tables\Columns\TextColumn::make('latitude')
                    ->label('Lat')
                    ->numeric(7)
                    ->toggleable(isToggledHiddenByDefault: true),

                Tables\Columns\TextColumn::make('longitude')
                    ->label('Lng')
                    ->numeric(7)
                    ->toggleable(isToggledHiddenByDefault: true),

                Tables\Columns\TextColumn::make('speed')
                    ->label('Vitesse')
                    ->suffix(' km/h')
                    ->placeholder('—')
                    ->color(fn (?int $state): string => match (true) {
                        $state === null => 'gray',
                        $state > 60 => 'danger',
                        $state > 30 => 'warning',
                        default => 'success',
                    }),

                Tables\Columns\TextColumn::make('accuracy')
                    ->label('Précision')
                    ->suffix(' m')
                    ->placeholder('—')
                    ->color(fn (?int $state): string => match (true) {
                        $state === null => 'gray',
                        $state > 50 => 'danger',
                        $state > 20 => 'warning',
                        default => 'success',
                    }),

                Tables\Columns\TextColumn::make('recorded_at')
                    ->label('Heure')
                    ->dateTime('H:i:s')
                    ->sortable(),
            ])
            ->defaultSort('recorded_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('event_type')
                    ->label('Type')
                    ->options([
                        DeliveryTrackingPoint::EVENT_LOCATION_UPDATE => 'GPS',
                        DeliveryTrackingPoint::EVENT_PICKUP => 'Ramassage',
                        DeliveryTrackingPoint::EVENT_DROPOFF => 'Livraison',
                        DeliveryTrackingPoint::EVENT_PAUSE => 'Pause',
                        DeliveryTrackingPoint::EVENT_RESUME => 'Reprise',
                    ]),

                Tables\Filters\Filter::make('today')
                    ->label('Aujourd\'hui')
                    ->query(fn ($query) => $query->where('recorded_at', '>=', today()))
                    ->default(),

                Tables\Filters\Filter::make('high_speed')
                    ->label('Vitesse > 60 km/h')
                    ->query(fn ($query) => $query->where('speed', '>', 60)),

                Tables\Filters\Filter::make('low_accuracy')
                    ->label('Précision > 50m')
                    ->query(fn ($query) => $query->where('accuracy', '>', 50)),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
            ])
            ->bulkActions([]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListDeliveryTrackingPoints::route('/'),
        ];
    }

    public static function canCreate(): bool
    {
        return false;
    }
}
