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
     * Seuil pour aHash - plus tolérant car sensible aux variations
     */
    public const AHASH_THRESHOLD = 12;

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
     * Calcule le aHash (Average Hash) - meilleur pour documents manuscrits.
     * 
     * Compare chaque pixel à la moyenne globale de l'image.
     * Plus robuste aux variations de contraste/luminosité que dHash.
     *
     * @param string $imageBinary Contenu binaire (jpeg/png/gif/webp).
     * @return string|null Hash hex 16 chars ou null si l'image est illisible.
     */
    public function ahash(string $imageBinary): ?string
    {
        if (!function_exists('imagecreatefromstring')) {
            return null;
        }

        $src = @imagecreatefromstring($imageBinary);
        if ($src === false) {
            return null;
        }

        try {
            $resized = imagecreatetruecolor(8, 8);
            if ($resized === false) {
                return null;
            }

            imagecopyresampled($resized, $src, 0, 0, 0, 0, 8, 8, imagesx($src), imagesy($src));

            // Calculer la moyenne des niveaux de gris
            $total = 0;
            $pixels = [];
            for ($y = 0; $y < 8; $y++) {
                for ($x = 0; $x < 8; $x++) {
                    $gray = $this->grayAt($resized, $x, $y);
                    $pixels[] = $gray;
                    $total += $gray;
                }
            }
            $average = $total / 64;

            imagedestroy($resized);

            // Comparer chaque pixel à la moyenne
            $bits = '';
            foreach ($pixels as $gray) {
                $bits .= ($gray >= $average) ? '1' : '0';
            }

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
     * Calcule le structure hash - détecte les zones d'encre/écriture.
     * 
     * Optimal pour ordonnances manuscrites au stylo BIC :
     * - Binarise l'image (encre vs papier)
     * - Découpe en grille 8x8
     * - 1 si zone contient de l'encre, 0 sinon
     *
     * @param string $imageBinary Contenu binaire.
     * @return string|null Hash hex 16 chars.
     */
    public function structureHash(string $imageBinary): ?string
    {
        if (!function_exists('imagecreatefromstring')) {
            return null;
        }

        $src = @imagecreatefromstring($imageBinary);
        if ($src === false) {
            return null;
        }

        try {
            $width = imagesx($src);
            $height = imagesy($src);
            
            // Calculer la moyenne globale pour le seuil de binarisation
            $total = 0;
            $count = 0;
            for ($y = 0; $y < $height; $y += 4) {
                for ($x = 0; $x < $width; $x += 4) {
                    $total += $this->grayAt($src, $x, $y);
                    $count++;
                }
            }
            $globalAvg = $total / max($count, 1);
            
            // Seuil adaptatif (encre BIC = plus foncé que papier)
            $threshold = $globalAvg * 0.7;

            // Découper en grille 8x8 et détecter les zones avec encre
            $cellW = $width / 8;
            $cellH = $height / 8;
            $bits = '';

            for ($cy = 0; $cy < 8; $cy++) {
                for ($cx = 0; $cx < 8; $cx++) {
                    $inkPixels = 0;
                    $totalPixels = 0;
                    
                    // Échantillonner la cellule
                    for ($y = (int)($cy * $cellH); $y < (int)(($cy + 1) * $cellH); $y += 2) {
                        for ($x = (int)($cx * $cellW); $x < (int)(($cx + 1) * $cellW); $x += 2) {
                            if ($x < $width && $y < $height) {
                                $gray = $this->grayAt($src, $x, $y);
                                if ($gray < $threshold) {
                                    $inkPixels++;
                                }
                                $totalPixels++;
                            }
                        }
                    }
                    
                    // Si plus de 5% de pixels encre dans la cellule
                    $bits .= ($totalPixels > 0 && ($inkPixels / $totalPixels) > 0.05) ? '1' : '0';
                }
            }

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
     * Calcule les 3 hashes d'une image.
     *
     * @param string $imageBinary Contenu binaire.
     * @return array{dhash:string|null, ahash:string|null, shash:string|null}
     */
    public function computeAllHashes(string $imageBinary): array
    {
        return [
            'dhash' => $this->dhash($imageBinary),
            'ahash' => $this->ahash($imageBinary),
            'shash' => $this->structureHash($imageBinary),
        ];
    }

    /**
     * Vérifie si deux images sont similaires en combinant plusieurs hashes.
     * 
     * Retourne true si AU MOINS 2 des 3 hashes correspondent.
     *
     * @param array $hashesA {dhash, ahash, shash}
     * @param array $hashesB {dhash, ahash, shash}
     * @return array{is_similar:bool, matches:int, details:array}
     */
    public function areSimilar(array $hashesA, array $hashesB): array
    {
        $matches = 0;
        $details = [];

        // dHash
        if (!empty($hashesA['dhash']) && !empty($hashesB['dhash'])) {
            $d = $this->hammingDistance($hashesA['dhash'], $hashesB['dhash']);
            $details['dhash'] = ['distance' => $d, 'match' => $d <= self::SIMILAR_THRESHOLD];
            if ($d <= self::SIMILAR_THRESHOLD) $matches++;
        }

        // aHash
        if (!empty($hashesA['ahash']) && !empty($hashesB['ahash'])) {
            $d = $this->hammingDistance($hashesA['ahash'], $hashesB['ahash']);
            $details['ahash'] = ['distance' => $d, 'match' => $d <= self::AHASH_THRESHOLD];
            if ($d <= self::AHASH_THRESHOLD) $matches++;
        }

        // Structure Hash
        if (!empty($hashesA['shash']) && !empty($hashesB['shash'])) {
            $d = $this->hammingDistance($hashesA['shash'], $hashesB['shash']);
            $details['shash'] = ['distance' => $d, 'match' => $d <= self::SIMILAR_THRESHOLD];
            if ($d <= self::SIMILAR_THRESHOLD) $matches++;
        }

        return [
            'is_similar' => $matches >= 2, // Au moins 2 hashes correspondent
            'matches' => $matches,
            'details' => $details,
        ];
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
