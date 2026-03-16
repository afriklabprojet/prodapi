<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    | To learn more: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie', 'broadcasting/auth'],

    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],

    /*
    |--------------------------------------------------------------------------
    | Allowed Origins - SECURITY FIX
    |--------------------------------------------------------------------------
    |
    | IMPORTANT: Ne JAMAIS utiliser '*' avec supports_credentials = true
    | Configurer les domaines autorisés via CORS_ALLOWED_ORIGINS dans .env
    |
    | Format .env: CORS_ALLOWED_ORIGINS=https://drpharma.ci,https://app.drpharma.ci
    */
    'allowed_origins' => array_filter(
        array_merge(
            // Frontend URL from environment
            [env('FRONTEND_URL', 'http://localhost:3000')],
            // Additional origins from comma-separated env variable
            explode(',', env('CORS_ALLOWED_ORIGINS', ''))
        )
    ),

    /*
    |--------------------------------------------------------------------------
    | Allowed Origin Patterns
    |--------------------------------------------------------------------------
    |
    | Patterns regex pour autoriser des sous-domaines dynamiquement
    | Exemple: '/^https:\/\/.*\.drpharma\.ci$/' autorise *.drpharma.ci
    */
    'allowed_origins_patterns' => array_filter(
        explode(',', env('CORS_ALLOWED_PATTERNS', '/^http:\/\/localhost(:\d+)?$/'))
    ),

    'allowed_headers' => ['*'],

    'exposed_headers' => ['X-RateLimit-Limit', 'X-RateLimit-Remaining'],

    'max_age' => 86400, // 24 heures

    /*
    |--------------------------------------------------------------------------
    | Supports Credentials
    |--------------------------------------------------------------------------
    |
    | Permet l'envoi de cookies/auth headers cross-origin.
    | ATTENTION: Si true, allowed_origins ne peut pas être '*'
    */
    'supports_credentials' => true,

];
