<?php

namespace App\Filament\Widgets;

use App\Models\CourierShift;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

/**
 * Widget affichant les créneaux livreurs du jour.
 * Permet de voir qui est prévu pour travailler aujourd'hui.
 */
class CourierShiftsWidget extends BaseWidget
{
    protected static ?int $sort = 4;
    
    protected int | string | array $columnSpan = 'full';
    
    protected static ?string $heading = '📅 Créneaux du jour';
    
    protected static ?string $pollingInterval = '60s';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                CourierShift::query()
                    ->with(['courier.user'])
                    ->whereDate('date', today())
                    ->orderByRaw("FIELD(status, 'in_progress', 'confirmed', 'completed', 'cancelled', 'no_show')")
                    ->orderBy('start_time')
            )
            ->columns([
                Tables\Columns\TextColumn::make('courier.user.name')
                    ->label('Livreur')
                    ->searchable()
                    ->icon('heroicon-o-user')
                    ->weight('bold'),
                    
                Tables\Columns\TextColumn::make('start_time')
                    ->label('Horaires')
                    ->formatStateUsing(fn ($state, $record) => 
                        $record->start_time?->format('H:i') . ' → ' . $record->end_time?->format('H:i')
                    ),
                    
                Tables\Columns\TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn ($state) => match($state) {
                        CourierShift::STATUS_IN_PROGRESS => 'success',
                        CourierShift::STATUS_CONFIRMED => 'info',
                        CourierShift::STATUS_COMPLETED => 'gray',
                        CourierShift::STATUS_CANCELLED => 'danger',
                        CourierShift::STATUS_NO_SHOW => 'danger',
                        default => 'gray',
                    })
                    ->icon(fn ($state) => match($state) {
                        CourierShift::STATUS_IN_PROGRESS => 'heroicon-o-play',
                        CourierShift::STATUS_CONFIRMED => 'heroicon-o-check',
                        CourierShift::STATUS_COMPLETED => 'heroicon-o-check-badge',
                        CourierShift::STATUS_CANCELLED => 'heroicon-o-x-circle',
                        CourierShift::STATUS_NO_SHOW => 'heroicon-o-exclamation-triangle',
                        default => null,
                    })
                    ->formatStateUsing(fn ($state) => match($state) {
                        CourierShift::STATUS_IN_PROGRESS => '🟢 Actif',
                        CourierShift::STATUS_CONFIRMED => '🔵 Prévu',
                        CourierShift::STATUS_COMPLETED => '✅ Terminé',
                        CourierShift::STATUS_CANCELLED => '❌ Annulé',
                        CourierShift::STATUS_NO_SHOW => '⚠️ No-show',
                        default => $state,
                    }),
                    
                Tables\Columns\TextColumn::make('deliveries_completed')
                    ->label('Livraisons')
                    ->badge()
                    ->color('success'),
                    
                Tables\Columns\TextColumn::make('violations_count')
                    ->label('Violations')
                    ->badge()
                    ->color(fn ($state) => $state >= 2 ? 'danger' : ($state >= 1 ? 'warning' : 'gray')),
                    
                Tables\Columns\TextColumn::make('guaranteed_bonus')
                    ->label('Bonus')
                    ->formatStateUsing(fn ($state) => number_format($state) . ' F')
                    ->color('success'),
            ])
            ->actions([
                Tables\Actions\Action::make('start')
                    ->label('Démarrer')
                    ->icon('heroicon-o-play')
                    ->color('success')
                    ->visible(fn ($record) => $record->status === CourierShift::STATUS_CONFIRMED)
                    ->action(fn ($record) => $record->update([
                        'status' => CourierShift::STATUS_IN_PROGRESS,
                        'actual_start_time' => now(),
                    ])),
                    
                Tables\Actions\Action::make('complete')
                    ->label('Terminer')
                    ->icon('heroicon-o-check')
                    ->color('gray')
                    ->visible(fn ($record) => $record->status === CourierShift::STATUS_IN_PROGRESS)
                    ->action(function ($record) {
                        $record->update([
                            'status' => CourierShift::STATUS_COMPLETED,
                            'actual_end_time' => now(),
                            'earned_bonus' => $record->calculated_bonus,
                        ]);
                    }),
                    
                Tables\Actions\Action::make('no_show')
                    ->label('No-show')
                    ->icon('heroicon-o-exclamation-triangle')
                    ->color('danger')
                    ->visible(fn ($record) => $record->status === CourierShift::STATUS_CONFIRMED)
                    ->requiresConfirmation()
                    ->action(fn ($record) => $record->update(['status' => CourierShift::STATUS_NO_SHOW])),
            ])
            ->emptyStateHeading('Aucun créneau aujourd\'hui')
            ->emptyStateDescription('Les créneaux planifiés apparaîtront ici')
            ->emptyStateIcon('heroicon-o-calendar-days');
    }
}
