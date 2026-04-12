<?php

/**
 * Feature flags par application.
 *
 * Permet d'activer/désactiver des fonctionnalités côté serveur
 * sans redéployer les apps mobiles.
 *
 * Les apps appellent GET /api/app/features?app=delivery
 */

return [
    'client' => [
        'wallet_enabled' => env('FEATURE_CLIENT_WALLET', true),
        'prescriptions_enabled' => env('FEATURE_CLIENT_PRESCRIPTIONS', true),
        'promo_codes_enabled' => env('FEATURE_CLIENT_PROMO_CODES', true),
        'ratings_enabled' => env('FEATURE_CLIENT_RATINGS', true),
        'chat_enabled' => env('FEATURE_CLIENT_CHAT', true),
        'on_duty_pharmacies' => env('FEATURE_CLIENT_ON_DUTY', true),
        'delivery_tracking' => env('FEATURE_CLIENT_DELIVERY_TRACKING', true),
        'push_notifications' => env('FEATURE_CLIENT_PUSH', true),
        'maintenance_mode' => env('FEATURE_CLIENT_MAINTENANCE', false),
        'maintenance_message' => env('FEATURE_CLIENT_MAINTENANCE_MSG', 'L\'application est en maintenance. Veuillez réessayer plus tard.'),
    ],

    'pharmacy' => [
        'inventory_enabled' => env('FEATURE_PHARMACY_INVENTORY', true),
        'prescriptions_enabled' => env('FEATURE_PHARMACY_PRESCRIPTIONS', true),
        'wallet_enabled' => env('FEATURE_PHARMACY_WALLET', true),
        'reports_enabled' => env('FEATURE_PHARMACY_REPORTS', true),
        'on_call_enabled' => env('FEATURE_PHARMACY_ON_CALL', true),
        'auto_statements' => env('FEATURE_PHARMACY_AUTO_STATEMENTS', true),
        'delivery_zones' => env('FEATURE_PHARMACY_DELIVERY_ZONES', true),
        'chat_enabled' => env('FEATURE_PHARMACY_CHAT', true),
        'push_notifications' => env('FEATURE_PHARMACY_PUSH', true),
        'maintenance_mode' => env('FEATURE_PHARMACY_MAINTENANCE', false),
        'maintenance_message' => env('FEATURE_PHARMACY_MAINTENANCE_MSG', 'L\'application est en maintenance.'),
    ],

    'delivery' => [
        'wallet_enabled' => env('FEATURE_DELIVERY_WALLET', true),
        'batch_deliveries' => env('FEATURE_DELIVERY_BATCH', true),
        'route_optimization' => env('FEATURE_DELIVERY_ROUTE_OPT', true),
        'challenges_enabled' => env('FEATURE_DELIVERY_CHALLENGES', true),
        'leaderboard_enabled' => env('FEATURE_DELIVERY_LEADERBOARD', true),
        'voice_announcements' => env('FEATURE_DELIVERY_VOICE', true),
        'chat_enabled' => env('FEATURE_DELIVERY_CHAT', true),
        'proof_of_delivery' => env('FEATURE_DELIVERY_PROOF', true),
        'push_notifications' => env('FEATURE_DELIVERY_PUSH', true),
        'maintenance_mode' => env('FEATURE_DELIVERY_MAINTENANCE', false),
        'maintenance_message' => env('FEATURE_DELIVERY_MAINTENANCE_MSG', 'L\'application est en maintenance.'),
    ],
];
