<?php

namespace Tests\Unit\Services;

use App\Services\GoogleMapsService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GoogleMapsServiceTest extends TestCase
{
    private GoogleMapsService $service;

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.google_maps.key' => 'test-api-key']);
        $this->service = new GoogleMapsService();
    }

    public function test_get_distance_matrix_returns_data_on_success(): void
    {
        Cache::shouldReceive('remember')
            ->once()
            ->andReturnUsing(function ($key, $ttl, $callback) {
                return $callback();
            });

        Http::fake([
            'maps.googleapis.com/maps/api/distancematrix/*' => Http::response([
                'status' => 'OK',
                'rows' => [[
                    'elements' => [[
                        'status' => 'OK',
                        'distance' => ['value' => 5000, 'text' => '5 km'],
                        'duration' => ['value' => 600, 'text' => '10 min'],
                    ]],
                ]],
            ]),
        ]);

        $result = $this->service->getDistanceMatrix(5.3, -4.0, 5.35, -3.95);

        $this->assertNotNull($result);
        $this->assertEquals(5.0, $result['distance_km']);
        $this->assertEquals(10.0, $result['duration_minutes']);
        $this->assertEquals('5 km', $result['distance_text']);
        $this->assertEquals('10 min', $result['duration_text']);
    }

    public function test_get_distance_matrix_returns_null_on_api_error(): void
    {
        Cache::shouldReceive('remember')
            ->once()
            ->andReturnUsing(function ($key, $ttl, $callback) {
                return $callback();
            });

        Http::fake([
            'maps.googleapis.com/*' => Http::response(['status' => 'REQUEST_DENIED'], 200),
        ]);

        $result = $this->service->getDistanceMatrix(5.3, -4.0, 5.35, -3.95);
        $this->assertNull($result);
    }

    public function test_get_distance_matrix_returns_null_on_http_failure(): void
    {
        Cache::shouldReceive('remember')
            ->once()
            ->andReturnUsing(function ($key, $ttl, $callback) {
                return $callback();
            });

        Http::fake([
            'maps.googleapis.com/*' => Http::response('Server Error', 500),
        ]);

        $result = $this->service->getDistanceMatrix(5.3, -4.0, 5.35, -3.95);
        $this->assertNull($result);
    }

    public function test_get_batch_distances_returns_empty_for_no_destinations(): void
    {
        $result = $this->service->getBatchDistances(5.3, -4.0, []);
        $this->assertEmpty($result);
    }

    public function test_get_batch_distances_processes_destinations(): void
    {
        Http::fake([
            'maps.googleapis.com/maps/api/distancematrix/*' => Http::response([
                'status' => 'OK',
                'rows' => [[
                    'elements' => [
                        [
                            'status' => 'OK',
                            'distance' => ['value' => 3000, 'text' => '3 km'],
                            'duration' => ['value' => 300, 'text' => '5 min'],
                        ],
                    ],
                ]],
            ]),
        ]);

        $result = $this->service->getBatchDistances(5.3, -4.0, [[5.35, -3.95]]);
        $this->assertCount(1, $result);
        $this->assertEquals(3.0, $result[0]['distance_km']);
    }

    public function test_get_directions_returns_route_data(): void
    {
        Http::fake([
            'maps.googleapis.com/maps/api/directions/*' => Http::response([
                'status' => 'OK',
                'routes' => [[
                    'overview_polyline' => ['points' => 'encoded_polyline'],
                    'waypoint_order' => [],
                    'legs' => [[
                        'start_address' => 'Origin',
                        'end_address' => 'Destination',
                        'distance' => ['value' => 5000, 'text' => '5 km'],
                        'duration' => ['value' => 600, 'text' => '10 min'],
                    ]],
                ]],
            ]),
        ]);

        $result = $this->service->getDirections(5.3, -4.0, 5.35, -3.95);

        $this->assertNotNull($result);
        $this->assertEquals(5.0, $result['total_distance_km']);
        $this->assertEquals(10.0, $result['total_duration_minutes']);
        $this->assertEquals('encoded_polyline', $result['polyline']);
        $this->assertCount(1, $result['legs']);
    }

    public function test_get_directions_returns_null_on_failure(): void
    {
        Http::fake([
            'maps.googleapis.com/*' => Http::response(['status' => 'ZERO_RESULTS'], 200),
        ]);

        $result = $this->service->getDirections(5.3, -4.0, 5.35, -3.95);
        $this->assertNull($result);
    }

    public function test_geocode_returns_coordinates(): void
    {
        Cache::shouldReceive('remember')
            ->once()
            ->andReturnUsing(function ($key, $ttl, $callback) {
                return $callback();
            });

        Http::fake([
            'maps.googleapis.com/maps/api/geocode/*' => Http::response([
                'status' => 'OK',
                'results' => [[
                    'geometry' => [
                        'location' => ['lat' => 5.3, 'lng' => -4.0],
                    ],
                    'formatted_address' => 'Abidjan, Côte d\'Ivoire',
                ]],
            ]),
        ]);

        $result = $this->service->geocode('Abidjan');
        $this->assertNotNull($result);
        $this->assertEquals(5.3, $result['latitude']);
        $this->assertEquals(-4.0, $result['longitude']);
    }

    public function test_reverse_geocode_returns_address(): void
    {
        Cache::shouldReceive('remember')
            ->once()
            ->andReturnUsing(function ($key, $ttl, $callback) {
                return $callback();
            });

        Http::fake([
            'maps.googleapis.com/maps/api/geocode/*' => Http::response([
                'status' => 'OK',
                'results' => [[
                    'formatted_address' => 'Plateau, Abidjan',
                ]],
            ]),
        ]);

        $result = $this->service->reverseGeocode(5.3, -4.0);
        $this->assertEquals('Plateau, Abidjan', $result);
    }
}
