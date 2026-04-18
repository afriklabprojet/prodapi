<?php

namespace App\Filament\Widgets;

use App\Models\Courier;
use App\Notifications\KycStatusNotification;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;
use Filament\Forms;
use Filament\Notifications\Notification;
use Illuminate\Support\HtmlString;

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
            return '<a href="'.$url.'" target="_blank" title="'.$label.'">
                <img src="'.$url.'" style="width: 60px; height: 60px; object-fit: cover; border-radius: 8px; border: 1px solid #e5e7eb;" 
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
                        $html = '<div style="padding: 16px;">';
                        
                        // Info livreur
                        $html .= '<div style="background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); color: white; padding: 16px; border-radius: 12px; margin-bottom: 20px;">';
                        $html .= '<h3 style="margin: 0 0 10px 0; font-size: 18px;">📋 Informations du livreur</h3>';
                        $html .= '<p style="margin: 4px 0;"><strong>Nom:</strong> ' . e($record->name) . '</p>';
                        $html .= '<p style="margin: 4px 0;"><strong>Téléphone:</strong> ' . e($record->phone ?? 'N/A') . '</p>';
                        $html .= '<p style="margin: 4px 0;"><strong>Email:</strong> ' . e($record->user?->email ?? 'N/A') . '</p>';
                        $html .= '<p style="margin: 4px 0;"><strong>Véhicule:</strong> ' . match($record->vehicle_type) {
                            'motorcycle' => '🏍️ Moto - ' . e($record->vehicle_number ?? ''),
                            'car' => '🚗 Voiture - ' . e($record->vehicle_number ?? ''),
                            'bicycle' => '🚲 Vélo',
                            default => e($record->vehicle_type),
                        } . '</p>';
                        if ($record->license_number) {
                            $html .= '<p style="margin: 4px 0;"><strong>N° Permis:</strong> ' . e($record->license_number) . '</p>';
                        }
                        $html .= '</div>';
                        
                        // Documents CNI (Recto/Verso côte à côte)
                        $html .= '<div style="margin-bottom: 24px;">';
                        $html .= '<h4 style="margin: 0 0 12px 0; color: #374151; display: flex; align-items: center; gap: 8px;">🪪 Carte d\'Identité Nationale (CNI)</h4>';
                        $html .= '<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">';
                        
                        // CNI Recto
                        $html .= '<div style="text-align: center;">';
                        $html .= '<div style="background: #f9fafb; border: 2px dashed #e5e7eb; border-radius: 12px; padding: 12px;">';
                        $html .= '<p style="margin: 0 0 8px 0; font-weight: 600; color: #6b7280; font-size: 13px;">RECTO</p>';
                        if ($record->id_card_front_document) {
                            $url = route('admin.documents.view', ['path' => $record->id_card_front_document]);
                            $html .= '<a href="'.$url.'" target="_blank"><img src="'.$url.'" style="max-width: 100%; max-height: 250px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" /></a>';
                        } else {
                            $html .= '<div style="height: 150px; display: flex; align-items: center; justify-content: center; color: #dc2626;">❌ Non fourni</div>';
                        }
                        $html .= '</div></div>';
                        
                        // CNI Verso
                        $html .= '<div style="text-align: center;">';
                        $html .= '<div style="background: #f9fafb; border: 2px dashed #e5e7eb; border-radius: 12px; padding: 12px;">';
                        $html .= '<p style="margin: 0 0 8px 0; font-weight: 600; color: #6b7280; font-size: 13px;">VERSO</p>';
                        if ($record->id_card_back_document) {
                            $url = route('admin.documents.view', ['path' => $record->id_card_back_document]);
                            $html .= '<a href="'.$url.'" target="_blank"><img src="'.$url.'" style="max-width: 100%; max-height: 250px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" /></a>';
                        } else {
                            $html .= '<div style="height: 150px; display: flex; align-items: center; justify-content: center; color: #dc2626;">❌ Non fourni</div>';
                        }
                        $html .= '</div></div>';
                        $html .= '</div></div>';
                        
                        // Selfie de vérification (centré, plus grand)
                        $html .= '<div style="margin-bottom: 24px;">';
                        $html .= '<h4 style="margin: 0 0 12px 0; color: #374151; display: flex; align-items: center; gap: 8px;">📸 Selfie de Vérification</h4>';
                        $html .= '<div style="text-align: center; background: #fef3c7; border: 2px solid #f59e0b; border-radius: 12px; padding: 16px;">';
                        if ($record->selfie_document) {
                            $url = route('admin.documents.view', ['path' => $record->selfie_document]);
                            $html .= '<a href="'.$url.'" target="_blank"><img src="'.$url.'" style="max-width: 300px; max-height: 300px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.15);" /></a>';
                            $html .= '<p style="margin: 10px 0 0 0; color: #92400e; font-size: 13px;">💡 Comparer avec la photo sur la CNI</p>';
                        } else {
                            $html .= '<div style="height: 150px; display: flex; align-items: center; justify-content: center; color: #dc2626; font-size: 16px;">❌ Selfie non fourni</div>';
                        }
                        $html .= '</div></div>';
                        
                        // Permis de conduire (si disponible)
                        if ($record->driving_license_front_document || $record->driving_license_back_document) {
                            $html .= '<div style="margin-bottom: 24px;">';
                            $html .= '<h4 style="margin: 0 0 12px 0; color: #374151; display: flex; align-items: center; gap: 8px;">🚗 Permis de Conduire</h4>';
                            $html .= '<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">';
                            
                            // Permis Recto
                            $html .= '<div style="text-align: center;">';
                            $html .= '<div style="background: #f0fdf4; border: 2px dashed #86efac; border-radius: 12px; padding: 12px;">';
                            $html .= '<p style="margin: 0 0 8px 0; font-weight: 600; color: #6b7280; font-size: 13px;">RECTO</p>';
                            if ($record->driving_license_front_document) {
                                $url = route('admin.documents.view', ['path' => $record->driving_license_front_document]);
                                $html .= '<a href="'.$url.'" target="_blank"><img src="'.$url.'" style="max-width: 100%; max-height: 220px; border-radius: 8px;" /></a>';
                            } else {
                                $html .= '<div style="height: 120px; display: flex; align-items: center; justify-content: center; color: #9ca3af;">Non fourni</div>';
                            }
                            $html .= '</div></div>';
                            
                            // Permis Verso
                            $html .= '<div style="text-align: center;">';
                            $html .= '<div style="background: #f0fdf4; border: 2px dashed #86efac; border-radius: 12px; padding: 12px;">';
                            $html .= '<p style="margin: 0 0 8px 0; font-weight: 600; color: #6b7280; font-size: 13px;">VERSO</p>';
                            if ($record->driving_license_back_document) {
                                $url = route('admin.documents.view', ['path' => $record->driving_license_back_document]);
                                $html .= '<a href="'.$url.'" target="_blank"><img src="'.$url.'" style="max-width: 100%; max-height: 220px; border-radius: 8px;" /></a>';
                            } else {
                                $html .= '<div style="height: 120px; display: flex; align-items: center; justify-content: center; color: #9ca3af;">Non fourni</div>';
                            }
                            $html .= '</div></div>';
                            $html .= '</div></div>';
                        }
                        
                        // Carte grise (si dispo)
                        if ($record->vehicle_registration_document) {
                            $html .= '<div style="margin-bottom: 16px;">';
                            $html .= '<h4 style="margin: 0 0 12px 0; color: #374151;">📄 Carte Grise</h4>';
                            $html .= '<div style="text-align: center;">';
                            $url = route('admin.documents.view', ['path' => $record->vehicle_registration_document]);
                            $html .= '<a href="'.$url.'" target="_blank"><img src="'.$url.'" style="max-width: 350px; max-height: 250px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" /></a>';
                            $html .= '</div></div>';
                        }
                        
                        $html .= '</div>';
                        
                        return new HtmlString($html);
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
