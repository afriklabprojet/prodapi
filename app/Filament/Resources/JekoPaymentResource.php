<?php

namespace App\Filament\Resources;

use App\Filament\Resources\JekoPaymentResource\Pages;
use App\Models\JekoPayment;
use App\Enums\JekoPaymentMethod;
use App\Enums\JekoPaymentStatus;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Infolists;
use Filament\Infolists\Infolist;

class JekoPaymentResource extends Resource
{
    protected static ?string $model = JekoPayment::class;

    protected static ?string $navigationIcon = 'heroicon-o-banknotes';

    protected static ?string $navigationLabel = 'Paiements Jeko';

    protected static ?string $modelLabel = 'Paiement Jeko';

    protected static ?string $pluralModelLabel = 'Paiements Jeko';

    protected static ?string $navigationGroup = 'Finance';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Informations')
                    ->schema([
                        Forms\Components\TextInput::make('reference')
                            ->label('Référence')
                            ->disabled(),
                        Forms\Components\TextInput::make('uuid')
                            ->label('UUID')
                            ->disabled(),
                        Forms\Components\Select::make('status')
                            ->label('Statut')
                            ->options(collect(JekoPaymentStatus::cases())->mapWithKeys(
                                fn ($s) => [$s->value => $s->label()]
                            ))
                            ->disabled(),
                        Forms\Components\Select::make('payment_method')
                            ->label('Méthode')
                            ->options(collect(JekoPaymentMethod::cases())->mapWithKeys(
                                fn ($m) => [$m->value => $m->label()]
                            ))
                            ->disabled(),
                        Forms\Components\TextInput::make('amount_cents')
                            ->label('Montant (FCFA)')
                            ->formatStateUsing(fn ($state) => number_format($state / 100, 0, ',', ' '))
                            ->disabled(),
                        Forms\Components\TextInput::make('currency')
                            ->label('Devise')
                            ->disabled(),
                    ])->columns(3),

                Forms\Components\Section::make('Utilisateur & Entité')
                    ->schema([
                        Forms\Components\Select::make('user_id')
                            ->label('Utilisateur')
                            ->relationship('user', 'name')
                            ->disabled(),
                        Forms\Components\TextInput::make('payable_type')
                            ->label('Type d\'entité')
                            ->disabled(),
                        Forms\Components\TextInput::make('payable_id')
                            ->label('ID entité')
                            ->disabled(),
                        Forms\Components\Toggle::make('is_payout')
                            ->label('Décaissement')
                            ->disabled(),
                    ])->columns(2),

                Forms\Components\Section::make('Détails techniques')
                    ->schema([
                        Forms\Components\TextInput::make('error_message')
                            ->label('Message d\'erreur')
                            ->disabled()
                            ->columnSpanFull(),
                        Forms\Components\TextInput::make('recipient_phone')
                            ->label('Téléphone destinataire')
                            ->disabled(),
                        Forms\Components\TextInput::make('description')
                            ->label('Description')
                            ->disabled(),
                        Forms\Components\KeyValue::make('transaction_data')
                            ->label('Données transaction')
                            ->disabled()
                            ->columnSpanFull(),
                        Forms\Components\KeyValue::make('bank_details')
                            ->label('Détails bancaires')
                            ->disabled()
                            ->columnSpanFull(),
                    ])->columns(2)->collapsible(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('reference')
                    ->label('Référence')
                    ->searchable()
                    ->sortable()
                    ->copyable(),
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Utilisateur')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('amount_cents')
                    ->label('Montant')
                    ->formatStateUsing(fn ($state) => number_format($state / 100, 0, ',', ' ') . ' FCFA')
                    ->sortable(),
                Tables\Columns\TextColumn::make('payment_method')
                    ->label('Méthode')
                    ->badge()
                    ->formatStateUsing(fn ($state) => $state instanceof JekoPaymentMethod ? $state->label() : $state)
                    ->color(fn ($state) => match (true) {
                        $state === JekoPaymentMethod::WAVE => 'info',
                        $state === JekoPaymentMethod::ORANGE => 'warning',
                        $state === JekoPaymentMethod::MTN => 'warning',
                        $state === JekoPaymentMethod::MOOV => 'success',
                        $state === JekoPaymentMethod::DJAMO => 'primary',
                        $state === JekoPaymentMethod::BANK_TRANSFER => 'gray',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->formatStateUsing(fn ($state) => $state instanceof JekoPaymentStatus ? $state->label() : $state)
                    ->color(fn ($state) => match (true) {
                        $state === JekoPaymentStatus::SUCCESS => 'success',
                        $state === JekoPaymentStatus::PENDING => 'warning',
                        $state === JekoPaymentStatus::PROCESSING => 'info',
                        $state === JekoPaymentStatus::FAILED => 'danger',
                        $state === JekoPaymentStatus::EXPIRED => 'gray',
                        default => 'gray',
                    }),
                Tables\Columns\IconColumn::make('is_payout')
                    ->label('Décaissement')
                    ->boolean()
                    ->trueIcon('heroicon-o-arrow-up-right')
                    ->falseIcon('heroicon-o-arrow-down-left')
                    ->trueColor('warning')
                    ->falseColor('success'),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Date')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->label('Statut')
                    ->options(collect(JekoPaymentStatus::cases())->mapWithKeys(
                        fn ($s) => [$s->value => $s->label()]
                    )),
                Tables\Filters\SelectFilter::make('payment_method')
                    ->label('Méthode')
                    ->options(collect(JekoPaymentMethod::cases())->mapWithKeys(
                        fn ($m) => [$m->value => $m->label()]
                    )),
                Tables\Filters\TernaryFilter::make('is_payout')
                    ->label('Type')
                    ->trueLabel('Décaissements')
                    ->falseLabel('Encaissements'),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
            ])
            ->bulkActions([])
            ->defaultSort('created_at', 'desc');
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListJekoPayments::route('/'),
            'view' => Pages\ViewJekoPayment::route('/{record}'),
        ];
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit($record): bool
    {
        return false;
    }

    public static function canDelete($record): bool
    {
        return false;
    }
}
