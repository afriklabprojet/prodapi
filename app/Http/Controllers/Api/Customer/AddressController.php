<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\CustomerAddress;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AddressController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $addresses = CustomerAddress::where('user_id', $request->user()->id)
            ->orderByDesc('is_default')
            ->orderByDesc('updated_at')
            ->get();

        return response()->json([
            'success' => true,
            'status' => 'success',
            'data' => $addresses,
        ]);
    }

    public function getLabels(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'status' => 'success',
            'data' => ['Maison', 'Bureau', 'Famille', 'Autre'],
        ]);
    }

    public function getDefault(Request $request): JsonResponse
    {
        $address = CustomerAddress::where('user_id', $request->user()->id)
            ->where('is_default', true)
            ->first();

        return response()->json([
            'success' => true,
            'status' => 'success',
            'data' => $address,
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $address = CustomerAddress::where('user_id', $request->user()->id)
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'status' => 'success',
            'data' => $address,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'label' => ['required', 'string', 'max:50'],
            'address' => 'required|string|max:255',
            'city' => 'nullable|string|max:100',
            'district' => 'nullable|string|max:100',
            'phone' => 'nullable|string|max:20',
            'instructions' => 'nullable|string|max:500',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'is_default' => 'boolean',
        ]);

        $validated['user_id'] = $request->user()->id;
        $validated['label'] = ucfirst(mb_strtolower(trim($validated['label'])));

        $hasExistingAddresses = CustomerAddress::where('user_id', $request->user()->id)->exists();
        $validated['is_default'] = $validated['is_default'] ?? !$hasExistingAddresses;

        if (!empty($validated['is_default'])) {
            CustomerAddress::where('user_id', $request->user()->id)
                ->update(['is_default' => false]);
        }

        $address = CustomerAddress::create($validated);

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Adresse créée avec succès',
            'data' => $address,
        ], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $address = CustomerAddress::where('user_id', $request->user()->id)
            ->findOrFail($id);

        $validated = $request->validate([
            'label' => ['sometimes', 'string', 'max:50'],
            'address' => 'sometimes|string|max:255',
            'city' => 'nullable|string|max:100',
            'district' => 'nullable|string|max:100',
            'phone' => 'nullable|string|max:20',
            'instructions' => 'nullable|string|max:500',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'is_default' => 'boolean',
        ]);

        if (isset($validated['label'])) {
            $validated['label'] = ucfirst(mb_strtolower(trim($validated['label'])));
        }

        if (!empty($validated['is_default'])) {
            CustomerAddress::where('user_id', $request->user()->id)
                ->where('id', '!=', $id)
                ->update(['is_default' => false]);
        }

        $address->update($validated);

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Adresse mise à jour',
            'data' => $address->fresh(),
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $address = CustomerAddress::where('user_id', $request->user()->id)
            ->findOrFail($id);

        $address->delete();

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Adresse supprimée',
        ]);
    }

    public function setDefault(Request $request, int $id): JsonResponse
    {
        $address = CustomerAddress::where('user_id', $request->user()->id)
            ->findOrFail($id);

        CustomerAddress::where('user_id', $request->user()->id)
            ->update(['is_default' => false]);

        $address->update(['is_default' => true]);

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Adresse par défaut mise à jour',
            'data' => $address->fresh(),
        ]);
    }
}
