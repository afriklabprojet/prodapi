<?php

namespace App\Filament\Resources;

use App\Models\Commission;
use App\Models\CommissionLine;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class CommissionResource extends Resource
{
    protected static ?string $model = Commission::class;

    protected static ?string $navigationIcon = 'heroicon-o-calculator';

    protected static ?string $navigationLabel = 'Commissions';

    protected static ?string $navigationGroup = 'Finance';

    protected static ?int $navigationSort = 1;

    protected static ?string $modelLabel = 'Commission';

    protected static ?string $pluralModelLabel = 'Commissions';

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Détails de la commission')
                ->schema([
                    Forms\Components\TextInput::make('order.reference')
                        ->label('Commande')
                        ->disabled(),
                    Forms\Components\TextInput::make('total_amount')
                        ->label('Montant total')
                        ->suffix('FCFA')
                        ->disabled(),
                    Forms\Components\DateTimePicker::make('calculated_at')
                        ->label('Calculée le')
                        ->disabled(),
                ])->columns(3),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('#')
                    ->sortable(),
                Tables\Columns\TextColumn::make('order.reference')
                    ->label('Commande')
                    ->searchable()
                    ->sortable()
                    ->url(fn (Commission $record) => $record->order_id
                        ? route('filament.admin.resources.orders.edit', $record->order_id)
                        : null),
                Tables\Columns\TextColumn::make('order.pharmacy.name')
                    ->label('Pharmacie')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('total_amount')
                    ->label('Sous-total commande')
                    ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                    ->sortable(),
                Tables\Columns\TextColumn::make('platform_amount')
                    ->label('Plateforme')
                    ->getStateUsing(fn (Commission $record) => $record->getPlatformAmount())
                    ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                    ->color('danger')
                    ->weight('bold'),
                Tables\Columns\TextColumn::make('pharmacy_amount')
                    ->label('Pharmacie')
                    ->getStateUsing(fn (Commission $record) => $record->getPharmacyAmount())
                    ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                    ->color('success')
                    ->weight('bold'),
                Tables\Columns\TextColumn::make('courier_amount')
                    ->label('Livreur')
                    ->getStateUsing(fn (Commission $record) => $record->getCourierAmount())
                    ->formatStateUsing(fn ($state) => $state > 0
                        ? number_format($state, 0, ',', ' ') . ' FCFA'
                        : '-'),
                Tables\Columns\TextColumn::make('order.payment_status')
                    ->label('Paiement')
                    ->badge()
                    ->color(fn (?string $state): string => match ($state) {
                        'paid' => 'success',
                        'pending' => 'warning',
                        'failed' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                        'paid' => 'Payé',
                        'pending' => 'En attente',
                        'failed' => 'Échoué',
                        default => $state ?? '-',
                    }),
                Tables\Columns\TextColumn::make('calculated_at')
                    ->label('Date')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\Filter::make('date_range')
                    ->form([
                        Forms\Components\DatePicker::make('from')
                            ->label('Du'),
                        Forms\Components\DatePicker::make('until')
                            ->label('Au'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when($data['from'],
                                fn (Builder $query, $date) => $query->whereDate('calculated_at', '>=', $date))
                            ->when($data['until'],
                                fn (Builder $query, $date) => $query->whereDate('calculated_at', '<=', $date));
                    }),
                Tables\Filters\SelectFilter::make('pharmacy')
                    ->label('Pharmacie')
                    ->relationship('order.pharmacy', 'name')
                    ->searchable()
                    ->preload(),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
            ])
            ->bulkActions([])
            ->defaultSort('calculated_at', 'desc');
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => CommissionResource\Pages\ListCommissions::route('/'),
        ];
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canDelete($record): bool
    {
        return false;
    }
}
