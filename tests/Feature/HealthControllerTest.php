<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

class HealthControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_health_check_returns_healthy(): void
    {
        $response = $this->getJson('/api/health');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'status' => 'healthy',
            ])
            ->assertJsonStructure([
                'success', 'status', 'version', 'checks' => ['database', 'cache'], 'timestamp',
            ]);
    }

    public function test_health_check_includes_queue_info(): void
    {
        $response = $this->getJson('/api/health');
        $data = $response->json();

        // Queue check depends on jobs table existing
        $this->assertArrayHasKey('queue', $data['checks']);
    }

    public function test_health_check_audit_pharmacies_mode(): void
    {
        $response = $this->getJson('/api/health?audit=pharmacies');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'total_pharmacies',
                'approved_count',
                'pending_count',
                'rejected_count',
                'pharmacies',
            ]);
    }
}
