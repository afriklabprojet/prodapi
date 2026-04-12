<?php

namespace Tests\Unit\Mail;

use App\Mail\AdminAlertMail;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class AdminAlertMailTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_creates_no_courier_available_alert()
    {
        $mail = new AdminAlertMail('no_courier_available', [
            'order_reference' => 'ORD-123',
            'pharmacy_name' => 'Pharma Center',
        ]);

        $this->assertEquals('no_courier_available', $mail->alertType);
        $this->assertEquals('ORD-123', $mail->data['order_reference']);
        
        $envelope = $mail->envelope();
        $this->assertStringContainsString('livreur', $envelope->subject);
    }

    #[Test]
    public function it_creates_kyc_pending_alert()
    {
        $mail = new AdminAlertMail('kyc_pending', ['courier_id' => 42]);

        $envelope = $mail->envelope();
        $this->assertStringContainsString('KYC', $envelope->subject);
    }

    #[Test]
    public function it_creates_withdrawal_request_alert()
    {
        $mail = new AdminAlertMail('withdrawal_request', ['amount' => 50000]);

        $envelope = $mail->envelope();
        $this->assertStringContainsString('retrait', $envelope->subject);
    }

    #[Test]
    public function it_creates_payment_failed_alert()
    {
        $mail = new AdminAlertMail('payment_failed', ['order_reference' => 'ORD-456']);

        $envelope = $mail->envelope();
        $this->assertStringContainsString('paiement', $envelope->subject);
    }

    #[Test]
    public function it_creates_high_value_order_alert()
    {
        $mail = new AdminAlertMail('high_value_order', ['total_amount' => 500000]);

        $envelope = $mail->envelope();
        $this->assertStringContainsString('valeur', $envelope->subject);
    }

    #[Test]
    public function it_creates_wallet_reconciliation_alert()
    {
        $mail = new AdminAlertMail('wallet_reconciliation', ['discrepancy' => 1000]);

        $envelope = $mail->envelope();
        $this->assertStringContainsString('solde', $envelope->subject);
    }

    #[Test]
    public function it_creates_daily_digest_alert()
    {
        $mail = new AdminAlertMail('daily_digest', ['orders_count' => 100]);

        $envelope = $mail->envelope();
        $this->assertStringContainsString('Rapport', $envelope->subject);
    }

    #[Test]
    public function it_creates_ticket_escalation_alert()
    {
        $mail = new AdminAlertMail('ticket_escalation', ['ticket_id' => 123]);

        $envelope = $mail->envelope();
        $this->assertStringContainsString('Tickets', $envelope->subject);
    }

    #[Test]
    public function it_creates_failed_jobs_alert()
    {
        $mail = new AdminAlertMail('failed_jobs', ['count' => 5]);

        $envelope = $mail->envelope();
        $this->assertStringContainsString('Jobs', $envelope->subject);
    }

    #[Test]
    public function it_creates_withdrawal_timeout_alert()
    {
        $mail = new AdminAlertMail('withdrawal_timeout', ['count' => 3]);

        $envelope = $mail->envelope();
        $this->assertStringContainsString('Retraits', $envelope->subject);
    }

    #[Test]
    public function it_handles_unknown_alert_type()
    {
        $mail = new AdminAlertMail('custom_alert', ['custom_data' => 'value']);

        $envelope = $mail->envelope();
        $this->assertStringContainsString('custom_alert', $envelope->subject);
    }

    #[Test]
    public function it_returns_content_with_markdown()
    {
        $mail = new AdminAlertMail('no_courier_available', [
            'order_reference' => 'ORD-789',
            'pharmacy_name' => 'TestPharmacy',
        ]);

        $content = $mail->content();
        $this->assertEquals('emails.admin-alert', $content->markdown);
    }

    #[Test]
    public function it_passes_data_to_content()
    {
        $mail = new AdminAlertMail('payment_failed', ['order_reference' => 'ORD-999']);

        $content = $mail->content();
        $this->assertArrayHasKey('alertType', $content->with);
        $this->assertArrayHasKey('data', $content->with);
        $this->assertArrayHasKey('alertTitle', $content->with);
        $this->assertArrayHasKey('alertMessage', $content->with);
    }
}
