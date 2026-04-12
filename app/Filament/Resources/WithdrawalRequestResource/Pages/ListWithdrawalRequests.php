<?php

namespace App\Filament\Resources\WithdrawalRequestResource\Pages;

use App\Filament\Resources\WithdrawalRequestResource;
use App\Models\WithdrawalRequest;
use Filament\Resources\Pages\ListRecords;
use Filament\Resources\Components\Tab;
use Illuminate\Database\Eloquent\Builder;

class ListWithdrawalRequests extends ListRecords
{
    protected static string $resource = WithdrawalRequestResource::class;

    public function getTabs(): array
    {
        return [
            'all' => Tab::make('Toutes')
                ->badge(WithdrawalRequest::count()),
            'pending' => Tab::make('En attente')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', 'pending'))
                ->badge(WithdrawalRequest::where('status', 'pending')->count())
                ->badgeColor('warning'),
            'processing' => Tab::make('En cours')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', 'processing'))
                ->badge(WithdrawalRequest::where('status', 'processing')->count())
                ->badgeColor('info'),
            'completed' => Tab::make('Complétées')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', 'completed'))
                ->badge(WithdrawalRequest::where('status', 'completed')->count())
                ->badgeColor('success'),
            'failed' => Tab::make('Échouées')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', 'failed'))
                ->badge(WithdrawalRequest::where('status', 'failed')->count())
                ->badgeColor('danger'),
        ];
    }
}
