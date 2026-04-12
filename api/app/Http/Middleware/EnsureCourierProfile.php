<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureCourierProfile
{
    /**
     * Vérifier que l'utilisateur authentifié a un profil coursier actif.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Non authentifié',
                'error_code' => 'UNAUTHENTICATED',
            ], 401);
        }

        if (!$user->isCourier()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès réservé aux livreurs',
                'error_code' => 'FORBIDDEN_COURIER',
            ], 403);
        }

        $courier = $user->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur introuvable. Veuillez compléter votre inscription.',
                'error_code' => 'COURIER_PROFILE_MISSING',
            ], 403);
        }

        // Vérifier le statut KYC EN PREMIER — le livreur doit soumettre ses docs avant tout
        $kycStatus = $courier->kyc_status ?? null;
        if ($kycStatus === 'incomplete') {
            return response()->json([
                'success' => false,
                'message' => $courier->kyc_rejection_reason ?? 'Veuillez soumettre vos documents KYC.',
                'error_code' => 'INCOMPLETE_KYC',
            ], 403);
        }

        // Vérifier le statut du coursier (après KYC pour le bon parcours)
        $status = $courier->status ?? null;
        if ($status === 'pending_approval') {
            return response()->json([
                'success' => false,
                'message' => 'Votre compte est en attente d\'approbation par l\'administrateur.',
                'error_code' => 'PENDING_APPROVAL',
            ], 403);
        }

        if ($status === 'suspended') {
            return response()->json([
                'success' => false,
                'message' => 'Votre compte a été suspendu. Veuillez contacter le support.',
                'error_code' => 'SUSPENDED',
            ], 403);
        }

        if ($status === 'rejected') {
            return response()->json([
                'success' => false,
                'message' => 'Votre demande d\'inscription a été refusée.',
                'error_code' => 'REJECTED',
            ], 403);
        }

        return $next($request);
    }
}
