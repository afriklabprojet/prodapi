<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\BusinessEventService;
use App\Services\FirebaseTokenService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class LoginController extends Controller
{
    /**
     * Login user and create token
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required', // Allow email or phone
            'password' => 'required',
            'device_name' => 'string',
            'role' => 'nullable|string|in:customer,courier,pharmacy', // Rôle attendu par l'application
        ]);

        // Normaliser l'email en minuscules pour éviter les problèmes de case sensitivity
        $login = trim($request->email);
        
        // Check if login is email or phone
        $fieldType = filter_var($login, FILTER_VALIDATE_EMAIL) ? 'email' : 'phone';

        // Si c'est un email, le convertir en minuscules
        if ($fieldType === 'email') {
            $login = strtolower($login);
        } else {
            // Supprimer tous les espaces du numéro de téléphone
            $login = preg_replace('/\s+/', '', $login);
        }

        $user = null;
        if ($fieldType === 'phone') {
             // Normaliser le numéro pour la recherche (suppression stricte espaces/tirets)
             $normalizedPhone = preg_replace('/[\s\-]+/', '', $login);
             
             // Nettoyer le 0 initial s'il existe pour format international
             $phoneWithoutZero = ltrim(ltrim($normalizedPhone, '+'), '0');
             
             // Liste des formats possibles à chercher
             $candidates = [
                 $normalizedPhone,                          // 0706070809
                 '+' . ltrim($normalizedPhone, '+'),        // +0706070809
                 ltrim($normalizedPhone, '+'),              // 0706070809 (sans + si présent)
                 '+225' . $normalizedPhone,                 // +2250706070809
                 '+225' . $phoneWithoutZero,                // +225706070809
                 '225' . $phoneWithoutZero,                 // 225706070809
             ];

             // Recherche robuste ignorant les espaces dans la base de données
             // Note: REPLACE() est supporté par SQLite, MySQL et Postgres
             $user = User::where(function($query) use ($candidates) {
                 foreach ($candidates as $candidate) {
                     $query->orWhereRaw("REPLACE(phone, ' ', '') = ?", [$candidate]);
                 }
                 // Fallback pour compatibilité exacte
                 $query->orWhereIn('phone', $candidates);
             })->first();
        } else {
             $user = User::where('email', $login)->first();
        }

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Les identifiants fournis sont incorrects.',
                'error_code' => 'INVALID_CREDENTIALS',
                'details' => 'Vérifiez votre email et votre mot de passe, puis réessayez.'
            ], 401);
        }

        // Vérifier que le rôle de l'utilisateur correspond à l'application
        $expectedRole = $request->role;
        if ($expectedRole) {
            if ($expectedRole === 'courier' && $user->role !== 'courier') {
                throw ValidationException::withMessages([
                    'email' => ['Ce compte n\'est pas un compte livreur. Veuillez utiliser l\'application client.'],
                ]);
            }
            if ($expectedRole === 'pharmacy' && $user->role !== 'pharmacy') {
                throw ValidationException::withMessages([
                    'email' => ['Ce compte n\'est pas un compte pharmacie. Veuillez utiliser l\'application appropriée.'],
                ]);
            }
            if ($expectedRole === 'customer' && $user->role !== 'customer') {
                throw ValidationException::withMessages([
                    'email' => ['Ce compte n\'est pas un compte client. Veuillez utiliser l\'application appropriée.'],
                ]);
            }
        }

        // Vérifier le statut d'approbation pour les coursiers
        if ($user->role === 'courier') {
            $courier = $user->courier;
            if ($courier) {
                // KYC incomplet - permettre connexion mais signaler le besoin de resoumettre
                if ($courier->kyc_status === 'incomplete') {
                    // On laisse passer avec un flag, l'app affichera l'écran de resoumission
                }
                // pending_approval et rejected : on laisse se connecter
                // L'app gère l'affichage des écrans appropriés (KYC → Pending → Dashboard)
                // via le middleware EnsureCourierProfile sur les routes protégées.
                if ($courier->status === 'suspended') {
                    throw ValidationException::withMessages([
                        'email' => ['Votre compte a été suspendu. Veuillez contacter le support.'],
                    ]);
                }
            }
        }

        // Vérifier le statut d'approbation pour les pharmacies
        if ($user->role === 'pharmacy') {
            $pharmacy = $user->pharmacies()->first();
            if ($pharmacy && $pharmacy->status === 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Votre pharmacie est en attente d\'approbation par l\'administrateur.',
                    'error_code' => 'PHARMACY_PENDING_APPROVAL',
                    'details' => 'Votre demande a été reçue et est en cours d\'examen. Vous serez notifié par email une fois approuvé. Délai habituel : 24-48h.'
                ], 403);
            }
            if ($pharmacy && $pharmacy->status === 'suspended') {
                return response()->json([
                    'success' => false,
                    'message' => 'Votre pharmacie a été suspendue.',
                    'error_code' => 'PHARMACY_SUSPENDED',
                    'details' => 'Veuillez contacter le support pour plus d\'informations.'
                ], 403);
            }
            if ($pharmacy && $pharmacy->status === 'rejected') {
                return response()->json([
                    'success' => false,
                    'message' => 'Votre demande d\'inscription a été refusée.',
                    'error_code' => 'PHARMACY_REJECTED',
                    'details' => 'Veuillez contacter le support pour connaître les raisons du refus.'
                ], 403);
            }
        }

        // Enforce max 2 simultaneous devices
        $maxDevices = 2;
        $activeTokens = $user->tokens()->orderBy('last_used_at', 'desc')->orderBy('created_at', 'desc')->get();
        if ($activeTokens->count() >= $maxDevices) {
            // Remove oldest tokens beyond the limit (keep the most recent one, new one will be #2)
            $tokensToDelete = $activeTokens->slice($maxDevices - 1);
            foreach ($tokensToDelete as $oldToken) {
                $oldToken->delete();
            }
        }

        // Create token
        $token = $user->createToken($request->device_name ?? 'mobile-app')->plainTextToken;

        // Prepare user data
        $userData = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'role' => $user->role,
            'avatar' => $user->avatar,
            'phone_verified_at' => $user->phone_verified_at,
            'email_verified_at' => $user->email_verified_at,
        ];

        if ($user->role === 'pharmacy') {
            $userData['pharmacies'] = $user->pharmacies;
        }
        
        // Ajouter le statut du coursier dans la réponse
        if ($user->role === 'courier' && $user->courier) {
            $userData['courier_status'] = $user->courier->status;
            $userData['kyc_status'] = $user->courier->kyc_status;
            $userData['kyc_rejection_reason'] = $user->courier->kyc_rejection_reason;
        }

        // Générer un custom token Firebase pour l'authentification Firestore
        $firebaseToken = null;
        try {
            $firebaseTokenService = app(FirebaseTokenService::class);
            $firebaseToken = $firebaseTokenService->generateCustomToken(
                $user->id,
                $user->role,
                $user->role === 'courier' && $user->courier
                    ? ['courier_id' => $user->courier->id]
                    : []
            );
        } catch (\Exception $e) {
            // Firebase token generation is optional - don't block login
            \Illuminate\Support\Facades\Log::warning('Firebase token generation failed during login', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
        }

        // Track login event
        BusinessEventService::login($user->id, $user->role, [
            'device' => $request->device_name ?? 'unknown',
            'login_method' => $fieldType,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Connexion réussie',
            'data' => [
                'user' => $userData,
                'token' => $token,
                'firebase_token' => $firebaseToken,
            ],
        ]);
    }

    /**
     * Logout user (revoke token)
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Déconnexion réussie',
        ]);
    }

    /**
     * Refresh Firebase custom token for the authenticated user.
     * Used by mobile apps when Firebase auth session is missing/expired.
     */
    public function refreshFirebaseToken(Request $request)
    {
        $user = $request->user();

        try {
            $firebaseTokenService = app(FirebaseTokenService::class);
            $firebaseToken = $firebaseTokenService->generateCustomToken(
                $user->id,
                $user->role,
                $user->role === 'courier' && $user->courier
                    ? ['courier_id' => $user->courier->id]
                    : []
            );

            return response()->json([
                'success' => true,
                'firebase_token' => $firebaseToken,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de générer le token Firebase',
            ], 500);
        }
    }

    /**
     * Get authenticated user
     */
    public function me(Request $request)
    {
        $user = $request->user();
        $data = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'role' => $user->role,
            'avatar' => $user->avatar,
            'phone_verified_at' => $user->phone_verified_at,
            'email_verified_at' => $user->email_verified_at,
            'created_at' => $user->created_at,
        ];

        if ($user->role === 'customer') {
            // Include default address for customers
            $defaultAddress = $user->defaultAddress;
            $data['default_address'] = $defaultAddress ? $defaultAddress->address : null;
            $data['default_address_id'] = $defaultAddress?->id;
            $data['addresses_count'] = $user->addresses()->count();
            // Order statistics
            $orders = $user->orders()->whereNotIn('status', ['cancelled', 'refunded']);
            $data['total_orders'] = $orders->count();
            $data['completed_orders'] = (clone $orders)->where('status', 'delivered')->count();
            $data['total_spent'] = (clone $orders)->where('payment_status', 'paid')->sum('total_amount');
        } elseif ($user->role === 'pharmacy') {
            $data['pharmacies'] = $user->pharmacies;
            // Wallet est sur le modèle Pharmacy, pas User
            $firstPharmacy = $user->pharmacies->first();
            $data['wallet'] = $firstPharmacy?->wallet; 
        } elseif ($user->role === 'courier') {
            $data['courier'] = $user->courier;
            $data['wallet'] = $user->courier?->wallet;
        }

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    /**
     * Update authenticated user profile
     */
    public function updateProfile(Request $request)
    {
        $request->validate([
            'name' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:20|unique:users,phone,' . $request->user()->id,
        ]);

        $user = $request->user();
        
        $data = [];
        if ($request->has('name') && $request->name) {
            $data['name'] = $request->name;
        }
        if ($request->has('phone') && $request->phone) {
            // Si le téléphone change, invalider la vérification
            if ($user->phone !== $request->phone) {
                $data['phone'] = $request->phone;
                $data['phone_verified_at'] = null;
            }
        }
        
        if (empty($data)) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune donnée à mettre à jour',
            ], 400);
        }
        
        $user->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Profil mis à jour avec succès',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role,
                'avatar' => $user->avatar,
                'phone_verified_at' => $user->phone_verified_at,
            ],
        ]);
    }

    /**
     * Upload user avatar
     */
    public function uploadAvatar(Request $request)
    {
        $request->validate([
            'avatar' => 'required|image|mimes:jpeg,png,jpg,webp|max:2048',
        ]);

        $user = $request->user();

        // Delete old avatar if exists
        if ($user->avatar) {
            $oldPath = str_replace('/storage/', '', $user->avatar);
            Storage::disk('public')->delete($oldPath);
        }

        // Store new avatar
        $path = $request->file('avatar')->store('avatars', 'public');
        $user->update(['avatar' => '/storage/' . $path]);

        return response()->json([
            'success' => true,
            'message' => 'Avatar mis à jour avec succès',
            'data' => [
                'avatar_url' => $user->avatar,
            ],
        ]);
    }

    /**
     * Delete user avatar
     */
    public function deleteAvatar(Request $request)
    {
        $user = $request->user();

        if ($user->avatar) {
            $path = str_replace('/storage/', '', $user->avatar);
            Storage::disk('public')->delete($path);
            $user->update(['avatar' => null]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Avatar supprimé avec succès',
        ]);
    }

    /**
     * List active sessions (tokens) for the authenticated user.
     */
    public function sessions(Request $request): \Illuminate\Http\JsonResponse
    {
        $user = $request->user();
        $currentTokenId = $user->currentAccessToken()->id;

        $sessions = $user->tokens()
            ->orderBy('last_used_at', 'desc')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($token) use ($currentTokenId) {
                return [
                    'id' => $token->id,
                    'name' => $token->name,
                    'is_current' => $token->id === $currentTokenId,
                    'last_used_at' => $token->last_used_at?->toIso8601String(),
                    'created_at' => $token->created_at?->toIso8601String(),
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'sessions' => $sessions,
                'max_devices' => 2,
            ],
        ]);
    }

    /**
     * Revoke all other sessions except the current one.
     */
    public function revokeOtherSessions(Request $request): \Illuminate\Http\JsonResponse
    {
        $user = $request->user();
        $currentTokenId = $user->currentAccessToken()->id;

        $deleted = $user->tokens()->where('id', '!=', $currentTokenId)->delete();

        return response()->json([
            'success' => true,
            'message' => "$deleted autre(s) session(s) déconnectée(s)",
            'data' => ['revoked_count' => $deleted],
        ]);
    }
}

