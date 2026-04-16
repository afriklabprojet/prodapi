<?php

namespace App\Filament\Resources;

use App\Models\WithdrawalRequest;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class WithdrawalRequestResource extends Resource
{
    protected static ?string $model = WithdrawalRequest::class;

    protected static ?string $navigationIcon = 'heroicon-o-arrow-down-tray';

    protected static ?string $navigationLabel = 'Demandes de retrait';

    protected static ?string $navigationGroup = 'Finance';

    protected static ?int $navigationSort = 3;

    protected static ?string $modelLabel = 'Demande de retrait';

    protected static ?string $pluralModelLabel = 'Demandes de retrait';

    public static function canCreate(): bool
    {
        return false;
    }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Détails du retrait')
                ->schema([
                    Forms\Components\TextInput::make('requester_name')
                        ->label('Demandeur')
                        ->disabled(),
                    Forms\Components\TextInput::make('requester_type')
                        ->label('Type')
                        ->disabled(),
                    Forms\Components\TextInput::make('amount')
                        ->label('Montant')
                        ->suffix('FCFA')
                        ->disabled(),
                    Forms\Components\TextInput::make('payment_method')
                        ->label('Méthode')
                        ->disabled(),
                    Forms\Components\TextInput::make('status')
                        ->label('Statut')
                        ->disabled(),
                    Forms\Components\Textarea::make('admin_notes')
                        ->label('Notes admin')
                        ->rows(3),
                ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('#')
                    ->sortable(),
                Tables\Columns\TextColumn::make('requester_type')
                    ->label('Type')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'Pharmacie' => 'success',
                        'Livreur' => 'info',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('requester_name')
                    ->label('Demandeur')
                    ->searchable(query: function (Builder $query, string $search) {
                        // Search in pharmacy name or courier user name
                        $query->where(function ($q) use ($search) {
                            $q->whereHasMorph('requestable', ['App\Models\Pharmacy'], function ($q) use ($search) {
                                $q->where('name', 'like', "%{$search}%");
                            })->orWhereHasMorph('requestable', ['App\Models\Courier'], function ($q) use ($search) {
                                $q->whereHas('user', fn ($u) => $u->where('name', 'like', "%{$search}%"));
                            });
                        });
                    }),
                Tables\Columns\TextColumn::make('amount')
                    ->label('Montant')
                    ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                    ->sortable()
                    ->weight('bold')
                    ->color('danger'),
                Tables\Columns\TextColumn::make('payment_method')
                    ->label('Méthode')
                    ->badge()
                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                        'orange_money' => 'Orange Money',
                        'mtn_money' => 'MTN Money',
                        'moov_money' => 'Moov Money',
                        'wave' => 'Wave',
                        'djamo' => 'Djamo',
                        'bank_transfer' => 'Virement bancaire',
                        default => $state ?? '-',
                    })
                    ->color('gray'),
                Tables\Columns\TextColumn::make('phone')
                    ->label('Téléphone')
                    ->default('-'),
                Tables\Columns\TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn (?string $state): string => match ($state) {
                        'completed' => 'success',
                        'processing' => 'info',
                        'pending' => 'warning',
                        'failed' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                        'completed' => 'Complété',
                        'processing' => 'En cours',
                        'pending' => 'En attente',
                        'failed' => 'Échoué',
                        default => $state ?? '-',
                    }),
                Tables\Columns\TextColumn::make('jeko_reference')
                    ->label('Réf. Jeko')
                    ->default('-')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Date demande')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
                Tables\Columns\TextColumn::make('completed_at')
                    ->label('Complété le')
                    ->dateTime('d/m/Y H:i')
                    ->default('-')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('Statut')
                    ->options([
                        'pending' => 'En attente',
                        'processing' => 'En cours',
                        'completed' => 'Complété',
                        'failed' => 'Échoué',
                    ]),
                Tables\Filters\SelectFilter::make('type')
                    ->label('Type')
                    ->options([
                        'App\Models\Pharmacy' => 'Pharmacies',
                        'App\Models\Courier' => 'Livreurs',
                    ])
                    ->query(fn (Builder $query, array $data) => $data['value']
                        ? $query->where('requestable_type', $data['value'])
                        : $query),
                Tables\Filters\Filter::make('date_range')
                    ->form([
                        Forms\Components\DatePicker::make('from')->label('Du'),
                        Forms\Components\DatePicker::make('until')->label('Au'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when($data['from'], fn (Builder $q, $date) => $q->whereDate('created_at', '>=', $date))
                            ->when($data['until'], fn (Builder $q, $date) => $q->whereDate('created_at', '<=', $date));
                    }),
            ])
            ->defaultSort('created_at', 'desc')
            ->striped()
            ->actions([
                Tables\Actions\Action::make('approve')
                    ->label('Approuver')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalHeading('Approuver le retrait')
                    ->modalDescription(fn (WithdrawalRequest $record): string => 
                        "Vous allez approuver le retrait de " . number_format($record->amount, 0, ',', ' ') . " FCFA vers {$record->phone}. Le paiement sera initié via JEKO Pay.")
                    ->visible(fn (WithdrawalRequest $record): bool => $record->status === 'pending')
                    ->action(function (WithdrawalRequest $record): void {
                        // Déclencher le paiement JEKO
                        try {
                            $jekoService = app(\App\Services\JekoPaymentService::class);
                            $amountCents = (int) ($record->amount * 100);
                            
                            $jekoPayment = $jekoService->createPayout(
                                $record,
                                $amountCents,
                                $record->phone,
                                $record->payment_method,
                                null, // user optionnel
                                "Retrait {$record->requester_type} - {$record->requester_name}"
                            );
                            
                            $record->update([
                                'status' => 'processing',
                                'jeko_reference' => $jekoPayment->reference,
                                'jeko_payment_id' => $jekoPayment->id,
                                'processed_at' => now(),
                            ]);
                            
                            \Filament\Notifications\Notification::make()
                                ->title('Retrait approuvé')
                                ->body("Paiement JEKO initié: {$jekoPayment->reference}")
                                ->success()
                                ->send();
                        } catch (\Exception $e) {
                            \Filament\Notifications\Notification::make()
                                ->title('Erreur JEKO')
                                ->body($e->getMessage())
                                ->danger()
                                ->send();
                        }
                    }),
                Tables\Actions\Action::make('complete')
                    ->label('Marquer complété')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalHeading('Marquer comme complété')
                    ->modalDescription('Confirmer que le paiement a bien été effectué ?')
                    ->visible(fn (WithdrawalRequest $record): bool => $record->status === 'processing')
                    ->action(function (WithdrawalRequest $record): void {
                        $record->update([
                            'status' => 'completed',
                            'completed_at' => now(),
                        ]);
                        
                        // Mettre à jour la transaction wallet associée
                        \App\Models\WalletTransaction::where('reference', $record->reference)
                            ->update(['status' => 'completed']);
                        
                        \Filament\Notifications\Notification::make()
                            ->title('Retrait complété')
                            ->success()
                            ->send();
                    }),
                Tables\Actions\Action::make('reject')
                    ->label('Rejeter')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->modalHeading('Rejeter le retrait')
                    ->form([
                        Forms\Components\Textarea::make('reason')
                            ->label('Motif du rejet')
                            ->required()
                            ->rows(3),
                    ])
                    ->visible(fn (WithdrawalRequest $record): bool => in_array($record->status, ['pending', 'processing']))
                    ->action(function (WithdrawalRequest $record, array $data): void {
                        // Recréditer le wallet
                        $wallet = $record->wallet;
                        if ($wallet) {
                            $wallet->credit(
                                $record->amount,
                                'REF-' . $record->reference,
                                "Remboursement retrait annulé: {$data['reason']}"
                            );
                        }
                        
                        $record->update([
                            'status' => 'failed',
                            'error_message' => $data['reason'],
                            'admin_notes' => "Rejeté par admin: {$data['reason']}",
                        ]);
                        
                        // Mettre à jour la transaction wallet
                        \App\Models\WalletTransaction::where('reference', $record->reference)
                            ->update(['status' => 'failed']);
                        
                        \Filament\Notifications\Notification::make()
                            ->title('Retrait rejeté')
                            ->body('Le montant a été recrédité au wallet.')
                            ->warning()
                            ->send();
                    }),
                Tables\Actions\ViewAction::make()
                    ->label('Détails'),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\BulkAction::make('bulk_approve')
                        ->label('Approuver sélection')
                        ->icon('heroicon-o-check-circle')
                        ->color('success')
                        ->requiresConfirmation()
                        ->deselectRecordsAfterCompletion()
                        ->action(function (\Illuminate\Database\Eloquent\Collection $records): void {
                            $approved = 0;
                            foreach ($records as $record) {
                                if ($record->status === 'pending') {
                                    $record->update([
                                        'status' => 'processing',
                                        'processed_at' => now(),
                                    ]);
                                    $approved++;
                                }
                            }
                            \Filament\Notifications\Notification::make()
                                ->title("{$approved} retrait(s) approuvé(s)")
                                ->success()
                                ->send();
                        }),
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
            'index' => WithdrawalRequestResource\Pages\ListWithdrawalRequests::route('/'),
            'view' => WithdrawalRequestResource\Pages\ViewWithdrawalRequest::route('/{record}'),
        ];
    }

    public static function getNavigationBadge(): ?string
    {
        $count = WithdrawalRequest::whereIn('status', ['pending', 'processing'])->count();
        return $count > 0 ? (string) $count : null;
    }

    public static function getNavigationBadgeColor(): string|array|null
    {
        return 'warning';
    }
}
