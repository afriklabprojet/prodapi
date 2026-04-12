<?php

namespace Tests\Unit\Mail;

use App\Mail\WelcomeMail;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class WelcomeMailTest extends TestCase
{
    #[Test]
    public function it_stores_name_and_user_type()
    {
        $mail = new WelcomeMail('Jean Dupont', 'customer');

        $this->assertEquals('Jean Dupont', $mail->name);
        $this->assertEquals('customer', $mail->userType);
    }

    #[Test]
    public function envelope_has_welcome_subject()
    {
        $mail = new WelcomeMail('Jean', 'customer');
        $envelope = $mail->envelope();

        $this->assertStringContainsString('Bienvenue', $envelope->subject);
        $this->assertStringContainsString('DR-PHARMA', $envelope->subject);
    }

    #[Test]
    public function content_uses_markdown_template()
    {
        $mail = new WelcomeMail('Jean', 'pharmacy');
        $content = $mail->content();

        $this->assertEquals('emails.welcome', $content->markdown);
        $this->assertEquals('Jean', $content->with['name']);
        $this->assertEquals('pharmacy', $content->with['userType']);
    }
}
