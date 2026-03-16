<?php

namespace App\Filament\Resources;

use App\Filament\Resources\RatingResource\Pages;
use App\Models\Rating;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class RatingResource extends Resource
{
    protected static ?string $model = Rating::class;

    protected static ?string $navigationIcon = 'heroicon-o-star';

    protected static ?string $navigationLabel = 'Avis & Notes';

    protected static ?string $modelLabel = 'Avis';

    protected static ?string $pluralModelLabel = 'Avis & Notes';

    protected static ?string $navigationGroup = 'Support';

    protected static ?int $navigationSort = 3;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Informations')
                    ->schema([
                        Forms\Components\Select::make('user_id')
                            ->label('Utilisateur')
                            ->relationship('user', 'name')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Forms\Components\Select::make('order_id')
                            ->label('Commande')
                            ->relationship('order', 'reference')
                            ->searchable()
                            ->preload(),
                        Forms\Components\Select::make('rateable_type')
                            ->label('Type')
                            ->options([
                                'App\\Models\\Courier' => 'Coursier',
                                'App\\Models\\Pharmacy' => 'Pharmacie',
                            ])
                            ->required(),
                        Forms\Components\TextInput::make('rateable_id')
                            ->label('ID de l\'entité notée')
                            ->numeric()
                            ->required(),
                        Forms\Components\Select::make('rating')
                            ->label('Note')
                            ->options([
                                1 => '⭐ 1/5',
                                2 => '⭐⭐ 2/5',
                                3 => '⭐⭐⭐ 3/5',
                                4 => '⭐⭐⭐⭐ 4/5',
                                5 => '⭐⭐⭐⭐⭐ 5/5',
                            ])
                            ->required(),
                        Forms\Components\Textarea::make('comment')
                            ->label('Commentaire')
                            ->rows(3)
                            ->columnSpanFull(),
                        Forms\Components\TagsInput::make('tags')
                            ->label('Tags')
                            ->placeholder('Ajouter un tag')
                            ->columnSpanFull(),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Utilisateur')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('order.reference')
                    ->label('Commande')
                    ->searchable()
                    ->url(fn ($record) => $record->order_id
                        ? OrderResource::getUrl('edit', ['record' => $record->order_id])
                        : null
                    )
                    ->color('primary'),
                Tables\Columns\TextColumn::make('rateable_type')
                    ->label('Type')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'App\\Models\\Courier' => 'Coursier',
                        'App\\Models\\Pharmacy' => 'Pharmacie',
                        default => $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'App\\Models\\Courier' => 'info',
                        'App\\Models\\Pharmacy' => 'success',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('rateable_id')
                    ->label('Entité')
                    ->formatStateUsing(function ($record) {
                        $rateable = $record->rateable;
                        if (!$rateable) return '#' . $record->rateable_id;
                        return $rateable->name ?? $rateable->user?->name ?? '#' . $record->rateable_id;
                    }),
                Tables\Columns\TextColumn::make('rating')
                    ->label('Note')
                    ->formatStateUsing(fn (int $state): string => str_repeat('⭐', $state))
                    ->sortable(),
                Tables\Columns\TextColumn::make('comment')
                    ->label('Commentaire')
                    ->limit(40)
                    ->tooltip(fn ($record) => $record->comment),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Date')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('rateable_type')
                    ->label('Type')
                    ->options([
                        'App\\Models\\Courier' => 'Coursier',
                        'App\\Models\\Pharmacy' => 'Pharmacie',
                    ]),
                Tables\Filters\SelectFilter::make('rating')
                    ->label('Note')
                    ->options([
                        1 => '1 étoile',
                        2 => '2 étoiles',
                        3 => '3 étoiles',
                        4 => '4 étoiles',
                        5 => '5 étoiles',
                    ]),
                Tables\Filters\Filter::make('has_comment')
                    ->label('Avec commentaire')
                    ->query(fn ($query) => $query->whereNotNull('comment')->where('comment', '!=', '')),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\DeleteAction::make()
                    ->label('Supprimer'),
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
            'index' => Pages\ListRatings::route('/'),
            'create' => Pages\CreateRating::route('/create'),
            'edit' => Pages\EditRating::route('/{record}/edit'),
        ];
    }

    public static function canCreate(): bool
    {
        return false; // Les avis sont créés par les utilisateurs, pas les admins
    }
}
