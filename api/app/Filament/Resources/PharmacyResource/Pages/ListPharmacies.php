<?php

namespace App\Filament\Resources\PharmacyResource\Pages;

use App\Filament\Resources\PharmacyResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListPharmacies extends ListRecords
{
    protected static string $resource = PharmacyResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
