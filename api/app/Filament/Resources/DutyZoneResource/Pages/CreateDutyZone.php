<?php

namespace App\Filament\Resources\DutyZoneResource\Pages;

use App\Filament\Resources\DutyZoneResource;
use Filament\Resources\Pages\CreateRecord;

class CreateDutyZone extends CreateRecord
{
    protected static string $resource = DutyZoneResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
