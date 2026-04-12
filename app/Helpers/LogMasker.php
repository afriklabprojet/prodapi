<?php

namespace App\Helpers;

class LogMasker
{
    private const SENSITIVE_KEYWORDS = [
        'email', 'phone', 'password', 'token', 'api_key', 'otp', 'verification_code',
    ];

    public static function mask(array $data): array
    {
        $masked = [];

        foreach ($data as $key => $value) {
            if (is_array($value)) {
                $masked[$key] = self::mask($value);
                continue;
            }

            if (self::isSensitive($key)) {
                if (is_null($value)) {
                    $masked[$key] = '[null]';
                } elseif ($value === '') {
                    $masked[$key] = '[empty]';
                } elseif (self::matchesKeyword($key, 'email')) {
                    $masked[$key] = self::maskEmail((string) $value);
                } elseif (self::matchesKeyword($key, 'phone')) {
                    $masked[$key] = self::maskPhone((string) $value);
                } else {
                    $masked[$key] = '***';
                }
            } else {
                $masked[$key] = $value;
            }
        }

        return $masked;
    }

    public static function maskEmail(string $email): string
    {
        if (!str_contains($email, '@')) {
            return '***';
        }

        [$local, $domain] = explode('@', $email, 2);
        $parts = explode('.', $domain);
        $tld = end($parts);
        $maskedLocal = mb_strlen($local) >= 3 ? mb_substr($local, 0, 3) . '***' : $local . '***';

        return $maskedLocal . '@***.' . $tld;
    }

    public static function maskPhone(string $phone): string
    {
        if (mb_strlen($phone) < 5) {
            return '****';
        }

        $prefix = mb_substr($phone, 0, 5);
        $suffix = mb_substr($phone, -4);

        return $prefix . '***' . $suffix;
    }

    private static function isSensitive(string $key): bool
    {
        $lowerKey = strtolower($key);

        foreach (self::SENSITIVE_KEYWORDS as $keyword) {
            if (str_contains($lowerKey, $keyword)) {
                return true;
            }
        }

        return false;
    }

    private static function matchesKeyword(string $key, string $keyword): bool
    {
        return str_contains(strtolower($key), $keyword);
    }
}
