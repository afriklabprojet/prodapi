<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Models\CourierShift;
use App\Models\CourierShiftSlot;
use App\Services\ShiftManagementService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ShiftController extends Controller
{
    public function __construct(
        private ShiftManagementService $shiftService
    ) {}

    /**
     * Liste les créneaux disponibles
     * 
     * GET /api/courier/shifts/slots
     */
    public function availableSlots(Request $request)
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $zoneId = $request->query('zone_id', 'default');
        $slots = $this->shiftService->getAvailableSlots($zoneId);

        return response()->json([
            'success' => true,
            'data' => $slots->map(function ($daySlots, $date) {
                return [
                    'date' => $date,
                    'slots' => $daySlots->map(fn($slot) => [
                        'id' => $slot->id,
                        'shift_type' => $slot->shift_type,
                        'shift_label' => ucfirst($slot->shift_type),
                        'start_time' => $slot->start_time->format('H:i'),
                        'end_time' => $slot->end_time->format('H:i'),
                        'capacity' => $slot->capacity,
                        'booked_count' => $slot->booked_count,
                        'spots_remaining' => $slot->spots_remaining,
                        'bonus_amount' => $slot->bonus_amount,
                        'status' => $slot->status,
                    ]),
                ];
            })->values(),
        ]);
    }

    /**
     * Réserver un shift
     * 
     * POST /api/courier/shifts/book
     */
    public function book(Request $request)
    {
        $request->validate([
            'slot_id' => 'required|exists:courier_shift_slots,id',
        ]);

        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $slot = CourierShiftSlot::findOrFail($request->slot_id);
        $result = $this->shiftService->bookShift($courier, $slot);

        if (!$result['success']) {
            return response()->json($result, 400);
        }

        Log::info("Shift: Courier {$courier->id} booked slot {$slot->id}");

        return response()->json([
            'success' => true,
            'message' => $result['message'],
            'data' => [
                'shift_id' => $result['shift']->id,
                'date' => $result['shift']->date->format('Y-m-d'),
                'start_time' => $result['shift']->start_time->format('H:i'),
                'end_time' => $result['shift']->end_time->format('H:i'),
                'guaranteed_bonus' => $result['shift']->guaranteed_bonus,
            ],
        ]);
    }

    /**
     * Liste mes shifts
     * 
     * GET /api/courier/shifts
     */
    public function index(Request $request)
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $shifts = $this->shiftService->getCourierShifts($courier);

        return response()->json([
            'success' => true,
            'data' => $shifts->map(fn($shift) => [
                'id' => $shift->id,
                'date' => $shift->date->format('Y-m-d'),
                'start_time' => $shift->start_time->format('H:i'),
                'end_time' => $shift->end_time->format('H:i'),
                'zone_id' => $shift->zone_id,
                'status' => $shift->status,
                'guaranteed_bonus' => $shift->guaranteed_bonus,
                'deliveries_completed' => $shift->deliveries_completed,
                'violations_count' => $shift->violations_count,
                'calculated_bonus' => $shift->calculated_bonus,
            ]),
        ]);
    }

    /**
     * Annuler un shift
     * 
     * POST /api/courier/shifts/{id}/cancel
     */
    public function cancel(Request $request, $id)
    {
        $request->validate([
            'reason' => 'nullable|string|max:200',
        ]);

        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $shift = CourierShift::forCourier($courier->id)->findOrFail($id);
        $result = $this->shiftService->cancelShift($shift, $request->reason);

        if (!$result['success']) {
            return response()->json($result, 400);
        }

        return response()->json($result);
    }

    /**
     * Démarrer un shift
     * 
     * POST /api/courier/shifts/{id}/start
     */
    public function start(Request $request, $id)
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $shift = CourierShift::forCourier($courier->id)->findOrFail($id);
        $result = $this->shiftService->startShift($shift);

        if (!$result['success']) {
            return response()->json($result, 400);
        }

        return response()->json([
            'success' => true,
            'message' => $result['message'],
            'data' => [
                'shift_id' => $shift->id,
                'status' => $shift->fresh()->status,
            ],
        ]);
    }

    /**
     * Terminer un shift
     * 
     * POST /api/courier/shifts/{id}/end
     */
    public function end(Request $request, $id)
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $shift = CourierShift::forCourier($courier->id)->findOrFail($id);
        $result = $this->shiftService->endShift($shift);

        if (!$result['success']) {
            return response()->json($result, 400);
        }

        return response()->json([
            'success' => true,
            'message' => $result['message'],
            'data' => [
                'shift_id' => $shift->id,
                'deliveries_completed' => $result['shift']->deliveries_completed,
                'earned_bonus' => $result['earned_bonus'],
            ],
        ]);
    }

    /**
     * Obtenir mon shift actif
     * 
     * GET /api/courier/shifts/active
     */
    public function active(Request $request)
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $shift = $this->shiftService->getActiveShift($courier);

        if (!$shift) {
            return response()->json([
                'success' => true,
                'data' => null,
                'message' => 'Aucun shift actif',
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $shift->id,
                'date' => $shift->date->format('Y-m-d'),
                'start_time' => $shift->start_time->format('H:i'),
                'end_time' => $shift->end_time->format('H:i'),
                'status' => $shift->status,
                'started_at' => $shift->started_at?->toIso8601String(),
                'deliveries_completed' => $shift->deliveries_completed,
                'violations_count' => $shift->violations_count,
                'guaranteed_bonus' => $shift->guaranteed_bonus,
                'remaining_minutes' => $shift->end_time->diffInMinutes(now()),
            ],
        ]);
    }
}
