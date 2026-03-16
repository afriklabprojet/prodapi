<?php

namespace App\Enums;

enum JekoPaymentMethod: string
{
    // Côte d'Ivoire - Codes Jeko
    case WAVE = 'wave';
    case ORANGE = 'orange';
    case MTN = 'mtn';
    case MOOV = 'moov';
    case DJAMO = 'djamo';
    
    // Autres
    case BANK_TRANSFER = 'bank_transfer';

    public function label(): string
    {
        return match ($this) {
            self::WAVE => 'Wave',
            self::ORANGE => 'Orange Money',
            self::MTN => 'MTN Mobile Money',
            self::MOOV => 'Moov Money',
            self::DJAMO => 'Djamo',
            self::BANK_TRANSFER => 'Virement Bancaire',
        };
    }

    public function icon(): string
    {
        return match ($this) {
            self::WAVE => 'wave',
            self::ORANGE => 'orange-money',
            self::MTN => 'mtn-momo',
            self::MOOV => 'moov-money',
            self::DJAMO => 'djamo',
            self::BANK_TRANSFER => 'bank',
        };
    }

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
    
    /**
     * Méthodes disponibles pour les décaissements (payout)
     */
    public static function payoutMethods(): array
    {
        return [
            self::ORANGE,
            self::MTN,
            self::MOOV,
            self::WAVE,
            self::DJAMO,
            self::BANK_TRANSFER,
        ];
    }
    
    /**
     * Méthodes disponibles pour les paiements (encaissement)
     */
    public static function paymentMethods(): array
    {
        return [
            self::ORANGE,
            self::MTN,
            self::MOOV,
            self::WAVE,
            self::DJAMO,
        ];
    }
}
