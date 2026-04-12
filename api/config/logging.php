<?php

use Monolog\Handler\NullHandler;
use Monolog\Handler\StreamHandler;
use Monolog\Handler\SyslogUdpHandler;
use Monolog\Processor\PsrLogMessageProcessor;

return [

    'default' => env('LOG_CHANNEL', 'stack'),

    'deprecations' => [
        'channel' => env('LOG_DEPRECATIONS_CHANNEL', 'null'),
        'trace' => false,
    ],

    'channels' => [
        'stack' => [
            'driver' => 'stack',
            'channels' => explode(',', env('LOG_STACK', 'single')),
            'ignore_exceptions' => false,
        ],

        'single' => [
            'driver' => 'single',
            'path' => storage_path('logs/laravel.log'),
            'level' => env('LOG_LEVEL', 'debug'),
            'replace_placeholders' => true,
        ],

        'daily' => [
            'driver' => 'daily',
            'path' => storage_path('logs/laravel.log'),
            'level' => env('LOG_LEVEL', 'debug'),
            'days' => env('LOG_DAILY_DAYS', 14),
            'replace_placeholders' => true,
        ],

        // === CANAUX SPÉCIALISÉS DR-PHARMA ===

        // Logs paiements (JEKO, wallet, retraits) — audit financier
        'payment' => [
            'driver' => 'daily',
            'path' => storage_path('logs/payment.log'),
            'level' => 'info',
            'days' => 90, // Garder 90 jours pour audit financier
        ],

        // Logs sécurité (fraude, accès suspect, authentification)
        'security' => [
            'driver' => 'daily',
            'path' => storage_path('logs/security.log'),
            'level' => 'warning',
            'days' => 180, // Garder 6 mois
        ],

        // Logs webhooks
        'webhook' => [
            'driver' => 'daily',
            'path' => storage_path('logs/webhook.log'),
            'level' => 'info',
            'days' => 30,
        ],

        // Préparé pour Sentry (décommenter quand intégré)
        // 'sentry' => [
        //     'driver' => 'sentry',
        //     'level' => 'error',
        //     'bubble' => true,
        // ],

        'stderr' => [
            'driver' => 'monolog',
            'level' => env('LOG_LEVEL', 'debug'),
            'handler' => StreamHandler::class,
            'formatter' => env('LOG_STDERR_FORMATTER'),
            'with' => [
                'stream' => 'php://stderr',
            ],
            'processors' => [PsrLogMessageProcessor::class],
        ],

        'syslog' => [
            'driver' => 'syslog',
            'level' => env('LOG_LEVEL', 'debug'),
            'facility' => env('LOG_SYSLOG_FACILITY', LOG_USER),
            'replace_placeholders' => true,
        ],

        'errorlog' => [
            'driver' => 'errorlog',
            'level' => env('LOG_LEVEL', 'debug'),
            'replace_placeholders' => true,
        ],

        'null' => [
            'driver' => 'monolog',
            'handler' => NullHandler::class,
        ],

        'emergency' => [
            'path' => storage_path('logs/laravel.log'),
        ],

        // Logs business/analytics (événements clés pour dashboard)
        'business' => [
            'driver' => 'daily',
            'path' => storage_path('logs/business.log'),
            'level' => 'info',
            'days' => 90,
        ],
    ],

];
