<?php

namespace Tests\Feature\Api\Courier;

use App\Models\Courier;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SupportControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Courier $courier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create([
            'user_id' => $this->user->id,
        ]);
    }

    public function test_courier_can_report_problem(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/courier/report-problem', [
            'category' => 'delivery',
            'subject' => 'Problème de livraison',
            'description' => 'Le client était introuvable à l\'adresse indiquée.',
        ]);

        $response->assertStatus(201)->assertJsonPath('success', true);
        $this->assertDatabaseHas('support_tickets', [
            'user_id' => $this->user->id,
            'category' => 'delivery',
            'status' => 'open',
        ]);
    }

    public function test_report_validates_category(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/courier/report-problem', [
            'category' => 'invalid_category',
            'subject' => 'Test',
            'description' => 'Test description',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('category');
    }

    public function test_report_requires_subject(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/courier/report-problem', [
            'category' => 'payment',
            'description' => 'Test description',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('subject');
    }

    public function test_report_requires_description(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/courier/report-problem', [
            'category' => 'payment',
            'subject' => 'Test',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('description');
    }

    public function test_all_valid_categories_accepted(): void
    {
        foreach (['delivery', 'payment', 'app_bug', 'account', 'other'] as $category) {
            $response = $this->actingAs($this->user)->postJson('/api/courier/report-problem', [
                'category' => $category,
                'subject' => "Test $category",
                'description' => 'Test description for this category.',
            ]);

            $response->assertStatus(201);
        }
    }

    public function test_unauthenticated_cannot_report(): void
    {
        $response = $this->postJson('/api/courier/report-problem', [
            'category' => 'delivery',
            'subject' => 'Test',
            'description' => 'Test',
        ]);

        $response->assertStatus(401);
    }
}
