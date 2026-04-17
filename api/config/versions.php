<?php

/**
 * Configuration des versions minimales et feature flags par application.
 *
 * Les valeurs sont lues depuis .env pour faciliter le déploiement sans re-deploy du code.
 */

return [
    /*
    |--------------------------------------------------------------------------
    | Versions minimales requises (force update)
    |--------------------------------------------------------------------------
    | Si l'app est en dessous de cette version, force_update = true
    */
    'min_versions' => [
        'client' => [
            'android' => env('MIN_VERSION_CLIENT_ANDROID', '1.0.0'),
            'ios' => env('MIN_VERSION_CLIENT_IOS', '1.0.0'),
        ],
        'pharmacy' => [
            'android' => env('MIN_VERSION_PHARMACY_ANDROID', '1.0.0'),
            'ios' => env('MIN_VERSION_PHARMACY_IOS', '1.0.0'),
        ],
        'delivery' => [
            'android' => env('MIN_VERSION_DELIVERY_ANDROID', '1.0.0'),
            'ios' => env('MIN_VERSION_DELIVERY_IOS', '1.0.0'),
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Dernières versions disponibles
    |--------------------------------------------------------------------------
    | Utilisées pour afficher "mise à jour disponible" (non-bloquant)
    */
    'latest_versions' => [
        'client' => [
            'android' => env('LATEST_VERSION_CLIENT_ANDROID', '1.0.0'),
            'ios' => env('LATEST_VERSION_CLIENT_IOS', '1.0.0'),
        ],
        'pharmacy' => [
            'android' => env('LATEST_VERSION_PHARMACY_ANDROID', '1.0.0'),
            'ios' => env('LATEST_VERSION_PHARMACY_IOS', '1.0.0'),
        ],
        'delivery' => [
            'android' => env('LATEST_VERSION_DELIVERY_ANDROID', '1.0.0'),
            'ios' => env('LATEST_VERSION_DELIVERY_IOS', '1.0.0'),
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | URLs des stores
    |--------------------------------------------------------------------------
    */
    'store_urls' => [
        'client' => [
            'android' => env('STORE_URL_CLIENT_ANDROID', ''),
            'ios' => env('STORE_URL_CLIENT_IOS', ''),
        ],
        'pharmacy' => [
            'android' => env('STORE_URL_PHARMACY_ANDROID', ''),
            'ios' => env('STORE_URL_PHARMACY_IOS', ''),
        ],
        'delivery' => [
            'android' => env('STORE_URL_DELIVERY_ANDROID', ''),
            'ios' => env('STORE_URL_DELIVERY_IOS', ''),
        ],
    ],
];
