<?php

namespace App\Filament\Resources\BonusMultiplierResource\Pages;

use App\Filament\Resources\BonusMultiplierResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListBonusMultipliers extends ListRecords
{
    protected static string $resource = BonusMultiplierResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
