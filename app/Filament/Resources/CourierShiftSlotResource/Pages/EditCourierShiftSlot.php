<?php

namespace App\Filament\Resources\CourierShiftSlotResource\Pages;

use App\Filament\Resources\CourierShiftSlotResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditCourierShiftSlot extends EditRecord
{
    protected static string $resource = CourierShiftSlotResource::class;

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
