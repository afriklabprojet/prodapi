<?php

namespace App\Filament\Resources;

use App\Filament\Resources\RefundResource\Pages;
use App\Models\Refund;
use App\Services\RefundService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Auth;

class RefundResource extends Resource
{
    protected static ?string $model = Refund::class;

    protected static ?string $navigationIcon = 'heroicon-o-receipt-refund';
    protected static ?string $navigationLabel = 'Remboursements';
    protected static ?string $navigationGroup = 'Finance';
    protected static ?int $navigationSort = 4;
    protected static ?string $modelLabel = 'Remboursement';
    protected static ?string $pluralModelLabel = 'Remboursements';

    public static function canCreate(): bool
    {
        return false;
    }

    public static function getNavigationBadge(): ?string
    {
        return (string) Refund::where('status', Refund::STATUS_PENDING)->count() ?: null;
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Demande')
                ->schema([
                    Forms\Components\TextInput::make('id')->label('#')->disabled(),
                    Forms\Components\TextInput::make('user.name')->label('Client')->disabled(),
                    Forms\Components\TextInput::make('order.reference')->label('Commande')->disabled(),
                    Forms\Components\TextInput::make('amount')->label('Montant')->suffix('FCFA')->disabled(),
                    Forms\Components\TextInput::make('type')->label('Type')->disabled(),
                    Forms\Components\TextInput::make('method')->label('Méthode')->disabled(),
                    Forms\Components\TextInput::make('source')->label('Source')->disabled(),
                    Forms\Components\TextInput::make('status')->label('Statut')->disabled(),
                    Forms\Components\Textarea::make('reason')->label('Motif client')->disabled()->rows(3)->columnSpanFull(),
                    Forms\Components\Textarea::make('admin_note')->label('Note admin')->rows(3)->columnSpanFull(),
                ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')->label('#')->sortable(),
                Tables\Columns\TextColumn::make('user.name')->label('Client')->searchable(),
                Tables\Columns\TextColumn::make('order.reference')->label('Cmd')->searchable(),
                Tables\Columns\TextColumn::make('amount')
                    ->label('Montant')
                    ->formatStateUsing(fn ($s) => number_format((float) $s, 0, ',', ' ') . ' FCFA')
                    ->sortable()
                    ->weight('bold')
                    ->color('danger'),
                Tables\Columns\TextColumn::make('type')->label('Type')->badge(),
                Tables\Columns\TextColumn::make('method')->label('Méthode')->badge()->color('gray'),
                Tables\Columns\TextColumn::make('source')->label('Source')->badge()->color('info')->toggleable(),
                Tables\Columns\TextColumn::make('status')
                    ->label('Statut')
                    ->badge()
                    ->color(fn (string $s): string => match ($s) {
                        Refund::STATUS_PROCESSED => 'success',
                        Refund::STATUS_APPROVED => 'info',
                        Refund::STATUS_PENDING => 'warning',
                        Refund::STATUS_REJECTED => 'danger',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('created_at')->label('Demande')->dateTime('d/m/Y H:i')->sortable(),
                Tables\Columns\TextColumn::make('processed_at')->label('Traité le')->dateTime('d/m/Y H:i')->toggleable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')->label('Statut')->options([
                    Refund::STATUS_PENDING => 'En attente',
                    Refund::STATUS_APPROVED => 'Approuvé',
                    Refund::STATUS_PROCESSED => 'Traité',
                    Refund::STATUS_REJECTED => 'Refusé',
                ]),
                Tables\Filters\SelectFilter::make('source')->label('Source')->options([
                    Refund::SOURCE_CUSTOMER => 'Client',
                    Refund::SOURCE_AUTO_PHARMACIST_REJECT => 'Auto rejet pharmacien',
                    Refund::SOURCE_AUTO_DELIVERY_FAILED => 'Auto livraison échouée',
                    Refund::SOURCE_ADMIN => 'Admin',
                ]),
            ])
            ->defaultSort('created_at', 'desc')
            ->striped()
            ->actions([
                Tables\Actions\Action::make('approve')
                    ->label('Approuver')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->visible(fn (Refund $r) => $r->isPending())
                    ->form([
                        Forms\Components\Textarea::make('note')->label('Note (optionnelle)')->rows(2),
                    ])
                    ->action(function (Refund $record, array $data): void {
                        try {
                            app(RefundService::class)->approve($record, Auth::user(), $data['note'] ?? null);
                            Notification::make()->success()->title('Approuvé')->send();
                        } catch (\Throwable $e) {
                            Notification::make()->danger()->title('Échec : ' . $e->getMessage())->send();
                        }
                    }),
                Tables\Actions\Action::make('reject')
                    ->label('Refuser')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->visible(fn (Refund $r) => $r->isPending())
                    ->form([
                        Forms\Components\Textarea::make('note')->label('Motif du refus')->required()->rows(3),
                    ])
                    ->action(function (Refund $record, array $data): void {
                        try {
                            app(RefundService::class)->reject($record, Auth::user(), $data['note']);
                            Notification::make()->success()->title('Refusé')->send();
                        } catch (\Throwable $e) {
                            Notification::make()->danger()->title('Échec : ' . $e->getMessage())->send();
                        }
                    }),
                Tables\Actions\Action::make('process')
                    ->label('Créditer wallet')
                    ->icon('heroicon-o-banknotes')
                    ->color('primary')
                    ->requiresConfirmation()
                    ->visible(fn (Refund $r) => in_array($r->status, [Refund::STATUS_PENDING, Refund::STATUS_APPROVED], true))
                    ->action(function (Refund $record): void {
                        try {
                            app(RefundService::class)->process($record, Auth::user());
                            Notification::make()->success()->title('Wallet crédité')->send();
                        } catch (\Throwable $e) {
                            Notification::make()->danger()->title('Échec : ' . $e->getMessage())->send();
                        }
                    }),
                Tables\Actions\ViewAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListRefunds::route('/'),
            'view' => Pages\ViewRefund::route('/{record}'),
        ];
    }
}
