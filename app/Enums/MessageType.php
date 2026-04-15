<?php

namespace App\Enums;

enum MessageType: string
{
    case TEXT = 'text';
    case IMAGE = 'image';
    case FILE = 'file';
    case LOCATION = 'location';
    case SYSTEM = 'system';

    public function label(): string
    {
        return match ($this) {
            self::TEXT => 'Texte',
            self::IMAGE => 'Image',
            self::FILE => 'Fichier',
            self::LOCATION => 'Position',
            self::SYSTEM => 'Système',
        };
    }

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
