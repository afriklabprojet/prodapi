<?php

namespace App\Filament\Resources\PharmacyResource\Pages;

use App\Filament\Resources\PharmacyResource;
use Filament\Resources\Pages\CreateRecord;

class CreatePharmacy extends CreateRecord
{
    protected static string $resource = PharmacyResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
