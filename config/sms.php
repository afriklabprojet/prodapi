<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default SMS Driver
    |--------------------------------------------------------------------------
    |
    | Provider par défaut pour l'envoi des SMS.
    | Supported: "infobip", "twilio", "africastalking", "log"
    |
    | Infobip est le provider principal avec intégration complète:
    | - Envoi simple et avancé (/sms/3/messages)
    | - Bulk SMS (multi-destinations)
    | - SMS programmés (scheduling)
    | - Flash SMS
    | - Delivery Reports (webhook + pull)
    | - Logs et rapports
    | - Preview SMS (comptage caractères)
    | - Conversion tracking
    | - 2FA / OTP natif (PIN send/verify/resend)
    | - Inbound SMS (réception)
    |
    */

    'default' => env('SMS_DRIVER', 'infobip'),

    /*
    |--------------------------------------------------------------------------
    | Infobip Configuration (Provider Principal)
    |--------------------------------------------------------------------------
    |
    | Documentation API: https://www.infobip.com/docs/api/channels/sms
    | Portail: https://portal.infobip.com
    |
    */

    'infobip' => [

        // ─── Credentials ────────────────────────────────────────────────────
        // Base URL format: https://XXXXX.api.infobip.com
        'base_url' => env('INFOBIP_BASE_URL'),
        'api_key' => env('INFOBIP_API_KEY'),

        // ─── Sender ─────────────────────────────────────────────────────────
        // Sender ID (alphanumeric 3-11 chars ou numérique 3-16 chars)
        // Doit être enregistré et approuvé dans le portail Infobip
        'sender' => env('INFOBIP_SMS_SENDER', env('INFOBIP_SENDER', 'DR-PHARMA')),

        // ─── Delivery Reports (Webhook) ─────────────────────────────────────
        // URL où Infobip enverra les rapports de livraison SMS
        // Configurer dans: Portail Infobip > Channels > SMS > Settings
        'notify_url' => env('INFOBIP_SMS_NOTIFY_URL', env('APP_URL') . '/api/webhooks/sms/delivery'),

        // ─── Translitération ────────────────────────────────────────────────
        // Convertir les caractères spéciaux pour économiser des SMS
        // Options: TURKISH, GREEK, CYRILLIC, SERBIAN_CYRILLIC, 
        //          CENTRAL_EUROPEAN, BALTIC, PORTUGUESE, COLOMBIAN, 
        //          NON_UNICODE, ALL
        'transliteration' => env('INFOBIP_SMS_TRANSLITERATION', null),

        // ─── Language Code ──────────────────────────────────────────────────
        // Code langue pour le jeu de caractères
        'language_code' => env('INFOBIP_SMS_LANGUAGE', 'FR'),

        // ─── Timeout ────────────────────────────────────────────────────────
        'timeout' => env('INFOBIP_SMS_TIMEOUT', 30),

        // ─── Validity Period ────────────────────────────────────────────────
        // Durée max (en minutes) pour tenter la livraison d'un SMS
        // Après ce délai, le SMS est marqué comme non livré
        'validity_period' => env('INFOBIP_SMS_VALIDITY_PERIOD', 1440), // 24h par défaut

        // ─── Delivery Time Window ───────────────────────────────────────────
        // Fenêtre horaire pendant laquelle les SMS peuvent être livrés
        // Utile pour respecter les réglementations sur les heures d'envoi
        'delivery_time_window' => [
            'enabled' => env('INFOBIP_SMS_TIME_WINDOW_ENABLED', false),
            'from' => env('INFOBIP_SMS_TIME_WINDOW_FROM', '08:00'),
            'to' => env('INFOBIP_SMS_TIME_WINDOW_TO', '22:00'),
            'days' => ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'],
        ],

        // ─── Conversion Tracking ────────────────────────────────────────────
        // Suivre les conversions (clics, codes OTP, etc.)
        'conversion_tracking' => env('INFOBIP_SMS_CONVERSION_TRACKING', false),

        // ─── Inbound SMS ────────────────────────────────────────────────────
        // Numéro pour recevoir les SMS entrants
        'inbound_number' => env('INFOBIP_SMS_INBOUND_NUMBER'),

        // ─── 2FA / OTP Configuration ────────────────────────────────────────
        // API 2FA native Infobip pour les OTP
        // Docs: https://www.infobip.com/docs/api/channels/sms/sms-messaging/number-masking
        //
        // Pour utiliser le 2FA natif:
        // 1. Créer une application 2FA dans le portail ou via API
        // 2. Créer un template de message 2FA
        // 3. Configurer les IDs ci-dessous
        //
        '2fa' => [
            // Activer le 2FA natif Infobip (sinon OTP manuelle)
            'enabled' => env('INFOBIP_2FA_ENABLED', false),

            // IDs de l'application et du template 2FA
            // Générés lors de la création dans le portail Infobip
            'application_id' => env('INFOBIP_2FA_APP_ID'),
            'message_id' => env('INFOBIP_2FA_MESSAGE_ID'),

            // Configuration du PIN
            'pin_length' => env('INFOBIP_2FA_PIN_LENGTH', 4),
            'pin_type' => env('INFOBIP_2FA_PIN_TYPE', 'NUMERIC'), // NUMERIC, ALPHA, HEX, ALPHANUMERIC
            'pin_ttl' => env('INFOBIP_2FA_PIN_TTL', '10m'), // Durée de validité du PIN

            // Limites de sécurité
            'pin_attempts' => env('INFOBIP_2FA_PIN_ATTEMPTS', 5), // Tentatives max avant blocage
            'verify_limit' => env('INFOBIP_2FA_VERIFY_LIMIT', '1/3s'), // Rate limit vérification
            'send_limit_app' => env('INFOBIP_2FA_SEND_LIMIT_APP', '5000/12h'), // Limite envois par app
            'send_limit_phone' => env('INFOBIP_2FA_SEND_LIMIT_PHONE', '3/1d'), // Limite envois par numéro

            // Template du message OTP
            // Placeholders: {{pin}}, {{timeToLive}}
            'message_text' => env('INFOBIP_2FA_MESSAGE', 'DR-PHARMA: Votre code de vérification est {{pin}}. Valide {{timeToLive}}.'),

            // Placeholders additionnels (key => value)
            'placeholders' => [],
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Twilio Configuration (Provider Alternatif)
    |--------------------------------------------------------------------------
    */

    'twilio' => [
        'sid' => env('TWILIO_SID'),
        'token' => env('TWILIO_AUTH_TOKEN'),
        'from' => env('TWILIO_FROM'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Africa's Talking Configuration (Provider Alternatif)
    |--------------------------------------------------------------------------
    */

    'africastalking' => [
        'username' => env('AFRICASTALKING_USERNAME', 'sandbox'),
        'api_key' => env('AFRICASTALKING_API_KEY'),
        'sender_id' => env('AFRICASTALKING_SENDER_ID', 'DR-PHARMA'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Phone Number Settings
    |--------------------------------------------------------------------------
    |
    | Default country code pour la normalisation des numéros (Côte d'Ivoire)
    |
    */

    'default_country_code' => env('SMS_DEFAULT_COUNTRY_CODE', '+225'),

    /*
    |--------------------------------------------------------------------------
    | Rate Limiting
    |--------------------------------------------------------------------------
    |
    | Limites d'envoi pour éviter le spam et respecter les quotas
    |
    */

    'rate_limit' => [
        'per_number_per_day' => env('SMS_RATE_LIMIT_PER_NUMBER', 10),
        'per_minute' => env('SMS_RATE_LIMIT_PER_MINUTE', 30),
        'global_per_hour' => env('SMS_RATE_LIMIT_GLOBAL', 1000),
    ],

    /*
    |--------------------------------------------------------------------------
    | Logging
    |--------------------------------------------------------------------------
    |
    | Contrôle du niveau de log pour les SMS
    |
    */

    'logging' => [
        // Logger tous les SMS envoyés (avec contenu)
        'log_content' => env('SMS_LOG_CONTENT', true),
        // Masquer les numéros dans les logs (RGPD/PDPA)
        'mask_numbers' => env('SMS_MASK_NUMBERS', false),
        // Canal de log spécifique
        'channel' => env('SMS_LOG_CHANNEL', null), // null = default channel
    ],

];
