<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SupportTicketResource\Pages;
use App\Filament\Resources\SupportTicketResource\RelationManagers;
use App\Models\SupportTicket;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class SupportTicketResource extends Resource
{
    protected static ?string $model = SupportTicket::class;

    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-left-right';
    
    protected static ?string $navigationLabel = 'Tickets Support';
    
    protected static ?string $modelLabel = 'Ticket';
    
    protected static ?string $pluralModelLabel = 'Tickets Support';
    
    protected static ?string $navigationGroup = 'Support';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('user_id')
                    ->label('Utilisateur')
                    ->relationship('user', 'name')
                    ->required(),
                Forms\Components\Select::make('category')
                    ->label('Catégorie')
                    ->options([
                        'technical' => 'Technique',
                        'payment' => 'Paiement',
                        'delivery' => 'Livraison',
                        'order' => 'Commande',
                        'account' => 'Compte',
                        'other' => 'Autre',
                    ])
                    ->required(),
                Forms\Components\TextInput::make('subject')
                    ->label('Sujet')
                    ->required(),
                Forms\Components\Textarea::make('description')
                    ->label('Description')
                    ->required()
                    ->columnSpanFull(),
                Forms\Components\Select::make('status')
                    ->label('Statut')
                    ->options([
                        'open' => 'Ouvert',
                        'in_progress' => 'En cours',
                        'resolved' => 'Résolu',
                        'closed' => 'Fermé',
                    ])
                    ->required(),
                Forms\Components\Select::make('priority')
                    ->label('Priorité')
                    ->options([
                        'low' => 'Basse',
                        'medium' => 'Moyenne',
                        'high' => 'Haute',
                        'urgent' => 'Urgente',
                    ])
                    ->required(),
                Forms\Components\Textarea::make('metadata')
                    ->label('Métadonnées')
                    ->columnSpanFull(),
                Forms\Components\TextInput::make('reference')
                    ->label('Référence'),
                Forms\Components\DateTimePicker::make('resolved_at')
                    ->label('Résolu le'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('reference')
                    ->label('Référence')
                    ->searchable(),
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Utilisateur')
                    ->sortable(),
                Tables\Columns\TextColumn::make('category')
                    ->label('Catégorie')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'technical' => 'Technique',
                        'payment' => 'Paiement',
                        'delivery' => 'Livraison',
                        'order' => 'Commande',
                        'account' => 'Compte',
                        'other' => 'Autre',
                        default => $state,
                    }),
                Tables\Columns\TextColumn::make('subject')
                    ->label('Sujet')
                    ->searchable()
                    ->limit(30),
                Tables\Columns\TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'open' => 'warning',
                        'in_progress' => 'info',
                        'resolved' => 'success',
                        'closed' => 'gray',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'open' => 'Ouvert',
                        'in_progress' => 'En cours',
                        'resolved' => 'Résolu',
                        'closed' => 'Fermé',
                        default => $state,
                    }),
                Tables\Columns\TextColumn::make('priority')
                    ->label('Priorité')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'low' => 'gray',
                        'medium' => 'info',
                        'high' => 'warning',
                        'urgent' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'low' => 'Basse',
                        'medium' => 'Moyenne',
                        'high' => 'Haute',
                        'urgent' => 'Urgente',
                        default => $state,
                    }),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Créé le')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
                Tables\Columns\TextColumn::make('resolved_at')
                    ->label('Résolu le')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            RelationManagers\SupportMessagesRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSupportTickets::route('/'),
            'create' => Pages\CreateSupportTicket::route('/create'),
            'edit' => Pages\EditSupportTicket::route('/{record}/edit'),
        ];
    }
}
