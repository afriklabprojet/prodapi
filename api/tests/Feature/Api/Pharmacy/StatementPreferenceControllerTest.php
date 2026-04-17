<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StatementPreferenceControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacy->users()->attach($this->user->id, ['role' => 'titulaire']);
    }

    public function test_pharmacy_can_view_statement_preferences(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/statement-preferences');

        $response->assertOk();
    }

    public function test_pharmacy_can_set_preferences(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/statement-preferences', [
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'pharmacie@example.com',
        ]);

        $response->assertSuccessful();
    }

    public function test_requires_valid_frequency(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/statement-preferences', [
            'frequency' => 'daily',
            'format' => 'pdf',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('frequency');
    }

    public function test_requires_valid_format(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/statement-preferences', [
            'frequency' => 'weekly',
            'format' => 'html',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('format');
    }

    public function test_pharmacy_can_disable_preferences(): void
    {
        $response = $this->actingAs($this->user)->deleteJson('/api/pharmacy/statement-preferences');

        $response->assertOk();
    }

    public function test_unauthenticated_cannot_access_preferences(): void
    {
        $response = $this->getJson('/api/pharmacy/statement-preferences');

        $response->assertStatus(401);
    }
}
