<?php

namespace App\Filament\Resources\JekoPaymentResource\Pages;

use App\Filament\Resources\JekoPaymentResource;
use Filament\Resources\Pages\ListRecords;

class ListJekoPayments extends ListRecords
{
    protected static string $resource = JekoPaymentResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}
