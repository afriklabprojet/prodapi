<?php

namespace App\Filament\Pages;

use App\Models\Courier;
use App\Models\Delivery;
use App\Models\CourierShift;
use Filament\Pages\Page;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Illuminate\Database\Eloquent\Builder;

class CourierPerformanceReport extends Page implements HasTable, HasForms
{
    use InteractsWithTable;
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-chart-bar';

    protected static string $view = 'filament.pages.courier-performance-report';

    protected static ?string $navigationLabel = 'Performance livreurs';

    protected static ?string $title = 'Rapport de performance livreurs';

    protected static ?string $navigationGroup = 'Analytics';

    protected static ?int $navigationSort = 1;

    public ?string $dateFrom = null;
    public ?string $dateTo = null;

    public function mount(): void
    {
        $this->dateFrom = now()->subDays(30)->format('Y-m-d');
        $this->dateTo = now()->format('Y-m-d');
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(
                Courier::query()
                    ->where('kyc_status', 'verified')
                    ->withCount([
                        'deliveries' => fn (Builder $q) => $q
                            ->whereBetween('created_at', [$this->dateFrom, $this->dateTo . ' 23:59:59']),
                        'deliveries as completed_deliveries_count' => fn (Builder $q) => $q
                            ->where('status', 'delivered')
                            ->whereBetween('created_at', [$this->dateFrom, $this->dateTo . ' 23:59:59']),
                        'shifts' => fn (Builder $q) => $q
                            ->whereBetween('date', [$this->dateFrom, $this->dateTo]),
                        'shifts as no_show_shifts_count' => fn (Builder $q) => $q
                            ->where('status', CourierShift::STATUS_NO_SHOW)
                            ->whereBetween('date', [$this->dateFrom, $this->dateTo]),
                    ])
            )
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Livreur')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('tier')
                    ->label('Tier')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'Platinum' => 'primary',
                        'Gold' => 'warning',
                        'Silver' => 'gray',
                        default => 'danger',
                    }),

                Tables\Columns\TextColumn::make('total_xp')
                    ->label('XP')
                    ->numeric()
                    ->sortable(),

                Tables\Columns\TextColumn::make('deliveries_count')
                    ->label('Livraisons')
                    ->sortable(),

                Tables\Columns\TextColumn::make('completed_deliveries_count')
                    ->label('Complétées')
                    ->sortable(),

                Tables\Columns\TextColumn::make('acceptance_rate')
                    ->label('Taux acceptation')
                    ->suffix('%')
                    ->sortable()
                    ->color(fn ($state) => $state >= 80 ? 'success' : ($state >= 60 ? 'warning' : 'danger')),

                Tables\Columns\TextColumn::make('completion_rate')
                    ->label('Taux complétion')
                    ->suffix('%')
                    ->sortable()
                    ->color(fn ($state) => $state >= 90 ? 'success' : ($state >= 70 ? 'warning' : 'danger')),

                Tables\Columns\TextColumn::make('on_time_rate')
                    ->label('Ponctualité')
                    ->suffix('%')
                    ->sortable()
                    ->color(fn ($state) => $state >= 85 ? 'success' : ($state >= 65 ? 'warning' : 'danger')),

                Tables\Columns\TextColumn::make('reliability_score')
                    ->label('Fiabilité')
                    ->sortable()
                    ->color(fn ($state) => $state >= 80 ? 'success' : ($state >= 60 ? 'warning' : 'danger')),

                Tables\Columns\TextColumn::make('shifts_count')
                    ->label('Shifts')
                    ->sortable(),

                Tables\Columns\TextColumn::make('no_show_shifts_count')
                    ->label('No-shows')
                    ->sortable()
                    ->color(fn ($state) => $state > 0 ? 'danger' : 'success'),

                Tables\Columns\TextColumn::make('current_streak_days')
                    ->label('Streak')
                    ->suffix(' j')
                    ->sortable(),
            ])
            ->defaultSort('reliability_score', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('tier')
                    ->label('Tier')
                    ->options([
                        'Bronze' => 'Bronze',
                        'Silver' => 'Silver',
                        'Gold' => 'Gold',
                        'Platinum' => 'Platinum',
                    ]),
            ])
            ->striped()
            ->paginated([10, 25, 50]);
    }

    protected function getHeaderWidgets(): array
    {
        return [];
    }

    public function getKpis(): array
    {
        $couriers = Courier::where('kyc_status', 'verified');
        $deliveries = Delivery::whereBetween('created_at', [$this->dateFrom, $this->dateTo . ' 23:59:59']);

        return [
            'total_couriers' => $couriers->count(),
            'active_couriers' => $couriers->clone()->whereHas('deliveries', fn ($q) => $q->whereBetween('created_at', [$this->dateFrom, $this->dateTo . ' 23:59:59']))->count(),
            'total_deliveries' => $deliveries->clone()->count(),
            'completed_deliveries' => $deliveries->clone()->where('status', 'delivered')->count(),
            'avg_acceptance_rate' => round($couriers->clone()->avg('acceptance_rate') ?? 0, 1),
            'avg_reliability' => round($couriers->clone()->avg('reliability_score') ?? 0, 1),
        ];
    }
}
