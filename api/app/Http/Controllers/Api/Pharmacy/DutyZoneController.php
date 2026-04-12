<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\DutyZone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

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
}
