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
    public function generateOtp(string $identifier, int $length = 4, int $validityMinutes = 10): string
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
     */
    public function verifyOtp(string $identifier, string $otp): bool
    {
        $cachedOtp = Cache::get('otp_' . $identifier);
        
        if ($cachedOtp && $cachedOtp === $otp) {
            // OTP is valid, remove it to prevent reuse
            Cache::forget('otp_' . $identifier);
            return true;
        }
        
        return false;
    }

    /**
     * Check if OTP is valid without removing it
     */
    public function checkOtp(string $identifier, string $otp): bool
    {
        $cachedOtp = Cache::get('otp_' . $identifier);
        return $cachedOtp && $cachedOtp === $otp;
    }

    /**
     * Send the OTP via appropriate channel
     * Priority: WhatsApp > SMS > Email
     * Returns the channel used: 'whatsapp', 'email', 'sms', 'sms_fallback_email', 'whatsapp_fallback_sms', 'whatsapp_fallback_email'
     */
    public function sendOtp(string $identifier, string $otp, string $purpose = 'verification', ?string $fallbackEmail = null): string
    {
        // Determine if identifier is email or phone
        if (filter_var($identifier, FILTER_VALIDATE_EMAIL)) {
            $this->sendEmailOtp($identifier, $otp, $purpose);
            return 'email';
        }

        // For phone numbers: try WhatsApp first, then SMS, then email fallback
        
        // 1. Try WhatsApp (if enabled for OTP)
        if (config('whatsapp.notifications.otp', false)) {
            $whatsappSent = $this->sendWhatsAppOtp($identifier, $otp, $purpose);
            if ($whatsappSent) {
                return 'whatsapp';
            }
            
            // WhatsApp failed, try SMS
            $smsSent = $this->sendSmsOtp($identifier, $otp, $purpose);
            if ($smsSent) {
                return 'whatsapp_fallback_sms';
            }
            
            // SMS also failed, try email
            if ($fallbackEmail) {
                $this->sendEmailOtp($fallbackEmail, $otp, $purpose);
                return 'whatsapp_fallback_email';
            }
            
            return 'whatsapp'; // Return whatsapp even if failed (logged)
        }

        // 2. Try SMS first (default behavior when WhatsApp OTP not enabled)
        $smsSent = $this->sendSmsOtp($identifier, $otp, $purpose);
        
        // If SMS failed and we have a fallback email, send via email
        if (!$smsSent && $fallbackEmail) {
            $this->sendEmailOtp($fallbackEmail, $otp, $purpose);
            return 'sms_fallback_email';
        }
        
        return 'sms';
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
            Mail::to($email)->send(new OtpMail($otp, $purpose));
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
