<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OnCallResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'           => $this->id,
            'pharmacy_id'  => $this->pharmacy_id,
            'duty_zone_id' => $this->duty_zone_id,
            'start_at'     => $this->start_at?->format('Y-m-d H:i:s'),
            'end_at'       => $this->end_at?->format('Y-m-d H:i:s'),
            'type'         => $this->type,
            'is_active'    => (bool) $this->is_active,
            'created_at'   => $this->created_at?->format('Y-m-d H:i:s'),
        ];
    }
}
