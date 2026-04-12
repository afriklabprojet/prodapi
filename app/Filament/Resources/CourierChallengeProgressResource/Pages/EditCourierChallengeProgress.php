<?php

namespace App\Filament\Resources\CourierChallengeProgressResource\Pages;

use App\Filament\Resources\CourierChallengeProgressResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditCourierChallengeProgress extends EditRecord
{
    protected static string $resource = CourierChallengeProgressResource::class;

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
