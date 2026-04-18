<?php

namespace App\Filament\Resources\CourierShiftResource\Pages;

use App\Filament\Resources\CourierShiftResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;
use Filament\Resources\Components\Tab;
use Illuminate\Database\Eloquent\Builder;
use App\Models\CourierShift;

class ListCourierShifts extends ListRecords
{
    protected static string $resource = CourierShiftResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make()
                ->label('Nouveau créneau'),
        ];
    }
    
    public function getTabs(): array
    {
        return [
            'today' => Tab::make('Aujourd\'hui')
                ->icon('heroicon-o-sun')
                ->badge(CourierShift::whereDate('date', today())->count())
                ->modifyQueryUsing(fn (Builder $query) => $query->whereDate('date', today())),
                
            'in_progress' => Tab::make('En cours')
                ->icon('heroicon-o-play')
                ->badge(CourierShift::where('status', CourierShift::STATUS_IN_PROGRESS)->count())
                ->badgeColor('success')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', CourierShift::STATUS_IN_PROGRESS)),
                
            'confirmed' => Tab::make('Confirmés')
                ->icon('heroicon-o-check')
                ->badge(CourierShift::where('status', CourierShift::STATUS_CONFIRMED)->whereDate('date', '>=', today())->count())
                ->badgeColor('info')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', CourierShift::STATUS_CONFIRMED)),
                
            'no_shows' => Tab::make('No-shows')
                ->icon('heroicon-o-exclamation-triangle')
                ->badge(CourierShift::where('status', CourierShift::STATUS_NO_SHOW)->whereDate('date', today())->count())
                ->badgeColor('danger')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('status', CourierShift::STATUS_NO_SHOW)),
                
            'all' => Tab::make('Tous')
                ->icon('heroicon-o-squares-2x2'),
        ];
    }
    
    public function getDefaultActiveTab(): string
    {
        return 'today';
    }
}
