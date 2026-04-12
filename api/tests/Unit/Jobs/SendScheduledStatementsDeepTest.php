<?php

namespace Tests\Unit\Jobs;

use App\Jobs\SendScheduledStatements;
use App\Mail\PharmacyStatementMail;
use App\Models\Pharmacy;
use App\Models\PharmacyStatementPreference;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class SendScheduledStatementsDeepTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Helper: Call the protected sendStatement method directly via reflection.
     */
    private function callSendStatement(SendScheduledStatements $job, PharmacyStatementPreference $preference): void
    {
        $method = new \ReflectionMethod($job, 'sendStatement');
        $method->setAccessible(true);
        $method->invoke($job, $preference);
    }

    // ─── handle(): no preferences due ───

    public function test_handle_with_no_due_preferences(): void
    {
        Mail::fake();

        Log::shouldReceive('info')
            ->withArgs(fn($m) => str_contains($m, 'Début'))
            ->once();
        Log::shouldReceive('info')
            ->withArgs(fn($m) => str_contains($m, '0 relevés'))
            ->once();
        Log::shouldReceive('info')
            ->withArgs(fn($m) => str_contains($m, 'Terminé'))
            ->once();

        $job = new SendScheduledStatements();
        $job->handle();

        Mail::assertNothingSent();
    }

    // ─── handle(): preferences not yet due ───

    public function test_handle_ignores_future_preferences(): void
    {
        Mail::fake();

        $pharmacy = Pharmacy::factory()->create();
        Wallet::factory()->forOwner($pharmacy)->withBalance(10000)->create();

        PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'weekly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'pharmacist@test.com',
            'next_send_at' => now()->addDays(7), // Future
        ]);

        Log::shouldReceive('info')->atLeast()->once();

        $job = new SendScheduledStatements();
        $job->handle();

        Mail::assertNothingSent();
    }

    // ─── handle(): preferences with auto_send = false ───

    public function test_handle_ignores_disabled_auto_send(): void
    {
        Mail::fake();

        $pharmacy = Pharmacy::factory()->create();
        Wallet::factory()->forOwner($pharmacy)->withBalance(10000)->create();

        PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'weekly',
            'format' => 'pdf',
            'auto_send' => false,
            'email' => 'pharmacist@test.com',
            'next_send_at' => now()->subHour(),
        ]);

        Log::shouldReceive('info')->atLeast()->once();

        $job = new SendScheduledStatements();
        $job->handle();

        Mail::assertNothingSent();
    }

    // ─── sendStatement(): no email → skip ───

    public function test_send_statement_skips_when_no_email(): void
    {
        Mail::fake();
        Log::spy();

        $pharmacy = Pharmacy::factory()->create();
        Wallet::factory()->forOwner($pharmacy)->withBalance(10000)->create();

        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'weekly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => null, // No email set
            'next_send_at' => now()->subHour(),
        ]);
        $preference->load('pharmacy.wallet');

        $job = new SendScheduledStatements();
        $this->callSendStatement($job, $preference);

        Log::shouldHaveReceived('warning')
            ->withArgs(fn($m) => str_contains($m, "Pas d'email"))
            ->once();

        Mail::assertNothingSent();
    }

    // ─── sendStatement(): no wallet → skip ───

    public function test_send_statement_skips_when_no_wallet(): void
    {
        Mail::fake();
        Log::spy();

        $pharmacy = Pharmacy::factory()->create();
        // No wallet created for this pharmacy

        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'test@example.com',
            'next_send_at' => now()->subHour(),
        ]);
        $preference->load('pharmacy');

        $job = new SendScheduledStatements();
        $this->callSendStatement($job, $preference);

        Log::shouldHaveReceived('warning')
            ->withArgs(fn($m) => str_contains($m, 'Pas de wallet'))
            ->once();

        Mail::assertNothingSent();
    }

    // ─── sendStatement(): successful email send ───

    public function test_send_statement_sends_email_with_correct_data(): void
    {
        Mail::fake();
        Log::spy();

        $pharmacy = Pharmacy::factory()->create(['name' => 'Pharmacie Test']);
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(50000)->create();

        // Create some transactions
        WalletTransaction::factory()->credit()->create([
            'wallet_id' => $wallet->id,
            'type' => 'CREDIT',
            'amount' => 30000,
            'balance_after' => 30000,
            'reference' => 'TXN-CREDIT-1',
            'created_at' => now()->subDays(5),
        ]);

        WalletTransaction::factory()->debit()->create([
            'wallet_id' => $wallet->id,
            'type' => 'DEBIT',
            'amount' => 5000,
            'balance_after' => 25000,
            'reference' => 'TXN-DEBIT-1',
            'created_at' => now()->subDays(3),
        ]);

        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'statement@pharmacy.com',
            'next_send_at' => now()->subMinute(),
        ]);
        $preference->load('pharmacy.wallet');

        $job = new SendScheduledStatements();
        $this->callSendStatement($job, $preference);

        Mail::assertSent(PharmacyStatementMail::class, function ($mail) {
            return $mail->hasTo('statement@pharmacy.com');
        });
    }

    // ─── sendStatement(): weekly frequency period ───

    public function test_send_statement_uses_weekly_period(): void
    {
        Mail::fake();
        Log::spy();

        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(10000)->create();

        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'weekly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'weekly@test.com',
            'next_send_at' => now()->subMinute(),
        ]);
        $preference->load('pharmacy.wallet');

        $job = new SendScheduledStatements();
        $this->callSendStatement($job, $preference);

        Mail::assertSent(PharmacyStatementMail::class);
    }

    // ─── sendStatement(): quarterly frequency ───

    public function test_send_statement_uses_quarterly_period(): void
    {
        Mail::fake();
        Log::spy();

        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(10000)->create();

        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'quarterly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'quarterly@test.com',
            'next_send_at' => now()->subMinute(),
        ]);
        $preference->load('pharmacy.wallet');

        $job = new SendScheduledStatements();
        $this->callSendStatement($job, $preference);

        Mail::assertSent(PharmacyStatementMail::class);
    }

    // ─── sendStatement(): mail data structure ───

    public function test_send_statement_mail_contains_expected_data(): void
    {
        Mail::fake();
        Log::spy();

        $pharmacy = Pharmacy::factory()->create(['name' => 'PharmData']);
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(25000)->create();

        // Create transactions within the expected period (last month for monthly)
        $lastMonth = now()->subMonth();
        WalletTransaction::factory()->create([
            'wallet_id' => $wallet->id,
            'type' => 'CREDIT',
            'amount' => 20000,
            'balance_after' => 20000,
            'reference' => 'TXN-C1',
            'created_at' => $lastMonth->copy()->addDays(5),
        ]);
        WalletTransaction::factory()->create([
            'wallet_id' => $wallet->id,
            'type' => 'DEBIT',
            'amount' => 5000,
            'balance_after' => 15000,
            'reference' => 'TXN-D1',
            'created_at' => $lastMonth->copy()->addDays(15),
        ]);

        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'totals@test.com',
            'next_send_at' => now()->subMinute(),
        ]);
        $preference->load('pharmacy.wallet');

        $job = new SendScheduledStatements();
        $this->callSendStatement($job, $preference);

        Mail::assertSent(PharmacyStatementMail::class, function ($mail) {
            $data = $mail->statementData;
            return isset($data['total_credits'])
                && isset($data['total_debits'])
                && isset($data['balance'])
                && isset($data['period_start'])
                && isset($data['period_end'])
                && isset($data['pharmacy']);
        });
    }

    // ─── sendStatement(): email sent to correct address ───

    public function test_send_statement_uses_preference_email(): void
    {
        Mail::fake();
        Log::spy();

        $pharmacy = Pharmacy::factory()->create();
        Wallet::factory()->forOwner($pharmacy)->withBalance(10000)->create();

        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'custom@pharmacy.com',
            'next_send_at' => now()->subMinute(),
        ]);
        $preference->load('pharmacy.wallet');

        $job = new SendScheduledStatements();
        $this->callSendStatement($job, $preference);

        Mail::assertSent(PharmacyStatementMail::class, function ($mail) {
            return $mail->hasTo('custom@pharmacy.com');
        });
    }

    // ─── PharmacyStatementPreference: dueForSending scope ───

    public function test_due_for_sending_scope_filters_correctly(): void
    {
        $pharmacy1 = Pharmacy::factory()->create();
        $pharmacy2 = Pharmacy::factory()->create();
        $pharmacy3 = Pharmacy::factory()->create();

        // Due: auto_send = true, next_send_at in past
        PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy1->id,
            'auto_send' => true,
            'next_send_at' => now()->subHour(),
            'frequency' => 'weekly',
        ]);

        // NOT due: auto_send = false
        PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy2->id,
            'auto_send' => false,
            'next_send_at' => now()->subHour(),
            'frequency' => 'weekly',
        ]);

        // NOT due: next_send_at in future
        PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy3->id,
            'auto_send' => true,
            'next_send_at' => now()->addDay(),
            'frequency' => 'weekly',
        ]);

        $due = PharmacyStatementPreference::dueForSending()->get();
        $this->assertCount(1, $due);
        $this->assertEquals($pharmacy1->id, $due->first()->pharmacy_id);
    }

    // ─── PharmacyStatementPreference: getStatementPeriod ───

    public function test_get_statement_period_weekly(): void
    {
        $preference = new PharmacyStatementPreference(['frequency' => 'weekly']);
        $period = $preference->getStatementPeriod();

        $this->assertArrayHasKey('start', $period);
        $this->assertArrayHasKey('end', $period);
        $this->assertTrue($period['start']->lt($period['end']));
    }

    public function test_get_statement_period_monthly(): void
    {
        $preference = new PharmacyStatementPreference(['frequency' => 'monthly']);
        $period = $preference->getStatementPeriod();

        $this->assertArrayHasKey('start', $period);
        $this->assertArrayHasKey('end', $period);
    }

    public function test_get_statement_period_quarterly(): void
    {
        $preference = new PharmacyStatementPreference(['frequency' => 'quarterly']);
        $period = $preference->getStatementPeriod();

        $this->assertArrayHasKey('start', $period);
        $this->assertArrayHasKey('end', $period);
    }

    // ─── PharmacyStatementPreference: effective email ───

    public function test_effective_email_prefers_preference_email(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'email' => 'pref@pharmacy.com',
            'frequency' => 'weekly',
            'auto_send' => true,
        ]);

        $this->assertEquals('pref@pharmacy.com', $preference->effective_email);
    }

    public function test_effective_email_returns_null_when_no_email(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'email' => null,
            'frequency' => 'weekly',
            'auto_send' => true,
        ]);

        // No preference email, no pharmacy users — returns null
        $this->assertNull($preference->effective_email);
    }

    public function test_effective_email_falls_back_to_first_user(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $user = User::factory()->create(['email' => 'fallback@pharmacy.com']);
        $pharmacy->users()->attach($user->id, ['role' => 'owner']);

        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'email' => null,
            'frequency' => 'weekly',
            'auto_send' => true,
        ]);

        $this->assertEquals('fallback@pharmacy.com', $preference->effective_email);
    }

    // ─── PharmacyStatementPreference: frequency_label ───

    public function test_frequency_label_weekly(): void
    {
        $preference = new PharmacyStatementPreference(['frequency' => 'weekly']);
        $this->assertEquals('Hebdomadaire', $preference->frequency_label);
    }

    public function test_frequency_label_monthly(): void
    {
        $preference = new PharmacyStatementPreference(['frequency' => 'monthly']);
        $this->assertEquals('Mensuel', $preference->frequency_label);
    }

    public function test_frequency_label_quarterly(): void
    {
        $preference = new PharmacyStatementPreference(['frequency' => 'quarterly']);
        $this->assertEquals('Trimestriel', $preference->frequency_label);
    }

    // ─── PharmacyStatementPreference: scheduleNextSend ───

    public function test_schedule_next_send_weekly(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'weekly',
            'auto_send' => true,
            'next_send_at' => now()->subHour(),
        ]);

        $preference->scheduleNextSend();
        $preference->refresh();

        $this->assertNotNull($preference->last_sent_at);
        $this->assertTrue($preference->next_send_at->isAfter(now()->addDays(6)));
    }

    public function test_schedule_next_send_monthly(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'monthly',
            'auto_send' => true,
            'next_send_at' => now()->subHour(),
        ]);

        $preference->scheduleNextSend();
        $preference->refresh();

        $this->assertNotNull($preference->last_sent_at);
        $this->assertTrue($preference->next_send_at->isAfter(now()->addDays(27)));
    }

    public function test_schedule_next_send_quarterly(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'quarterly',
            'auto_send' => true,
            'next_send_at' => now()->subHour(),
        ]);

        $preference->scheduleNextSend();
        $preference->refresh();

        $this->assertNotNull($preference->last_sent_at);
        $this->assertTrue($preference->next_send_at->isAfter(now()->addDays(80)));
    }

    // ─── sendStatement(): schedules next send after mail ───

    public function test_send_statement_schedules_next_send(): void
    {
        Mail::fake();
        Log::spy();

        $pharmacy = Pharmacy::factory()->create();
        Wallet::factory()->forOwner($pharmacy)->withBalance(10000)->create();

        $oldNextSend = now()->subHour();
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy->id,
            'frequency' => 'weekly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'test@test.com',
            'next_send_at' => $oldNextSend,
        ]);
        $preference->load('pharmacy.wallet');

        $job = new SendScheduledStatements();
        $this->callSendStatement($job, $preference);

        $preference->refresh();
        $this->assertNotNull($preference->last_sent_at);
        $this->assertTrue($preference->next_send_at->isAfter(now()));
    }

    // ─── Job properties ───

    public function test_job_has_correct_properties(): void
    {
        $job = new SendScheduledStatements();
        $this->assertEquals(3, $job->tries);
        $this->assertEquals(60, $job->backoff);
        $this->assertEquals(300, $job->timeout);
    }
}
