<?php

namespace App\Filament\Resources\SupportTicketResource\RelationManagers;

use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Auth;

class SupportMessagesRelationManager extends RelationManager
{
    protected static string $relationship = 'messages';

    protected static ?string $title = 'Messages';

    protected static ?string $recordTitleAttribute = 'message';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Hidden::make('user_id')
                    ->default(fn () => Auth::id()),
                Forms\Components\Hidden::make('is_from_support')
                    ->default(true),
                Forms\Components\Textarea::make('message')
                    ->label('Réponse')
                    ->required()
                    ->rows(3)
                    ->columnSpanFull()
                    ->placeholder('Tapez votre réponse au client...'),
                Forms\Components\FileUpload::make('attachment')
                    ->label('Pièce jointe')
                    ->directory('support-attachments')
                    ->maxSize(5120)
                    ->columnSpanFull(),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Auteur')
                    ->formatStateUsing(function ($record) {
                        $name = $record->user?->name ?? 'Inconnu';
                        return $record->is_from_support ? "🛡️ {$name}" : $name;
                    }),
                Tables\Columns\TextColumn::make('message')
                    ->label('Message')
                    ->limit(60)
                    ->tooltip(fn ($record) => $record->message)
                    ->wrap(),
                Tables\Columns\IconColumn::make('is_from_support')
                    ->label('Support')
                    ->boolean()
                    ->trueIcon('heroicon-o-shield-check')
                    ->falseIcon('heroicon-o-user')
                    ->trueColor('primary')
                    ->falseColor('gray'),
                Tables\Columns\TextColumn::make('attachment')
                    ->label('PJ')
                    ->formatStateUsing(fn ($state) => $state ? '📎' : '-')
                    ->url(fn ($record) => $record->attachment
                        ? asset('storage/' . $record->attachment)
                        : null
                    )
                    ->openUrlInNewTab(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Date')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
                Tables\Columns\TextColumn::make('read_at')
                    ->label('Lu')
                    ->formatStateUsing(fn ($state) => $state ? '✓ Lu' : 'Non lu')
                    ->color(fn ($state) => $state ? 'success' : 'warning'),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_from_support')
                    ->label('Source')
                    ->trueLabel('Support uniquement')
                    ->falseLabel('Client uniquement'),
            ])
            ->headerActions([
                Tables\Actions\CreateAction::make()
                    ->label('Répondre')
                    ->icon('heroicon-o-paper-airplane')
                    ->mutateFormDataUsing(function (array $data): array {
                        $data['user_id'] = Auth::id();
                        $data['is_from_support'] = true;
                        return $data;
                    }),
            ])
            ->actions([
                Tables\Actions\Action::make('mark_read')
                    ->label('Marquer lu')
                    ->icon('heroicon-o-check')
                    ->action(fn ($record) => $record->update(['read_at' => now()]))
                    ->visible(fn ($record) => !$record->read_at && !$record->is_from_support),
            ])
            ->bulkActions([])
            ->defaultSort('created_at', 'asc');
    }
}
