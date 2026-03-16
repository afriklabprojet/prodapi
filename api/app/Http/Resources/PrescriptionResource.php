<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PrescriptionResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'             => (int) $this->id,
            'status'         => (string) ($this->status ?? 'pending'),
            'source'         => (string) ($this->source ?? 'upload'),
            'notes'          => $this->notes,
            // The 'images' attribute is automatically transformed by the Model Accessor to absolute URLs
            'images'         => $this->images,
            'quote_amount'   => $this->quote_amount !== null ? (float) $this->quote_amount : null,
            'pharmacy_notes' => $this->pharmacy_notes,
            'admin_notes'    => $this->when($request->user()->id === $this->validated_by || $request->user()->role === 'admin' || $request->user()->role === 'pharmacy', $this->admin_notes),
            'customer_id'    => (int) $this->customer_id,
            'created_at'     => $this->created_at?->toIso8601String(),
            'validated_at'   => $this->validated_at?->toIso8601String(),
            'validated_by'   => $this->validated_by !== null ? (int) $this->validated_by : null,
            'order' => $this->whenLoaded('order', function () {
                return [
                    'id'        => (int) $this->order->id,
                    'reference' => (string) $this->order->reference,
                    'status'    => (string) $this->order->status,
                ];
            }),
            'customer' => $this->whenLoaded('customer', function () {
                return [
                    'id'    => (int) $this->customer->id,
                    'name'  => (string) ($this->customer->name ?? ''),
                    'email' => (string) ($this->customer->email ?? ''),
                    'phone' => $this->customer->phone,
                ];
            }),
        ];
    }
}
