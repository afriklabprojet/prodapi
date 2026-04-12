<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CourierChallengeProgressResource\Pages;
use App\Models\CourierChallengeProgress;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CourierChallengeProgressResource extends Resource
{
    protected static ?string $model = CourierChallengeProgress::class;

    protected static ?string $navigationIcon = 'heroicon-o-trophy';

    protected static ?string $navigationGroup = 'Gamification';

    protected static ?int $navigationSort = 2;

    protected static ?string $navigationLabel = 'Progression défis';

    protected static ?string $modelLabel = 'Progression défi';

    protected static ?string $pluralModelLabel = 'Progressions défis';

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Select::make('courier_id')
                ->relationship('courier', 'id')
                ->label('Livreur')
                ->searchable()
                ->preload()
                ->required(),

            Forms\Components\Select::make('challenge_type')
                ->options([
                    CourierChallengeProgress::DAILY_STREAK => 'Série quotidienne',
                    CourierChallengeProgress::PEAK_HOUR_HERO => 'Héros heures de pointe',
                    CourierChallengeProgress::PERFECT_RATING => 'Note parfaite',
                    CourierChallengeProgress::SPEED_DEMON => 'Rapide comme l\'éclair',
                    CourierChallengeProgress::ZONE_EXPLORER => 'Explorateur de zones',
                ])
                ->label('Type de défi')
                ->required(),

            Forms\Components\DatePicker::make('period_date')
                ->label('Date de période')
                ->required()
                ->default(today()),

            Forms\Components\TextInput::make('current_progress')
                ->label('Progression actuelle')
                ->numeric()
                ->default(0)
                ->required(),

            Forms\Components\TextInput::make('tier_reached')
                ->label('Palier atteint')
                ->numeric()
                ->default(0)
                ->required(),

            Forms\Components\TextInput::make('rewards_earned')
                ->label('Récompenses gagnées')
                ->numeric()
                ->suffix('FCFA')
                ->default(0)
                ->required(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('courier.user.name')
                    ->label('Livreur')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('challenge_type')
                    ->label('Défi')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        CourierChallengeProgress::DAILY_STREAK => 'primary',
                        CourierChallengeProgress::PEAK_HOUR_HERO => 'warning',
                        CourierChallengeProgress::PERFECT_RATING => 'success',
                        CourierChallengeProgress::SPEED_DEMON => 'danger',
                        CourierChallengeProgress::ZONE_EXPLORER => 'info',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        CourierChallengeProgress::DAILY_STREAK => 'Série quotidienne',
                        CourierChallengeProgress::PEAK_HOUR_HERO => 'Heures de pointe',
                        CourierChallengeProgress::PERFECT_RATING => 'Note parfaite',
                        CourierChallengeProgress::SPEED_DEMON => 'Rapide',
                        CourierChallengeProgress::ZONE_EXPLORER => 'Explorateur',
                        default => $state,
                    }),

                Tables\Columns\TextColumn::make('period_date')
                    ->label('Période')
                    ->date('d/m/Y')
                    ->sortable(),

                Tables\Columns\TextColumn::make('current_progress')
                    ->label('Progression')
                    ->formatStateUsing(function ($state, $record) {
                        $config = $record->config;
                        if (!$config) return $state;
                        $tiers = $config['tiers'] ?? [];
                        $maxTarget = end($tiers)['target'] ?? $state;
                        return "{$state} / {$maxTarget}";
                    }),

                Tables\Columns\TextColumn::make('progress_percent')
                    ->label('% Complet')
                    ->suffix('%')
                    ->color(fn ($state): string => match (true) {
                        $state >= 100 => 'success',
                        $state >= 50 => 'warning',
                        default => 'gray',
                    }),

                Tables\Columns\TextColumn::make('tier_reached')
                    ->label('Palier')
                    ->badge()
                    ->color(fn (int $state): string => match (true) {
                        $state >= 3 => 'success',
                        $state >= 2 => 'warning',
                        $state >= 1 => 'primary',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (int $state): string => $state > 0 ? "Tier {$state}" : 'Aucun'),

                Tables\Columns\TextColumn::make('rewards_earned')
                    ->label('Récompenses')
                    ->money('XOF')
                    ->sortable(),

                Tables\Columns\IconColumn::make('is_completed')
                    ->label('Terminé')
                    ->boolean(),
            ])
            ->defaultSort('period_date', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('challenge_type')
                    ->label('Type de défi')
                    ->options([
                        CourierChallengeProgress::DAILY_STREAK => 'Série quotidienne',
                        CourierChallengeProgress::PEAK_HOUR_HERO => 'Heures de pointe',
                        CourierChallengeProgress::PERFECT_RATING => 'Note parfaite',
                        CourierChallengeProgress::SPEED_DEMON => 'Rapide',
                        CourierChallengeProgress::ZONE_EXPLORER => 'Explorateur',
                    ]),

                Tables\Filters\Filter::make('today')
                    ->label('Aujourd\'hui')
                    ->query(fn ($query) => $query->where('period_date', today()))
                    ->default(),

                Tables\Filters\Filter::make('completed')
                    ->label('Terminés')
                    ->query(function ($query) {
                        return $query->whereRaw('tier_reached >= 3');
                    }),

                Tables\Filters\Filter::make('has_rewards')
                    ->label('Avec récompenses')
                    ->query(fn ($query) => $query->where('rewards_earned', '>', 0)),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
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
            'index' => Pages\ListCourierChallengeProgress::route('/'),
            'edit' => Pages\EditCourierChallengeProgress::route('/{record}/edit'),
        ];
    }
}
