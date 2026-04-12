<?php

namespace App\Filament\Widgets;

use App\Models\Prescription;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;
use Filament\Forms;
use Filament\Notifications\Notification;

class PendingPrescriptionsWidget extends BaseWidget
{
    protected static ?int $sort = 2;
    
    protected int | string | array $columnSpan = 'full';
    
    protected static ?string $heading = '📋 Ordonnances en attente';
    
    protected static ?string $pollingInterval = '30s';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                Prescription::query()
                    ->where('status', 'pending')
                    ->orderBy('created_at', 'desc')
                    ->limit(10)
            )
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('#')
                    ->sortable(),
                    
                // Miniature de l'ordonnance
                Tables\Columns\ViewColumn::make('first_image')
                    ->label('Ordonnance')
                    ->view('filament.tables.columns.prescription-image-widget'),
                    
                Tables\Columns\TextColumn::make('customer.name')
                    ->label('Client')
                    ->searchable()
                    ->description(fn ($record) => $record->customer?->phone ?? ''),
                    
                Tables\Columns\TextColumn::make('notes')
                    ->label('Notes')
                    ->limit(50)
                    ->placeholder('Aucune note')
                    ->wrap(),
                    
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Soumise')
                    ->since()
                    ->sortable(),
            ])
            ->actions([
                // Voir les images en popup
                Tables\Actions\Action::make('view')
                    ->label('Voir')
                    ->icon('heroicon-o-eye')
                    ->color('info')
                    ->modalHeading(fn ($record) => 'Ordonnance #' . $record->id)
                    ->modalContent(function ($record) {
                        return view('filament.modals.prescription-view', [
                            'prescription' => $record,
                            'customer' => $record->customer,
                            'images' => $record->getRawImages(),
                        ]);
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
                    ->action(function ($record) {
                        $record->update([
                            'status' => 'validated',
                            'validated_at' => now(),
                            'validated_by' => auth()->id(),
                        ]);
                        Notification::make()
                            ->title('Ordonnance #' . $record->id . ' validée')
                            ->success()
                            ->send();
                    }),
                    
                // Envoyer devis
                Tables\Actions\Action::make('quote')
                    ->label('Devis')
                    ->icon('heroicon-o-currency-dollar')
                    ->color('warning')
                    ->form([
                        Forms\Components\TextInput::make('quote_amount')
                            ->label('Montant (FCFA)')
                            ->numeric()
                            ->required()
                            ->prefix('FCFA'),
                        Forms\Components\Textarea::make('notes')
                            ->label('Détails'),
                    ])
                    ->action(function ($record, array $data) {
                        $record->update([
                            'status' => 'quoted',
                            'quote_amount' => $data['quote_amount'],
                            'admin_notes' => $data['notes'] ?? null,
                            'validated_at' => now(),
                            'validated_by' => auth()->id(),
                        ]);
                        Notification::make()
                            ->title('Devis envoyé: ' . number_format($data['quote_amount'], 0, ',', ' ') . ' FCFA')
                            ->success()
                            ->send();
                    }),
                    
                // Rejeter
                Tables\Actions\Action::make('reject')
                    ->label('Rejeter')
                    ->icon('heroicon-o-x-mark')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\Textarea::make('reason')
                            ->label('Raison')
                            ->required(),
                    ])
                    ->action(function ($record, array $data) {
                        $record->update([
                            'status' => 'rejected',
                            'admin_notes' => $data['reason'],
                        ]);
                        Notification::make()
                            ->title('Ordonnance rejetée')
                            ->warning()
                            ->send();
                    }),
            ])
            ->emptyStateHeading('Aucune ordonnance en attente')
            ->emptyStateDescription('Les nouvelles ordonnances apparaîtront ici.')
            ->emptyStateIcon('heroicon-o-check-circle');
    }
    
    public static function canView(): bool
    {
        return Prescription::where('status', 'pending')->exists();
    }
}
