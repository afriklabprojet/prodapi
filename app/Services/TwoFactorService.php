<?php

namespace App\Services;

use App\Models\User;
use BaconQrCode\Renderer\GDLibRenderer;
use BaconQrCode\Renderer\ImageRenderer;
use BaconQrCode\Renderer\Image\SvgImageBackEnd;
use BaconQrCode\Renderer\RendererStyle\RendererStyle;
use BaconQrCode\Writer;
use Illuminate\Support\Str;
use PragmaRX\Google2FA\Google2FA;

/**
 * Gestion 2FA TOTP pour les comptes admin.
 *
 * Cycle de vie :
 *   1. enroll($user) -> génère un secret + QR + codes de récupération (non confirmé)
 *   2. confirm($user, $code) -> valide le code TOTP, marque confirmé
 *   3. verify($user, $code) -> vérifie un code à la connexion (TOTP ou recovery)
 *   4. disable($user) -> retire totalement la 2FA
 */
class TwoFactorService
{
    private Google2FA $engine;

    public function __construct()
    {
        $this->engine = new Google2FA();
    }

    /**
     * Génère un nouveau secret + recovery codes pour l'utilisateur.
     * Le secret est stocké mais NON confirmé (two_factor_confirmed_at = null).
     */
    public function enroll(User $user): array
    {
        $secret = $this->engine->generateSecretKey(32);
        $recoveryCodes = $this->generateRecoveryCodes();

        $user->forceFill([
            'two_factor_secret' => $secret,
            'two_factor_recovery_codes' => $recoveryCodes,
            'two_factor_confirmed_at' => null,
        ])->save();

        return [
            'secret' => $secret,
            'qr_svg' => $this->qrCodeSvg($user, $secret),
            'otpauth_url' => $this->otpauthUrl($user, $secret),
            'recovery_codes' => $recoveryCodes,
        ];
    }

    /**
     * Valide le code TOTP fourni et active définitivement la 2FA.
     */
    public function confirm(User $user, string $code): bool
    {
        if (! $user->two_factor_secret) {
            return false;
        }
        if (! $this->engine->verifyKey($user->two_factor_secret, $code)) {
            return false;
        }
        $user->forceFill(['two_factor_confirmed_at' => now()])->save();
        return true;
    }

    /**
     * Vérifie un code de challenge (TOTP ou recovery code).
     */
    public function verify(User $user, string $code): bool
    {
        if (! $user->hasTwoFactorEnabled()) {
            return false;
        }
        $code = trim($code);

        // TOTP 6 chiffres
        if (preg_match('/^\d{6}$/', $code)) {
            return (bool) $this->engine->verifyKey($user->two_factor_secret, $code);
        }

        // Recovery code (10 chars hex-ish séparés par tiret)
        $codes = $user->two_factor_recovery_codes ?? [];
        if (in_array($code, $codes, true)) {
            $remaining = array_values(array_diff($codes, [$code]));
            $user->forceFill(['two_factor_recovery_codes' => $remaining])->save();
            return true;
        }

        return false;
    }

    public function disable(User $user): void
    {
        $user->forceFill([
            'two_factor_secret' => null,
            'two_factor_recovery_codes' => null,
            'two_factor_confirmed_at' => null,
        ])->save();
    }

    public function regenerateRecoveryCodes(User $user): array
    {
        $codes = $this->generateRecoveryCodes();
        $user->forceFill(['two_factor_recovery_codes' => $codes])->save();
        return $codes;
    }

    private function generateRecoveryCodes(int $count = 8): array
    {
        return collect(range(1, $count))
            ->map(fn () => Str::lower(Str::random(5).'-'.Str::random(5)))
            ->all();
    }

    private function otpauthUrl(User $user, string $secret): string
    {
        $issuer = rawurlencode(config('app.name', 'DR-PHARMA').' Admin');
        $label = rawurlencode($user->email);
        return "otpauth://totp/{$issuer}:{$label}?secret={$secret}&issuer={$issuer}&algorithm=SHA1&digits=6&period=30";
    }

    private function qrCodeSvg(User $user, string $secret): string
    {
        $renderer = new ImageRenderer(
            new RendererStyle(220, 1),
            new SvgImageBackEnd()
        );
        return (new Writer($renderer))->writeString($this->otpauthUrl($user, $secret));
    }
}
