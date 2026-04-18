<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;

/**
 * Service de génération de custom tokens Firebase.
 * 
 * Permet aux apps mobiles de s'authentifier auprès de Firebase
 * (Firestore, FCM, etc.) via un custom token signé côté serveur.
 */
class FirebaseTokenService
{
    protected FirebaseAuth $auth;

    public function __construct(FirebaseAuth $auth)
    {
        $this->auth = $auth;
    }

    /**
     * Générer un custom token Firebase pour un utilisateur.
     * 
     * Le UID Firebase sera "user_{id}" pour éviter les collisions.
     * Les custom claims incluent le rôle pour les security rules Firestore.
     *
     * @param int $userId
     * @param string $role (customer, courier, pharmacy)
     * @param array $additionalClaims Claims supplémentaires
     * @return string|null Le custom token ou null en cas d'erreur
     */
    public function generateCustomToken(int $userId, string $role, array $additionalClaims = []): ?string
    {
        try {
            $uid = "user_{$userId}";
            
            $claims = array_merge([
                'role' => $role,
                'user_id' => $userId,
            ], $additionalClaims);

            $customToken = $this->auth->createCustomToken($uid, $claims);

            Log::debug('Firebase custom token generated', [
                'uid' => $uid,
                'role' => $role,
            ]);

            return $customToken->toString();
        } catch (\Exception $e) {
            Log::error('Firebase custom token generation failed', [
                'user_id' => $userId,
                'error' => $e->getMessage(),
            ]);

            return null;
        }
    }
}
