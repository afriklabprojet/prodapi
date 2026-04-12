<?php

namespace App\Filament\Resources\DutyZoneResource\Pages;

use App\Filament\Resources\DutyZoneResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListDutyZones extends ListRecords
{
    protected static string $resource = DutyZoneResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
