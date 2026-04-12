<?php

namespace Tests\Unit\Mail;

use App\Mail\OtpMail;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class OtpMailTest extends TestCase
{
    #[Test]
    public function it_stores_otp_and_purpose()
    {
        $mail = new OtpMail('123456', 'verification');

        $this->assertEquals('123456', $mail->otp);
        $this->assertEquals('verification', $mail->purpose);
    }

    #[Test]
    public function envelope_verification_subject()
    {
        $mail = new OtpMail('123456', 'verification');
        $envelope = $mail->envelope();

        $this->assertStringContainsString('vérification', $envelope->subject);
    }

    #[Test]
    public function envelope_password_reset_subject()
    {
        $mail = new OtpMail('654321', 'password_reset');
        $envelope = $mail->envelope();

        $this->assertStringContainsString('initialisation', $envelope->subject);
    }

    #[Test]
    public function envelope_login_subject()
    {
        $mail = new OtpMail('111111', 'login');
        $envelope = $mail->envelope();

        $this->assertStringContainsString('connexion', $envelope->subject);
    }

    #[Test]
    public function envelope_default_subject()
    {
        $mail = new OtpMail('000000', 'unknown');
        $envelope = $mail->envelope();

        $this->assertStringContainsString('DR-PHARMA', $envelope->subject);
    }

    #[Test]
    public function content_uses_markdown_template()
    {
        $mail = new OtpMail('123456');
        $content = $mail->content();

        $this->assertEquals('emails.otp', $content->markdown);
        $this->assertEquals('123456', $content->with['otp']);
        $this->assertEquals(10, $content->with['expiryMinutes']);
    }
}
