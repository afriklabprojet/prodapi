<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class PasswordResetController extends Controller
{
    protected $otpService;

    public function __construct(OtpService $otpService)
    {
        $this->otpService = $otpService;
    }

    /**
     * Request Password Reset (Forgot Password)
     */
    public function forgotPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            // Return success even if user not found to prevent enumeration
            return response()->json(['message' => 'Si un compte existe avec cet email, un code a été envoyé.']);
        }

        $otp = $this->otpService->generateOtp($user->email, length: 6);
        $this->otpService->sendOtp($user->email, $otp);

        return response()->json(['message' => 'Code de réinitialisation envoyé']);
    }

    /**
     * Verify Reset OTP (Optional step if UI separates verification from reset)
     */
    public function verifyResetOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
        ]);

        if ($this->otpService->checkOtp($request->email, $request->otp)) {
            return response()->json(['message' => 'Code valide']);
        }

        return response()->json(['message' => 'Code invalide'], 400);
    }

    /**
     * Reset Password
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        // Verify OTP
        // Note: If verifyResetOtp was called before, the OTP is gone from cache.
        // We need to handle this. 
        // Option A: Don't use verifyResetOtp, just do it all here.
        // Option B: verifyResetOtp returns a signed token.
        
        // Let's go with Option A for now as it's stateless and simple.
        // But if the UI has a separate screen for OTP, the user enters OTP, clicks "Verify", then sees "New Password" screen.
        // If "Verify" consumes the OTP, the "New Password" screen call will fail.
        
        // I'll modify OtpService to have a `checkOtp` method that doesn't delete, or just rely on the final step.
        // For now, let's assume the user enters OTP and Password on the same screen or the OTP is passed along.
        
        if (!$this->otpService->verifyOtp($request->email, $request->otp)) {
             return response()->json(['message' => 'Code invalide ou expiré'], 400);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['message' => 'Utilisateur non trouvé'], 404);
        }

        $user->forceFill([
            'password' => Hash::make($request->password),
        ])->save();

        return response()->json(['message' => 'Mot de passe réinitialisé avec succès']);
    }

    /**
     * Update Password (for authenticated users)
     */
    public function updatePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password' => ['required', 'confirmed', Password::defaults()],
        ]);

        $user = $request->user();

        // Verify current password
        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'message' => 'Le mot de passe actuel est incorrect',
                'errors' => ['current_password' => ['Le mot de passe actuel est incorrect']]
            ], 422);
        }

        // Check new password is different from current
        if (Hash::check($request->new_password, $user->password)) {
            return response()->json([
                'message' => 'Le nouveau mot de passe doit être différent de l\'ancien',
                'errors' => ['new_password' => ['Le nouveau mot de passe doit être différent de l\'ancien']]
            ], 422);
        }

        $user->forceFill([
            'password' => Hash::make($request->new_password),
            'must_change_password' => false,
        ])->save();

        return response()->json(['message' => 'Mot de passe modifié avec succès']);
    }
}
