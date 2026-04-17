<?php

namespace Tests\Feature;

use App\Models\Setting;
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

class PricingControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_index_returns_pricing_data(): void
    {
        $response = $this->getJson('/api/pricing');

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'delivery_base_fee',
                    'delivery_per_km',
                    'service_fee_percent',
                    'minimum_order',
                    'free_delivery_threshold',
                    'currency',
                    'payment_modes',
                ],
            ]);
    }

    public function test_index_returns_xof_currency(): void
    {
        $response = $this->getJson('/api/pricing');
        $response->assertJsonPath('data.currency', 'XOF');
    }

    public function test_calculate_requires_subtotal(): void
    {
        $response = $this->postJson('/api/pricing/calculate', []);
        $response->assertStatus(422);
    }

    public function test_calculate_rejects_negative_subtotal(): void
    {
        $response = $this->postJson('/api/pricing/calculate', ['subtotal' => -100]);
        $response->assertStatus(422);
    }

    public function test_calculate_returns_correct_structure(): void
    {
        $response = $this->postJson('/api/pricing/calculate', [
            'subtotal' => 5000,
            'distance_km' => 3,
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'subtotal',
                    'delivery_fee',
                    'service_fee',
                    'total',
                    'currency',
                ],
            ]);
    }

    public function test_calculate_without_distance(): void
    {
        $response = $this->postJson('/api/pricing/calculate', [
            'subtotal' => 10000,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_calculate_total_is_sum_of_parts(): void
    {
        $response = $this->postJson('/api/pricing/calculate', [
            'subtotal' => 10000,
            'distance_km' => 0,
        ]);

        $data = $response->json('data');
        $expectedTotal = $data['subtotal'] + $data['delivery_fee'] + $data['service_fee'];
        $this->assertEquals(round($expectedTotal), $data['total']);
    }

    public function test_estimate_delivery_requires_coordinates(): void
    {
        $response = $this->postJson('/api/pricing/delivery', []);
        $response->assertStatus(422);
    }

    public function test_estimate_delivery_returns_distance_and_fee(): void
    {
        $response = $this->postJson('/api/pricing/delivery', [
            'origin_lat' => 5.3600,
            'origin_lng' => -4.0083,
            'destination_lat' => 5.3200,
            'destination_lng' => -3.9900,
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'distance_km',
                    'estimated_fee',
                    'estimated_minutes',
                    'currency',
                ],
            ]);

        $data = $response->json('data');
        $this->assertGreaterThan(0, $data['distance_km']);
        $this->assertGreaterThan(0, $data['estimated_fee']);
        $this->assertGreaterThanOrEqual(10, $data['estimated_minutes']);
    }

    public function test_estimate_delivery_same_point_returns_small_distance(): void
    {
        $response = $this->postJson('/api/pricing/delivery', [
            'origin_lat' => 5.3600,
            'origin_lng' => -4.0083,
            'destination_lat' => 5.3600,
            'destination_lng' => -4.0083,
        ]);

        $data = $response->json('data');
        $this->assertEquals(0, $data['distance_km']);
    }
}
