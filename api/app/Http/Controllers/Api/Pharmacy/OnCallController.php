<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Pharmacy\StoreOnCallRequest;
use App\Http\Resources\OnCallResource;
use App\Models\PharmacyOnCall;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class OnCallController extends Controller
{
    private function getAuthenticatedUser(): User
    {
        $user = Auth::user();

        if (! $user instanceof User) {
            abort(401, 'Unauthenticated.');
        }

        return $user;
    }

    /**
     * List on-call shifts for the authenticated pharmacy.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $this->getAuthenticatedUser();
        
        // Assuming the user is linked to a pharmacy somehow. 
        // Based on PharmacyResource, there is a pharmacy_user table.
        // We need to find the pharmacy associated with this user.
        $pharmacy = $user->pharmacies()->first();

        if (!$pharmacy) {
            return response()->json([
                'status' => 'error',
                'message' => 'User is not associated with any pharmacy.'
            ], 403);
        }

        // Auto-expire periods whose end_at has passed but are still marked active.
        PharmacyOnCall::where('pharmacy_id', $pharmacy->id)
            ->where('is_active', true)
            ->where('end_at', '<', now())
            ->update(['is_active' => false]);

        $query = PharmacyOnCall::with('dutyZone')
            ->where('pharmacy_id', $pharmacy->id)
            ->orderBy('start_at', 'desc');

        if ($request->has('active_only')) {
            $query->where('is_active', true)
                  ->where('end_at', '>=', now());
        }

        $paginated = $query->paginate(20);

        return response()->json([
            'success' => true,
            'status' => 'success',
            'data' => $paginated->items(),
            'meta' => [
                'current_page' => $paginated->currentPage(),
                'last_page' => $paginated->lastPage(),
                'per_page' => $paginated->perPage(),
                'total' => $paginated->total(),
            ],
        ]);
    }

    /**
     * Déclarer une période de garde (Garde).
     */
    public function store(StoreOnCallRequest $request): JsonResponse
    {
        $user = $this->getAuthenticatedUser();
        $pharmacy = $user->pharmacies()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'êtes pas associé à une pharmacie.',
            ], 403);
        }

        if (!$pharmacy->duty_zone_id) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Veuillez configurer une zone de garde avant de programmer une garde.',
            ], 422);
        }

        $startAt = Carbon::parse($request->start_at);
        $endAt   = Carbon::parse($request->end_at);

        // Vérification supplémentaire : fin > début
        if (!$endAt->isAfter($startAt)) {
            return response()->json([
                'success' => false,
                'message' => 'La date de fin doit être après la date de début.',
            ], 422);
        }

        // Auto-expire stale periods before checking for overlaps.
        PharmacyOnCall::where('pharmacy_id', $pharmacy->id)
            ->where('is_active', true)
            ->where('end_at', '<', now())
            ->update(['is_active' => false]);

        // Vérification des chevauchements de gardes (only against active, non-expired periods).
        $overlap = PharmacyOnCall::where('pharmacy_id', $pharmacy->id)
            ->where('is_active', true)
            ->where('end_at', '>', now())
            ->where(function ($query) use ($startAt, $endAt) {
                $query->where('start_at', '<', $endAt)
                      ->where('end_at', '>', $startAt);
            })
            ->exists();

        if ($overlap) {
            return response()->json([
                'success' => false,
                'message' => 'Une période de garde existe déjà sur cet intervalle. Veuillez choisir d\'autres dates.',
            ], 422);
        }

        $onCall = PharmacyOnCall::create([
            'pharmacy_id'  => $pharmacy->id,
            'duty_zone_id' => $pharmacy->duty_zone_id,
            'start_at'     => $startAt,
            'end_at'       => $endAt,
            'type'         => $request->type,
            'is_active'    => true,
        ]);

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Garde programmée avec succès.',
            'data'    => new OnCallResource($onCall),
        ], 201);
    }

    /**
     * Update an on-call shift.
     */
    public function update(Request $request, $id): JsonResponse
    {
        $user = $this->getAuthenticatedUser();
        $pharmacy = $user->pharmacies()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'User is not associated with any pharmacy.'
            ], 403);
        }

        $onCall = PharmacyOnCall::where('pharmacy_id', $pharmacy->id)->findOrFail($id);

        $validated = $request->validate([
            'duty_zone_id' => 'exists:duty_zones,id',
            'start_at' => 'date',
            'end_at' => 'date|after:start_at',
            'type' => [Rule::in(['night', 'weekend', 'holiday', 'emergency'])],
            'is_active' => 'boolean',
        ]);

        $onCall->update($validated);

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'On-call shift updated successfully.',
            'data' => $onCall
        ]);
    }

    /**
     * Delete (cancel) an on-call shift.
     */
    public function destroy($id): JsonResponse
    {
        $user = $this->getAuthenticatedUser();
        $pharmacy = $user->pharmacies()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'User is not associated with any pharmacy.'
            ], 403);
        }

        $onCall = PharmacyOnCall::where('pharmacy_id', $pharmacy->id)->findOrFail($id);
        $onCall->delete();

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'On-call shift cancelled successfully.'
        ]);
    }
}
