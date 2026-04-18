<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ChallengeResource\Pages;
use App\Models\Challenge;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ChallengeResource extends Resource
{
    protected static ?string $model = Challenge::class;

    protected static ?string $navigationIcon = 'heroicon-o-trophy';
    
    protected static ?string $navigationLabel = 'Défis';
    
    protected static ?string $modelLabel = 'Défi';
    
    protected static ?string $pluralModelLabel = 'Défis';
    
    protected static ?string $navigationGroup = 'Gestion';
    
    protected static ?int $navigationSort = 5;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Informations du défi')
                    ->schema([
                        Forms\Components\TextInput::make('title')
                            ->label('Titre')
                            ->required()
                            ->maxLength(255)
                            ->placeholder('Ex: Roi de la semaine'),
                            
                        Forms\Components\Textarea::make('description')
                            ->label('Description')
                            ->required()
                            ->rows(3)
                            ->placeholder('Décrivez l\'objectif du défi...'),
                            
                        Forms\Components\Select::make('type')
                            ->label('Type')
                            ->options([
                                'daily' => '📅 Quotidien',
                                'weekly' => '📆 Hebdomadaire',
                                'monthly' => '🗓️ Mensuel',
                                'special' => '⭐ Spécial',
                                'one_time' => '🎯 Unique',
                            ])
                            ->required()
                            ->default('weekly'),
                            
                        Forms\Components\Select::make('metric')
                            ->label('Métrique')
                            ->options([
                                'deliveries' => '📦 Nombre de livraisons',
                                'distance' => '🛣️ Distance parcourue (km)',
                                'earnings' => '💰 Gains accumulés',
                                'rating' => '⭐ Note moyenne',
                                'on_time' => '⏱️ Livraisons à l\'heure',
                                'consecutive_days' => '📆 Jours consécutifs',
                            ])
                            ->required()
                            ->default('deliveries'),
                    ])->columns(2),
                    
                Forms\Components\Section::make('Objectif et récompense')
                    ->schema([
                        Forms\Components\TextInput::make('target_value')
                            ->label('Objectif à atteindre')
                            ->numeric()
                            ->required()
                            ->default(10)
                            ->suffix('unités')
                            ->helperText('Nombre de livraisons, km, etc.'),
                            
                        Forms\Components\TextInput::make('reward_amount')
                            ->label('Récompense')
                            ->numeric()
                            ->required()
                            ->default(1000)
                            ->suffix('FCFA')
                            ->helperText('Montant crédité au livreur'),
                    ])->columns(2),
                    
                Forms\Components\Section::make('Apparence')
                    ->schema([
                        Forms\Components\TextInput::make('icon')
                            ->label('Icône')
                            ->placeholder('trophy, star, rocket, fire, crown...')
                            ->default('trophy')
                            ->helperText('Nom de l\'icône (heroicons)'),
                            
                        Forms\Components\ColorPicker::make('color')
                            ->label('Couleur')
                            ->default('#10B981'),
                    ])->columns(2),
                    
                Forms\Components\Section::make('Période et statut')
                    ->schema([
                        Forms\Components\Toggle::make('is_active')
                            ->label('Actif')
                            ->default(true)
                            ->helperText('Visible pour les livreurs'),
                            
                        Forms\Components\DateTimePicker::make('starts_at')
                            ->label('Début')
                            ->nullable()
                            ->helperText('Laisser vide = immédiat'),
                            
                        Forms\Components\DateTimePicker::make('ends_at')
                            ->label('Fin')
                            ->nullable()
                            ->helperText('Laisser vide = permanent'),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('#')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('title')
                    ->label('Titre')
                    ->searchable()
                    ->weight('bold'),
                    
                Tables\Columns\TextColumn::make('type')
                    ->label('Type')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'daily' => '📅 Quotidien',
                        'weekly' => '📆 Hebdo',
                        'monthly' => '🗓️ Mensuel',
                        'special' => '⭐ Spécial',
                        'one_time' => '🎯 Unique',
                        default => $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'daily' => 'info',
                        'weekly' => 'success',
                        'monthly' => 'warning',
                        'special' => 'danger',
                        default => 'gray',
                    }),
                    
                Tables\Columns\TextColumn::make('metric')
                    ->label('Objectif')
                    ->formatStateUsing(fn (string $state, $record): string => match ($state) {
                        'deliveries' => "📦 {$record->target_value} livraisons",
                        'distance' => "🛣️ {$record->target_value} km",
                        'earnings' => "💰 {$record->target_value} FCFA",
                        'rating' => "⭐ {$record->target_value}/5",
                        'on_time' => "⏱️ {$record->target_value} à l'heure",
                        'consecutive_days' => "📆 {$record->target_value} jours",
                        default => "{$record->target_value}",
                    }),
                    
                Tables\Columns\TextColumn::make('reward_amount')
                    ->label('Récompense')
                    ->formatStateUsing(fn ($state): string => number_format($state, 0, ',', ' ') . ' FCFA')
                    ->color('success'),
                    
                Tables\Columns\IconColumn::make('is_active')
                    ->label('Actif')
                    ->boolean(),
                    
                Tables\Columns\TextColumn::make('couriers_count')
                    ->label('Participants')
                    ->counts('couriers')
                    ->badge()
                    ->color('info'),
                    
                Tables\Columns\TextColumn::make('ends_at')
                    ->label('Fin')
                    ->dateTime('d/m/Y H:i')
                    ->placeholder('Permanent')
                    ->sortable(),
            ])
            ->defaultSort('id', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('type')
                    ->label('Type')
                    ->options([
                        'daily' => 'Quotidien',
                        'weekly' => 'Hebdomadaire',
                        'monthly' => 'Mensuel',
                        'special' => 'Spécial',
                        'one_time' => 'Unique',
                    ]),
                    
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Actif'),
                    
                Tables\Filters\Filter::make('active_now')
                    ->label('En cours')
                    ->query(fn ($query) => $query
                        ->where('is_active', true)
                        ->where(fn ($q) => $q->whereNull('starts_at')->orWhere('starts_at', '<=', now()))
                        ->where(fn ($q) => $q->whereNull('ends_at')->orWhere('ends_at', '>=', now()))
                    ),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\Action::make('toggle_active')
                    ->label(fn ($record) => $record->is_active ? 'Désactiver' : 'Activer')
                    ->icon(fn ($record) => $record->is_active ? 'heroicon-o-pause' : 'heroicon-o-play')
                    ->color(fn ($record) => $record->is_active ? 'warning' : 'success')
                    ->requiresConfirmation()
                    ->action(fn ($record) => $record->update(['is_active' => !$record->is_active])),
                Tables\Actions\Action::make('view_participants')
                    ->label('Participants')
                    ->icon('heroicon-o-users')
                    ->color('info')
                    ->url(fn ($record) => static::getUrl('participants', ['record' => $record])),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                    Tables\Actions\BulkAction::make('activate')
                        ->label('Activer')
                        ->icon('heroicon-o-check')
                        ->action(fn ($records) => $records->each->update(['is_active' => true])),
                    Tables\Actions\BulkAction::make('deactivate')
                        ->label('Désactiver')
                        ->icon('heroicon-o-x-mark')
                        ->action(fn ($records) => $records->each->update(['is_active' => false])),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListChallenges::route('/'),
            'create' => Pages\CreateChallenge::route('/create'),
            'edit' => Pages\EditChallenge::route('/{record}/edit'),
            'participants' => Pages\ChallengeParticipants::route('/{record}/participants'),
        ];
    }
    
    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::where('is_active', true)
            ->where(fn ($q) => $q->whereNull('ends_at')->orWhere('ends_at', '>=', now()))
            ->count() ?: null;
    }
    
    public static function getNavigationBadgeColor(): ?string
    {
        return 'success';
    }
}
