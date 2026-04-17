<?php

namespace App\Filament\Resources\CourierShiftSlotResource\Pages;

use App\Filament\Resources\CourierShiftSlotResource;
use Filament\Resources\Pages\CreateRecord;

class CreateCourierShiftSlot extends CreateRecord
{
    protected static string $resource = CourierShiftSlotResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
