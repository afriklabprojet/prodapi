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
            'pharmacy' => $this->whenLoaded('pharmacy', function () {
                return [
                    'id'        => (int) $this->pharmacy->id,
                    'name'      => (string) ($this->pharmacy->name ?? ''),
                    'address'   => $this->pharmacy->address,
                    'latitude'  => $this->pharmacy->latitude !== null ? (float) $this->pharmacy->latitude : null,
                    'longitude' => $this->pharmacy->longitude !== null ? (float) $this->pharmacy->longitude : null,
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

            // OCR Analysis fields
            'analysis_status'        => $this->analysis_status,
            'analysis_error'         => $this->analysis_error,
            'analyzed_at'            => $this->analyzed_at?->toIso8601String() ?? $this->analyzed_at,
            'ocr_confidence'         => $this->ocr_confidence !== null ? (float) $this->ocr_confidence : null,
            'ocr_raw_text'           => $this->ocr_raw_text,
            'extracted_medications'  => $this->extracted_medications,
            'matched_products'       => $this->matched_products,
            'unmatched_medications'  => $this->unmatched_medications,

            // Dispensing / anti-reuse fields
            'fulfillment_status'    => $this->fulfillment_status ?? 'none',
            'dispensing_count'      => (int) ($this->dispensing_count ?? 0),
            'first_dispensed_at'    => $this->first_dispensed_at?->toIso8601String(),
            'image_hash'            => $this->image_hash,
            'dispensings'           => $this->whenLoaded('dispensings', function () {
                return $this->dispensings->map(function ($d) {
                    return [
                        'id' => $d->id,
                        'medication_name' => $d->medication_name,
                        'product_id' => $d->product_id,
                        'quantity_prescribed' => (int) $d->quantity_prescribed,
                        'quantity_dispensed' => (int) $d->quantity_dispensed,
                        'dispensed_at' => $d->dispensed_at?->toIso8601String(),
                        'dispensed_by' => $d->dispensedBy?->name ?? 'Inconnu',
                        'pharmacy_id' => (int) $d->pharmacy_id,
                    ];
                });
            }),
        ];
    }
}
