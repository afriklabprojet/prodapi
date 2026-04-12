<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

/**
 * Service de logging structuré pour les actions sensibles.
 * Tous les logs sont structurés (JSON) avec des champs standards.
 * Prêt pour ingestion Sentry / ELK / Datadog.
 */
class AuditLogService
{
    /**
     * Log une action de paiement
     */
    public static function payment(string $action, array $context = []): void
    {
        Log::channel('payment')->info("[PAYMENT] {$action}", array_merge([
            'timestamp' => now()->toIso8601String(),
            'category' => 'payment',
        ], $context));
    }

    /**
     * Log une action financière (wallet, retrait, commission)
     */
    public static function financial(string $action, array $context = []): void
    {
        Log::channel('payment')->info("[FINANCIAL] {$action}", array_merge([
            'timestamp' => now()->toIso8601String(),
            'category' => 'financial',
        ], $context));
    }

    /**
     * Log une action de sécurité (login, permission, fraude)
     */
    public static function security(string $action, array $context = []): void
    {
        Log::channel('security')->warning("[SECURITY] {$action}", array_merge([
            'timestamp' => now()->toIso8601String(),
            'category' => 'security',
        ], $context));
    }

    /**
     * Log une alerte critique (fraude, incohérence montant, paiement suspect)
     */
    public static function critical(string $action, array $context = []): void
    {
        Log::channel('security')->critical("[CRITICAL] {$action}", array_merge([
            'timestamp' => now()->toIso8601String(),
            'category' => 'critical',
        ], $context));

        // Prêt pour Sentry
        if (app()->bound('sentry')) {
            \Sentry\captureMessage("[CRITICAL] {$action}", \Sentry\Severity::fatal(), $context);
        }
    }

    /**
     * Log une action webhook
     */
    public static function webhook(string $action, array $context = []): void
    {
        Log::channel('payment')->info("[WEBHOOK] {$action}", array_merge([
            'timestamp' => now()->toIso8601String(),
            'category' => 'webhook',
        ], $context));
    }

    /**
     * Log une tentative suspecte
     */
    public static function suspicious(string $action, array $context = []): void
    {
        Log::channel('security')->warning("[SUSPICIOUS] {$action}", array_merge([
            'timestamp' => now()->toIso8601String(),
            'category' => 'suspicious',
            'ip' => request()?->ip(),
            'user_agent' => request()?->userAgent(),
        ], $context));
    }
}
