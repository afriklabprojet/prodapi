<?php

namespace App\Filament\Resources\DeliveryOfferResource\Pages;

use App\Filament\Resources\DeliveryOfferResource;
use Filament\Actions;
use Filament\Resources\Pages\ViewRecord;

class ViewDeliveryOffer extends ViewRecord
{
    protected static string $resource = DeliveryOfferResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\Action::make('cancel')
                ->label('Annuler l\'offre')
                ->icon('heroicon-o-x-mark')
                ->color('danger')
                ->requiresConfirmation()
                ->modalHeading('Annuler cette offre ?')
                ->modalDescription('Cette action est irréversible. L\'offre sera marquée comme annulée.')
                ->visible(fn () => $this->record->status === \App\Models\DeliveryOffer::STATUS_PENDING)
                ->action(function () {
                    $this->record->update(['status' => \App\Models\DeliveryOffer::STATUS_CANCELLED]);
                    $this->redirect(DeliveryOfferResource::getUrl('index'));
                }),
        ];
    }
}
