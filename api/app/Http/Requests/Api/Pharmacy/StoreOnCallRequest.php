<?php

namespace App\Http\Requests\Api\Pharmacy;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class StoreOnCallRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'start_at' => ['required', 'date', 'after:now'],
            'end_at'   => ['required', 'date', 'after:start_at'],
            'type'     => ['required', 'in:night,weekend,holiday,emergency'],
        ];
    }

    public function messages(): array
    {
        return [
            'start_at.required' => 'La date de début est obligatoire.',
            'start_at.date'     => 'La date de début n\'est pas valide.',
            'start_at.after'    => 'La date de début doit être dans le futur.',
            'end_at.required'   => 'La date de fin est obligatoire.',
            'end_at.date'       => 'La date de fin n\'est pas valide.',
            'end_at.after'      => 'La date de fin doit être après la date de début.',
            'type.required'     => 'Le type de garde est obligatoire.',
            'type.in'           => 'Le type de garde sélectionné n\'est pas valide. Valeurs: night, weekend, holiday, emergency.',
        ];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(
            response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 422)
        );
    }
}
