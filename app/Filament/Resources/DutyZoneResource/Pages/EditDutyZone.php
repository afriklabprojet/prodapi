<?php

namespace App\Filament\Resources\DutyZoneResource\Pages;

use App\Filament\Resources\DutyZoneResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditDutyZone extends EditRecord
{
    protected static string $resource = DutyZoneResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
