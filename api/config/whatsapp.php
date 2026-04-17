<?php

return [

    /*
    |--------------------------------------------------------------------------
    | WhatsApp Integration via Infobip
    |--------------------------------------------------------------------------
    |
    | Configuration for WhatsApp Business API through Infobip.
    | Documentation: https://www.infobip.com/docs/whatsapp
    |
    */

    'enabled' => env('WHATSAPP_ENABLED', false),

    /*
    |--------------------------------------------------------------------------
    | Infobip API Credentials
    |--------------------------------------------------------------------------
    |
    | Your Infobip base URL and API key.
    | Base URL format: https://XXXXX.api.infobip.com
    | Get your credentials at: https://portal.infobip.com
    |
    */

    'base_url' => env('WHATSAPP_INFOBIP_BASE_URL', env('INFOBIP_BASE_URL')),

    'api_key' => env('WHATSAPP_INFOBIP_API_KEY', env('INFOBIP_API_KEY')),

    /*
    |--------------------------------------------------------------------------
    | WhatsApp Sender Number
    |--------------------------------------------------------------------------
    |
    | Registered WhatsApp Business sender number.
    | Must be in international format (e.g., 2250700000000).
    | Register at: https://www.infobip.com/docs/whatsapp/get-started/sender-registration
    |
    */

    'sender_number' => env('WHATSAPP_SENDER_NUMBER'),

    /*
    |--------------------------------------------------------------------------
    | Default Language
    |--------------------------------------------------------------------------
    |
    | Default language code for template messages.
    | Must match the language used when registering templates with Meta.
    |
    */

    'default_language' => env('WHATSAPP_DEFAULT_LANGUAGE', 'fr'),

    /*
    |--------------------------------------------------------------------------
    | Default Country Code
    |--------------------------------------------------------------------------
    |
    | Default country code for phone number normalization (Côte d'Ivoire).
    |
    */

    'default_country_code' => env('WHATSAPP_DEFAULT_COUNTRY_CODE', '+225'),

    /*
    |--------------------------------------------------------------------------
    | SMS Failover
    |--------------------------------------------------------------------------
    |
    | If enabled, an SMS will be sent as fallback when WhatsApp delivery fails
    | (e.g., user doesn't have WhatsApp). Infobip handles this automatically.
    |
    */

    'sms_failover' => [
        'enabled' => env('WHATSAPP_SMS_FAILOVER', false),
        'sender' => env('WHATSAPP_SMS_FAILOVER_SENDER', 'DR-PHARMA'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Notification Preferences
    |--------------------------------------------------------------------------
    |
    | Control which notification types should be sent via WhatsApp.
    | Types: order_status, delivery, prescription, otp, promotion
    |
    */

    'notifications' => [
        'order_status' => env('WHATSAPP_NOTIFY_ORDER_STATUS', true),
        'delivery' => env('WHATSAPP_NOTIFY_DELIVERY', true),
        'prescription' => env('WHATSAPP_NOTIFY_PRESCRIPTION', true),
        'otp' => env('WHATSAPP_NOTIFY_OTP', true), // WhatsApp as primary OTP channel
        'promotion' => env('WHATSAPP_NOTIFY_PROMOTION', false),
        'chat' => env('WHATSAPP_NOTIFY_CHAT', false), // Chat messages (can be chatty)
    ],

    /*
    |--------------------------------------------------------------------------
    | WhatsApp Message Templates
    |--------------------------------------------------------------------------
    |
    | Pre-approved message templates registered with Meta via Infobip.
    | Template names must be lowercase alphanumeric with underscores.
    |
    | Each template requires:
    | - name: Template name as registered with Meta
    | - language: Language code used during registration
    | - category: marketing, utility, or authentication
    | - placeholders: Description of each placeholder for documentation
    | - sms_fallback: SMS text to send if WhatsApp fails (with {1}, {2}... for values)
    |
    | IMPORTANT: Templates must be registered and approved in your Infobip
    | portal before they can be used.
    |
    | Register templates at:
    | https://portal.infobip.com/channels/whatsapp/senders → Your Sender → Templates
    |
    */

    'templates' => [

        // ─── UTILITY: Order Status Updates ──────────────────────────────────

        'order_confirmed' => [
            'name' => 'order_confirmed',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du client',
                '{2}' => 'Référence commande',
                '{3}' => 'Nom de la pharmacie',
            ],
            'sms_fallback' => 'DR-PHARMA: Bonjour {1}, votre commande {2} a été confirmée par {3}.',
        ],

        'order_ready' => [
            'name' => 'order_ready',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du client',
                '{2}' => 'Référence commande',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, votre commande {2} est prête et sera livrée bientôt.',
        ],

        'order_delivered' => [
            'name' => 'order_delivered',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du client',
                '{2}' => 'Référence commande',
                '{3}' => 'Montant total',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, votre commande {2} a été livrée! Montant: {3}. Merci!',
        ],

        'order_cancelled' => [
            'name' => 'order_cancelled',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du client',
                '{2}' => 'Référence commande',
                '{3}' => 'Raison annulation',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, votre commande {2} a été annulée. Raison: {3}.',
        ],

        // ─── UTILITY: Delivery Updates ──────────────────────────────────────

        'delivery_assigned' => [
            'name' => 'delivery_assigned',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du client',
                '{2}' => 'Référence commande',
                '{3}' => 'Nom du livreur',
                '{4}' => 'Téléphone du livreur',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, un livreur ({3}, {4}) est assigné à votre commande {2}.',
        ],

        'delivery_on_the_way' => [
            'name' => 'delivery_on_the_way',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du client',
                '{2}' => 'Référence commande',
                '{3}' => 'Temps estimé (minutes)',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, votre commande {2} est en route! Arrivée estimée: {3} min.',
        ],

        'courier_arrived' => [
            'name' => 'courier_arrived',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du client',
                '{2}' => 'Nom du livreur',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, votre livreur {2} est arrivé à votre adresse.',
        ],

        // ─── UTILITY: Prescription Updates ──────────────────────────────────

        'prescription_received' => [
            'name' => 'prescription_received',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du client',
                '{2}' => 'Nom de la pharmacie',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, votre ordonnance a été reçue par {2}. Vous serez notifié dès le traitement.',
        ],

        'prescription_ready' => [
            'name' => 'prescription_ready',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du client',
                '{2}' => 'Nombre de produits',
                '{3}' => 'Montant estimé',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, votre ordonnance est prête ({2} produits, ~{3}). Confirmez votre commande.',
        ],

        // ─── UTILITY: New Order for Pharmacy ────────────────────────────────

        'new_order_pharmacy' => [
            'name' => 'new_order_pharmacy',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom de la pharmacie',
                '{2}' => 'Référence commande',
                '{3}' => 'Nombre de produits',
                '{4}' => 'Montant',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, nouvelle commande {2} ({3} produits, {4}). Veuillez confirmer.',
        ],

        'new_prescription_pharmacy' => [
            'name' => 'new_prescription_pharmacy',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom de la pharmacie',
                '{2}' => 'Référence ordonnance',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, nouvelle ordonnance {2} reçue. Veuillez la traiter.',
        ],

        // ─── UTILITY: Order Delivered to Pharmacy ───────────────────────────

        'order_delivered_pharmacy' => [
            'name' => 'order_delivered_pharmacy',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom de la pharmacie',
                '{2}' => 'Référence commande',
                '{3}' => 'Nom du client',
                '{4}' => 'Nom du livreur',
                '{5}' => 'Montant total',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, commande {2} livrée à {3} par {4}. Montant: {5}.',
        ],

        // ─── UTILITY: Delivery Timeout Cancelled ────────────────────────────

        'delivery_timeout_customer' => [
            'name' => 'delivery_timeout_customer',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du client',
                '{2}' => 'Minutes d\'attente',
                '{3}' => 'Frais d\'attente',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, votre commande a été annulée après {2} min d\'attente. Frais: {3} FCFA.',
        ],

        'delivery_timeout_courier' => [
            'name' => 'delivery_timeout_courier',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du livreur',
                '{2}' => 'Référence commande',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, la livraison {2} a été annulée (timeout). Vous pouvez accepter de nouvelles livraisons.',
        ],

        'delivery_timeout_pharmacy' => [
            'name' => 'delivery_timeout_pharmacy',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom de la pharmacie',
                '{2}' => 'Référence commande',
                '{3}' => 'Minutes d\'attente',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, commande {2} annulée. Client indisponible après {3} min.',
        ],

        // ─── UTILITY: Courier Arrived at Client (for pharmacy) ──────────────

        'courier_at_client' => [
            'name' => 'courier_at_client',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom de la pharmacie',
                '{2}' => 'Référence commande',
                '{3}' => 'Nom du livreur',
                '{4}' => 'Minutes timeout',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, le livreur {3} est arrivé chez le client pour la commande {2}. Timeout: {4} min.',
        ],

        // ─── UTILITY: Chat Message ──────────────────────────────────────────

        'new_chat_message' => [
            'name' => 'new_chat_message',
            'language' => 'fr',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Type d\'expéditeur',
                '{2}' => 'Nom de l\'expéditeur',
                '{3}' => 'Aperçu du message',
            ],
            'sms_fallback' => 'DR-PHARMA: Nouveau message de {1} {2}: {3}',
        ],

        // ─── AUTHENTICATION: OTP ────────────────────────────────────────────

        'otp_verification' => [
            'name' => 'otp_verification',
            'language' => 'fr',
            'category' => 'authentication',
            'placeholders' => [
                '{1}' => 'Code OTP',
            ],
            'sms_fallback' => 'DR-PHARMA: Votre code de vérification est {1}. Ne le partagez avec personne.',
        ],

        // ─── MARKETING: Promotions (opt-in required) ────────────────────────

        'welcome_customer' => [
            'name' => 'welcome_customer',
            'language' => 'fr',
            'category' => 'marketing',
            'placeholders' => [
                '{1}' => 'Nom du client',
            ],
            'sms_fallback' => 'DR-PHARMA: Bienvenue {1}! Commandez vos médicaments en toute simplicité.',
        ],

        'promotion_offer' => [
            'name' => 'promotion_offer',
            'language' => 'fr',
            'category' => 'marketing',
            'placeholders' => [
                '{1}' => 'Nom du client',
                '{2}' => 'Description de l\'offre',
                '{3}' => 'Code promo',
            ],
            'sms_fallback' => 'DR-PHARMA: {1}, {2}. Code: {3}.',
        ],

        // ─── TEST: Template de test Infobip (anglais) ───────────────────────

        'test_whatsapp_template_en' => [
            'name' => 'test_whatsapp_template_en',
            'language' => 'en',
            'category' => 'utility',
            'placeholders' => [
                '{1}' => 'Nom du destinataire',
            ],
            'sms_fallback' => 'DR-PHARMA: Hello {1}, this is a test message.',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Delivery Report Webhook
    |--------------------------------------------------------------------------
    |
    | URL where Infobip will send delivery reports.
    | Set this up in your Infobip portal for real-time delivery tracking.
    |
    */

    'webhook_url' => env('WHATSAPP_WEBHOOK_URL'),

    /*
    |--------------------------------------------------------------------------
    | Rate Limiting
    |--------------------------------------------------------------------------
    |
    | WhatsApp has a rate limit of 80 messages/second for business accounts.
    | Infobip API limit is 4000 requests/second.
    |
    */

    'rate_limit' => [
        'messages_per_second' => env('WHATSAPP_RATE_LIMIT', 80),
    ],
];
