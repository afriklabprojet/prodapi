<?php

namespace Tests\Unit\Mail;

use App\Mail\PharmacyStatementMail;
use Tests\TestCase;

class PharmacyStatementMailTest extends TestCase
{
    private function makeStatementData(array $overrides = []): array
    {
        $pharmacy = new \stdClass();
        $pharmacy->name = 'Pharmacie Test';
        $pharmacy->id = 1;

        return array_merge([
            'pharmacy' => $pharmacy,
            'transactions' => collect([]),
            'period_start' => now()->subDays(30),
            'period_end' => now(),
            'total_credits' => 500000,
            'total_debits' => 50000,
            'balance' => 450000,
            'format' => 'pdf',
            'frequency_label' => 'Hebdomadaire',
        ], $overrides);
    }

    public function test_it_can_be_instantiated(): void
    {
        $mail = new PharmacyStatementMail($this->makeStatementData());
        $this->assertInstanceOf(PharmacyStatementMail::class, $mail);
    }

    public function test_envelope_contains_pharmacy_name(): void
    {
        $mail = new PharmacyStatementMail($this->makeStatementData());
        $envelope = $mail->envelope();
        $this->assertStringContainsString('Pharmacie Test', $envelope->subject);
    }

    public function test_envelope_contains_period_end_date(): void
    {
        $data = $this->makeStatementData(['period_end' => now()]);
        $mail = new PharmacyStatementMail($data);
        $envelope = $mail->envelope();
        $this->assertStringContainsString(now()->format('d/m/Y'), $envelope->subject);
    }

    public function test_content_uses_correct_markdown(): void
    {
        $mail = new PharmacyStatementMail($this->makeStatementData());
        $content = $mail->content();
        $this->assertEquals('emails.pharmacy-statement', $content->markdown);
    }

    public function test_content_passes_all_data(): void
    {
        $mail = new PharmacyStatementMail($this->makeStatementData());
        $content = $mail->content();

        $this->assertArrayHasKey('pharmacy', $content->with);
        $this->assertArrayHasKey('transactions', $content->with);
        $this->assertArrayHasKey('periodStart', $content->with);
        $this->assertArrayHasKey('periodEnd', $content->with);
        $this->assertArrayHasKey('totalCredits', $content->with);
        $this->assertArrayHasKey('totalDebits', $content->with);
        $this->assertArrayHasKey('balance', $content->with);
        $this->assertArrayHasKey('format', $content->with);
        $this->assertArrayHasKey('frequencyLabel', $content->with);
    }

    public function test_statement_data_is_accessible(): void
    {
        $data = $this->makeStatementData();
        $mail = new PharmacyStatementMail($data);
        $this->assertEquals($data, $mail->statementData);
    }

    public function test_default_format_is_pdf(): void
    {
        $data = $this->makeStatementData();
        unset($data['format']);
        $mail = new PharmacyStatementMail($data);
        $content = $mail->content();
        $this->assertEquals('pdf', $content->with['format']);
    }
}
