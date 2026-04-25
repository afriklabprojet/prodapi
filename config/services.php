<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'fcm' => [
        'key' => env('FCM_SERVER_KEY'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Payment Gateways Configuration
    |--------------------------------------------------------------------------
    */

    'jeko' => [
        'api_url' => env('JEKO_API_URL', 'https://api.jeko.africa'),
        'api_key' => env('JEKO_API_KEY'),
        'api_key_id' => env('JEKO_API_KEY_ID'),
        'store_id' => env('JEKO_STORE_ID'),
        'webhook_secret' => env('JEKO_WEBHOOK_SECRET'),
        'return_url' => env('JEKO_RETURN_URL'),
        'error_url' => env('JEKO_ERROR_URL'),
        // Mode sandbox: true = simulation, false = production réelle
        'sandbox_mode' => env('JEKO_SANDBOX_MODE', false) === true || env('JEKO_SANDBOX_MODE', 'false') === 'true',
        // Security: Whitelist IPs autorisées pour les webhooks
        // Laissez vide pour désactiver la vérification (dev), configurez en production
        'webhook_allowed_ips' => array_filter(explode(',', env('JEKO_WEBHOOK_IPS', ''))),
    ],

    /*
    |--------------------------------------------------------------------------
    | SMS Services Configuration
    |--------------------------------------------------------------------------
    */

    'sms' => [
        'provider' => env('SMS_PROVIDER', 'log'), // africas_talking, twilio, log
    ],

    'africas_talking' => [
        'username' => env('AFRICAS_TALKING_USERNAME'),
        'api_key' => env('AFRICAS_TALKING_API_KEY'),
        'sender_id' => env('AFRICAS_TALKING_SENDER_ID', 'DR-PHARMA'),
        'base_url' => env('AFRICAS_TALKING_BASE_URL', 'https://api.africastalking.com/version1'),
    ],

    'twilio' => [
        'account_sid' => env('TWILIO_ACCOUNT_SID'),
        'auth_token' => env('TWILIO_AUTH_TOKEN'),
        'from_number' => env('TWILIO_FROM_NUMBER'),
        'base_url' => env('TWILIO_BASE_URL', 'https://api.twilio.com/2010-04-01'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Firebase Cloud Messaging (FCM) Configuration
    |--------------------------------------------------------------------------
    */

    'fcm' => [
        'key' => env('FCM_SERVER_KEY'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Google Maps Configuration
    |--------------------------------------------------------------------------
    */

    'google_maps' => [
        'key' => env('GOOGLE_MAPS_API_KEY'),
        'base_url' => env('GOOGLE_MAPS_BASE_URL', 'https://maps.googleapis.com/maps/api'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Google Vision API - KYC Validation
    |--------------------------------------------------------------------------
    */

    'google_vision' => [
        'enabled' => env('GOOGLE_VISION_ENABLED', false),
        'credentials_path' => env('GOOGLE_APPLICATION_CREDENTIALS'),
        'api_key' => env('GOOGLE_VISION_API_KEY', env('GOOGLE_MAPS_API_KEY')),
        'base_url' => env('GOOGLE_VISION_BASE_URL', 'https://vision.googleapis.com/v1'),
    ],

    /*
    |--------------------------------------------------------------------------
    | OpenWeatherMap - Weather-based delivery pricing
    |--------------------------------------------------------------------------
    */

    'openweather' => [
        'key' => env('OPENWEATHER_API_KEY'),
        'base_url' => env('OPENWEATHER_BASE_URL', 'https://api.openweathermap.org/data/2.5'),
    ],

    /*
    |--------------------------------------------------------------------------
    | TomTom Traffic API
    |--------------------------------------------------------------------------
    */

    'tomtom' => [
        'key' => env('TOMTOM_API_KEY'),
        'base_url' => env('TOMTOM_BASE_URL', 'https://api.tomtom.com'),
    ],

];
