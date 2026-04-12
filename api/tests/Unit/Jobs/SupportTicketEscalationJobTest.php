<?php

namespace Tests\Unit\Jobs;

use App\Jobs\SupportTicketEscalationJob;
use App\Models\SupportTicket;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class SupportTicketEscalationJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_job_can_be_instantiated(): void
    {
        $job = new SupportTicketEscalationJob();
        $this->assertInstanceOf(SupportTicketEscalationJob::class, $job);
        $this->assertEquals(2, $job->tries);
        $this->assertEquals(120, $job->timeout);
    }

    public function test_job_has_middleware(): void
    {
        $job = new SupportTicketEscalationJob();
        $middleware = $job->middleware();
        $this->assertNotEmpty($middleware);
    }

    public function test_handle_escalates_old_tickets(): void
    {
        Mail::fake();

        $user = User::factory()->create();
        $ticket = SupportTicket::create([
            'user_id' => $user->id,
            'reference' => 'TKT-001',
            'subject' => 'Test ticket',
            'category' => 'order',
            'priority' => 'normal',
            'status' => 'open',
        ]);

        \Illuminate\Support\Facades\DB::table('support_tickets')
            ->where('id', $ticket->id)
            ->update(['created_at' => now()->subDays(6)]);

        $job = new SupportTicketEscalationJob();
        $job->handle();

        $ticket->refresh();
        $this->assertEquals('high', $ticket->priority);
    }

    public function test_handle_auto_closes_very_old_tickets(): void
    {
        Mail::fake();

        $user = User::factory()->create();
        $ticket = SupportTicket::create([
            'user_id' => $user->id,
            'reference' => 'TKT-002',
            'subject' => 'Old ticket',
            'category' => 'other',
            'priority' => 'high',
            'status' => 'open',
        ]);

        \Illuminate\Support\Facades\DB::table('support_tickets')
            ->where('id', $ticket->id)
            ->update(['created_at' => now()->subDays(35)]);

        $job = new SupportTicketEscalationJob();
        $job->handle();

        $ticket->refresh();
        $this->assertEquals('resolved', $ticket->status);
    }

    public function test_failed_logs_error(): void
    {
        Log::shouldReceive('error')->once()->with('SupportTicketEscalationJob failed', \Mockery::type('array'));

        $job = new SupportTicketEscalationJob();
        $job->failed(new \RuntimeException('Test error'));
    }
}
