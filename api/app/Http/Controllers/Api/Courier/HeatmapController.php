<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Services\HeatmapService;
use Illuminate\Http\Request;

class HeatmapController extends Controller
{
    public function __construct(
        private HeatmapService $heatmapService
    ) {}

    /**
     * Opportunites de zones chaudes pour le livreur connecte
     *
     * GET /api/courier/heatmap/opportunities
     */
    public function opportunities(Request $request)
    {
        $request->validate([
            'max_distance_km' => 'nullable|numeric|min:1|max:30',
        ]);

        $courier = $request->user()?->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouve',
            ], 403);
        }

        if (!$courier->latitude || !$courier->longitude) {
            return response()->json([
                'success' => true,
                'data' => [
                    'courier_id' => $courier->id,
                    'opportunities' => [],
                    'best_action' => 'Activez la localisation pour voir les zones chaudes',
                    'generated_at' => now()->toIso8601String(),
                ],
                'message' => 'Position GPS indisponible',
            ]);
        }

        $maxDistanceKm = (float) $request->query('max_distance_km', 15);
        $data = $this->heatmapService->getCourierOpportunities($courier, $maxDistanceKm);

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }
}
