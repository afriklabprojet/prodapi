<?php

namespace Tests\Unit\Models;

use App\Models\SupportTicket;
use App\Models\SupportMessage;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class SupportTicketTest extends TestCase
{
    use RefreshDatabase;

    public function test_fillable_fields(): void
    {
        $model = new SupportTicket();
        $fillable = $model->getFillable();
        $this->assertContains('user_id', $fillable);
        $this->assertContains('reference', $fillable);
        $this->assertContains('category', $fillable);
        $this->assertContains('subject', $fillable);
        $this->assertContains('status', $fillable);
        $this->assertContains('priority', $fillable);
    }

    public function test_casts(): void
    {
        $model = new SupportTicket();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('metadata', $casts);
        $this->assertArrayHasKey('resolved_at', $casts);
    }

    public function test_has_user_relationship(): void
    {
        $model = new SupportTicket();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->user());
    }

    public function test_has_messages_relationship(): void
    {
        $model = new SupportTicket();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\HasMany::class, $model->messages());
    }

    #[Test]
    public function it_has_latest_message_relationship(): void
    {
        $model = new SupportTicket();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\HasOne::class, $model->latestMessage());
    }

    #[Test]
    public function it_generates_reference_on_create(): void
    {
        $user = User::factory()->create();
        $ticket = SupportTicket::create([
            'user_id' => $user->id,
            'category' => 'general',
            'subject' => 'Test Subject',
            'description' => 'Test Description',
            'status' => 'open',
            'priority' => 'normal',
        ]);

        $this->assertNotNull($ticket->reference);
        $this->assertStringStartsWith('TK-', $ticket->reference);
        $this->assertEquals(11, strlen($ticket->reference)); // TK- + 8 chars
    }

    #[Test]
    public function it_does_not_override_existing_reference(): void
    {
        $user = User::factory()->create();
        $ticket = SupportTicket::create([
            'user_id' => $user->id,
            'reference' => 'TK-CUSTOM01',
            'category' => 'general',
            'subject' => 'Test Subject',
            'description' => 'Test Description',
            'status' => 'open',
            'priority' => 'normal',
        ]);

        $this->assertEquals('TK-CUSTOM01', $ticket->reference);
    }

    #[Test]
    public function it_scopes_tickets_by_user(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        SupportTicket::create([
            'user_id' => $user1->id,
            'reference' => 'TK-USER1001',
            'category' => 'general',
            'subject' => 'User1 Ticket',
            'description' => 'Description',
            'status' => 'open',
            'priority' => 'normal',
        ]);

        SupportTicket::create([
            'user_id' => $user2->id,
            'reference' => 'TK-USER2001',
            'category' => 'general',
            'subject' => 'User2 Ticket',
            'description' => 'Description',
            'status' => 'open',
            'priority' => 'normal',
        ]);

        $user1Tickets = SupportTicket::forUser($user1->id)->get();
        $this->assertCount(1, $user1Tickets);
        $this->assertEquals('User1 Ticket', $user1Tickets->first()->subject);
    }

    #[Test]
    public function it_scopes_open_tickets(): void
    {
        $user = User::factory()->create();

        SupportTicket::create([
            'user_id' => $user->id,
            'reference' => 'TK-OPEN0001',
            'category' => 'general',
            'subject' => 'Open Ticket',
            'description' => 'Description',
            'status' => 'open',
            'priority' => 'normal',
        ]);

        SupportTicket::create([
            'user_id' => $user->id,
            'reference' => 'TK-RESOLVED',
            'category' => 'general',
            'subject' => 'Resolved Ticket',
            'description' => 'Description',
            'status' => 'resolved',
            'priority' => 'normal',
        ]);

        $openTickets = SupportTicket::open()->get();
        $this->assertCount(1, $openTickets);
        $this->assertEquals('Open Ticket', $openTickets->first()->subject);
    }

    #[Test]
    public function it_marks_ticket_as_resolved(): void
    {
        $user = User::factory()->create();
        $ticket = SupportTicket::create([
            'user_id' => $user->id,
            'reference' => 'TK-RESOLVE1',
            'category' => 'general',
            'subject' => 'Test Ticket',
            'description' => 'Description',
            'status' => 'open',
            'priority' => 'normal',
        ]);

        $this->assertEquals('open', $ticket->status);
        $this->assertNull($ticket->resolved_at);

        $ticket->markAsResolved();

        $ticket->refresh();
        $this->assertEquals('resolved', $ticket->status);
        $this->assertNotNull($ticket->resolved_at);
    }

    #[Test]
    public function it_reopens_resolved_ticket(): void
    {
        $user = User::factory()->create();
        $ticket = SupportTicket::create([
            'user_id' => $user->id,
            'reference' => 'TK-REOPEN01',
            'category' => 'general',
            'subject' => 'Test Ticket',
            'description' => 'Description',
            'status' => 'resolved',
            'priority' => 'normal',
            'resolved_at' => now(),
        ]);

        $this->assertEquals('resolved', $ticket->status);
        $this->assertNotNull($ticket->resolved_at);

        $ticket->reopen();

        $ticket->refresh();
        $this->assertEquals('open', $ticket->status);
        $this->assertNull($ticket->resolved_at);
    }
}
