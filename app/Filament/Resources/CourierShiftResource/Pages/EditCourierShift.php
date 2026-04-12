<?php

namespace App\Filament\Resources\CourierShiftResource\Pages;

use App\Filament\Resources\CourierShiftResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditCourierShift extends EditRecord
{
    protected static string $resource = CourierShiftResource::class;

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
