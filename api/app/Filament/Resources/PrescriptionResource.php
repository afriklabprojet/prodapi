<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PrescriptionResource\Pages;
use App\Filament\Resources\PrescriptionResource\RelationManagers;
use App\Models\Prescription;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Infolists;
use Filament\Infolists\Infolist;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;
use Filament\Notifications\Notification;
use Illuminate\Support\Facades\Storage;

class PrescriptionResource extends Resource
{
    protected static ?string $model = Prescription::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-text';
    
    protected static ?string $navigationLabel = 'Ordonnances';
    
    protected static ?string $modelLabel = 'Ordonnance';
    
    protected static ?string $pluralModelLabel = 'Ordonnances';
    
    protected static ?string $navigationGroup = 'Gestion';
    
    protected static ?int $navigationSort = 1;

    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::where('status', 'pending')->count() ?: null;
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Grid::make(3)
                    ->schema([
                        // Colonne de gauche - Informations
                        Forms\Components\Section::make('Informations')
                            ->schema([
                                Forms\Components\Select::make('customer_id')
                                    ->relationship('customer', 'name')
                                    ->label('Client')
                                    ->disabled()
                                    ->dehydrated(false),
                                Forms\Components\Placeholder::make('customer_phone')
                                    ->label('Téléphone')
                                    ->content(fn ($record) => $record?->customer?->phone ?? 'N/A'),
                                Forms\Components\Placeholder::make('customer_email')
                                    ->label('Email')
                                    ->content(fn ($record) => $record?->customer?->email ?? 'N/A'),
                                Forms\Components\Placeholder::make('created_at')
                                    ->label('Soumise le')
                                    ->content(fn ($record) => $record?->created_at?->format('d/m/Y H:i') ?? 'N/A'),
                                Forms\Components\Select::make('status')
                                    ->options([
                                        'pending' => 'En attente',
                                        'validated' => 'Validée',
                                        'quoted' => 'Devis envoyé',
                                        'rejected' => 'Rejetée',
                                    ])
                                    ->required()
                                    ->native(false),
                                Forms\Components\TextInput::make('quote_amount')
                                    ->label('Montant du devis (FCFA)')
                                    ->numeric()
                                    ->prefix('FCFA'),
                            ])
                            ->columnSpan(1),
                        
                        // Colonne centrale - Images ordonnance
                        Forms\Components\Section::make('Images de l\'ordonnance')
                            ->schema([
                                Forms\Components\Placeholder::make('prescription_images')
                                    ->label('')
                                    ->content(function ($record) {
                                        if (!$record) return 'Aucune image';
                                        
                                        $images = $record->getRawImages();
                                        if (empty($images)) return 'Aucune image';
                                        
                                        $html = '<div style="display: flex; flex-wrap: wrap; gap: 10px;">';
                                        foreach ($images as $image) {
                                            $url = route('admin.documents.view', ['path' => $image]);
                                            $html .= '<a href="' . $url . '" target="_blank" style="display: block;">';
                                            $html .= '<img src="' . $url . '" style="max-width: 300px; max-height: 400px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" />';
                                            $html .= '</a>';
                                        }
                                        $html .= '</div>';
                                        
                                        return new \Illuminate\Support\HtmlString($html);
                                    }),
                            ])
                            ->columnSpan(2),
                    ]),
                
                // Notes
                Forms\Components\Section::make('Notes')
                    ->schema([
                        Forms\Components\Grid::make(2)
                            ->schema([
                                Forms\Components\Textarea::make('notes')
                                    ->label('Notes du client')
                                    ->rows(3)
                                    ->disabled(),
                                Forms\Components\Textarea::make('admin_notes')
                                    ->label('Notes admin / Réponse au client')
                                    ->rows(3),
                            ]),
                    ]),
                
                // Analyse OCR (si disponible)
                Forms\Components\Section::make('Analyse OCR')
                    ->schema([
                        Forms\Components\Placeholder::make('analysis_status_display')
                            ->label('Statut analyse')
                            ->content(fn ($record) => match($record?->analysis_status) {
                                'completed' => '✅ Analysée',
                                'analyzing' => '⏳ En cours...',
                                'failed' => '❌ Échec',
                                'manual_review' => '👁️ Révision manuelle',
                                default => '⏸️ Non analysée',
                            }),
                        Forms\Components\Placeholder::make('ocr_confidence_display')
                            ->label('Confiance OCR')
                            ->content(fn ($record) => $record?->ocr_confidence ? $record->ocr_confidence . '%' : 'N/A'),
                        Forms\Components\Placeholder::make('extracted_meds')
                            ->label('Médicaments détectés')
                            ->content(function ($record) {
                                $meds = $record?->extracted_medications;
                                if (empty($meds)) return 'Aucun';
                                
                                $html = '<ul style="list-style: none; padding: 0;">';
                                foreach ($meds as $med) {
                                    $name = $med['name'] ?? 'Inconnu';
                                    $dosage = $med['dosage'] ?? '';
                                    $html .= "<li>💊 <strong>$name</strong> $dosage</li>";
                                }
                                $html .= '</ul>';
                                return new \Illuminate\Support\HtmlString($html);
                            }),
                    ])
                    ->collapsible()
                    ->collapsed(fn ($record) => $record?->analysis_status !== 'completed'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('#')
                    ->sortable(),
                    
                // Miniature de l'image
                Tables\Columns\ViewColumn::make('first_image')
                    ->label('Aperçu')
                    ->view('filament.tables.columns.prescription-image'),
                    
                Tables\Columns\TextColumn::make('customer.name')
                    ->label('Client')
                    ->searchable()
                    ->sortable()
                    ->description(fn ($record) => $record->customer?->phone),
                    
                Tables\Columns\TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pending' => 'En attente',
                        'validated' => 'Validée',
                        'quoted' => 'Devis envoyé',
                        'rejected' => 'Rejetée',
                        default => $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'validated' => 'success',
                        'quoted' => 'info',
                        'rejected' => 'danger',
                        default => 'gray',
                    }),
                    
                Tables\Columns\TextColumn::make('quote_amount')
                    ->label('Devis')
                    ->money('XOF')
                    ->placeholder('—'),
                    
                Tables\Columns\IconColumn::make('analysis_status')
                    ->label('OCR')
                    ->icon(fn ($state) => match($state) {
                        'completed' => 'heroicon-o-check-circle',
                        'analyzing' => 'heroicon-o-arrow-path',
                        'failed' => 'heroicon-o-x-circle',
                        'manual_review' => 'heroicon-o-eye',
                        default => 'heroicon-o-minus-circle',
                    })
                    ->color(fn ($state) => match($state) {
                        'completed' => 'success',
                        'analyzing' => 'warning',
                        'failed' => 'danger',
                        'manual_review' => 'info',
                        default => 'gray',
                    })
                    ->tooltip(fn ($state) => match($state) {
                        'completed' => 'Analyse terminée',
                        'analyzing' => 'Analyse en cours',
                        'failed' => 'Analyse échouée',
                        'manual_review' => 'Révision manuelle requise',
                        default => 'Non analysée',
                    }),
                    
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Date')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'pending' => 'En attente',
                        'validated' => 'Validée',
                        'quoted' => 'Devis envoyé',
                        'rejected' => 'Rejetée',
                    ])
                    ->label('Statut'),
                Tables\Filters\Filter::make('pending_only')
                    ->label('En attente uniquement')
                    ->query(fn (Builder $query) => $query->where('status', 'pending'))
                    ->toggle(),
            ])
            ->actions([
                // Voir les images en grand
                Tables\Actions\Action::make('view_images')
                    ->label('Voir')
                    ->icon('heroicon-o-photo')
                    ->color('info')
                    ->modalHeading('Images de l\'ordonnance')
                    ->modalContent(function ($record) {
                        $images = $record->getRawImages();
                        if (empty($images)) {
                            return new \Illuminate\Support\HtmlString('<p>Aucune image</p>');
                        }
                        
                        $html = '<div style="display: flex; flex-direction: column; gap: 20px; align-items: center;">';
                        foreach ($images as $index => $image) {
                            $url = route('admin.documents.view', ['path' => $image]);
                            $html .= '<div style="text-align: center;">';
                            $html .= '<p style="margin-bottom: 8px; color: #666;">Image ' . ($index + 1) . '</p>';
                            $html .= '<a href="' . $url . '" target="_blank">';
                            $html .= '<img src="' . $url . '" style="max-width: 100%; max-height: 600px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);" />';
                            $html .= '</a>';
                            $html .= '</div>';
                        }
                        $html .= '</div>';
                        
                        return new \Illuminate\Support\HtmlString($html);
                    })
                    ->modalWidth('4xl')
                    ->modalSubmitAction(false)
                    ->modalCancelActionLabel('Fermer'),
                    
                // Valider rapidement
                Tables\Actions\Action::make('validate')
                    ->label('Valider')
                    ->icon('heroicon-o-check')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalHeading('Valider l\'ordonnance')
                    ->modalDescription('Êtes-vous sûr de vouloir valider cette ordonnance ?')
                    ->visible(fn ($record) => $record->status === 'pending')
                    ->action(function ($record) {
                        $record->update([
                            'status' => 'validated',
                            'validated_at' => now(),
                            'validated_by' => auth()->id(),
                        ]);
                        Notification::make()
                            ->title('Ordonnance validée')
                            ->success()
                            ->send();
                    }),
                    
                // Rejeter
                Tables\Actions\Action::make('reject')
                    ->label('Rejeter')
                    ->icon('heroicon-o-x-mark')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->modalHeading('Rejeter l\'ordonnance')
                    ->form([
                        Forms\Components\Textarea::make('rejection_reason')
                            ->label('Raison du rejet')
                            ->required(),
                    ])
                    ->visible(fn ($record) => $record->status === 'pending')
                    ->action(function ($record, array $data) {
                        $record->update([
                            'status' => 'rejected',
                            'admin_notes' => $data['rejection_reason'],
                        ]);
                        Notification::make()
                            ->title('Ordonnance rejetée')
                            ->warning()
                            ->send();
                    }),
                    
                // Envoyer un devis
                Tables\Actions\Action::make('send_quote')
                    ->label('Devis')
                    ->icon('heroicon-o-currency-dollar')
                    ->color('warning')
                    ->modalHeading('Envoyer un devis')
                    ->form([
                        Forms\Components\TextInput::make('quote_amount')
                            ->label('Montant (FCFA)')
                            ->numeric()
                            ->required()
                            ->prefix('FCFA'),
                        Forms\Components\Textarea::make('quote_notes')
                            ->label('Détails du devis'),
                    ])
                    ->visible(fn ($record) => in_array($record->status, ['pending', 'validated']))
                    ->action(function ($record, array $data) {
                        $record->update([
                            'status' => 'quoted',
                            'quote_amount' => $data['quote_amount'],
                            'admin_notes' => $data['quote_notes'] ?? $record->admin_notes,
                            'validated_at' => now(),
                            'validated_by' => auth()->id(),
                        ]);
                        Notification::make()
                            ->title('Devis envoyé: ' . number_format($data['quote_amount'], 0, ',', ' ') . ' FCFA')
                            ->success()
                            ->send();
                    }),
                    
                Tables\Actions\EditAction::make()
                    ->label('Modifier'),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->emptyStateHeading('Aucune ordonnance')
            ->emptyStateDescription('Les ordonnances soumises par les clients apparaîtront ici.')
            ->emptyStateIcon('heroicon-o-document-text')
            ->poll('30s'); // Auto-refresh every 30 seconds
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
            'index' => Pages\ListPrescriptions::route('/'),
            'create' => Pages\CreatePrescription::route('/create'),
            'edit' => Pages\EditPrescription::route('/{record}/edit'),
        ];
    }
}
