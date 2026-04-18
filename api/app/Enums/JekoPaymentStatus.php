<?php

namespace App\Enums;

enum JekoPaymentStatus: string
{
    case PENDING = 'pending';
    case PROCESSING = 'processing';
    case SUCCESS = 'success';
    case FAILED = 'failed';
    case EXPIRED = 'expired';

    public function label(): string
    {
        return match ($this) {
            self::PENDING => 'En attente',
            self::PROCESSING => 'En cours',
            self::SUCCESS => 'Réussi',
            self::FAILED => 'Échoué',
            self::EXPIRED => 'Expiré',
        };
    }

    public function color(): string
    {
        return match ($this) {
            self::PENDING => 'warning',
            self::PROCESSING => 'info',
            self::SUCCESS => 'success',
            self::FAILED => 'danger',
            self::EXPIRED => 'gray',
        };
    }

    /**
     * Vérifie si le statut est final (ne changera plus)
     */
    public function isFinal(): bool
    {
        return in_array($this, [self::SUCCESS, self::FAILED, self::EXPIRED]);
    }

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
