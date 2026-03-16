<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\Pharmacy;
use Illuminate\Http\Request;

class PharmacyController extends Controller
{
    /**
     * Get nearby pharmacies based on GPS coordinates
     * Inclut les pharmacies avec coordonnées (triées par distance)
     * puis les pharmacies sans coordonnées (triées par nom) en fallback
     */
    public function nearby(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'radius' => 'nullable|numeric|min:1|max:100',
        ]);

        $latitude = $request->latitude;
        $longitude = $request->longitude;
        $radius = $request->radius ?? 25; // Default 25km

        $mapPharmacy = function ($pharmacy, $latitude, $longitude) {
            $isOnDuty = $pharmacy->onCalls()
                ->where('start_at', '<=', now())
                ->where('end_at', '>=', now())
                ->where('is_active', true)
                ->exists();
            
            $currentOnCall = $isOnDuty ? $pharmacy->onCalls()
                ->where('start_at', '<=', now())
                ->where('end_at', '>=', now())
                ->where('is_active', true)
                ->first() : null;

            // Calcul distance en PHP si les coordonnées existent
            $distance = null;
            if ($pharmacy->latitude && $pharmacy->longitude) {
                $distance = $pharmacy->distance ?? $this->haversineDistance(
                    (float) $latitude, (float) $longitude,
                    (float) $pharmacy->latitude, (float) $pharmacy->longitude
                );
            }

            return [
                'id' => $pharmacy->id,
                'name' => $pharmacy->name,
                'phone' => $pharmacy->phone,
                'email' => $pharmacy->email,
                'address' => $pharmacy->address,
                'city' => $pharmacy->city,
                'latitude' => $pharmacy->latitude ? (float) $pharmacy->latitude : null,
                'longitude' => $pharmacy->longitude ? (float) $pharmacy->longitude : null,
                'distance' => $distance ? round($distance, 2) : null,
                'status' => $pharmacy->status,
                'is_open' => $pharmacy->is_open ?? true,
                'is_on_duty' => $isOnDuty,
                'duty_info' => $currentOnCall ? [
                    'type' => $currentOnCall->type,
                    'end_at' => ($currentOnCall && $currentOnCall->end_at) ? $currentOnCall->end_at->toIso8601String() : null,
                ] : null,
            ];
        };

        // 1) Pharmacies AVEC coordonnées GPS dans le rayon (triées par distance)
        $geoPharmacies = Pharmacy::approved()
            ->nearLocation($latitude, $longitude, $radius)
            ->get()
            ->map(fn($p) => $mapPharmacy($p, $latitude, $longitude));

        // 2) IDs déjà inclus
        $geoIds = $geoPharmacies->pluck('id')->toArray();

        // 3) Pharmacies SANS coordonnées GPS (fallback, triées par nom)
        $noGpsPharmacies = Pharmacy::approved()
            ->whereNotIn('id', $geoIds)
            ->where(function ($q) {
                $q->whereNull('latitude')->orWhereNull('longitude');
            })
            ->orderBy('name')
            ->get()
            ->map(fn($p) => $mapPharmacy($p, $latitude, $longitude));

        // Combiner: d'abord les plus proches, puis celles sans GPS
        $allPharmacies = $geoPharmacies->values()->merge($noGpsPharmacies->values());

        return response()->json([
            'success' => true,
            'data' => $allPharmacies->values(),
            'meta' => [
                'count' => $allPharmacies->count(),
                'nearby_count' => $geoPharmacies->count(),
                'radius_km' => $radius,
            ],
        ]);
    }

    /**
     * Calcul de distance Haversine en PHP (fallback)
     */
    private function haversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371; // km
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $earthRadius * $c;
    }

    /**
     * Get all approved pharmacies
     */
    public function index()
    {
        $pharmacies = Pharmacy::approved()
            ->with(['onCalls' => fn($q) => $q->where('start_at', '<=', now())->where('end_at', '>=', now())->where('is_active', true)])
            ->orderBy('name')
            ->get()
            ->map(function ($pharmacy) {
                // Use eager-loaded onCalls (no N+1)
                $currentOnCall = $pharmacy->onCalls->first();
                $isOnDuty = $currentOnCall !== null;

                return [
                    'id' => $pharmacy->id,
                    'name' => $pharmacy->name,
                    'phone' => $pharmacy->phone,
                    'email' => $pharmacy->email,
                    'address' => $pharmacy->address,
                    'city' => $pharmacy->city,
                    'latitude' => $pharmacy->latitude ? (float) $pharmacy->latitude : null,
                    'longitude' => $pharmacy->longitude ? (float) $pharmacy->longitude : null,
                    'status' => $pharmacy->status,
                    'is_open' => $pharmacy->is_open ?? true, // Default to open if not specified
                    'is_on_duty' => $isOnDuty,
                    'duty_info' => $currentOnCall ? [
                        'type' => $currentOnCall->type,
                        'end_at' => ($currentOnCall && $currentOnCall->end_at) ? $currentOnCall->end_at->toIso8601String() : null,
                    ] : null,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $pharmacies,
        ]);
    }

    /**
     * Get pharmacy details
     */
    public function show($id)
    {
        $pharmacy = Pharmacy::approved()->findOrFail($id);
        
        // Single query for on-duty info
        $currentOnCall = $pharmacy->onCalls()
            ->where('start_at', '<=', now())
            ->where('end_at', '>=', now())
            ->where('is_active', true)
            ->first();
        $isOnDuty = $currentOnCall !== null;

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $pharmacy->id,
                'name' => $pharmacy->name,
                'phone' => $pharmacy->phone,
                'email' => $pharmacy->email,
                'address' => $pharmacy->address,
                'city' => $pharmacy->city,
                'region' => $pharmacy->region,
                'latitude' => $pharmacy->latitude ? (float) $pharmacy->latitude : null,
                'longitude' => $pharmacy->longitude ? (float) $pharmacy->longitude : null,
                'license_number' => $pharmacy->license_number,
                'owner_name' => $pharmacy->owner_name,
                'status' => $pharmacy->status,
                'is_open' => $pharmacy->is_open ?? true,
                'is_on_duty' => $isOnDuty,
                'duty_info' => $currentOnCall ? [
                    'type' => $currentOnCall->type,
                    'end_at' => $currentOnCall->end_at?->toIso8601String(),
                ] : null,
            ],
        ]);
    }

    /**
     * Get pharmacies currently on duty (Garde)
     */
    public function onDuty(Request $request)
    {
        $request->validate([
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'radius' => 'nullable|numeric|min:1|max:50',
        ]);

        // Récupérer TOUTES les pharmacies de garde avec eager loading
        $allOnDutyPharmacies = Pharmacy::approved()->onDuty()
            ->with(['onCalls' => fn($q) => $q->where('start_at', '<=', now())->where('end_at', '>=', now())->where('is_active', true)])
            ->get();

        // Si des coordonnées sont fournies, calculer la distance pour celles qui ont des coords
        $hasLocation = $request->has('latitude') && $request->has('longitude');
        $latitude = $hasLocation ? (float) $request->latitude : null;
        $longitude = $hasLocation ? (float) $request->longitude : null;
        $radius = $hasLocation ? ($request->radius ?? 20) : null;

        $pharmacies = $allOnDutyPharmacies->map(function ($pharmacy) use ($hasLocation, $latitude, $longitude) {
            $currentOnCall = $pharmacy->onCalls->first();

            // Calculer la distance si coordonnées disponibles des deux côtés
            $distance = null;
            if ($hasLocation && $pharmacy->latitude && $pharmacy->longitude) {
                $distance = $this->calculateHaversineDistance(
                    $latitude, $longitude,
                    (float) $pharmacy->latitude, (float) $pharmacy->longitude
                );
            }

            return [
                'id' => $pharmacy->id,
                'name' => $pharmacy->name,
                'phone' => $pharmacy->phone,
                'email' => $pharmacy->email,
                'address' => $pharmacy->address,
                'city' => $pharmacy->city,
                'latitude' => $pharmacy->latitude ? (float) $pharmacy->latitude : null,
                'longitude' => $pharmacy->longitude ? (float) $pharmacy->longitude : null,
                'distance' => $distance,
                'status' => $pharmacy->status,
                'is_open' => true, // On-duty pharmacies are always considered open
                'is_on_duty' => true,
                'duty_info' => $currentOnCall ? [
                     'type' => $currentOnCall->type,
                     'end_at' => $currentOnCall->end_at?->toIso8601String(),
                ] : null,
            ];
        })
        // Trier: pharmacies avec distance d'abord (par proximité), puis celles sans
        ->sortBy(fn($p) => $p['distance'] ?? 99999)
        ->values();

        return response()->json([
            'success' => true,
            'data' => $pharmacies,
        ]);
    }

    /**
     * Get featured pharmacies
     * Falls back to recently active pharmacies if no featured ones exist
     */
    public function featured()
    {
        // First try to get featured pharmacies
        $pharmacies = Pharmacy::approved()
            ->featured()
            ->orderBy('name')
            ->limit(10)
            ->get();

        // Fallback: if no featured pharmacies, get recently active or any approved pharmacies
        if ($pharmacies->isEmpty()) {
            $pharmacies = Pharmacy::approved()
                ->where('is_open', true)
                ->orderByDesc('updated_at')
                ->limit(10)
                ->get();
        }

        // Second fallback: if still empty, get any approved pharmacies
        if ($pharmacies->isEmpty()) {
            $pharmacies = Pharmacy::approved()
                ->orderByDesc('created_at')
                ->limit(10)
                ->get();
        }

        // Eager load onCalls for all fetched pharmacies to avoid N+1
        $pharmacies->load(['onCalls' => fn($q) => $q->where('start_at', '<=', now())->where('end_at', '>=', now())->where('is_active', true)]);

        $pharmacies = $pharmacies->map(function ($pharmacy) {
                // Use eager-loaded onCalls (no N+1)
                $currentOnCall = $pharmacy->onCalls->first();
                $isOnDuty = $currentOnCall !== null;

                return [
                    'id' => $pharmacy->id,
                    'name' => $pharmacy->name,
                    'phone' => $pharmacy->phone,
                    'email' => $pharmacy->email,
                    'address' => $pharmacy->address,
                    'city' => $pharmacy->city,
                    'latitude' => $pharmacy->latitude ? (float) $pharmacy->latitude : null,
                    'longitude' => $pharmacy->longitude ? (float) $pharmacy->longitude : null,
                    'status' => $pharmacy->status,
                    'is_open' => $pharmacy->is_open ?? true,
                    'is_on_duty' => $isOnDuty,
                    'is_featured' => true,
                    'duty_info' => $currentOnCall ? [
                        'type' => $currentOnCall->type,
                        'end_at' => $currentOnCall->end_at?->toIso8601String(),
                    ] : null,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $pharmacies,
        ]);
    }

    /**
     * Alias de haversineDistance() pour éviter la duplication
     */
    private function calculateHaversineDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        return round($this->haversineDistance($lat1, $lng1, $lat2, $lng2), 2);
    }
}
