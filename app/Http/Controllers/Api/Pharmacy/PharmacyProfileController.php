<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class PharmacyProfileController extends Controller
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
     * Get the pharmacy profile(s) for the logged in user.
     */
    public function index()
    {
        $user = $this->getAuthenticatedUser();
        return response()->json([
            'success' => true,
            'data' => $user->pharmacies,
        ]);
    }

    /**
     * Update the pharmacy profile.
     */
    public function update(Request $request, $id)
    {
        $user = $this->getAuthenticatedUser();
        
        // Ensure the user owns this pharmacy
        $pharmacy = $user->pharmacies()->where('pharmacies.id', $id)->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Pharmacy not found or access denied.',
            ], 403); // Forbidden
        }

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'phone' => 'sometimes|required|string|max:20',
            'email' => 'nullable|email|max:255',
            'address' => 'sometimes|required|string|max:255',
            'city' => 'sometimes|required|string|max:100',
            'duty_zone_id' => 'nullable|exists:duty_zones,id',
            'license_number' => 'nullable|string|max:100',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            // SÉCURITÉ: Validation MIME type stricte + taille max
            'license_document' => 'nullable|file|mimetypes:application/pdf,image/jpeg,image/png|max:5120',
            'id_card_document' => 'nullable|file|mimetypes:application/pdf,image/jpeg,image/png|max:5120',
        ]);

        // SÉCURITÉ: Documents sensibles stockés en PRIVÉ (pas accessible publiquement)
        // Handle License Document Upload
        if ($request->hasFile('license_document')) {
            // Delete old file if exists
            if ($pharmacy->license_document && Storage::disk('private')->exists($pharmacy->license_document)) {
                Storage::disk('private')->delete($pharmacy->license_document);
            }
            
            // Stocker en privé avec nom aléatoire pour éviter l'énumération
            $validated['license_document'] = $request->file('license_document')
                ->store('pharmacy-documents/licenses', 'private');
        }

        // Handle ID Card (CNI) Document Upload
        if ($request->hasFile('id_card_document')) {
            // Delete old file if exists
            if ($pharmacy->id_card_document && Storage::disk('private')->exists($pharmacy->id_card_document)) {
                Storage::disk('private')->delete($pharmacy->id_card_document);
            }
            
            // Stocker en privé avec nom aléatoire
            $validated['id_card_document'] = $request->file('id_card_document')
                ->store('pharmacy-documents/id-cards', 'private');
        }

        $pharmacy->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Pharmacy profile updated successfully.',
            'data' => $pharmacy,
        ]);
    }

    /**
     * Télécharger un document sécurisé (license ou CNI)
     * SÉCURITÉ: Seuls les propriétaires de la pharmacie peuvent télécharger
     */
    public function downloadDocument(Request $request, $id, $type)
    {
        $user = $this->getAuthenticatedUser();
        
        // Vérifier propriétaire ou admin
        $pharmacy = $user->pharmacies()->where('pharmacies.id', $id)->first();
        
        if (!$pharmacy && !$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Access denied.',
            ], 403);
        }

        if (!$pharmacy) {
            $pharmacy = Pharmacy::find($id);
        }

        $documentPath = match($type) {
            'license' => $pharmacy->license_document,
            'id_card' => $pharmacy->id_card_document,
            default => null,
        };

        if (!$documentPath || !Storage::disk('private')->exists($documentPath)) {
            return response()->json([
                'success' => false,
                'message' => 'Document not found.',
            ], 404);
        }

        return response()->download(
            Storage::disk('private')->path($documentPath),
            basename($documentPath)
        );
    }
}
