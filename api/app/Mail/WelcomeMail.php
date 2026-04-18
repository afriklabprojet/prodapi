<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class WelcomeMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $name;
    public string $userType;

    public function __construct(string $name, string $userType)
    {
        $this->name = $name;
        $this->userType = $userType;
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Bienvenue sur DR-PHARMA',
        );
    }

    public function content(): Content
    {
        return new Content(
            markdown: 'emails.welcome',
            with: [
                'name' => $this->name,
                'userType' => $this->userType,
            ],
        );
    }
}
