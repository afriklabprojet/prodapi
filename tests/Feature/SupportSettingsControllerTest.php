<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

class SupportSettingsControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_index_returns_support_settings(): void
    {
        $response = $this->getJson('/api/support/settings');

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'support_phone',
                    'support_email',
                    'support_whatsapp',
                    'website_url',
                    'terms_url',
                    'privacy_url',
                ],
            ]);
    }

    public function test_courier_faq_returns_faq_data(): void
    {
        $response = $this->getJson('/api/support/faq/courier');

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'data']);

        $data = $response->json('data');
        $this->assertIsArray($data);
        $this->assertNotEmpty($data);

        // Check FAQ structure
        $first = $data[0];
        $this->assertArrayHasKey('question', $first);
        $this->assertArrayHasKey('answer', $first);
    }

    public function test_customer_faq_returns_faq_data(): void
    {
        $response = $this->getJson('/api/support/faq/customer');

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'data']);

        $data = $response->json('data');
        $this->assertIsArray($data);
        $this->assertNotEmpty($data);
    }
}
