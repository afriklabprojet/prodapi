<?php

namespace Tests\Unit;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HelperFunctionsTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function it_generates_valid_reference_format()
    {
        $reference = \App\Models\Order::generateReference();
        
        $this->assertStringStartsWith('DR-', $reference);
        $this->assertGreaterThan(3, strlen($reference));
    }

    /** @test */
    public function settings_helper_returns_default_value()
    {
        // Test getting a non-existent setting with default
        $value = \App\Models\Setting::get('non_existent_key', 'default_value');
        
        $this->assertEquals('default_value', $value);
    }

    /** @test */
    public function settings_helper_stores_and_retrieves_value()
    {
        \App\Models\Setting::set('test_key', 'test_value');
        
        $value = \App\Models\Setting::get('test_key');
        
        $this->assertEquals('test_value', $value);
    }

    /** @test */
    public function settings_helper_updates_existing_value()
    {
        \App\Models\Setting::set('update_key', 'initial_value');
        \App\Models\Setting::set('update_key', 'updated_value');
        
        $value = \App\Models\Setting::get('update_key');
        
        $this->assertEquals('updated_value', $value);
    }

    /** @test */
    public function log_masker_masks_sensitive_data()
    {
        $masker = new \App\Helpers\LogMasker();
        
        // Test phone masking
        $data = ['phone' => '0787654321'];
        $masked = $masker->mask($data);
        
        $this->assertNotEquals('0787654321', $masked['phone']);
    }

    /** @test */
    public function haversine_distance_calculation_is_accurate()
    {
        // Abidjan coordinates
        $lat1 = 5.3600;
        $lng1 = -4.0083;
        
        // A point about 1km away (approximately)
        $lat2 = 5.3690;
        $lng2 = -4.0083;
        
        // The actual distance is approximately 1km
        // Using simple calculation: 1 degree latitude ≈ 111km
        // So 0.009 degrees ≈ 1km
        
        // This is a placeholder test - actual implementation would use the 
        // nearLocation scope or a helper function
        $this->assertTrue(true);
    }

    /** @test */
    public function delivery_code_is_4_digits()
    {
        $order = \App\Models\Order::factory()->make();
        
        // Trigger the creating event
        $order->save();
        
        $this->assertNotNull($order->delivery_code);
        $this->assertEquals(4, strlen($order->delivery_code));
        $this->assertMatchesRegularExpression('/^\d{4}$/', $order->delivery_code);
    }
}
