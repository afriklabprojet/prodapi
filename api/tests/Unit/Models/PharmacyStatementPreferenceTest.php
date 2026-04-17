<?php

namespace Tests\Unit\Models;

use App\Models\Pharmacy;
use App\Models\PharmacyStatementPreference;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PharmacyStatementPreferenceTest extends TestCase
{
    use RefreshDatabase;

    private Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();
        $this->pharmacy = Pharmacy::factory()->create();
    }

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new PharmacyStatementPreference();
        $fillable = $model->getFillable();

        $this->assertContains('pharmacy_id', $fillable);
        $this->assertContains('frequency', $fillable);
        $this->assertContains('format', $fillable);
        $this->assertContains('auto_send', $fillable);
        $this->assertContains('email', $fillable);
        $this->assertContains('next_send_at', $fillable);
        $this->assertContains('last_sent_at', $fillable);
    }

    #[Test]
    public function it_casts_auto_send_as_boolean(): void
    {
        $model = new PharmacyStatementPreference();
        $casts = $model->getCasts();

        $this->assertSame('boolean', $casts['auto_send']);
    }

    #[Test]
    public function it_casts_timestamps_as_datetime(): void
    {
        $model = new PharmacyStatementPreference();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['next_send_at']);
        $this->assertSame('datetime', $casts['last_sent_at']);
    }

    #[Test]
    public function it_has_pharmacy_relationship(): void
    {
        $model = new PharmacyStatementPreference();
        $relation = $model->pharmacy();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_can_be_created_in_database(): void
    {
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $this->pharmacy->id,
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'custom@email.com',
        ]);

        $this->assertDatabaseHas('pharmacy_statement_preferences', [
            'pharmacy_id' => $this->pharmacy->id,
            'frequency' => 'monthly',
        ]);
    }

    #[Test]
    public function it_returns_custom_email_as_effective_email(): void
    {
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $this->pharmacy->id,
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'custom@email.com',
        ]);

        $this->assertEquals('custom@email.com', $preference->effective_email);
    }

    #[Test]
    public function it_returns_null_when_no_email_set_and_no_user(): void
    {
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $this->pharmacy->id,
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => null,
        ]);

        // When pharmacy has no user, effective_email returns null
        $this->assertNull($preference->effective_email);
    }

    #[Test]
    public function it_scopes_due_for_sending(): void
    {
        $duePreference = PharmacyStatementPreference::create([
            'pharmacy_id' => $this->pharmacy->id,
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => true,
            'next_send_at' => now()->subHour(),
        ]);

        $pharmacy2 = Pharmacy::factory()->create();
        $notDuePreference = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy2->id,
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => true,
            'next_send_at' => now()->addDay(),
        ]);

        $pharmacy3 = Pharmacy::factory()->create();
        $autoSendDisabled = PharmacyStatementPreference::create([
            'pharmacy_id' => $pharmacy3->id,
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => false,
            'next_send_at' => now()->subHour(),
        ]);

        $dueIds = PharmacyStatementPreference::dueForSending()->pluck('id')->toArray();

        $this->assertContains($duePreference->id, $dueIds);
        $this->assertNotContains($notDuePreference->id, $dueIds);
        $this->assertNotContains($autoSendDisabled->id, $dueIds);
    }

    #[Test]
    public function it_calculates_weekly_statement_period(): void
    {
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $this->pharmacy->id,
            'frequency' => 'weekly',
            'format' => 'pdf',
            'auto_send' => true,
        ]);

        Carbon::setTestNow(Carbon::parse('2026-04-05'));

        $period = $preference->getStatementPeriod();

        $this->assertTrue($period['start']->isBefore($period['end']));
        $this->assertEquals('Monday', $period['start']->format('l'));
        $this->assertEquals('Sunday', $period['end']->format('l'));
    }

    #[Test]
    public function it_calculates_monthly_statement_period(): void
    {
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $this->pharmacy->id,
            'frequency' => 'monthly',
            'format' => 'pdf',
            'auto_send' => true,
        ]);

        Carbon::setTestNow(Carbon::parse('2026-04-05'));

        $period = $preference->getStatementPeriod();

        $this->assertEquals('2026-03-01', $period['start']->format('Y-m-d'));
        $this->assertEquals('2026-03-31', $period['end']->format('Y-m-d'));
    }

    #[Test]
    public function it_calculates_quarterly_statement_period(): void
    {
        $preference = PharmacyStatementPreference::create([
            'pharmacy_id' => $this->pharmacy->id,
            'frequency' => 'quarterly',
            'format' => 'pdf',
            'auto_send' => true,
        ]);

        Carbon::setTestNow(Carbon::parse('2026-04-05'));

        $period = $preference->getStatementPeriod();

        $this->assertEquals('2026-01-01', $period['start']->format('Y-m-d'));
        $this->assertEquals('2026-03-31', $period['end']->format('Y-m-d'));
    }
}
