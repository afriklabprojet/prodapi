<?php

namespace App\Filament\Resources\WithdrawalRequestResource\Pages;

use App\Filament\Resources\WithdrawalRequestResource;
use Filament\Actions;
use Filament\Resources\Pages\ViewRecord;
use Filament\Infolists\Infolist;
use Filament\Infolists\Components;

class ViewWithdrawalRequest extends ViewRecord
{
    protected static string $resource = WithdrawalRequestResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\Action::make('approve')
                ->label('Approuver')
                ->icon('heroicon-o-check-circle')
                ->color('success')
                ->requiresConfirmation()
                ->visible(fn () => $this->record->status === 'pending')
                ->action(function () {
                    try {
                        $jekoService = app(\App\Services\JekoPaymentService::class);
                        $amountCents = (int) ($this->record->amount * 100);
                        
                        $jekoPayment = $jekoService->createPayout(
                            $this->record,
                            $amountCents,
                            $this->record->phone,
                            $this->record->payment_method,
                            null,
                            "Retrait {$this->record->requester_type} - {$this->record->requester_name}"
                        );
                        
                        $this->record->update([
                            'status' => 'processing',
                            'jeko_reference' => $jekoPayment->reference,
                            'jeko_payment_id' => $jekoPayment->id,
                            'processed_at' => now(),
                        ]);
                        
                        $this->refreshFormData(['status', 'jeko_reference', 'processed_at']);
                        
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
            Actions\Action::make('complete')
                ->label('Marquer complété')
                ->icon('heroicon-o-check-badge')
                ->color('success')
                ->requiresConfirmation()
                ->visible(fn () => $this->record->status === 'processing')
                ->action(function () {
                    $this->record->update([
                        'status' => 'completed',
                        'completed_at' => now(),
                    ]);
                    
                    \App\Models\WalletTransaction::where('reference', $this->record->reference)
                        ->update(['status' => 'completed']);
                    
                    $this->refreshFormData(['status', 'completed_at']);
                    
                    \Filament\Notifications\Notification::make()
                        ->title('Retrait complété')
                        ->success()
                        ->send();
                }),
            Actions\Action::make('reject')
                ->label('Rejeter')
                ->icon('heroicon-o-x-circle')
                ->color('danger')
                ->requiresConfirmation()
                ->form([
                    \Filament\Forms\Components\Textarea::make('reason')
                        ->label('Motif du rejet')
                        ->required()
                        ->rows(3),
                ])
                ->visible(fn () => in_array($this->record->status, ['pending', 'processing']))
                ->action(function (array $data) {
                    $wallet = $this->record->wallet;
                    if ($wallet) {
                        $wallet->credit(
                            $this->record->amount,
                            'REF-' . $this->record->reference,
                            "Remboursement retrait annulé: {$data['reason']}"
                        );
                    }
                    
                    $this->record->update([
                        'status' => 'failed',
                        'error_message' => $data['reason'],
                        'admin_notes' => "Rejeté par admin: {$data['reason']}",
                    ]);
                    
                    \App\Models\WalletTransaction::where('reference', $this->record->reference)
                        ->update(['status' => 'failed']);
                    
                    $this->refreshFormData(['status', 'error_message', 'admin_notes']);
                    
                    \Filament\Notifications\Notification::make()
                        ->title('Retrait rejeté')
                        ->body('Le montant a été recrédité au wallet.')
                        ->warning()
                        ->send();
                }),
        ];
    }

    public function infolist(Infolist $infolist): Infolist
    {
        return $infolist
            ->schema([
                Components\Section::make('Informations du retrait')
                    ->schema([
                        Components\TextEntry::make('id')
                            ->label('ID'),
                        Components\TextEntry::make('reference')
                            ->label('Référence')
                            ->copyable(),
                        Components\TextEntry::make('requester_type')
                            ->label('Type demandeur')
                            ->badge()
                            ->color(fn (string $state): string => match ($state) {
                                'Pharmacie' => 'success',
                                'Livreur' => 'info',
                                default => 'gray',
                            }),
                        Components\TextEntry::make('requester_name')
                            ->label('Demandeur'),
                        Components\TextEntry::make('amount')
                            ->label('Montant')
                            ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                            ->color('danger')
                            ->weight('bold'),
                        Components\TextEntry::make('status')
                            ->label('Statut')
                            ->badge()
                            ->color(fn (?string $state): string => match ($state) {
                                'completed' => 'success',
                                'processing' => 'info',
                                'pending' => 'warning',
                                'failed' => 'danger',
                                default => 'gray',
                            }),
                    ])->columns(3),
                Components\Section::make('Détails de paiement')
                    ->schema([
                        Components\TextEntry::make('payment_method')
                            ->label('Méthode')
                            ->formatStateUsing(fn (?string $state): string => match ($state) {
                                'orange' => 'Orange Money',
                                'mtn' => 'MTN Money',
                                'moov' => 'Moov Money',
                                'wave' => 'Wave',
                                'djamo' => 'Djamo',
                                'bank' => 'Virement bancaire',
                                default => $state ?? '-',
                            }),
                        Components\TextEntry::make('phone')
                            ->label('Téléphone')
                            ->copyable(),
                        Components\TextEntry::make('jeko_reference')
                            ->label('Réf. JEKO')
                            ->copyable()
                            ->default('-'),
                    ])->columns(3),
                Components\Section::make('Dates')
                    ->schema([
                        Components\TextEntry::make('created_at')
                            ->label('Demandé le')
                            ->dateTime('d/m/Y H:i'),
                        Components\TextEntry::make('processed_at')
                            ->label('Traité le')
                            ->dateTime('d/m/Y H:i')
                            ->default('-'),
                        Components\TextEntry::make('completed_at')
                            ->label('Complété le')
                            ->dateTime('d/m/Y H:i')
                            ->default('-'),
                    ])->columns(3),
                Components\Section::make('Notes')
                    ->schema([
                        Components\TextEntry::make('admin_notes')
                            ->label('Notes admin')
                            ->default('Aucune note'),
                        Components\TextEntry::make('error_message')
                            ->label('Message d\'erreur')
                            ->default('-')
                            ->color('danger'),
                    ])->columns(2)
                    ->collapsible(),
            ]);
    }
}
