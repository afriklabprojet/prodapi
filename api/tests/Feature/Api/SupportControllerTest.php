<?php

namespace Tests\Feature\Api;

use App\Models\Customer;
use App\Models\SupportTicket;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SupportControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->user->id]);
    }

    public function test_user_can_list_tickets(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/support/tickets');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_user_can_create_ticket(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/support/tickets', [
            'subject' => 'Problème de paiement',
            'description' => 'Mon paiement n\'a pas été pris en compte.',
            'category' => 'payment',
        ]);

        $response->assertStatus(201)->assertJsonPath('success', true);
        $this->assertDatabaseHas('support_tickets', [
            'user_id' => $this->user->id,
            'category' => 'payment',
            'status' => 'open',
        ]);
    }

    public function test_create_ticket_validates_subject(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/support/tickets', [
            'description' => 'Test description',
            'category' => 'payment',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('subject');
    }

    public function test_create_ticket_validates_category(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/support/tickets', [
            'subject' => 'Test',
            'description' => 'Test description',
            'category' => 'invalid',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('category');
    }

    public function test_user_can_view_own_ticket(): void
    {
        $ticket = SupportTicket::create([
            'user_id' => $this->user->id,
            'subject' => 'Test',
            'description' => 'Test description',
            'category' => 'payment',
            'priority' => 'medium',
            'status' => 'open',
        ]);

        $response = $this->actingAs($this->user)->getJson("/api/support/tickets/{$ticket->id}");

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_user_cannot_view_others_ticket(): void
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        $ticket = SupportTicket::create([
            'user_id' => $otherUser->id,
            'subject' => 'Test',
            'description' => 'Test',
            'category' => 'payment',
            'priority' => 'medium',
            'status' => 'open',
        ]);

        $response = $this->actingAs($this->user)->getJson("/api/support/tickets/{$ticket->id}");

        $response->assertStatus(404);
    }

    public function test_user_can_send_message_to_ticket(): void
    {
        $ticket = SupportTicket::create([
            'user_id' => $this->user->id,
            'subject' => 'Test',
            'description' => 'Test',
            'category' => 'payment',
            'priority' => 'medium',
            'status' => 'open',
        ]);

        $response = $this->actingAs($this->user)->postJson("/api/support/tickets/{$ticket->id}/messages", [
            'message' => 'Avez-vous reçu ma demande ?',
        ]);

        $response->assertSuccessful()->assertJsonPath('success', true);
    }

    public function test_unauthenticated_cannot_access_support(): void
    {
        $response = $this->getJson('/api/support/tickets');

        $response->assertStatus(401);
    }
}
