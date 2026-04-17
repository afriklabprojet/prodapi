<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

class AppVersionControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_version_check_requires_app_field(): void
    {
        $response = $this->getJson('/api/app/version-check');
        $response->assertStatus(422);
    }

    public function test_version_check_requires_version_field(): void
    {
        $response = $this->getJson('/api/app/version-check?app=client');
        $response->assertStatus(422);
    }

    public function test_version_check_requires_platform_field(): void
    {
        $response = $this->getJson('/api/app/version-check?app=client&version=1.0.0');
        $response->assertStatus(422);
    }

    public function test_version_check_rejects_invalid_app(): void
    {
        $response = $this->getJson('/api/app/version-check?app=invalid&version=1.0.0&platform=android');
        $response->assertStatus(422);
    }

    public function test_version_check_rejects_invalid_platform(): void
    {
        $response = $this->getJson('/api/app/version-check?app=client&version=1.0.0&platform=windows');
        $response->assertStatus(422);
    }

    public function test_version_check_returns_correct_structure(): void
    {
        $response = $this->getJson('/api/app/version-check?app=client&version=1.0.0&platform=android');

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'success',
                'data' => [
                    'force_update',
                    'update_available',
                    'min_version',
                    'latest_version',
                    'current_version',
                    'store_url',
                ],
            ]);
    }

    public function test_version_check_for_delivery_app(): void
    {
        $response = $this->getJson('/api/app/version-check?app=delivery&version=1.0.0&platform=ios');

        $response->assertStatus(200)
            ->assertJsonPath('data.current_version', '1.0.0');
    }

    public function test_version_check_for_pharmacy_app(): void
    {
        $response = $this->getJson('/api/app/version-check?app=pharmacy&version=2.0.0&platform=android');

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_features_requires_app(): void
    {
        $response = $this->getJson('/api/app/features');
        $response->assertStatus(422);
    }

    public function test_features_rejects_invalid_app(): void
    {
        $response = $this->getJson('/api/app/features?app=invalid');
        $response->assertStatus(422);
    }

    public function test_features_returns_success(): void
    {
        $response = $this->getJson('/api/app/features?app=client');

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'data']);
    }

    public function test_features_for_delivery_app(): void
    {
        $response = $this->getJson('/api/app/features?app=delivery');

        $response->assertStatus(200)
            ->assertJson(['success' => true]);
    }
}
