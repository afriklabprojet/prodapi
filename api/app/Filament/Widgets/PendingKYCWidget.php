<?php

namespace App\Filament\Widgets;

use App\Models\Courier;
use App\Notifications\KycStatusNotification;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;
use Filament\Forms;
use Filament\Notifications\Notification;

class PendingKYCWidget extends BaseWidget
{
    protected static ?int $sort = 3;
    
    protected int | string | array $columnSpan = 'full';
    
    protected static ?string $heading = '🪪 Vérifications KYC en attente';
    
    protected static ?string $pollingInterval = '60s';

    /**
     * Génère le HTML pour afficher un document KYC miniature
     */
    private function renderDocumentThumbnail(?string $documentPath, string $label = ''): string
    {
        if (empty($documentPath)) {
            return '<div style="width: 60px; height: 60px; background: #f3f4f6; border-radius: 8px; display: flex; align-items: center; justify-content: center; color: #9ca3af; font-size: 10px;">N/A</div>';
        }
        
        try {
            $url = route('admin.documents.view', ['path' => $documentPath]);
            return '<a href="' . e($url) . '" target="_blank" title="' . e($label) . '">
                <img src="' . e($url) . '" style="width: 60px; height: 60px; object-fit: cover; border-radius: 8px; border: 1px solid #e5e7eb;" 
                     onerror="this.style.display=\'none\'" />
            </a>';
        } catch (\Exception $e) {
            return '<div style="width: 60px; height: 60px; background: #fef2f2; border-radius: 8px; display: flex; align-items: center; justify-content: center; color: #dc2626; font-size: 10px;">Err</div>';
        }
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(
                Courier::query()
                    ->where('kyc_status', 'pending_review')
                    ->orderBy('created_at', 'desc')
                    ->limit(10)
            )
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('#')
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('name')
                    ->label('Livreur')
                    ->searchable()
                    ->description(fn ($record) => $record->phone ?? ''),
                
                // Documents KYC miniatures
                Tables\Columns\ViewColumn::make('kyc_documents')
                    ->label('Documents KYC')
                    ->view('filament.tables.columns.kyc-documents-thumbnail'),
                    
                Tables\Columns\TextColumn::make('vehicle_type')
                    ->label('Véhicule')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'motorcycle' => 'info',
                        'car' => 'success',
                        'bicycle' => 'warning',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'motorcycle' => '🏍️ Moto',
                        'car' => '🚗 Voiture',
                        'bicycle' => '🚲 Vélo',
                        default => $state,
                    }),
                    
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Inscrit')
                    ->since()
                    ->sortable(),
            ])
            ->actions([
                // Voir les documents en détail
                Tables\Actions\Action::make('view_documents')
                    ->label('Vérifier')
                    ->icon('heroicon-o-eye')
                    ->color('info')
                    ->modalHeading(fn ($record) => '🪪 Vérification KYC - ' . $record->name)
                    ->modalContent(function ($record) {
                        return view('filament.modals.kyc-verification', ['courier' => $record]);
                    })
                    ->modalWidth('5xl')
                    ->modalSubmitAction(false)
                    ->modalCancelActionLabel('Fermer'),
                
                // Approuver KYC
                Tables\Actions\Action::make('approve_kyc')
                    ->label('Approuver')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalHeading('Approuver ce livreur ?')
                    ->modalDescription(fn ($record) => 'Le livreur "' . $record->name . '" pourra commencer à livrer immédiatement.')
                    ->action(function ($record) {
                        $record->update([
                            'status' => 'available',
                            'kyc_status' => 'approved',
                            'kyc_verified_at' => now(),
                            'kyc_rejection_reason' => null,
                        ]);
                        
                        // Envoyer notification push au livreur
                        $record->user?->notify(new KycStatusNotification('approved'));
                        
                        Notification::make()
                            ->title('✅ KYC approuvé')
                            ->body('Le livreur ' . $record->name . ' peut maintenant livrer.')
                            ->success()
                            ->send();
                    }),
                    
                // Demander re-soumission
                Tables\Actions\Action::make('request_resubmission')
                    ->label('Resoumission')
                    ->icon('heroicon-o-arrow-path')
                    ->color('warning')
                    ->form([
                        Forms\Components\CheckboxList::make('documents_to_resubmit')
                            ->label('Documents à resoumettre')
                            ->options([
                                'id_card_front' => '🪪 CNI (Recto)',
                                'id_card_back' => '🪪 CNI (Verso)',
                                'selfie' => '📸 Selfie de vérification',
                                'driving_license_front' => '🚗 Permis (Recto)',
                                'driving_license_back' => '🚗 Permis (Verso)',
                                'vehicle_registration' => '📄 Carte Grise',
                            ])
                            ->required()
                            ->columns(2),
                        Forms\Components\Textarea::make('reason')
                            ->label('Raison / Instructions')
                            ->required()
                            ->placeholder('Ex: Photo floue, document expiré, selfie ne correspond pas...'),
                    ])
                    ->action(function ($record, array $data) {
                        $documents = implode(', ', $data['documents_to_resubmit']);
                        
                        $rejectionReason = "Documents à resoumettre: {$documents}. Raison: {$data['reason']}";
                        
                        $record->update([
                            'kyc_status' => 'incomplete',
                            'kyc_rejection_reason' => $rejectionReason,
                        ]);
                        
                        // Envoyer notification push au livreur avec instructions
                        $record->user?->notify(new KycStatusNotification('incomplete', $rejectionReason));
                        
                        Notification::make()
                            ->title('📤 Demande de resoumission envoyée')
                            ->body('Le livreur devra resoumettre certains documents.')
                            ->warning()
                            ->send();
                    }),
                    
                // Rejeter définitivement
                Tables\Actions\Action::make('reject_kyc')
                    ->label('Rejeter')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\Textarea::make('reason')
                            ->label('Motif du rejet')
                            ->required()
                            ->placeholder('Ex: Documents frauduleux, identité non vérifiable...'),
                    ])
                    ->action(function ($record, array $data) {
                        $record->update([
                            'status' => 'rejected',
                            'kyc_status' => 'rejected',
                            'kyc_rejection_reason' => $data['reason'],
                        ]);
                        
                        Notification::make()
                            ->title('❌ KYC rejeté')
                            ->body('Le livreur ' . $record->name . ' a été rejeté.')
                            ->danger()
                            ->send();
                    }),
            ])
            ->emptyStateHeading('Aucune vérification KYC en attente')
            ->emptyStateDescription('Les nouvelles demandes de vérification apparaîtront ici.')
            ->emptyStateIcon('heroicon-o-check-badge');
    }
    
    public static function canView(): bool
    {
        return Courier::where('kyc_status', 'pending_review')->exists();
    }
}
