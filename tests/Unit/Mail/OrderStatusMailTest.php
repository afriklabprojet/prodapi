<?php

namespace Tests\Unit\Mail;

use App\Mail\OrderStatusMail;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class OrderStatusMailTest extends TestCase
{
    #[Test]
    public function it_creates_with_string_reference()
    {
        $mail = new OrderStatusMail('CMD-001', 'confirmed', ['note' => 'Merci']);

        $this->assertEquals('CMD-001', $mail->orderReference);
        $this->assertEquals('confirmed', $mail->status);
        $this->assertEquals(['note' => 'Merci'], $mail->details);
    }

    #[Test]
    public function envelope_contains_reference_and_status_label()
    {
        $mail = new OrderStatusMail('CMD-002', 'delivered');
        $envelope = $mail->envelope();

        $this->assertStringContainsString('CMD-002', $envelope->subject);
        $this->assertStringContainsString('Livrée', $envelope->subject);
    }

    #[Test]
    public function envelope_confirmed_status()
    {
        $mail = new OrderStatusMail('CMD-003', 'confirmed');
        $envelope = $mail->envelope();

        $this->assertStringContainsString('Confirmée', $envelope->subject);
    }

    #[Test]
    public function envelope_cancelled_status()
    {
        $mail = new OrderStatusMail('CMD-004', 'cancelled');
        $envelope = $mail->envelope();

        $this->assertStringContainsString('Annulée', $envelope->subject);
    }

    #[Test]
    public function envelope_in_transit_status()
    {
        $mail = new OrderStatusMail('CMD-005', 'in_transit');
        $envelope = $mail->envelope();

        $this->assertStringContainsString('livraison', $envelope->subject);
    }

    #[Test]
    public function envelope_unknown_status_uses_ucfirst()
    {
        $mail = new OrderStatusMail('CMD-006', 'custom_status');
        $envelope = $mail->envelope();

        $this->assertStringContainsString('Custom status', $envelope->subject);
    }

    #[Test]
    public function content_uses_markdown_template()
    {
        $mail = new OrderStatusMail('CMD-007', 'delivered');
        $content = $mail->content();

        $this->assertEquals('emails.order-status', $content->markdown);
    }
}
