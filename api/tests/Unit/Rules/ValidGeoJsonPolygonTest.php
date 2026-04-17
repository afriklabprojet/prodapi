<?php

namespace Tests\Unit\Rules;

use App\Rules\ValidGeoJsonPolygon;
use Tests\TestCase;

class ValidGeoJsonPolygonTest extends TestCase
{
    private ValidGeoJsonPolygon $rule;

    protected function setUp(): void
    {
        parent::setUp();
        $this->rule = new ValidGeoJsonPolygon();
    }

    public function test_valid_polygon_passes(): void
    {
        $polygon = [
            ['lat' => 5.3, 'lng' => -4.0],
            ['lat' => 5.35, 'lng' => -3.95],
            ['lat' => 5.32, 'lng' => -3.9],
            ['lat' => 5.3, 'lng' => -4.0],
        ];

        $errors = [];
        $this->rule->validate('polygon', $polygon, function ($msg) use (&$errors) {
            $errors[] = $msg;
        });

        $this->assertEmpty($errors);
    }

    public function test_fails_when_not_array(): void
    {
        $errors = [];
        $this->rule->validate('polygon', 'not an array', function ($msg) use (&$errors) {
            $errors[] = $msg;
        });

        $this->assertNotEmpty($errors);
    }

    public function test_fails_with_too_few_points(): void
    {
        $polygon = [
            ['lat' => 5.3, 'lng' => -4.0],
            ['lat' => 5.35, 'lng' => -3.95],
        ];

        $errors = [];
        $this->rule->validate('polygon', $polygon, function ($msg) use (&$errors) {
            $errors[] = $msg;
        });

        $this->assertNotEmpty($errors);
        $this->assertStringContainsString('au moins', $errors[0]);
    }

    public function test_fails_with_too_many_points(): void
    {
        $rule = new ValidGeoJsonPolygon(3, 5);
        $polygon = array_map(fn($i) => ['lat' => 5.3 + $i * 0.01, 'lng' => -4.0 + $i * 0.01], range(0, 6));

        $errors = [];
        $rule->validate('polygon', $polygon, function ($msg) use (&$errors) {
            $errors[] = $msg;
        });

        $this->assertNotEmpty($errors);
    }

    public function test_fails_with_invalid_point_structure(): void
    {
        $polygon = [
            ['lat' => 5.3, 'lng' => -4.0],
            ['x' => 5.35, 'y' => -3.95],
            ['lat' => 5.32, 'lng' => -3.9],
        ];

        $errors = [];
        $this->rule->validate('polygon', $polygon, function ($msg) use (&$errors) {
            $errors[] = $msg;
        });

        $this->assertNotEmpty($errors);
        $this->assertStringContainsString('valide', $errors[0]);
    }

    public function test_fails_with_out_of_bounds_latitude(): void
    {
        $polygon = [
            ['lat' => 95, 'lng' => -4.0],
            ['lat' => 5.35, 'lng' => -3.95],
            ['lat' => 5.32, 'lng' => -3.9],
        ];

        $errors = [];
        $this->rule->validate('polygon', $polygon, function ($msg) use (&$errors) {
            $errors[] = $msg;
        });

        $this->assertNotEmpty($errors);
        $this->assertStringContainsString('latitude', $errors[0]);
    }

    public function test_fails_with_out_of_bounds_longitude(): void
    {
        $polygon = [
            ['lat' => 5.3, 'lng' => -200],
            ['lat' => 5.35, 'lng' => -3.95],
            ['lat' => 5.32, 'lng' => -3.9],
        ];

        $errors = [];
        $this->rule->validate('polygon', $polygon, function ($msg) use (&$errors) {
            $errors[] = $msg;
        });

        $this->assertNotEmpty($errors);
        $this->assertStringContainsString('longitude', $errors[0]);
    }

    public function test_fails_with_duplicate_consecutive_points(): void
    {
        $polygon = [
            ['lat' => 5.3, 'lng' => -4.0],
            ['lat' => 5.3, 'lng' => -4.0],
            ['lat' => 5.35, 'lng' => -3.95],
            ['lat' => 5.32, 'lng' => -3.9],
        ];

        $errors = [];
        $this->rule->validate('polygon', $polygon, function ($msg) use (&$errors) {
            $errors[] = $msg;
        });

        $this->assertNotEmpty($errors);
        $this->assertStringContainsString('identiques', $errors[0]);
    }

    public function test_fails_when_not_closed_and_auto_close_disabled(): void
    {
        $rule = new ValidGeoJsonPolygon(3, 1000, false);
        $polygon = [
            ['lat' => 5.3, 'lng' => -4.0],
            ['lat' => 5.35, 'lng' => -3.95],
            ['lat' => 5.32, 'lng' => -3.9],
        ];

        $errors = [];
        $rule->validate('polygon', $polygon, function ($msg) use (&$errors) {
            $errors[] = $msg;
        });

        $this->assertNotEmpty($errors);
        $this->assertStringContainsString('fermé', $errors[0]);
    }

    public function test_ensure_closed_adds_closing_point(): void
    {
        $points = [
            ['lat' => 5.3, 'lng' => -4.0],
            ['lat' => 5.35, 'lng' => -3.95],
            ['lat' => 5.32, 'lng' => -3.9],
        ];

        $closed = ValidGeoJsonPolygon::ensureClosed($points);

        $this->assertCount(4, $closed);
        $this->assertEquals($closed[0], $closed[3]);
    }

    public function test_ensure_closed_does_not_duplicate_if_already_closed(): void
    {
        $points = [
            ['lat' => 5.3, 'lng' => -4.0],
            ['lat' => 5.35, 'lng' => -3.95],
            ['lat' => 5.32, 'lng' => -3.9],
            ['lat' => 5.3, 'lng' => -4.0],
        ];

        $closed = ValidGeoJsonPolygon::ensureClosed($points);

        $this->assertCount(4, $closed);
    }

    public function test_ensure_closed_returns_short_arrays_unchanged(): void
    {
        $points = [['lat' => 5.3, 'lng' => -4.0], ['lat' => 5.35, 'lng' => -3.95]];
        $result = ValidGeoJsonPolygon::ensureClosed($points);
        $this->assertCount(2, $result);
    }

    public function test_fails_with_degenerate_polygon(): void
    {
        // All points on a line (zero area)
        $polygon = [
            ['lat' => 5.3, 'lng' => -4.0],
            ['lat' => 5.3, 'lng' => -3.95],
            ['lat' => 5.3, 'lng' => -3.9],
            ['lat' => 5.3, 'lng' => -4.0],
        ];

        $errors = [];
        $this->rule->validate('polygon', $polygon, function ($msg) use (&$errors) {
            $errors[] = $msg;
        });

        $this->assertNotEmpty($errors);
    }

    public function test_non_numeric_coordinates_fail(): void
    {
        $polygon = [
            ['lat' => 'abc', 'lng' => -4.0],
            ['lat' => 5.35, 'lng' => -3.95],
            ['lat' => 5.32, 'lng' => -3.9],
        ];

        $errors = [];
        $this->rule->validate('polygon', $polygon, function ($msg) use (&$errors) {
            $errors[] = $msg;
        });

        $this->assertNotEmpty($errors);
    }
}
