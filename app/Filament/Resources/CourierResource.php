<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CourierResource\Pages;
use App\Filament\Resources\CourierResource\RelationManagers;
use App\Models\Courier;
use App\Notifications\KycStatusNotification;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\HtmlString;
use App\Models\User;

class CourierResource extends Resource
{
    protected static ?string $model = Courier::class;

    protected static ?string $navigationIcon = 'heroicon-o-truck';
    
    protected static ?string $navigationLabel = 'Livreurs';
    
    protected static ?string $navigationGroup = 'Gestion';
    
    protected static ?int $navigationSort = 3;
    
    /**
     * Badge de navigation montrant les KYC en attente
     */
    public static function getNavigationBadge(): ?string
    {
        $pendingCount = Courier::where('kyc_status', 'pending_review')->count();
        return $pendingCount > 0 ? (string) $pendingCount : null;
    }
    
    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }
    
    /**
     * Génère le HTML pour afficher un document KYC
     */
    private static function renderDocumentPreview(?string $documentPath, string $fallbackText = 'Aucun document'): HtmlString|string
    {
        if (empty($documentPath)) {
            return $fallbackText;
        }
        
        try {
            $url = route('admin.documents.view', ['path' => $documentPath]);
            return new HtmlString(
                '<a href="'.$url.'" target="_blank" class="text-primary-600 hover:underline">
                    <img src="'.$url.'" class="max-h-32 rounded border" onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'block\'"/>
                    <span style="display:none">📄 Voir le document</span>
                </a>'
            );
        } catch (\Exception $e) {
            return $fallbackText;
        }
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('user_id')
                    ->relationship('user', 'name')
                    ->required()
                    ->createOptionForm([
                        Forms\Components\TextInput::make('name')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('email')
                            ->email()
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('phone')
                            ->tel()
                            ->required()
                            ->maxLength(20),
                        Forms\Components\FileUpload::make('avatar')
                            ->label('Photo de profil')
                            ->image()
                            ->directory('avatars')
                            ->visibility('public'),
                        Forms\Components\TextInput::make('password')
                            ->password()
                            ->dehydrateStateUsing(fn ($state) => Hash::make($state))
                            ->required(),
                        Forms\Components\Hidden::make('role')
                            ->default('courier'),
                    ])
                    ->createOptionUsing(function (array $data) {
                        return User::create($data)->id;
                    }),
                Forms\Components\TextInput::make('name')
                    ->required(),
                Forms\Components\TextInput::make('phone')
                    ->tel()
                    ->required(),
                Forms\Components\TextInput::make('vehicle_type'),
                Forms\Components\TextInput::make('vehicle_number'),
                Forms\Components\TextInput::make('license_number'),
                Forms\Components\Section::make('Documents KYC')
                    ->description('Documents d\'identité soumis par le coursier (recto/verso)')
                    ->schema([
                        Forms\Components\Placeholder::make('id_card_front_preview')
                            ->label('CNI (Recto)')
                            ->content(fn ($record) => self::renderDocumentPreview($record?->id_card_front_document)),
                        Forms\Components\Placeholder::make('id_card_back_preview')
                            ->label('CNI (Verso)')
                            ->content(fn ($record) => self::renderDocumentPreview($record?->id_card_back_document)),
                        Forms\Components\Placeholder::make('selfie_preview')
                            ->label('Selfie de vérification')
                            ->content(fn ($record) => self::renderDocumentPreview($record?->selfie_document)),
                        Forms\Components\Placeholder::make('driving_license_front_preview')
                            ->label('Permis de Conduire (Recto)')
                            ->content(fn ($record) => self::renderDocumentPreview($record?->driving_license_front_document)),
                        Forms\Components\Placeholder::make('driving_license_back_preview')
                            ->label('Permis de Conduire (Verso)')
                            ->content(fn ($record) => self::renderDocumentPreview($record?->driving_license_back_document)),
                        Forms\Components\Placeholder::make('vehicle_registration_preview')
                            ->label('Carte Grise')
                            ->content(fn ($record) => self::renderDocumentPreview($record?->vehicle_registration_document)),
                    ])->columns(3)
                    ->visible(fn ($record) => $record !== null),
                Forms\Components\Section::make('Télécharger des documents')
                    ->description('Ajouter ou remplacer les documents KYC')
                    ->schema([
                        Forms\Components\FileUpload::make('id_card_front_document')
                            ->label('CNI (Recto)')
                            ->disk('private')
                            ->directory('courier-documents')
                            ->acceptedFileTypes(['application/pdf', 'image/*'])
                            ->required()
                            ->maxSize(5120),
                        Forms\Components\FileUpload::make('id_card_back_document')
                            ->label('CNI (Verso)')
                            ->disk('private')
                            ->directory('courier-documents')
                            ->acceptedFileTypes(['application/pdf', 'image/*'])
                            ->required()
                            ->maxSize(5120),
                        Forms\Components\FileUpload::make('selfie_document')
                            ->label('Selfie')
                            ->disk('private')
                            ->directory('courier-documents')
                            ->acceptedFileTypes(['image/*'])
                            ->maxSize(5120),
                        Forms\Components\FileUpload::make('driving_license_front_document')
                            ->label('Permis (Recto)')
                            ->disk('private')
                            ->directory('courier-documents')
                            ->acceptedFileTypes(['application/pdf', 'image/*'])
                            ->maxSize(5120),
                        Forms\Components\FileUpload::make('driving_license_back_document')
                            ->label('Permis (Verso)')
                            ->disk('private')
                            ->directory('courier-documents')
                            ->acceptedFileTypes(['application/pdf', 'image/*'])
                            ->maxSize(5120),
                        Forms\Components\FileUpload::make('vehicle_registration_document')
                            ->label('Carte Grise')
                            ->disk('private')
                            ->directory('courier-documents')
                            ->acceptedFileTypes(['application/pdf', 'image/*'])
                            ->maxSize(5120),
                    ])->columns(3)
                    ->collapsible()
                    ->collapsed(),
                Forms\Components\Section::make('Statut KYC')
                    ->schema([
                        Forms\Components\Select::make('kyc_status')
                            ->label('Statut KYC')
                            ->options([
                                'incomplete' => 'Incomplet',
                                'pending_review' => 'En attente de vérification',
                                'approved' => 'Approuvé',
                                'rejected' => 'Rejeté',
                            ])
                            ->default('incomplete'),
                        Forms\Components\Textarea::make('kyc_rejection_reason')
                            ->label('Motif du rejet')
                            ->visible(fn ($get) => $get('kyc_status') === 'rejected'),
                        Forms\Components\DateTimePicker::make('kyc_verified_at')
                            ->label('Date de vérification'),
                    ])->columns(2),
                Forms\Components\TextInput::make('latitude')
                    ->numeric(),
                Forms\Components\TextInput::make('longitude')
                    ->numeric(),
                Forms\Components\Select::make('status')
                    ->options([
                        'pending_approval' => 'En attente d\'approbation',
                        'available' => 'Disponible',
                        'busy' => 'Occupé',
                        'offline' => 'Hors ligne',
                        'suspended' => 'Suspendu',
                    ])
                    ->required()
                    ->default('pending_approval'),
                Forms\Components\TextInput::make('rating')
                    ->required()
                    ->numeric()
                    ->default(5),
                Forms\Components\TextInput::make('completed_deliveries')
                    ->required()
                    ->numeric()
                    ->default(0),
                Forms\Components\DateTimePicker::make('last_location_update'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('user.avatar')
                    ->label('Avatar')
                    ->circular(),
                Tables\Columns\TextColumn::make('user.name')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('name')
                    ->searchable(),
                Tables\Columns\TextColumn::make('phone')
                    ->searchable(),
                Tables\Columns\TextColumn::make('vehicle_type')
                    ->searchable(),
                Tables\Columns\TextColumn::make('vehicle_number')
                    ->searchable(),
                Tables\Columns\TextColumn::make('license_number')
                    ->searchable()
                    ->toggleable(isToggledHiddenByDefault: true),
                    
                // Documents KYC miniatures
                Tables\Columns\ViewColumn::make('kyc_documents')
                    ->label('Documents')
                    ->view('filament.tables.columns.kyc-documents-thumbnail'),
                    
                Tables\Columns\TextColumn::make('latitude')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('longitude')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pending_approval' => 'warning',
                        'available' => 'success',
                        'busy' => 'info',
                        'offline' => 'gray',
                        'suspended' => 'danger',
                        'rejected' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pending_approval' => 'En attente',
                        'available' => 'Disponible',
                        'busy' => 'Occupé',
                        'offline' => 'Hors ligne',
                        'suspended' => 'Suspendu',
                        'rejected' => 'Rejeté',
                        default => $state,
                    })
                    ->searchable(),
                Tables\Columns\TextColumn::make('kyc_status')
                    ->label('KYC')
                    ->badge()
                    ->color(fn (?string $state): string => match ($state) {
                        'approved' => 'success',
                        'pending_review' => 'warning',
                        'rejected' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                        'approved' => '✓ Vérifié',
                        'pending_review' => 'En attente',
                        'rejected' => 'Rejeté',
                        'incomplete' => 'Incomplet',
                        default => $state ?? 'N/A',
                    }),
                Tables\Columns\TextColumn::make('rating')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('completed_deliveries')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('last_location_update')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('deleted_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('Statut')
                    ->options([
                        'pending_approval' => 'En attente d\'approbation',
                        'available' => 'Disponible',
                        'busy' => 'Occupé',
                        'offline' => 'Hors ligne',
                        'suspended' => 'Suspendu',
                        'rejected' => 'Rejeté',
                    ]),
                Tables\Filters\SelectFilter::make('kyc_status')
                    ->label('Statut KYC')
                    ->options([
                        'incomplete' => 'Incomplet',
                        'pending_review' => 'En attente de vérification',
                        'approved' => 'Approuvé',
                        'rejected' => 'Rejeté',
                    ]),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                
                // Action: Vérifier KYC avec vue détaillée des documents
                Tables\Actions\Action::make('verify_kyc')
                    ->label('Vérifier KYC')
                    ->icon('heroicon-o-identification')
                    ->color('info')
                    ->visible(fn ($record) => $record->kyc_status === 'pending_review')
                    ->modalHeading(fn ($record) => '🪪 Vérification KYC - ' . $record->name)
                    ->modalWidth('5xl')
                    ->modalContent(function ($record) {
                        $html = '<div style="padding: 16px;">';
                        
                        // Info livreur
                        $html .= '<div style="background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); color: white; padding: 16px; border-radius: 12px; margin-bottom: 20px;">';
                        $html .= '<h3 style="margin: 0 0 10px 0; font-size: 18px;">📋 Informations du livreur</h3>';
                        $html .= '<p style="margin: 4px 0;"><strong>Nom:</strong> ' . e($record->name) . '</p>';
                        $html .= '<p style="margin: 4px 0;"><strong>Téléphone:</strong> ' . e($record->phone ?? 'N/A') . '</p>';
                        $html .= '<p style="margin: 4px 0;"><strong>Email:</strong> ' . e($record->user?->email ?? 'N/A') . '</p>';
                        $html .= '<p style="margin: 4px 0;"><strong>Véhicule:</strong> ' . match($record->vehicle_type) {
                            'motorcycle' => '🏍️ Moto',
                            'car' => '🚗 Voiture',
                            'bicycle' => '🚲 Vélo',
                            default => e($record->vehicle_type ?? 'N/A'),
                        } . ($record->vehicle_number ? ' - ' . e($record->vehicle_number) : '') . '</p>';
                        $html .= '</div>';
                        
                        // CNI Recto/Verso
                        $html .= '<h4 style="margin: 16px 0 12px 0; color: #374151;">🪪 Carte d\'Identité (CNI)</h4>';
                        $html .= '<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px;">';
                        
                        // Recto
                        $html .= '<div style="text-align: center; background: #f9fafb; padding: 12px; border-radius: 8px; border: 2px dashed #e5e7eb;">';
                        $html .= '<p style="margin: 0 0 8px 0; font-weight: 600; color: #6b7280;">RECTO</p>';
                        if ($record->id_card_front_document) {
                            $url = route('admin.documents.view', ['path' => $record->id_card_front_document]);
                            $html .= '<a href="'.$url.'" target="_blank"><img src="'.$url.'" style="max-width: 100%; max-height: 250px; border-radius: 8px;" /></a>';
                        } else {
                            $html .= '<div style="height: 120px; display: flex; align-items: center; justify-content: center; color: #dc2626;">❌ Non fourni</div>';
                        }
                        $html .= '</div>';
                        
                        // Verso
                        $html .= '<div style="text-align: center; background: #f9fafb; padding: 12px; border-radius: 8px; border: 2px dashed #e5e7eb;">';
                        $html .= '<p style="margin: 0 0 8px 0; font-weight: 600; color: #6b7280;">VERSO</p>';
                        if ($record->id_card_back_document) {
                            $url = route('admin.documents.view', ['path' => $record->id_card_back_document]);
                            $html .= '<a href="'.$url.'" target="_blank"><img src="'.$url.'" style="max-width: 100%; max-height: 250px; border-radius: 8px;" /></a>';
                        } else {
                            $html .= '<div style="height: 120px; display: flex; align-items: center; justify-content: center; color: #dc2626;">❌ Non fourni</div>';
                        }
                        $html .= '</div></div>';
                        
                        // Selfie
                        $html .= '<h4 style="margin: 16px 0 12px 0; color: #374151;">📸 Selfie de Vérification</h4>';
                        $html .= '<div style="text-align: center; background: #fef3c7; padding: 16px; border-radius: 8px; border: 2px solid #f59e0b; margin-bottom: 20px;">';
                        if ($record->selfie_document) {
                            $url = route('admin.documents.view', ['path' => $record->selfie_document]);
                            $html .= '<a href="'.$url.'" target="_blank"><img src="'.$url.'" style="max-width: 280px; max-height: 280px; border-radius: 12px;" /></a>';
                            $html .= '<p style="margin: 10px 0 0 0; color: #92400e; font-size: 13px;">💡 Comparer ce selfie avec la photo sur la CNI</p>';
                        } else {
                            $html .= '<div style="height: 120px; display: flex; align-items: center; justify-content: center; color: #dc2626;">❌ Selfie non fourni</div>';
                        }
                        $html .= '</div>';
                        
                        // Permis (si dispo)
                        if ($record->driving_license_front_document || $record->driving_license_back_document) {
                            $html .= '<h4 style="margin: 16px 0 12px 0; color: #374151;">🚗 Permis de Conduire</h4>';
                            $html .= '<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">';
                            
                            $html .= '<div style="text-align: center; background: #f0fdf4; padding: 12px; border-radius: 8px; border: 2px dashed #86efac;">';
                            $html .= '<p style="margin: 0 0 8px 0; font-weight: 600; color: #6b7280;">RECTO</p>';
                            if ($record->driving_license_front_document) {
                                $url = route('admin.documents.view', ['path' => $record->driving_license_front_document]);
                                $html .= '<a href="'.$url.'" target="_blank"><img src="'.$url.'" style="max-width: 100%; max-height: 200px; border-radius: 8px;" /></a>';
                            } else {
                                $html .= '<div style="height: 100px; display: flex; align-items: center; justify-content: center; color: #9ca3af;">Non fourni</div>';
                            }
                            $html .= '</div>';
                            
                            $html .= '<div style="text-align: center; background: #f0fdf4; padding: 12px; border-radius: 8px; border: 2px dashed #86efac;">';
                            $html .= '<p style="margin: 0 0 8px 0; font-weight: 600; color: #6b7280;">VERSO</p>';
                            if ($record->driving_license_back_document) {
                                $url = route('admin.documents.view', ['path' => $record->driving_license_back_document]);
                                $html .= '<a href="'.$url.'" target="_blank"><img src="'.$url.'" style="max-width: 100%; max-height: 200px; border-radius: 8px;" /></a>';
                            } else {
                                $html .= '<div style="height: 100px; display: flex; align-items: center; justify-content: center; color: #9ca3af;">Non fourni</div>';
                            }
                            $html .= '</div></div>';
                        }
                        
                        $html .= '</div>';
                        return new HtmlString($html);
                    })
                    ->modalSubmitAction(false)
                    ->modalCancelActionLabel('Fermer'),
                
                // Action: Approuver le coursier
                Tables\Actions\Action::make('approve')
                    ->label('Approuver')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->visible(fn ($record) => $record->status === 'pending_approval')
                    ->requiresConfirmation()
                    ->modalHeading('Approuver ce coursier ?')
                    ->modalDescription('Le coursier pourra se connecter et commencer à livrer.')
                    ->action(function ($record) {
                        $record->update([
                            'status' => 'available',
                            'kyc_status' => 'approved',
                            'kyc_verified_at' => now(),
                        ]);
                    }),
                // Action: Rejeter le coursier
                Tables\Actions\Action::make('reject')
                    ->label('Rejeter')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->visible(fn ($record) => in_array($record->status, ['pending_approval']))
                    ->form([
                        Forms\Components\Textarea::make('rejection_reason')
                            ->label('Motif du rejet')
                            ->required()
                            ->placeholder('Expliquez pourquoi la demande est rejetée...'),
                    ])
                    ->action(function ($record, array $data) {
                        $record->update([
                            'status' => 'rejected',
                            'kyc_status' => 'rejected',
                            'kyc_rejection_reason' => $data['rejection_reason'],
                        ]);
                    }),
                    
                // Action: Demander resoumission de documents
                Tables\Actions\Action::make('request_resubmission')
                    ->label('Resoumission')
                    ->icon('heroicon-o-arrow-path')
                    ->color('warning')
                    ->visible(fn ($record) => in_array($record->kyc_status, ['pending_review', 'incomplete']))
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
                            ->placeholder('Ex: Photo floue, document expiré, selfie ne correspond pas à la CNI...'),
                    ])
                    ->action(function ($record, array $data) {
                        $documentsLabels = [
                            'id_card_front' => 'CNI (Recto)',
                            'id_card_back' => 'CNI (Verso)',
                            'selfie' => 'Selfie',
                            'driving_license_front' => 'Permis (Recto)',
                            'driving_license_back' => 'Permis (Verso)',
                            'vehicle_registration' => 'Carte Grise',
                        ];
                        $docsList = array_map(fn($d) => $documentsLabels[$d] ?? $d, $data['documents_to_resubmit']);
                        
                        $rejectionReason = "📤 Documents à resoumettre: " . implode(', ', $docsList) . "\n\n💬 Raison: {$data['reason']}";
                        
                        $record->update([
                            'kyc_status' => 'incomplete',
                            'kyc_rejection_reason' => $rejectionReason,
                        ]);
                        
                        // Envoyer notification push au livreur
                        $record->user?->notify(new KycStatusNotification('incomplete', $rejectionReason));
                    }),
                    
                // Action: Suspendre le coursier
                Tables\Actions\Action::make('suspend')
                    ->label('Suspendre')
                    ->icon('heroicon-o-pause-circle')
                    ->color('warning')
                    ->visible(fn ($record) => in_array($record->status, ['available', 'busy', 'offline']))
                    ->requiresConfirmation()
                    ->modalHeading('Suspendre ce coursier ?')
                    ->modalDescription('Le coursier ne pourra plus se connecter.')
                    ->action(fn ($record) => $record->update(['status' => 'suspended'])),
                // Action: Réactiver le coursier
                Tables\Actions\Action::make('reactivate')
                    ->label('Réactiver')
                    ->icon('heroicon-o-arrow-path')
                    ->color('success')
                    ->visible(fn ($record) => in_array($record->status, ['suspended', 'rejected']))
                    ->requiresConfirmation()
                    ->action(fn ($record) => $record->update(['status' => 'available'])),
                Tables\Actions\Action::make('setAvailable')
                    ->label('Disponible')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->visible(fn ($record) => $record->status === 'offline')
                    ->action(fn ($record) => $record->update(['status' => 'available'])),
                Tables\Actions\Action::make('setOffline')
                    ->label('Hors ligne')
                    ->icon('heroicon-o-x-circle')
                    ->color('gray')
                    ->visible(fn ($record) => $record->status === 'available')
                    ->action(fn ($record) => $record->update(['status' => 'offline'])),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
                Tables\Actions\BulkAction::make('setAllOffline')
                    ->label('Mettre hors ligne')
                    ->icon('heroicon-o-moon')
                    ->color('gray')
                    ->action(fn (\Illuminate\Database\Eloquent\Collection $records) => 
                        $records->each(fn ($record) => $record->update(['status' => 'offline']))
                    )
                    ->deselectRecordsAfterCompletion(),
                Tables\Actions\BulkAction::make('exportCsv')
                    ->label('Exporter CSV')
                    ->icon('heroicon-o-arrow-down-tray')
                    ->action(function (\Illuminate\Database\Eloquent\Collection $records) {
                        $csvData = "ID,Nom,Téléphone,Véhicule,Statut,Livraisons,Note\n";
                        foreach ($records as $record) {
                            $csvData .= "{$record->id},{$record->name},{$record->phone},{$record->vehicle_type},{$record->status},{$record->completed_deliveries},{$record->rating}\n";
                        }
                        
                        return response()->streamDownload(function () use ($csvData) {
                            echo $csvData;
                        }, 'couriers_export_' . now()->format('Ymd_His') . '.csv');
                    }),
            ])->defaultSort('created_at', 'desc');
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
            'index' => Pages\ListCouriers::route('/'),
            'create' => Pages\CreateCourier::route('/create'),
            'view' => Pages\ViewCourier::route('/{record}'),
            'edit' => Pages\EditCourier::route('/{record}/edit'),
        ];
    }
}
