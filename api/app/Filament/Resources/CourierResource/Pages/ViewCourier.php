<?php

namespace App\Filament\Resources\CourierResource\Pages;

use App\Filament\Resources\CourierResource;
use Filament\Actions;
use Filament\Resources\Pages\ViewRecord;
use Filament\Infolists;
use Filament\Infolists\Infolist;
use Illuminate\Support\HtmlString;

class ViewCourier extends ViewRecord
{
    protected static string $resource = CourierResource::class;
    
    protected static ?string $title = 'Détails du Livreur';

    protected function getHeaderActions(): array
    {
        return [
            Actions\EditAction::make(),
            
            // Approuver KYC
            Actions\Action::make('approve_kyc')
                ->label('Approuver KYC')
                ->icon('heroicon-o-check-badge')
                ->color('success')
                ->visible(fn () => $this->record->kyc_status === 'pending_review')
                ->requiresConfirmation()
                ->modalHeading('Approuver ce livreur ?')
                ->modalDescription('Le livreur pourra commencer à effectuer des livraisons.')
                ->action(function () {
                    $this->record->update([
                        'status' => 'available',
                        'kyc_status' => 'approved',
                        'kyc_verified_at' => now(),
                        'kyc_rejection_reason' => null,
                    ]);
                    $this->redirect(static::getResource()::getUrl('index'));
                }),
            
            // Rejeter KYC
            Actions\Action::make('reject_kyc')
                ->label('Rejeter KYC')
                ->icon('heroicon-o-x-circle')
                ->color('danger')
                ->visible(fn () => in_array($this->record->kyc_status, ['pending_review', 'incomplete']))
                ->form([
                    \Filament\Forms\Components\Textarea::make('reason')
                        ->label('Motif du rejet')
                        ->required(),
                ])
                ->action(function (array $data) {
                    $this->record->update([
                        'status' => 'rejected',
                        'kyc_status' => 'rejected',
                        'kyc_rejection_reason' => $data['reason'],
                    ]);
                    $this->redirect(static::getResource()::getUrl('index'));
                }),
        ];
    }

    public function infolist(Infolist $infolist): Infolist
    {
        return $infolist
            ->schema([
                // Informations personnelles
                Infolists\Components\Section::make('📋 Informations du Livreur')
                    ->schema([
                        Infolists\Components\TextEntry::make('name')
                            ->label('Nom complet'),
                        Infolists\Components\TextEntry::make('phone')
                            ->label('Téléphone'),
                        Infolists\Components\TextEntry::make('user.email')
                            ->label('Email'),
                        Infolists\Components\TextEntry::make('vehicle_type')
                            ->label('Type de véhicule')
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
                        Infolists\Components\TextEntry::make('vehicle_number')
                            ->label('N° Immatriculation'),
                        Infolists\Components\TextEntry::make('license_number')
                            ->label('N° Permis'),
                    ])->columns(3),
                
                // Statut actuel
                Infolists\Components\Section::make('📊 Statut')
                    ->schema([
                        Infolists\Components\TextEntry::make('status')
                            ->label('Statut compte')
                            ->badge()
                            ->color(fn (string $state): string => match ($state) {
                                'available' => 'success',
                                'busy' => 'info',
                                'offline' => 'gray',
                                'pending_approval' => 'warning',
                                'suspended' => 'danger',
                                'rejected' => 'danger',
                                default => 'gray',
                            }),
                        Infolists\Components\TextEntry::make('kyc_status')
                            ->label('Statut KYC')
                            ->badge()
                            ->color(fn (?string $state): string => match ($state) {
                                'approved' => 'success',
                                'pending_review' => 'warning',
                                'rejected' => 'danger',
                                'incomplete' => 'gray',
                                default => 'gray',
                            })
                            ->formatStateUsing(fn (?string $state): string => match ($state) {
                                'approved' => '✓ Vérifié',
                                'pending_review' => '⏳ En attente',
                                'rejected' => '❌ Rejeté',
                                'incomplete' => '📝 Incomplet',
                                default => $state ?? 'N/A',
                            }),
                        Infolists\Components\TextEntry::make('kyc_verified_at')
                            ->label('Date vérification KYC')
                            ->dateTime('d/m/Y H:i'),
                        Infolists\Components\TextEntry::make('rating')
                            ->label('Note'),
                        Infolists\Components\TextEntry::make('completed_deliveries')
                            ->label('Livraisons effectuées'),
                        Infolists\Components\TextEntry::make('created_at')
                            ->label('Inscrit le')
                            ->dateTime('d/m/Y H:i'),
                    ])->columns(3),
                
                // Raison de rejet KYC (si applicable)
                Infolists\Components\Section::make('❌ Raison du rejet / Demande de resoumission')
                    ->schema([
                        Infolists\Components\TextEntry::make('kyc_rejection_reason')
                            ->label('')
                            ->columnSpanFull(),
                    ])
                    ->visible(fn ($record) => !empty($record->kyc_rejection_reason)),
                
                // Documents KYC
                Infolists\Components\Section::make('🪪 Documents KYC')
                    ->description('Cliquez sur les images pour les agrandir')
                    ->schema([
                        // CNI
                        Infolists\Components\Grid::make(2)
                            ->schema([
                                Infolists\Components\ViewEntry::make('id_card_front_document')
                                    ->label('CNI (Recto)')
                                    ->view('filament.infolists.entries.kyc-document'),
                                Infolists\Components\ViewEntry::make('id_card_back_document')
                                    ->label('CNI (Verso)')
                                    ->view('filament.infolists.entries.kyc-document'),
                            ]),
                        
                        // Selfie - centré
                        Infolists\Components\ViewEntry::make('selfie_document')
                            ->label('📸 Selfie de vérification (comparer avec la CNI)')
                            ->view('filament.infolists.entries.kyc-document-large'),
                        
                        // Permis
                        Infolists\Components\Grid::make(2)
                            ->schema([
                                Infolists\Components\ViewEntry::make('driving_license_front_document')
                                    ->label('Permis (Recto)')
                                    ->view('filament.infolists.entries.kyc-document'),
                                Infolists\Components\ViewEntry::make('driving_license_back_document')
                                    ->label('Permis (Verso)')
                                    ->view('filament.infolists.entries.kyc-document'),
                            ]),
                        
                        // Carte grise
                        Infolists\Components\ViewEntry::make('vehicle_registration_document')
                            ->label('Carte Grise')
                            ->view('filament.infolists.entries.kyc-document'),
                    ]),
            ]);
    }
}
