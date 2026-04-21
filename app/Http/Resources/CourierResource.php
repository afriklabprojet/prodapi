<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * CourierResource
 *
 * Sérialise un modèle Courier (avec son User parent) vers un format JSON
 * stable et propre pour l'API.
 *
 * Pré-requis : la relation `user` doit être eager-loadée.
 * Optionnel : passer des extras via ->additional(['extras' => [...]])
 *             pour les compteurs calculés (deliveries, earnings, badges, ...).
 *
 * @property-read \App\Models\Courier $resource
 */
class CourierResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $courier = $this->resource;
        $user    = $courier->relationLoaded('user') ? $courier->user : null;

        return [
            'id'                   => $courier->id,
            'user_id'              => $courier->user_id,
            'name'                 => $user?->name,
            'email'                => $user?->email,
            'phone'                => $user?->phone ?? $courier->phone,
            'avatar'               => $user?->avatar,

            // Statut & véhicule
            'status'               => $courier->status,
            'vehicle_type'         => $courier->vehicle_type,
            'plate_number'         => $courier->plate_number, // accessor → vehicle_number
            'license_number'       => $courier->license_number,

            // Localisation
            'latitude'             => $courier->latitude,
            'longitude'            => $courier->longitude,
            'last_location_update' => $courier->last_location_update,

            // KYC
            'kyc_status'           => $courier->kyc_status ?? 'pending_review',
            'kyc_verified_at'      => $courier->kyc_verified_at,

            // Performance
            'rating'               => $courier->rating,
            'completed_deliveries' => $courier->completed_deliveries,
            'acceptance_rate'      => $courier->acceptance_rate,
            'completion_rate'      => $courier->completion_rate,
            'on_time_rate'         => $courier->on_time_rate,
            'reliability_score'    => $courier->reliability_score,

            // Gamification
            'tier'                 => $courier->tier,
            'total_xp'             => $courier->total_xp,
            'current_streak_days'  => $courier->current_streak_days,
        ];
    }
}
