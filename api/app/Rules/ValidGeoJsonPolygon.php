<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

/**
 * Validation rule for GeoJSON polygon coordinates
 * 
 * Ensures:
 * - Minimum 3 points
 * - Valid lat/lng bounds
 * - Polygon is properly closed (first point == last point)
 * - No duplicate consecutive points
 */
class ValidGeoJsonPolygon implements ValidationRule
{
    /**
     * Minimum number of points required for a valid polygon
     */
    protected int $minPoints;

    /**
     * Maximum number of points allowed
     */
    protected int $maxPoints;

    /**
     * Whether to auto-close the polygon (append first point at end)
     */
    protected bool $autoClose;

    public function __construct(int $minPoints = 3, int $maxPoints = 1000, bool $autoClose = true)
    {
        $this->minPoints = $minPoints;
        $this->maxPoints = $maxPoints;
        $this->autoClose = $autoClose;
    }

    /**
     * Run the validation rule.
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        // Must be an array
        if (!is_array($value)) {
            $fail('Le polygone doit être un tableau de coordonnées.');
            return;
        }

        $points = $value;

        // Check minimum points
        if (count($points) < $this->minPoints) {
            $fail("Le polygone doit contenir au moins {$this->minPoints} points.");
            return;
        }

        // Check maximum points
        if (count($points) > $this->maxPoints) {
            $fail("Le polygone ne peut pas contenir plus de {$this->maxPoints} points.");
            return;
        }

        // Validate each point
        foreach ($points as $index => $point) {
            if (!$this->isValidPoint($point)) {
                $fail("Le point à l'index {$index} n'est pas valide. Format attendu: {lat: number, lng: number}");
                return;
            }

            // Check lat bounds (-90 to 90)
            if ($point['lat'] < -90 || $point['lat'] > 90) {
                $fail("La latitude au point {$index} doit être entre -90 et 90.");
                return;
            }

            // Check lng bounds (-180 to 180)
            if ($point['lng'] < -180 || $point['lng'] > 180) {
                $fail("La longitude au point {$index} doit être entre -180 et 180.");
                return;
            }
        }

        // Check for duplicate consecutive points
        for ($i = 1; $i < count($points); $i++) {
            if ($this->pointsEqual($points[$i], $points[$i - 1])) {
                $fail("Les points aux index " . ($i - 1) . " et {$i} sont identiques.");
                return;
            }
        }

        // Check if polygon is closed (first == last)
        $first = $points[0];
        $last = $points[count($points) - 1];
        
        if (!$this->pointsEqual($first, $last) && !$this->autoClose) {
            $fail("Le polygone doit être fermé (premier point = dernier point).");
            return;
        }

        // Check minimum area (avoid degenerate polygons)
        if (!$this->hasMinimumArea($points)) {
            $fail("Le polygone est trop petit ou dégénéré (points colinéaires).");
            return;
        }
    }

    /**
     * Check if a point has valid structure
     */
    protected function isValidPoint(mixed $point): bool
    {
        if (!is_array($point)) {
            return false;
        }

        if (!isset($point['lat']) || !isset($point['lng'])) {
            return false;
        }

        if (!is_numeric($point['lat']) || !is_numeric($point['lng'])) {
            return false;
        }

        return true;
    }

    /**
     * Check if two points are equal (within tolerance)
     */
    protected function pointsEqual(array $p1, array $p2, float $tolerance = 0.0000001): bool
    {
        return abs($p1['lat'] - $p2['lat']) < $tolerance 
            && abs($p1['lng'] - $p2['lng']) < $tolerance;
    }

    /**
     * Check if polygon has minimum area (not degenerate)
     * Uses shoelace formula to calculate signed area
     */
    protected function hasMinimumArea(array $points, float $minArea = 0.0000001): bool
    {
        $n = count($points);
        if ($n < 3) {
            return false;
        }

        // Shoelace formula for signed area
        $area = 0;
        for ($i = 0; $i < $n; $i++) {
            $j = ($i + 1) % $n;
            $area += $points[$i]['lat'] * $points[$j]['lng'];
            $area -= $points[$j]['lat'] * $points[$i]['lng'];
        }
        $area = abs($area) / 2;

        return $area > $minArea;
    }

    /**
     * Auto-close polygon if needed (static helper)
     */
    public static function ensureClosed(array $points): array
    {
        if (count($points) < 3) {
            return $points;
        }

        $first = $points[0];
        $last = $points[count($points) - 1];

        // If not closed, append first point
        if (abs($first['lat'] - $last['lat']) > 0.0000001 
            || abs($first['lng'] - $last['lng']) > 0.0000001) {
            $points[] = $first;
        }

        return $points;
    }
}
