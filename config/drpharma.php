<?php

return [
    /*
    |--------------------------------------------------------------------------
    | DR-PHARMA Brand Configuration
    |--------------------------------------------------------------------------
    |
    | Centralise toutes les URLs / contacts publics de la marque pour éviter
    | le hardcoding dans les controllers, seeders, settings et messages.
    |
    */

    'brand' => [
        'website' => env('DRPHARMA_WEBSITE_URL', 'https://drlpharma.pro'),
        'support_email' => env('DRPHARMA_SUPPORT_EMAIL', 'support@drlpharma.com'),
        'support_phone' => env('DRPHARMA_SUPPORT_PHONE', '+225 07 00 00 00 00'),
        'youtube' => env('DRPHARMA_YOUTUBE_URL', 'https://www.youtube.com/@drlpharma'),
    ],

    'urls' => [
        'help' => env('DRPHARMA_HELP_URL', env('DRPHARMA_WEBSITE_URL', 'https://drlpharma.pro') . '/aide'),
        'guide' => env('DRPHARMA_GUIDE_URL', env('DRPHARMA_WEBSITE_URL', 'https://drlpharma.pro') . '/guide'),
        'faq' => env('DRPHARMA_FAQ_URL', env('DRPHARMA_WEBSITE_URL', 'https://drlpharma.pro') . '/faq'),
        'terms' => env('DRPHARMA_TERMS_URL', env('DRPHARMA_WEBSITE_URL', 'https://drlpharma.pro') . '/terms'),
        'privacy' => env('DRPHARMA_PRIVACY_URL', env('DRPHARMA_WEBSITE_URL', 'https://drlpharma.pro') . '/privacy'),
    ],
];
