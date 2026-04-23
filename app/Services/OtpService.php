<?php

namespace App\Services;

use App\Mail\OtpMail;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class OtpService
{
    /**
     * Generate an OTP for a given identifier (email or phone)
     */
    public function generateOtp(string $identifier, int $length = 6, int $validityMinutes = 10): string
    {
        // In production, generate random number. For dev/demo, use '1234' or similar if needed, 
        // but let's stick to random for "complete backend".
        $otp = (string) random_int(pow(10, $length - 1), pow(10, $length) - 1);
        
        // Store in cache
        Cache::put('otp_' . $identifier, $otp, now()->addMinutes($validityMinutes));
        
        return $otp;
    }

    /**
     * Verify the OTP for a given identifier (and remove it)
     *
     * SECURITY: Uses hash_equals() for constant-time comparison to prevent
     * timing attacks that could be used to brute-force OTP values.
     */
    public function verifyOtp(string $identifier, string $otp): bool
    {
        $cachedOtp = Cache::get('otp_' . $identifier);

        if (is_string($cachedOtp) && hash_equals($cachedOtp, $otp)) {
            // OTP is valid, remove it to prevent reuse
            Cache::forget('otp_' . $identifier);
            return true;
        }

        return false;
    }

    /**
     * Check if OTP is valid without removing it
     *
     * SECURITY: Uses hash_equals() for constant-time comparison.
     */
    public function checkOtp(string $identifier, string $otp): bool
    {
        $cachedOtp = Cache::get('otp_' . $identifier);
        return is_string($cachedOtp) && hash_equals($cachedOtp, $otp);
    }

    /**
     * Check if Firebase Auth service account is functional.
     * Cached for 5 minutes to avoid checking on every OTP request.
     */
    protected function isFirebaseAvailable(): bool
    {
        return Cache::remember('firebase_auth_available', now()->addMinutes(5), function () {
            try {
                $auth = app('firebase.auth');
                // Quick check: try to list 1 user (lightweight call)
                iterator_to_array($auth->listUsers(1));
                Log::info('Firebase Auth: service account is functional');
                return true;
            } catch (\Throwable $e) {
                Log::warning('Firebase Auth unavailable: ' . $e->getMessage());
                return false;
            }
        });
    }

    /**
     * Send the OTP via appropriate channel
     * Priority: Firebase Phone Auth (client) > Infobip SMS > Email
     *
     * Flow:
     * 1. Check if Firebase service account works → return 'firebase' (app uses client SDK)
     * 2. If Firebase is down OR force_fallback → send via Infobip SMS
     * 3. If SMS fails → send via Email
     *
     * Returns the channel used: 'firebase', 'sms', 'email', 'sms_fallback_email'
     */
    public function sendOtp(string $identifier, string $otp, string $purpose = 'verification', ?string $fallbackEmail = null, bool $forceFallback = false): string
    {
        // Determine if identifier is email or phone
        if (filter_var($identifier, FILTER_VALIDATE_EMAIL)) {
            $this->sendEmailOtp($identifier, $otp, $purpose);
            return 'email';
        }

        // For phone numbers: Firebase first, then Infobip SMS, then Email

        // 1. Firebase Phone Auth — only if service account works AND client didn't request fallback
        if (!$forceFallback && $this->isFirebaseAvailable()) {
            Log::info("OTP channel: firebase (client-side) for {$identifier}");
            return 'firebase';
        }

        // 2. Firebase unavailable or client requested fallback → Infobip SMS
        $reason = $forceFallback ? 'client fallback' : 'Firebase unavailable';
        Log::info("OTP sending via Infobip SMS for {$identifier} (reason: {$reason})");

        $smsSent = $this->sendSmsOtp($identifier, $otp, $purpose);
        if ($smsSent) {
            return 'sms';
        }

        // 3. Infobip SMS failed → fallback email
        Log::warning("Infobip SMS failed for {$identifier}, trying email fallback");
        if ($fallbackEmail) {
            $emailSent = $this->sendEmailOtp($fallbackEmail, $otp, $purpose);
            if ($emailSent) {
                return 'sms_fallback_email';
            }
        }

        // All channels failed
        Log::error("All OTP channels failed for {$identifier}");
        return 'failed';
    }

    /**
     * Send OTP via WhatsApp using Infobip template
     * Uses the 'otp_verification' template (authentication category)
     */
    protected function sendWhatsAppOtp(string $phone, string $otp, string $purpose = 'verification'): bool
    {
        try {
            $whatsappService = app(WhatsAppService::class);
            
            if (!$whatsappService->isConfigured()) {
                Log::info("WhatsApp OTP not configured, skipping", ['phone' => $phone]);
                return false;
            }

            // Send OTP via WhatsApp template (authentication templates)
            $result = $whatsappService->sendTemplate(
                $phone,
                'otp_verification',
                config('whatsapp.default_language', 'fr'),
                [$otp], // Placeholder {1} = code OTP
            );

            if ($result) {
                Log::info("OTP WhatsApp sent successfully to {$phone}");
                return true;
            }

            Log::warning("WhatsApp OTP service returned false for {$phone}");
            return false;
        } catch (\Exception $e) {
            Log::error("Failed to send OTP WhatsApp to {$phone}: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Send OTP via email using Resend
     */
    protected function sendEmailOtp(string $email, string $otp, string $purpose = 'verification'): bool
    {
        try {
            Mail::to($email)->queue(new OtpMail($otp, $purpose));
            Log::info("OTP email sent successfully to {$email}");
            return true;
        } catch (\Exception $e) {
            Log::error("Failed to send OTP email to {$email}: " . $e->getMessage());
            // Log OTP only in local environment for debugging
            if (app()->environment('local', 'testing')) {
                Log::info("OTP for {$email}: {$otp}");
            }
            return false;
        }
    }

    /**
     * Send OTP via SMS
     * Returns true if SMS sent successfully, false otherwise
     */
    protected function sendSmsOtp(string $phone, string $otp, string $purpose = 'verification'): bool
    {
        $message = $this->getSmsMessage($otp, $purpose);
        
        try {
            // Utiliser le SmsChannel existant via notification ou direct
            $smsService = app(SmsService::class);
            $result = $smsService->send($phone, $message);
            
            // Vérifier si l'envoi a réussi
            if ($result) {
                Log::info("OTP SMS sent successfully to {$phone}");
                return true;
            }
            
            Log::warning("SMS service returned false for {$phone}");
            return false;
        } catch (\Exception $e) {
            Log::error("Failed to send OTP SMS to {$phone}: " . $e->getMessage());
            // Log OTP only in local environment for debugging
            if (app()->environment('local', 'testing')) {
                Log::info("OTP for {$phone}: {$otp}");
            }
            return false;
        }
    }

    /**
     * Get SMS message based on purpose
     */
    protected function getSmsMessage(string $otp, string $purpose): string
    {
        return match($purpose) {
            'verification' => "DR-PHARMA: Votre code de vérification est {$otp}. Valide 10 min.",
            'password_reset' => "DR-PHARMA: Code de réinitialisation: {$otp}. Valide 10 min.",
            'login' => "DR-PHARMA: Votre code de connexion est {$otp}. Valide 10 min.",
            default => "DR-PHARMA: Votre code est {$otp}. Valide 10 min.",
        };
    }
}
