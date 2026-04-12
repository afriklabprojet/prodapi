<?php

namespace Tests\Feature\Api;

use App\Services\GoogleMapsService;
use App\Services\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;

class DeliveryPricingControllerTest extends TestCase
{
    use RefreshDatabase;
    public function test_get_pricing_returns_pricing_structure(): void
    {
        $response = $this->getJson('/api/delivery/pricing');

        $response->assertOk();
        $response->assertJsonStructure([
            'base_fee',
            'fee_per_km',
            'min_fee',
            'max_fee',
            'currency',
            'formula',
            'example' => ['distance_km', 'calculated_fee'],
        ]);
        $response->assertJson(['currency' => 'XOF']);
    }

    public function test_estimate_with_distance_km(): void
    {
        $response = $this->postJson('/api/delivery/estimate', [
                'distance_km' => 5.0,
            ]);

        $response->assertOk();
        $response->assertJsonStructure([
            'distance_km',
            'delivery_fee',
            'currency',
            'breakdown' => ['base_fee', 'distance_fee', 'raw_total'],
            'pricing',
        ]);
        $response->assertJson(['currency' => 'XOF', 'distance_source' => 'provided']);
    }

    public function test_estimate_requires_distance_or_coordinates(): void
    {
        $response = $this->postJson('/api/delivery/estimate', []);

        $response->assertStatus(422);
    }

    public function test_estimate_validates_distance_range(): void
    {
        $response = $this->postJson('/api/delivery/estimate', [
                'distance_km' => 200, // max is 100
            ]);

        $response->assertStatus(422);
    }

    public function test_estimate_validates_latitude_range(): void
    {
        $response = $this->postJson('/api/delivery/estimate', [
                'pharmacy_lat' => 200, // invalid lat
                'pharmacy_lng' => -4.008,
                'delivery_lat' => 5.316,
                'delivery_lng' => -4.012,
            ]);

        $response->assertStatus(422);
    }

    public function test_estimate_with_coordinates_uses_haversine_fallback(): void
    {
        // Mock GoogleMapsService to return null (force Haversine fallback)
        $mockMaps = Mockery::mock(GoogleMapsService::class);
        $mockMaps->shouldReceive('getDistanceMatrix')
            ->once()
            ->andReturn(null);

        $this->app->instance(GoogleMapsService::class, $mockMaps);

        $response = $this->postJson('/api/delivery/estimate', [
                'pharmacy_lat' => 5.360,
                'pharmacy_lng' => -4.008,
                'delivery_lat' => 5.316,
                'delivery_lng' => -4.012,
            ]);

        $response->assertOk();
        $response->assertJson(['distance_source' => 'haversine']);
    }

    public function test_estimate_with_coordinates_uses_google_when_available(): void
    {
        $mockMaps = Mockery::mock(GoogleMapsService::class);
        $mockMaps->shouldReceive('getDistanceMatrix')
            ->once()
            ->andReturn([
                'distance_km' => 7.5,
                'duration_minutes' => 15,
            ]);

        $this->app->instance(GoogleMapsService::class, $mockMaps);

        $response = $this->postJson('/api/delivery/estimate', [
                'pharmacy_lat' => 5.360,
                'pharmacy_lng' => -4.008,
                'delivery_lat' => 5.316,
                'delivery_lng' => -4.012,
            ]);

        $response->assertOk();
        $response->assertJson([
            'distance_source' => 'google_distance_matrix',
            'distance_km' => 7.5,
            'estimated_duration_minutes' => 15,
        ]);
    }
}
