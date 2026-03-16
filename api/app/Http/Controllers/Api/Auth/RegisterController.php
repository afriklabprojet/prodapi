<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\OtpService;
use App\Services\KycValidationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class RegisterController extends Controller
{
    protected $otpService;
    protected $kycService;

    public function __construct(OtpService $otpService, KycValidationService $kycService)
    {
        $this->otpService = $otpService;
        $this->kycService = $kycService;
    }

    /**
     * Register a new customer
     */
    public function register(Request $request)
    {
        // Supprimer les comptes non vérifiés avec le même email ou téléphone
        // pour permettre la réinscription si l'OTP n'a jamais été validé
        $this->deleteUnverifiedAccounts($request->email, $request->phone);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'phone' => 'required|string|max:20|unique:users',
            'password' => ['required', 'confirmed', Password::min(8)],
            'device_name' => 'string',
        ]);

        // Normaliser l'email en minuscules pour éviter les problèmes de case sensitivity
        $validated['email'] = strtolower(trim($validated['email']));

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'phone' => $validated['phone'],
            'password' => Hash::make($validated['password']),
            'role' => 'customer',
        ]);

        // Firebase gère l'OTP dans les apps mobiles - pas besoin d'envoyer via backend
        // L'envoi SMS/WhatsApp Infobip est réservé aux notifications (commandes, livraisons)
        $channel = 'firebase'; // OTP géré côté client via Firebase Phone Auth

        // Create token
        $token = $user->createToken($request->device_name ?? 'mobile-app')->plainTextToken;

        // Determine verification message
        $verificationMessage = match($channel) {
            'sms' => 'Un code de vérification a été envoyé par SMS.',
            'sms_fallback_email' => 'SMS indisponible, un code a été envoyé à votre email.',
            default => 'Un code de vérification vous a été envoyé.',
        };

        return response()->json([
            'success' => true,
            'message' => 'Inscription réussie. ' . $verificationMessage,
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'role' => $user->role,
                    'phone_verified_at' => $user->phone_verified_at,
                ],
                'token' => $token,
                'otp_channel' => $channel,
            ],
        ], 201);
    }

    /**
     * Register a new courier with KYC documents (recto/verso)
     */
    public function registerCourier(Request $request)
    {
        // Supprimer les comptes non vérifiés avec le même email ou téléphone
        $this->deleteUnverifiedAccounts($request->email, $request->phone);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'phone' => 'required|string|max:20|unique:users',
            'password' => ['required', 'confirmed', Password::min(8)],
            'vehicle_type' => 'required|in:motorcycle,car,bicycle',
            'vehicle_registration' => 'required|string|max:50',
            'license_number' => 'nullable|string|max:50',
            'device_name' => 'nullable|string',
            // KYC Documents - Recto/Verso
            'id_card_front_document' => 'required|file|mimetypes:image/jpeg,image/png,application/pdf|max:5120',
            'id_card_back_document' => 'required|file|mimetypes:image/jpeg,image/png,application/pdf|max:5120',
            'selfie_document' => 'required|file|mimetypes:image/jpeg,image/png|max:5120',
            'driving_license_front_document' => 'nullable|file|mimetypes:image/jpeg,image/png,application/pdf|max:5120',
            'driving_license_back_document' => 'nullable|file|mimetypes:image/jpeg,image/png,application/pdf|max:5120',
        ]);

        // Validation KYC via Google Vision (si activé)
        $kycValidation = $this->validateKycDocuments($request);
        if (!$kycValidation['valid']) {
            return response()->json([
                'success' => false,
                'message' => 'Les documents KYC ne sont pas valides.',
                'errors' => $kycValidation['errors'],
                'validation_details' => $kycValidation['details'] ?? null,
            ], 422);
        }

        DB::transaction(function () use ($request, $validated, &$response) {
            // Normaliser l'email en minuscules pour éviter les problèmes de case sensitivity
            $validated['email'] = strtolower(trim($validated['email']));

            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'],
                'password' => Hash::make($validated['password']),
                'role' => 'courier',
            ]);

            // Handle KYC document uploads - Recto/Verso
            $idCardFrontPath = null;
            $idCardBackPath = null;
            $selfiePath = null;
            $drivingLicenseFrontPath = null;
            $drivingLicenseBackPath = null;

            if ($request->hasFile('id_card_front_document')) {
                $idCardFrontPath = $request->file('id_card_front_document')
                    ->store("courier-documents/{$user->id}", 'private');
            }

            if ($request->hasFile('id_card_back_document')) {
                $idCardBackPath = $request->file('id_card_back_document')
                    ->store("courier-documents/{$user->id}", 'private');
            }

            if ($request->hasFile('selfie_document')) {
                $selfiePath = $request->file('selfie_document')
                    ->store("courier-documents/{$user->id}", 'private');
            }

            if ($request->hasFile('driving_license_front_document')) {
                $drivingLicenseFrontPath = $request->file('driving_license_front_document')
                    ->store("courier-documents/{$user->id}", 'private');
            }

            if ($request->hasFile('driving_license_back_document')) {
                $drivingLicenseBackPath = $request->file('driving_license_back_document')
                    ->store("courier-documents/{$user->id}", 'private');
            }

            // Create courier profile with KYC documents (recto/verso)
            $user->courier()->create([
                'name' => $user->name,
                'phone' => $user->phone,
                'vehicle_type' => $validated['vehicle_type'],
                'vehicle_number' => $validated['vehicle_registration'],
                'license_number' => $validated['license_number'] ?? null,
                'id_card_front_document' => $idCardFrontPath,
                'id_card_back_document' => $idCardBackPath,
                'selfie_document' => $selfiePath,
                'driving_license_front_document' => $drivingLicenseFrontPath,
                'driving_license_back_document' => $drivingLicenseBackPath,
                'status' => 'pending_approval',
                'kyc_status' => ($idCardFrontPath && $idCardBackPath && $selfiePath) ? 'pending_review' : 'incomplete',
            ]);

            // Firebase gère l'OTP dans les apps mobiles - pas besoin d'envoyer via backend
            // L'envoi SMS Infobip est réservé aux notifications (commandes, livraisons, etc.)

            // Générer un token pour permettre la vérification du téléphone
            $deviceName = $request->input('device_name', 'courier_app');
            $token = $user->createToken($deviceName)->plainTextToken;

            $response = response()->json([
                'success' => true,
                'message' => 'Inscription livreur réussie. Votre compte est en attente d\'approbation par l\'administrateur. Vous recevrez une notification une fois approuvé.',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => $user->name,
                        'email' => $user->email,
                        'phone' => $user->phone,
                        'role' => $user->role,
                        'status' => 'pending_approval',
                    ],
                    'requires_approval' => true,
                    'token' => $token,
                ],
            ], 201);
        });

        return $response;
    }

    /**
     * Register a new pharmacy
     */
    public function registerPharmacy(Request $request)
    {
        // Supprimer les comptes non vérifiés avec le même email ou téléphone
        $this->deleteUnverifiedAccounts($request->email, $request->phone);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'phone' => 'required|string|max:20|unique:users',
            'password' => ['required', 'confirmed', Password::min(8)],
            'pharmacy_name' => 'required|string|max:255',
            'pharmacy_license' => 'required|string|max:50',
            'pharmacy_email' => 'nullable|string|email|max:255', // Email spécifique pour la pharmacie
            'pharmacy_phone' => 'nullable|string|max:20', // Téléphone spécifique pour la pharmacie
            'pharmacy_address' => 'required|string',
            'city' => 'required|string',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'device_name' => 'string',
        ]);

        // Déterminer l'email et téléphone de la pharmacie
        $pharmacyEmail = strtolower(trim($validated['pharmacy_email'] ?? $validated['email']));
        $pharmacyPhone = $validated['pharmacy_phone'] ?? $validated['phone'];

        // Vérifier l'unicité dans la table pharmacies
        $existingPharmacy = \App\Models\Pharmacy::where('email', $pharmacyEmail)
            ->orWhere('phone', $pharmacyPhone)
            ->first();

        if ($existingPharmacy) {
            $conflicts = [];
            if ($existingPharmacy->email === $pharmacyEmail) {
                $conflicts['pharmacy_email'] = ['Cet email est déjà utilisé par une autre pharmacie.'];
            }
            if ($existingPharmacy->phone === $pharmacyPhone) {
                $conflicts['pharmacy_phone'] = ['Ce téléphone est déjà utilisé par une autre pharmacie.'];
            }
            return response()->json([
                'success' => false,
                'message' => 'Une pharmacie existe déjà avec cet email ou téléphone.',
                'errors' => $conflicts,
            ], 422);
        }

        return DB::transaction(function () use ($request, $validated, $pharmacyEmail, $pharmacyPhone) {
            // Normaliser l'email en minuscules pour éviter les problèmes de case sensitivity
            $validated['email'] = strtolower(trim($validated['email']));

            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'],
                'password' => Hash::make($validated['password']),
                'role' => 'pharmacy',
            ]);

            // Create pharmacy avec email/phone potentiellement différents
            $pharmacy = \App\Models\Pharmacy::create([
                'name' => $validated['pharmacy_name'],
                'phone' => $pharmacyPhone,
                'email' => $pharmacyEmail,
                'address' => $validated['pharmacy_address'],
                'city' => $validated['city'],
                'license_number' => $validated['pharmacy_license'],
                'owner_name' => $validated['name'],
                'latitude' => $validated['latitude'],
                'longitude' => $validated['longitude'],
                'status' => 'pending',
            ]);

            // Attach user to pharmacy
            $pharmacy->users()->attach($user->id, ['role' => 'owner']);

            // Send OTP with email fallback
            $otp = $this->otpService->generateOtp($user->phone);
            $channel = $this->otpService->sendOtp($user->phone, $otp, 'verification', $user->email);

            $token = $user->createToken($request->device_name ?? 'mobile-app')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Inscription pharmacie réussie. Veuillez vérifier votre compte. En attente d\'approbation.',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => $user->name,
                        'email' => $user->email,
                        'phone' => $user->phone,
                        'role' => $user->role,
                        'pharmacies' => [
                            [
                                'id' => $pharmacy->id,
                                'name' => $pharmacy->name,
                                'address' => $pharmacy->address,
                                'city' => $pharmacy->city,
                                'phone' => $pharmacy->phone,
                                'email' => $pharmacy->email,
                                'status' => $pharmacy->status,
                                'license_number' => $pharmacy->license_number,
                            ]
                        ],
                    ],
                    'token' => $token,
                ],
            ], 201);
        });
    }

    /**
     * Supprimer les comptes non vérifiés (phone_verified_at IS NULL)
     * avec le même email ou téléphone pour permettre la réinscription.
     */
    private function deleteUnverifiedAccounts(?string $email, ?string $phone): void
    {
        if (!$email && !$phone) {
            return;
        }

        $users = User::whereNull('phone_verified_at')
            ->where(function ($query) use ($email, $phone) {
                if ($email) {
                    $query->where('email', strtolower(trim($email)));
                }
                if ($phone) {
                    // BUGFIX: orWhere correctement scopé
                    $query->orWhere('phone', $phone);
                }
            })
            ->get();

        foreach ($users as $user) {
            // Supprimer les tokens d'accès
            $user->tokens()->delete();

            // Supprimer le profil coursier si existant
            if ($user->courier) {
                $user->courier->delete();
            }

            // Détacher les pharmacies si existant
            if ($user->pharmacies()->count() > 0) {
                $user->pharmacies()->detach();
            }

            // Supprimer l'utilisateur
            $user->delete();
        }
    }

    /**
     * Valider les documents KYC avec Google Vision
     */
    private function validateKycDocuments(Request $request): array
    {
        $errors = [];
        $details = [];
        $valid = true;

        // Valider le selfie
        if ($request->hasFile('selfie_document')) {
            try {
                $selfieResult = $this->kycService->validateSelfie(
                    $request->file('selfie_document')->getRealPath()
                );
            } catch (\Throwable $e) {
                \Log::error('KYC selfie validation crash: ' . $e->getMessage());
                $selfieResult = ['valid' => true, 'skipped' => true, 'error' => $e->getMessage()];
            }
            $details['selfie'] = $selfieResult;
            
            if (!$selfieResult['valid'] && !($selfieResult['skipped'] ?? false)) {
                $valid = false;
                $errors['selfie_document'] = [$selfieResult['reason']];
            }
        }

        // Valider le recto de la CNI
        if ($request->hasFile('id_card_front_document')) {
            try {
                $idFrontResult = $this->kycService->validateIdCard(
                    $request->file('id_card_front_document')->getRealPath()
                );
            } catch (\Throwable $e) {
                \Log::error('KYC id_card_front validation crash: ' . $e->getMessage());
                $idFrontResult = ['valid' => true, 'skipped' => true, 'error' => $e->getMessage()];
            }
            $details['id_card_front'] = $idFrontResult;
            
            if (!$idFrontResult['valid'] && !($idFrontResult['skipped'] ?? false)) {
                $valid = false;
                $errors['id_card_front_document'] = [$idFrontResult['reason']];
            }
        }

        // Valider le verso de la CNI
        if ($request->hasFile('id_card_back_document')) {
            try {
                $idBackResult = $this->kycService->validateIdCardBack(
                    $request->file('id_card_back_document')->getRealPath()
                );
            } catch (\Throwable $e) {
                \Log::error('KYC id_card_back validation crash: ' . $e->getMessage());
                $idBackResult = ['valid' => true, 'skipped' => true, 'error' => $e->getMessage()];
            }
            $details['id_card_back'] = $idBackResult;
            
            if (!$idBackResult['valid'] && !($idBackResult['skipped'] ?? false)) {
                $valid = false;
                $errors['id_card_back_document'] = [$idBackResult['reason']];
            }
        }

        return [
            'valid' => $valid,
            'errors' => $errors,
            'details' => $details,
        ];
    }
}

