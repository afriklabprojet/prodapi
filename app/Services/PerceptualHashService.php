<?php

namespace App\Services;

/**
 * Calcule un perceptual hash (dHash) 64 bits d'une image.
 *
 * Principe :
 *  1. Image redimensionnée en 9x8 niveaux de gris.
 *  2. Pour chaque ligne, on compare chaque pixel à son voisin de droite : 1 si plus clair, 0 sinon.
 *  3. On obtient 8 lignes × 8 bits = 64 bits → encodés en hex (16 chars).
 *
 * Deux images sont considérées « visuellement identiques » si la distance de Hamming
 * entre leurs hash est ≤ 10 (sur 64). Robuste à la luminosité, au léger recadrage
 * et au bruit de re-photo, contrairement à un hash cryptographique (SHA-256).
 */
class PerceptualHashService
{
    public const SIMILAR_THRESHOLD = 10;

    /**
     * Calcule le dHash hex (16 chars) d'une image.
     *
     * @param string $imageBinary Contenu binaire (jpeg/png/gif/webp).
     * @return string|null Hash hex 16 chars ou null si l'image est illisible.
     */
    public function dhash(string $imageBinary): ?string
    {
        if (!function_exists('imagecreatefromstring')) {
            return null;
        }

        $src = @imagecreatefromstring($imageBinary);
        if ($src === false) {
            return null;
        }

        try {
            $resized = imagecreatetruecolor(9, 8);
            if ($resized === false) {
                return null;
            }

            imagecopyresampled($resized, $src, 0, 0, 0, 0, 9, 8, imagesx($src), imagesy($src));

            // Convertir en niveaux de gris en lisant chaque pixel.
            $bits = '';
            for ($y = 0; $y < 8; $y++) {
                for ($x = 0; $x < 8; $x++) {
                    $left = $this->grayAt($resized, $x, $y);
                    $right = $this->grayAt($resized, $x + 1, $y);
                    $bits .= ($left < $right) ? '1' : '0';
                }
            }

            imagedestroy($resized);

            // 64 bits → 16 chars hex
            $hex = '';
            foreach (str_split($bits, 4) as $nibble) {
                $hex .= dechex(bindec($nibble));
            }

            return $hex;
        } finally {
            imagedestroy($src);
        }
    }

    /**
     * Distance de Hamming entre deux hash hex 16 chars (0–64).
     */
    public function hammingDistance(string $hexA, string $hexB): int
    {
        if (strlen($hexA) !== 16 || strlen($hexB) !== 16) {
            return 64;
        }

        $a = hexdec(substr($hexA, 0, 8)) << 32 | hexdec(substr($hexA, 8, 8));
        $b = hexdec(substr($hexB, 0, 8)) << 32 | hexdec(substr($hexB, 8, 8));

        $xor = $a ^ $b;
        $distance = 0;
        while ($xor !== 0) {
            $distance += $xor & 1;
            $xor = ($xor >> 1) & PHP_INT_MAX; // shift logique
        }

        return $distance;
    }

    /**
     * Cherche parmi une collection de hash celui qui est le plus proche (≤ threshold).
     *
     * @param string $candidate    Hex 16 chars de l'image testée.
     * @param iterable<array{id:int,hash:string}> $known Liste {id,hash}.
     * @param int $threshold       Distance maximale acceptée.
     * @return array{id:int,distance:int}|null
     */
    public function findClosest(string $candidate, iterable $known, int $threshold = self::SIMILAR_THRESHOLD): ?array
    {
        $best = null;
        foreach ($known as $row) {
            if (empty($row['hash'])) {
                continue;
            }
            $d = $this->hammingDistance($candidate, $row['hash']);
            if ($d <= $threshold && ($best === null || $d < $best['distance'])) {
                $best = ['id' => (int) $row['id'], 'distance' => $d];
                if ($d === 0) {
                    break;
                }
            }
        }
        return $best;
    }

    private function grayAt(\GdImage $img, int $x, int $y): int
    {
        $rgb = imagecolorat($img, $x, $y);
        $r = ($rgb >> 16) & 0xFF;
        $g = ($rgb >> 8) & 0xFF;
        $b = $rgb & 0xFF;
        // Pondération luminance ITU-R BT.601
        return (int) round(0.299 * $r + 0.587 * $g + 0.114 * $b);
    }
}
