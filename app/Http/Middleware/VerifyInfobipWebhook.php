<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * Verify Infobip webhook requests using HMAC-SHA256 signature or IP whitelist.
 *
 * SECURITY: En production, au moins une méthode de vérification est OBLIGATOIRE.
 * 
 * Méthode 1 (recommandée): Signature HMAC
 * - Infobip envoie la signature dans le header `x-hub-signature` comme: sha256=<hex-digest>
 * - Configurez INFOBIP_WEBHOOK_SECRET dans le .env
 * 
 * Méthode 2: IP Whitelist
 * - Configurez INFOBIP_WEBHOOK_IPS dans le .env (IPs séparées par virgule)
 * - Supporte la notation CIDR (ex: 192.168.1.0/24)
 * 
 * @see https://www.infobip.com/docs/api/platform/webhooks
 * @see https://www.infobip.com/docs/essentials/security/ip-whitelisting
 */
class VerifyInfobipWebhook
{
    public function handle(Request $request, Closure $next): Response
    {
        $secret = config('sms.infobip.webhook_secret');
        $allowedIps = config('sms.infobip.webhook_allowed_ips', []);

        // Convertir string en array si nécessaire (depuis .env)
        if (is_string($allowedIps) && !empty($allowedIps)) {
            $allowedIps = array_map('trim', explode(',', $allowedIps));
        }

        // Mode 1: Vérification par signature HMAC (prioritaire)
        if (!empty($secret)) {
            return $this->verifySignature($request, $secret, $next);
        }

        // Mode 2: Vérification par IP Whitelist
        if (!empty($allowedIps) && is_array($allowedIps)) {
            return $this->verifyIpWhitelist($request, $allowedIps, $next);
        }

        // SÉCURITÉ: Aucune vérification configurée
        if (app()->isProduction()) {
            Log::critical('Infobip webhook: REJETÉ — Aucune sécurité configurée en production', [
                'ip' => $request->ip(),
                'path' => $request->path(),
                'action' => 'Configurez INFOBIP_WEBHOOK_SECRET ou INFOBIP_WEBHOOK_IPS dans .env',
            ]);
            
            return response()->json([
                'error' => 'Webhook security not configured',
            ], 503);
        }

        // Environnements non-production: autoriser avec avertissement
        Log::warning('Infobip webhook: Aucune vérification configurée (env non-production)', [
            'ip' => $request->ip(),
            'path' => $request->path(),
        ]);
        
        return $next($request);
    }

    /**
     * Vérifie la signature HMAC du webhook.
     */
    private function verifySignature(Request $request, string $secret, Closure $next): Response
    {
        $signature = $request->header('x-hub-signature');

        if (empty($signature)) {
            Log::warning('Infobip webhook: missing signature header', [
                'ip' => $request->ip(),
                'path' => $request->path(),
            ]);
            return response()->json(['error' => 'Missing signature'], 401);
        }

        // Extract algo and hash: "sha256=abc123..."
        $parts = explode('=', $signature, 2);
        if (count($parts) !== 2 || $parts[0] !== 'sha256') {
            Log::warning('Infobip webhook: invalid signature format', [
                'ip' => $request->ip(),
                'signature' => $signature,
            ]);
            return response()->json(['error' => 'Invalid signature format'], 401);
        }

        $expectedHash = hash_hmac('sha256', $request->getContent(), $secret);

        if (!hash_equals($expectedHash, $parts[1])) {
            Log::warning('Infobip webhook: signature mismatch', [
                'ip' => $request->ip(),
                'path' => $request->path(),
            ]);
            return response()->json(['error' => 'Invalid signature'], 401);
        }

        return $next($request);
    }

    /**
     * Vérifie si l'IP est dans la whitelist autorisée.
     */
    private function verifyIpWhitelist(Request $request, array $allowedIps, Closure $next): Response
    {
        $clientIp = $request->ip();

        if (!$this->isIpAllowed($clientIp, $allowedIps)) {
            Log::warning('Infobip webhook: IP non autorisée', [
                'ip' => $clientIp,
                'path' => $request->path(),
                'allowed_ips' => $allowedIps,
            ]);
            return response()->json(['error' => 'Forbidden'], 403);
        }

        return $next($request);
    }

    /**
     * Vérifie si l'IP est dans la whitelist.
     * Supporte les CIDR notations (ex: 192.168.1.0/24).
     */
    private function isIpAllowed(string $ip, array $allowedIps): bool
    {
        foreach ($allowedIps as $allowed) {
            $allowed = trim($allowed);
            
            // IP exacte
            if ($ip === $allowed) {
                return true;
            }
            
            // CIDR notation (ex: 192.168.1.0/24)
            if (str_contains($allowed, '/') && $this->ipInCidr($ip, $allowed)) {
                return true;
            }
        }
        
        return false;
    }

    /**
     * Vérifie si une IP est dans un range CIDR.
     */
    private function ipInCidr(string $ip, string $cidr): bool
    {
        [$subnet, $mask] = explode('/', $cidr);
        $mask = (int) $mask;
        
        $subnetLong = ip2long($subnet);
        $ipLong = ip2long($ip);
        
        if ($subnetLong === false || $ipLong === false) {
            return false;
        }
        
        $maskLong = ~((1 << (32 - $mask)) - 1);
        
        return ($ipLong & $maskLong) === ($subnetLong & $maskLong);
    }
}
