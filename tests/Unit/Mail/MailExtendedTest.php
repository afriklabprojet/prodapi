<?php

namespace Tests\Unit\Mail;

use App\Mail\OrderStatusMail;
use App\Mail\OtpMail;
use App\Mail\WelcomeMail;
use Tests\TestCase;

class MailExtendedTest extends TestCase
{
    public function test_order_status_mail_confirmed(): void
    {
        $mail = new OrderStatusMail('CMD-001', 'confirmed');
        $this->assertInstanceOf(OrderStatusMail::class, $mail);

        $envelope = $mail->envelope();
        $this->assertNotNull($envelope->subject);
    }

    public function test_order_status_mail_delivered(): void
    {
        $mail = new OrderStatusMail('CMD-001', 'delivered');
        $envelope = $mail->envelope();
        $this->assertNotNull($envelope->subject);
    }

    public function test_order_status_mail_cancelled(): void
    {
        $mail = new OrderStatusMail('CMD-001', 'cancelled');
        $envelope = $mail->envelope();
        $this->assertNotNull($envelope->subject);
    }

    public function test_order_status_mail_with_details(): void
    {
        $mail = new OrderStatusMail('CMD-001', 'ready', ['pharmacy' => 'TestPharmacy']);
        $content = $mail->content();
        $this->assertNotNull($content);
    }

    public function test_otp_mail_verification(): void
    {
        $mail = new OtpMail('123456', 'verification');
        $this->assertInstanceOf(OtpMail::class, $mail);

        $envelope = $mail->envelope();
        $this->assertNotNull($envelope->subject);
    }

    public function test_otp_mail_password_reset(): void
    {
        $mail = new OtpMail('654321', 'password_reset');
        $envelope = $mail->envelope();
        $this->assertNotNull($envelope->subject);
    }

    public function test_otp_mail_login(): void
    {
        $mail = new OtpMail('111111', 'login');
        $envelope = $mail->envelope();
        $this->assertNotNull($envelope->subject);
    }

    public function test_welcome_mail_customer(): void
    {
        $mail = new WelcomeMail('John', 'customer');
        $this->assertInstanceOf(WelcomeMail::class, $mail);

        $envelope = $mail->envelope();
        $this->assertNotNull($envelope->subject);
    }

    public function test_welcome_mail_pharmacy(): void
    {
        $mail = new WelcomeMail('PharmaCie', 'pharmacy');
        $envelope = $mail->envelope();
        $this->assertNotNull($envelope->subject);
    }

    public function test_welcome_mail_courier(): void
    {
        $mail = new WelcomeMail('Driver', 'courier');
        $envelope = $mail->envelope();
        $this->assertNotNull($envelope->subject);
    }

    public function test_order_status_mail_content(): void
    {
        $mail = new OrderStatusMail('CMD-002', 'in_delivery');
        $content = $mail->content();
        $this->assertEquals('emails.order-status', $content->markdown);
    }

    public function test_otp_mail_content(): void
    {
        $mail = new OtpMail('999999');
        $content = $mail->content();
        $this->assertEquals('emails.otp', $content->markdown);
    }

    public function test_welcome_mail_content(): void
    {
        $mail = new WelcomeMail('User', 'customer');
        $content = $mail->content();
        $this->assertEquals('emails.welcome', $content->markdown);
    }
}
