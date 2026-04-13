<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * Verify Infobip webhook requests using HMAC-SHA256 signature.
 *
 * Infobip sends the signature in the `x-hub-signature` header as:
 *   sha256=<hex-digest>
 *
 * The digest is computed over the raw request body using the shared
 * webhook secret configured in the Infobip portal.
 *
 * If no secret is configured, the middleware logs a warning and allows
 * the request through (graceful degradation for development).
 *
 * @see https://www.infobip.com/docs/api/platform/webhooks
 */
class VerifyInfobipWebhook
{
    public function handle(Request $request, Closure $next): Response
    {
        $secret = config('sms.infobip.webhook_secret');

        // No secret configured — allow through with warning (dev/staging)
        if (empty($secret)) {
            if (app()->isProduction()) {
                Log::warning('Infobip webhook secret not configured in production', [
                    'ip' => $request->ip(),
                    'path' => $request->path(),
                ]);
            }
            return $next($request);
        }

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
}
