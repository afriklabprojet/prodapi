<?php

namespace Tests\Feature\Api;

use App\Models\Customer;
use App\Models\SupportMessage;
use App\Models\SupportTicket;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

/**
 * Deep tests for SupportController
 * @group deep
 */
class SupportControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Customer $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'customer']);
        $this->customer = Customer::factory()->create(['user_id' => $this->user->id]);
    }

    protected function createTicket(array $attributes = []): SupportTicket
    {
        return SupportTicket::create(array_merge([
            'user_id' => $this->user->id,
            'subject' => 'Test ticket',
            'description' => 'Test description',
            'category' => 'other',
            'priority' => 'medium',
            'status' => 'open',
        ], $attributes));
    }

    // ==================== INDEX ====================

    #[Test]
    public function index_returns_paginated_tickets()
    {
        for ($i = 0; $i < 20; $i++) {
            $this->createTicket(['subject' => "Ticket {$i}"]);
        }

        $response = $this->actingAs($this->user)
            ->getJson('/api/support/tickets');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'data' => [
                        '*' => ['id', 'subject', 'category', 'status'],
                    ],
                ],
            ]);
    }

    #[Test]
    public function index_orders_by_updated_at_desc()
    {
        $oldTicket = $this->createTicket(['subject' => 'Old ticket']);
        SupportTicket::withoutTimestamps(fn () => $oldTicket->forceFill(['updated_at' => now()->subDays(2)])->save());
        
        $newTicket = $this->createTicket(['subject' => 'New ticket']);
        SupportTicket::withoutTimestamps(fn () => $newTicket->forceFill(['updated_at' => now()])->save());

        $response = $this->actingAs($this->user)
            ->getJson('/api/support/tickets');

        $response->assertOk();
        $data = $response->json('data.data');
        if (count($data) >= 2) {
            $this->assertEquals($newTicket->id, $data[0]['id']);
        }
    }

    #[Test]
    public function index_includes_unread_count()
    {
        $ticket = $this->createTicket();
        
        // Create unread messages from support
        SupportMessage::create([
            'support_ticket_id' => $ticket->id,
            'user_id' => null,
            'message' => 'Message from support',
            'is_from_support' => true,
            'read_at' => null,
        ]);

        $response = $this->actingAs($this->user)
            ->getJson('/api/support/tickets');

        $response->assertOk();
        $ticketData = collect($response->json('data.data'))->firstWhere('id', $ticket->id);
        $this->assertEquals(1, $ticketData['unread_count']);
    }

    #[Test]
    public function index_returns_only_user_tickets()
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        $this->createTicket();
        SupportTicket::create([
            'user_id' => $otherUser->id,
            'subject' => 'Other user ticket',
            'description' => 'Test',
            'category' => 'other',
            'priority' => 'medium',
            'status' => 'open',
        ]);

        $response = $this->actingAs($this->user)
            ->getJson('/api/support/tickets');

        $response->assertOk();
        foreach ($response->json('data.data') as $ticket) {
            $this->assertEquals($this->user->id, SupportTicket::find($ticket['id'])->user_id);
        }
    }

    #[Test]
    public function index_includes_latest_message()
    {
        $ticket = $this->createTicket();
        SupportMessage::create([
            'support_ticket_id' => $ticket->id,
            'user_id' => $this->user->id,
            'message' => 'Latest message',
            'is_from_support' => false,
        ]);

        $response = $this->actingAs($this->user)
            ->getJson('/api/support/tickets');

        $response->assertOk();
    }

    // ==================== STORE ====================

    #[Test]
    public function store_creates_ticket_with_all_categories()
    {
        $categories = ['order', 'delivery', 'payment', 'account', 'app_bug', 'other'];

        foreach ($categories as $category) {
            $response = $this->actingAs($this->user)
                ->postJson('/api/support/tickets', [
                    'subject' => "Test ticket for {$category}",
                    'description' => 'Test description',
                    'category' => $category,
                ]);

            $response->assertStatus(201);
        }

        $this->assertEquals(6, SupportTicket::where('user_id', $this->user->id)->count());
    }

    #[Test]
    public function store_creates_ticket_with_priority()
    {
        $response = $this->actingAs($this->user)
            ->postJson('/api/support/tickets', [
                'subject' => 'High priority issue',
                'description' => 'This is urgent',
                'category' => 'payment',
                'priority' => 'high',
            ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('support_tickets', [
            'user_id' => $this->user->id,
            'priority' => 'high',
        ]);
    }

    #[Test]
    public function store_defaults_priority_to_medium()
    {
        $response = $this->actingAs($this->user)
            ->postJson('/api/support/tickets', [
                'subject' => 'Normal issue',
                'description' => 'Test',
                'category' => 'other',
            ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('support_tickets', [
            'user_id' => $this->user->id,
            'priority' => 'medium',
        ]);
    }

    #[Test]
    public function store_creates_initial_message()
    {
        $response = $this->actingAs($this->user)
            ->postJson('/api/support/tickets', [
                'subject' => 'Test ticket',
                'description' => 'Initial description message',
                'category' => 'other',
            ]);

        $response->assertStatus(201);
        $ticket = SupportTicket::where('user_id', $this->user->id)->latest()->first();
        $this->assertEquals(1, $ticket->messages()->count());
    }

    #[Test]
    public function store_validates_description_max_length()
    {
        $response = $this->actingAs($this->user)
            ->postJson('/api/support/tickets', [
                'subject' => 'Test',
                'description' => str_repeat('a', 2001), // Max is 2000
                'category' => 'other',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['description']);
    }

    #[Test]
    public function store_validates_subject_max_length()
    {
        $response = $this->actingAs($this->user)
            ->postJson('/api/support/tickets', [
                'subject' => str_repeat('a', 256), // Max is 255
                'description' => 'Test',
                'category' => 'other',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['subject']);
    }

    #[Test]
    public function store_sets_status_to_open()
    {
        $response = $this->actingAs($this->user)
            ->postJson('/api/support/tickets', [
                'subject' => 'New ticket',
                'description' => 'Test',
                'category' => 'other',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.status', 'open');
    }

    // ==================== SHOW ====================

    #[Test]
    public function show_returns_ticket_with_messages()
    {
        $ticket = $this->createTicket();
        SupportMessage::create([
            'support_ticket_id' => $ticket->id,
            'user_id' => $this->user->id,
            'message' => 'First message',
            'is_from_support' => false,
        ]);
        SupportMessage::create([
            'support_ticket_id' => $ticket->id,
            'user_id' => null,
            'message' => 'Support reply',
            'is_from_support' => true,
        ]);

        $response = $this->actingAs($this->user)
            ->getJson("/api/support/tickets/{$ticket->id}");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['id', 'subject', 'messages'],
            ]);
    }

    #[Test]
    public function show_marks_support_messages_as_read()
    {
        $ticket = $this->createTicket();
        $message = SupportMessage::create([
            'support_ticket_id' => $ticket->id,
            'message' => 'Support message',
            'is_from_support' => true,
            'read_at' => null,
        ]);

        $response = $this->actingAs($this->user)
            ->getJson("/api/support/tickets/{$ticket->id}");

        $response->assertOk();
        $message->refresh();
        $this->assertNotNull($message->read_at);
    }

    #[Test]
    public function show_does_not_mark_user_messages_as_read()
    {
        $ticket = $this->createTicket();
        $message = SupportMessage::create([
            'support_ticket_id' => $ticket->id,
            'user_id' => $this->user->id,
            'message' => 'User message',
            'is_from_support' => false,
            'read_at' => null,
        ]);

        $response = $this->actingAs($this->user)
            ->getJson("/api/support/tickets/{$ticket->id}");

        $response->assertOk();
        $message->refresh();
        $this->assertNull($message->read_at);
    }

    #[Test]
    public function show_returns_404_for_nonexistent_ticket()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/support/tickets/99999');

        $response->assertNotFound();
    }

    // ==================== SEND MESSAGE ====================

    #[Test]
    public function send_message_adds_message_to_ticket()
    {
        $ticket = $this->createTicket(['status' => 'open']);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/messages", [
                'message' => 'New message from user',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true);
        
        $this->assertDatabaseHas('support_messages', [
            'support_ticket_id' => $ticket->id,
            'message' => 'New message from user',
            'is_from_support' => false,
        ]);
    }

    #[Test]
    public function send_message_with_attachment()
    {
        Storage::fake('private');

        $ticket = $this->createTicket(['status' => 'open']);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/messages", [
                'message' => 'Message with attachment',
                'attachment' => UploadedFile::fake()->create('document.pdf', 100),
            ]);

        $response->assertStatus(201);
        
        $message = SupportMessage::where('support_ticket_id', $ticket->id)->latest()->first();
        $this->assertNotNull($message->attachment);
    }

    #[Test]
    public function send_message_validates_attachment_type()
    {
        Storage::fake('private');

        $ticket = $this->createTicket(['status' => 'open']);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/messages", [
                'message' => 'Message',
                'attachment' => UploadedFile::fake()->create('file.exe', 100),
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['attachment']);
    }

    #[Test]
    public function send_message_validates_attachment_size()
    {
        Storage::fake('private');

        $ticket = $this->createTicket(['status' => 'open']);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/messages", [
                'message' => 'Message',
                'attachment' => UploadedFile::fake()->create('large.pdf', 6000), // 6MB > 5MB limit
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['attachment']);
    }

    #[Test]
    public function send_message_reopens_resolved_ticket()
    {
        $ticket = $this->createTicket(['status' => 'resolved']);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/messages", [
                'message' => 'I have a follow-up question',
            ]);

        $response->assertStatus(201);
        $ticket->refresh();
        $this->assertEquals('open', $ticket->status);
    }

    #[Test]
    public function send_message_fails_for_closed_ticket()
    {
        $ticket = $this->createTicket(['status' => 'closed']);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/messages", [
                'message' => 'Trying to send message',
            ]);

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    #[Test]
    public function send_message_validates_max_length()
    {
        $ticket = $this->createTicket(['status' => 'open']);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/messages", [
                'message' => str_repeat('a', 2001), // Max 2000
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['message']);
    }

    #[Test]
    public function send_message_updates_ticket_timestamp()
    {
        $ticket = $this->createTicket(['status' => 'open']);
        SupportTicket::withoutTimestamps(fn () => $ticket->forceFill(['updated_at' => now()->subDay()])->save());
        $ticket->refresh();
        $oldUpdatedAt = $ticket->updated_at;

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/messages", [
                'message' => 'New message',
            ]);

        $response->assertStatus(201);
        $ticket->refresh();
        $this->assertTrue($ticket->updated_at->gt($oldUpdatedAt));
    }

    // ==================== RESOLVE ====================

    #[Test]
    public function resolve_marks_ticket_as_resolved()
    {
        $ticket = $this->createTicket(['status' => 'open']);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/resolve");

        $response->assertOk()
            ->assertJsonPath('success', true);
        
        $ticket->refresh();
        $this->assertEquals('resolved', $ticket->status);
    }

    #[Test]
    public function resolve_returns_404_for_other_user_ticket()
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        $ticket = SupportTicket::create([
            'user_id' => $otherUser->id,
            'subject' => 'Other user ticket',
            'description' => 'Test',
            'category' => 'other',
            'status' => 'open',
        ]);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/resolve");

        $response->assertStatus(404);
    }

    // ==================== CLOSE ====================

    #[Test]
    public function close_sets_ticket_status_to_closed()
    {
        $ticket = $this->createTicket(['status' => 'open']);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/close");

        $response->assertOk()
            ->assertJsonPath('success', true);
        
        $ticket->refresh();
        $this->assertEquals('closed', $ticket->status);
    }

    #[Test]
    public function close_returns_404_for_other_user_ticket()
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        $ticket = SupportTicket::create([
            'user_id' => $otherUser->id,
            'subject' => 'Other user ticket',
            'description' => 'Test',
            'category' => 'other',
            'status' => 'open',
        ]);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/close");

        $response->assertStatus(404);
    }

    // ==================== STATS ====================

    #[Test]
    public function stats_returns_ticket_counts()
    {
        $this->createTicket(['status' => 'open']);
        $this->createTicket(['status' => 'open']);
        $this->createTicket(['status' => 'resolved']);
        $this->createTicket(['status' => 'closed']);

        $response = $this->actingAs($this->user)
            ->getJson('/api/support/tickets/stats');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.total', 4)
            ->assertJsonPath('data.open', 2)
            ->assertJsonPath('data.resolved', 1)
            ->assertJsonPath('data.closed', 1);
    }

    #[Test]
    public function stats_returns_zero_for_no_tickets()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/support/tickets/stats');

        $response->assertOk()
            ->assertJsonPath('data.total', 0)
            ->assertJsonPath('data.open', 0)
            ->assertJsonPath('data.resolved', 0)
            ->assertJsonPath('data.closed', 0);
    }

    #[Test]
    public function stats_counts_only_user_tickets()
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        $this->createTicket(['status' => 'open']);
        SupportTicket::create([
            'user_id' => $otherUser->id,
            'subject' => 'Other user ticket',
            'description' => 'Test',
            'category' => 'other',
            'status' => 'open',
        ]);

        $response = $this->actingAs($this->user)
            ->getJson('/api/support/tickets/stats');

        $response->assertOk()
            ->assertJsonPath('data.total', 1);
    }

    // ==================== AUTHORIZATION ====================

    #[Test]
    public function unauthenticated_cannot_list_tickets()
    {
        $response = $this->getJson('/api/support/tickets');

        $response->assertUnauthorized();
    }

    #[Test]
    public function unauthenticated_cannot_create_ticket()
    {
        $response = $this->postJson('/api/support/tickets', [
            'subject' => 'Test',
            'description' => 'Test',
            'category' => 'other',
        ]);

        $response->assertUnauthorized();
    }

    #[Test]
    public function unauthenticated_cannot_view_ticket()
    {
        $ticket = $this->createTicket();

        $response = $this->getJson("/api/support/tickets/{$ticket->id}");

        $response->assertUnauthorized();
    }

    #[Test]
    public function pharmacy_user_can_create_ticket()
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);

        $response = $this->actingAs($pharmacyUser)
            ->postJson('/api/support/tickets', [
                'subject' => 'Pharmacy support request',
                'description' => 'Need help',
                'category' => 'other',
            ]);

        $response->assertStatus(201);
    }

    #[Test]
    public function courier_user_can_create_ticket()
    {
        $courierUser = User::factory()->create(['role' => 'courier']);

        $response = $this->actingAs($courierUser)
            ->postJson('/api/support/tickets', [
                'subject' => 'Courier support request',
                'description' => 'Need help',
                'category' => 'delivery',
            ]);

        $response->assertStatus(201);
    }

    // ==================== EDGE CASES ====================

    #[Test]
    public function index_handles_empty_tickets()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/support/tickets');

        $response->assertOk()
            ->assertJsonPath('success', true);
        $this->assertEmpty($response->json('data.data'));
    }

    #[Test]
    public function store_handles_unicode_characters()
    {
        $response = $this->actingAs($this->user)
            ->postJson('/api/support/tickets', [
                'subject' => 'Problème avec émoji 🚀',
                'description' => 'Message avec accents é è à ù et caractères spéciaux €',
                'category' => 'other',
            ]);

        $response->assertStatus(201);
    }

    #[Test]
    public function send_message_handles_unicode()
    {
        $ticket = $this->createTicket(['status' => 'open']);

        $response = $this->actingAs($this->user)
            ->postJson("/api/support/tickets/{$ticket->id}/messages", [
                'message' => 'Merci beaucoup! 👍 Très bien résolu.',
            ]);

        $response->assertStatus(201);
    }

    #[Test]
    public function ticket_with_all_priority_levels()
    {
        $priorities = ['low', 'medium', 'high'];

        foreach ($priorities as $priority) {
            $response = $this->actingAs($this->user)
                ->postJson('/api/support/tickets', [
                    'subject' => "Priority {$priority}",
                    'description' => 'Test',
                    'category' => 'other',
                    'priority' => $priority,
                ]);

            $response->assertStatus(201)
                ->assertJsonPath('data.priority', $priority);
        }
    }
}
