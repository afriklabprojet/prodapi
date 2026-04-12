<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class SocialAuthController extends Controller
{
    /**
     * Authenticate or register a user via Google Sign-In (Firebase).
     *
     * Flow:
     *  1. Client signs in with Google via google_sign_in package.
     *  2. Client signs in to Firebase Auth with the Google credential.
     *  3. Client sends the Firebase ID token to this endpoint.
     *  4. We verify the token server-side using the Firebase Admin SDK.
     *  5. We find or create the user, then return a Sanctum token.
     *
     * POST /auth/social-google
     * Body: { firebase_id_token: string, device_name?: string }
     */
    public function loginWithGoogle(Request $request)
    {
        $request->validate([
            'firebase_id_token' => 'required|string',
            'device_name'       => 'sometimes|string|max:100',
        ]);

        $idToken    = $request->firebase_id_token;
        $deviceName = $request->input('device_name', 'mobile');

        // ── 1. Verify Firebase ID token server-side ────────────────────────
        try {
            $firebaseAuth  = app('firebase.auth');
            $verifiedToken = $firebaseAuth->verifyIdToken($idToken);
        } catch (\Exception $e) {
            Log::warning('[SocialAuth] Firebase token verification failed', [
                'error' => $e->getMessage(),
            ]);
            return response()->json([
                'message' => 'Vérification du token Google échouée. Réessayez.',
            ], 403);
        }

        $claims      = $verifiedToken->claims();
        $firebaseUid = $claims->get('sub');
        $email       = $claims->get('email');
        $name        = $claims->get('name') ?? $claims->get('display_name');
        $photoUrl    = $claims->get('picture');

        // Google always provides a verified email
        if (empty($email)) {
            return response()->json([
                'message' => 'Impossible de récupérer l\'adresse email depuis Google.',
            ], 422);
        }

        // ── 2. Find or create the user ─────────────────────────────────────
        $user = User::where('email', strtolower($email))
            ->orWhere('firebase_uid', $firebaseUid)
            ->first();

        if ($user) {
            // Update Firebase UID if missing
            if (!$user->firebase_uid) {
                $user->firebase_uid = $firebaseUid;
            }
            // Mark phone as verified (Google auth is trusted)
            if (!$user->phone_verified_at) {
                $user->phone_verified_at = now();
            }
            $user->save();
        } else {
            // New user — create with Google data
            $user = User::create([
                'name'              => $name ?? explode('@', $email)[0],
                'email'             => strtolower($email),
                'phone'             => '+225' . Str::random(9), // placeholder, user can update
                'password'          => bcrypt(Str::random(32)), // random, social users don't use password
                'firebase_uid'      => $firebaseUid,
                'avatar'            => $photoUrl,
                'email_verified_at' => now(),
                'phone_verified_at' => now(), // Google is a trusted provider
                'role'              => 'customer',
            ]);
        }

        // ── 3. Issue Sanctum token ─────────────────────────────────────────
        $token = $user->createToken($deviceName)->plainTextToken;

        return response()->json([
            'message' => 'Connexion Google réussie',
            'user'    => $user,
            'token'   => $token,
        ]);
    }
}
