<?php

namespace App\Filament\Resources\CourierShiftSlotResource\Pages;

use App\Filament\Resources\CourierShiftSlotResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListCourierShiftSlots extends ListRecords
{
    protected static string $resource = CourierShiftSlotResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
