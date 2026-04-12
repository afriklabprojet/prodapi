<?php

namespace App\Filament\Resources\CourierShiftResource\Pages;

use App\Filament\Resources\CourierShiftResource;
use Filament\Actions;
use Filament\Resources\Pages\CreateRecord;

class CreateCourierShift extends CreateRecord
{
    protected static string $resource = CourierShiftResource::class;
    
    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
