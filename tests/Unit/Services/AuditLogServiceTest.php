<?php

namespace Tests\Unit\Services;

use App\Services\AuditLogService;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class AuditLogServiceTest extends TestCase
{
    public function test_payment_logs_to_payment_channel(): void
    {
        Log::shouldReceive('channel')
            ->with('payment')
            ->once()
            ->andReturnSelf();
        Log::shouldReceive('info')
            ->once()
            ->withArgs(function ($message, $context) {
                return str_contains($message, '[PAYMENT]')
                    && str_contains($message, 'Test payment')
                    && $context['category'] === 'payment'
                    && isset($context['timestamp']);
            });

        AuditLogService::payment('Test payment', ['amount' => 1000]);
    }

    public function test_financial_logs_to_payment_channel(): void
    {
        Log::shouldReceive('channel')
            ->with('payment')
            ->once()
            ->andReturnSelf();
        Log::shouldReceive('info')
            ->once()
            ->withArgs(function ($message, $context) {
                return str_contains($message, '[FINANCIAL]')
                    && $context['category'] === 'financial';
            });

        AuditLogService::financial('Withdrawal processed', ['wallet_id' => 5]);
    }

    public function test_security_logs_to_security_channel(): void
    {
        Log::shouldReceive('channel')
            ->with('security')
            ->once()
            ->andReturnSelf();
        Log::shouldReceive('warning')
            ->once()
            ->withArgs(function ($message, $context) {
                return str_contains($message, '[SECURITY]')
                    && $context['category'] === 'security';
            });

        AuditLogService::security('Failed login attempt', ['ip' => '127.0.0.1']);
    }

    public function test_critical_logs_to_security_channel_with_critical_level(): void
    {
        Log::shouldReceive('channel')
            ->with('security')
            ->once()
            ->andReturnSelf();
        Log::shouldReceive('critical')
            ->once()
            ->withArgs(function ($message, $context) {
                return str_contains($message, '[CRITICAL]')
                    && $context['category'] === 'critical';
            });

        AuditLogService::critical('Fraud detected', ['order_id' => 42]);
    }

    public function test_webhook_logs_to_payment_channel(): void
    {
        Log::shouldReceive('channel')
            ->with('payment')
            ->once()
            ->andReturnSelf();
        Log::shouldReceive('info')
            ->once()
            ->withArgs(function ($message, $context) {
                return str_contains($message, '[WEBHOOK]')
                    && $context['category'] === 'webhook';
            });

        AuditLogService::webhook('Jeko callback received', ['reference' => 'REF123']);
    }

    public function test_suspicious_logs_to_security_channel_with_ip_and_user_agent(): void
    {
        Log::shouldReceive('channel')
            ->with('security')
            ->once()
            ->andReturnSelf();
        Log::shouldReceive('warning')
            ->once()
            ->withArgs(function ($message, $context) {
                return str_contains($message, '[SUSPICIOUS]')
                    && $context['category'] === 'suspicious'
                    && array_key_exists('ip', $context)
                    && array_key_exists('user_agent', $context);
            });

        AuditLogService::suspicious('Multiple failed attempts', ['user_id' => 10]);
    }

    public function test_payment_with_empty_context(): void
    {
        Log::shouldReceive('channel')
            ->with('payment')
            ->once()
            ->andReturnSelf();
        Log::shouldReceive('info')
            ->once()
            ->withArgs(function ($message, $context) {
                return str_contains($message, '[PAYMENT]')
                    && $context['category'] === 'payment'
                    && isset($context['timestamp']);
            });

        AuditLogService::payment('Simple log');
    }
}
