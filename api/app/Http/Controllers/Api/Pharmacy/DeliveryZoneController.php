<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\DeliveryZone;
use App\Rules\ValidGeoJsonPolygon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * Gestion des zones de livraison pour les pharmacies
 * 
 * Permet aux pharmacies de définir leur périmètre de livraison
 * via un polygone sur Google Maps.
 */
class DeliveryZoneController extends Controller
{
    /**
     * Récupérer la zone de livraison d'une pharmacie
     */
    public function show(Request $request)
    {
        $pharmacy = $request->user()->pharmacies()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Pharmacie non trouvée',
            ], 403);
        }

        $zone = DeliveryZone::where('pharmacy_id', $pharmacy->id)->first();

        if (!$zone) {
            return response()->json([
                'success' => true,
                'data' => null,
                'message' => 'Aucune zone de livraison définie',
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $zone->id,
                'pharmacy_id' => $zone->pharmacy_id,
                'name' => $zone->name,
                'polygon' => $zone->polygon,
                'radius_km' => $zone->radius_km,
                'is_active' => $zone->is_active,
                'created_at' => $zone->created_at,
                'updated_at' => $zone->updated_at,
            ],
        ]);
    }

    /**
     * Créer ou mettre à jour la zone de livraison
     */
    public function store(Request $request)
    {
        $pharmacy = $request->user()->pharmacies()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Pharmacie non trouvée',
            ], 403);
        }

        $validated = $request->validate([
            'name' => 'nullable|string|max:100',
            'polygon' => ['required', 'array', 'min:3', new ValidGeoJsonPolygon(minPoints: 3, maxPoints: 500)],
            'polygon.*.lat' => 'required|numeric|between:-90,90',
            'polygon.*.lng' => 'required|numeric|between:-180,180',
            'radius_km' => 'nullable|numeric|min:0.5|max:50',
            'is_active' => 'nullable|boolean',
        ]);

        // Ensure polygon is closed (first point == last point)
        $polygon = ValidGeoJsonPolygon::ensureClosed($validated['polygon']);

        try {
            $zone = DeliveryZone::updateOrCreate(
                ['pharmacy_id' => $pharmacy->id],
                [
                    'name' => $validated['name'] ?? 'Zone de livraison',
                    'polygon' => $polygon,
                    'radius_km' => $validated['radius_km'] ?? null,
                    'is_active' => $validated['is_active'] ?? true,
                ]
            );

            Log::info('[DeliveryZone] Zone mise à jour', [
                'pharmacy_id' => $pharmacy->id,
                'zone_id' => $zone->id,
                'points_count' => count($validated['polygon']),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Zone de livraison enregistrée',
                'data' => [
                    'id' => $zone->id,
                    'points_count' => $zone->points_count,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('[DeliveryZone] Erreur sauvegarde', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la sauvegarde',
            ], 500);
        }
    }

    /**
     * Supprimer la zone de livraison
     */
    public function destroy(Request $request)
    {
        $pharmacy = $request->user()->pharmacies()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Pharmacie non trouvée',
            ], 403);
        }

        DeliveryZone::where('pharmacy_id', $pharmacy->id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Zone de livraison supprimée',
        ]);
    }
}
