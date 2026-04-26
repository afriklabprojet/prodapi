<?php

namespace App\Filament\Resources\UserResource\RelationManagers;

use App\Services\CustomerBadgeService;
use Filament\Forms\Components\Select;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class BadgesRelationManager extends RelationManager
{
    protected static string $relationship = 'badges';

    protected static ?string $title = 'Badges';

    protected static ?string $modelLabel = 'badge';

    protected static ?string $pluralModelLabel = 'badges';

    public function form(Form $form): Form
    {
        $options = collect(CustomerBadgeService::CATALOG)
            ->map(fn (array $b) => "{$b['title']} — {$b['description']}")
            ->toArray();

        return $form->schema([
            Select::make('badge_id')
                ->label('Badge')
                ->options($options)
                ->required()
                ->disabledOn('edit'),
        ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('badge_id')
            ->columns([
                Tables\Columns\TextColumn::make('badge_id')
                    ->label('Badge')
                    ->badge()
                    ->color('warning')
                    ->icon('heroicon-m-trophy')
                    ->formatStateUsing(fn (string $state): string => CustomerBadgeService::CATALOG[$state]['title'] ?? $state),
                Tables\Columns\TextColumn::make('description')
                    ->label('Description')
                    ->getStateUsing(fn ($record) => CustomerBadgeService::CATALOG[$record->badge_id]['description'] ?? '—')
                    ->wrap(),
                Tables\Columns\TextColumn::make('unlocked_at')
                    ->label('Débloqué le')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->defaultSort('unlocked_at', 'desc')
            ->headerActions([
                Tables\Actions\CreateAction::make()
                    ->label('Attribuer un badge')
                    ->mutateFormDataUsing(function (array $data): array {
                        $data['unlocked_at'] = now();
                        return $data;
                    }),
            ])
            ->actions([
                Tables\Actions\DeleteAction::make()->label('Retirer'),
            ]);
    }
}
