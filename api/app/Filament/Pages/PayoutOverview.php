<?php

namespace App\Filament\Pages;

use App\Models\Courier;
use App\Models\Pharmacy;
use App\Models\Wallet;
use App\Models\WithdrawalRequest;
use Filament\Pages\Page;
use Filament\Tables;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Table;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Database\Eloquent\Builder;

class PayoutOverview extends Page implements HasTable
{
    use InteractsWithTable;

    protected static ?string $navigationIcon = 'heroicon-o-banknotes';
    protected static ?string $navigationLabel = 'Paiements à effectuer';
    protected static ?string $navigationGroup = 'Finance';
    protected static ?int $navigationSort = 2;
    protected static ?string $slug = 'payout-overview';
    protected static string $view = 'filament.pages.payout-overview';

    public string $activeTab = 'pharmacies';

    public static function canAccess(): bool
    {
        return auth()->user()?->isAdmin() ?? false;
    }

    public function switchTab(string $tab): void
    {
        $this->activeTab = $tab;
        $this->resetTable();
    }

    public function table(Table $table): Table
    {
        if ($this->activeTab === 'couriers') {
            return $this->courierTable($table);
        }
        return $this->pharmacyTable($table);
    }

    protected function pharmacyTable(Table $table): Table
    {
        return $table
            ->query(
                Wallet::query()
                    ->where('walletable_type', 'App\Models\Pharmacy')
                    ->where('balance', '>', 0)
                    ->with('walletable')
            )
            ->columns([
                Tables\Columns\TextColumn::make('walletable.name')
                    ->label('Pharmacie')
                    ->searchable(query: function (Builder $query, string $search) {
                        $query->whereHasMorph('walletable', [Pharmacy::class], function ($q) use ($search) {
                            $q->where('name', 'like', "%{$search}%");
                        });
                    })
                    ->sortable(query: function (Builder $query, string $direction) {
                        $query->join('pharmacies', function ($join) {
                            $join->on('wallets.walletable_id', '=', 'pharmacies.id')
                                 ->where('wallets.walletable_type', '=', 'App\Models\Pharmacy');
                        })->orderBy('pharmacies.name', $direction);
                    }),
                Tables\Columns\TextColumn::make('balance')
                    ->label('Solde à payer')
                    ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                    ->sortable()
                    ->color('danger')
                    ->weight('bold')
                    ->size(Tables\Columns\TextColumn\TextColumnSize::Large),
                Tables\Columns\TextColumn::make('total_earned')
                    ->label('Total gagné')
                    ->getStateUsing(function (Wallet $record) {
                        return $record->transactions()
                            ->where('type', 'CREDIT')
                            ->sum('amount');
                    })
                    ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                    ->color('success'),
                Tables\Columns\TextColumn::make('total_withdrawn')
                    ->label('Total retiré')
                    ->getStateUsing(function (Wallet $record) {
                        return $record->transactions()
                            ->where('type', 'DEBIT')
                            ->where('category', 'withdrawal')
                            ->sum('amount');
                    })
                    ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                    ->color('gray'),
                Tables\Columns\TextColumn::make('pending_withdrawal')
                    ->label('Retrait en cours')
                    ->getStateUsing(function (Wallet $record) {
                        return WithdrawalRequest::where('wallet_id', $record->id)
                            ->whereIn('status', ['pending', 'processing'])
                            ->sum('amount');
                    })
                    ->formatStateUsing(fn ($state) => $state > 0
                        ? number_format($state, 0, ',', ' ') . ' FCFA'
                        : '-')
                    ->color('warning'),
                Tables\Columns\TextColumn::make('last_transaction')
                    ->label('Dernière transaction')
                    ->getStateUsing(function (Wallet $record) {
                        return $record->transactions()->latest()->value('created_at');
                    })
                    ->dateTime('d/m/Y H:i')
                    ->color('gray'),
            ])
            ->defaultSort('balance', 'desc')
            ->striped()
            ->emptyStateHeading('Aucune pharmacie avec un solde positif')
            ->emptyStateDescription('Toutes les pharmacies ont été payées.');
    }

    protected function courierTable(Table $table): Table
    {
        return $table
            ->query(
                Wallet::query()
                    ->where('walletable_type', 'App\Models\Courier')
                    ->where('balance', '>', 0)
                    ->with('walletable')
            )
            ->columns([
                Tables\Columns\TextColumn::make('walletable.user.name')
                    ->label('Livreur')
                    ->searchable(query: function (Builder $query, string $search) {
                        $query->whereHasMorph('walletable', [Courier::class], function ($q) use ($search) {
                            $q->whereHas('user', fn ($u) => $u->where('name', 'like', "%{$search}%"));
                        });
                    })
                    ->default('—'),
                Tables\Columns\TextColumn::make('walletable.phone')
                    ->label('Téléphone')
                    ->searchable(query: function (Builder $query, string $search) {
                        $query->whereHasMorph('walletable', [Courier::class], function ($q) use ($search) {
                            $q->where('phone', 'like', "%{$search}%");
                        });
                    })
                    ->default('—'),
                Tables\Columns\TextColumn::make('balance')
                    ->label('Solde à payer')
                    ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                    ->sortable()
                    ->color('danger')
                    ->weight('bold')
                    ->size(Tables\Columns\TextColumn\TextColumnSize::Large),
                Tables\Columns\TextColumn::make('total_earned')
                    ->label('Total gagné')
                    ->getStateUsing(function (Wallet $record) {
                        return $record->transactions()
                            ->where('type', 'CREDIT')
                            ->sum('amount');
                    })
                    ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                    ->color('success'),
                Tables\Columns\TextColumn::make('total_withdrawn')
                    ->label('Total retiré')
                    ->getStateUsing(function (Wallet $record) {
                        return $record->transactions()
                            ->where('type', 'DEBIT')
                            ->where('category', 'withdrawal')
                            ->sum('amount');
                    })
                    ->formatStateUsing(fn ($state) => number_format($state, 0, ',', ' ') . ' FCFA')
                    ->color('gray'),
                Tables\Columns\TextColumn::make('pending_withdrawal')
                    ->label('Retrait en cours')
                    ->getStateUsing(function (Wallet $record) {
                        return WithdrawalRequest::where('wallet_id', $record->id)
                            ->whereIn('status', ['pending', 'processing'])
                            ->sum('amount');
                    })
                    ->formatStateUsing(fn ($state) => $state > 0
                        ? number_format($state, 0, ',', ' ') . ' FCFA'
                        : '-')
                    ->color('warning'),
                Tables\Columns\TextColumn::make('last_transaction')
                    ->label('Dernière transaction')
                    ->getStateUsing(function (Wallet $record) {
                        return $record->transactions()->latest()->value('created_at');
                    })
                    ->dateTime('d/m/Y H:i')
                    ->color('gray'),
            ])
            ->defaultSort('balance', 'desc')
            ->striped()
            ->emptyStateHeading('Aucun livreur avec un solde positif')
            ->emptyStateDescription('Tous les livreurs ont été payés.');
    }

    protected function getHeaderWidgets(): array
    {
        return [
            PayoutOverview\PayoutStatsWidget::class,
        ];
    }

    public function getHeaderWidgetsColumns(): int|string|array
    {
        return 4;
    }
}
