<?php

namespace App\Filament\Resources\BonusMultiplierResource\Pages;

use App\Filament\Resources\BonusMultiplierResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditBonusMultiplier extends EditRecord
{
    protected static string $resource = BonusMultiplierResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
