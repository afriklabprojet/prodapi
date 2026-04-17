<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\DutyZone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class DutyZoneController extends Controller
{
    public function index(): JsonResponse
    {
        $zones = DutyZone::where('is_active', true)
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $zones,
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $zone = DutyZone::with(['pharmacies' => function ($q) {
            $q->where('is_active', true)->select('id', 'name', 'duty_zone_id', 'latitude', 'longitude');
        }])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $zone,
        ]);
    }

    /**
     * La pharmacie authentifiée crée sa propre zone personnalisée
     * et se l'auto-assigne. Si une zone du même nom existe déjà
     * pour cette ville, on la réutilise plutôt que de dupliquer.
     */
    public function storeForPharmacy(Request $request): JsonResponse
    {
        $user = Auth::user();
        $pharmacy = $user?->pharmacies()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune pharmacie associée à ce compte.',
            ], 403);
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'city' => ['required', 'string', 'max:120'],
            'description' => ['nullable', 'string', 'max:500'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'radius' => ['nullable', 'numeric', 'min:0.5', 'max:50'],
        ]);

        // Fallback sur la position de la pharmacie si non fournie
        $lat = $data['latitude'] ?? $pharmacy->latitude;
        $lng = $data['longitude'] ?? $pharmacy->longitude;
        $radius = $data['radius'] ?? 5.0;

        $zone = DB::transaction(function () use ($data, $lat, $lng, $radius, $pharmacy) {
            $zone = DutyZone::firstOrCreate(
                ['name' => $data['name'], 'city' => $data['city']],
                [
                    'description' => $data['description'] ?? null,
                    'latitude' => $lat,
                    'longitude' => $lng,
                    'radius' => $radius,
                    'is_active' => true,
                ]
            );

            $pharmacy->duty_zone_id = $zone->id;
            $pharmacy->save();

            return $zone;
        });

        return response()->json([
            'success' => true,
            'message' => 'Zone de garde configurée avec succès.',
            'data' => $zone,
        ], 201);
    }
}

