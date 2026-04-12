<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class OtpMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $otp;
    public string $purpose;

    /**
     * Create a new message instance.
     */
    public function __construct(string $otp, string $purpose = 'verification')
    {
        $this->otp = $otp;
        $this->purpose = $purpose;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        $subject = match ($this->purpose) {
            'verification' => 'Code de vérification DR-PHARMA',
            'password_reset' => 'Réinitialisation de mot de passe DR-PHARMA',
            'login' => 'Code de connexion DR-PHARMA',
            default => 'Votre code DR-PHARMA',
        };

        return new Envelope(subject: $subject);
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            markdown: 'emails.otp',
            with: [
                'otp' => $this->otp,
                'purpose' => $this->purpose,
                'purposeLabel' => $this->getPurposeLabel(),
                'expiryMinutes' => 10,
                'validityMinutes' => 10,
            ],
        );
    }

    protected function getPurposeLabel(): string
    {
        return match ($this->purpose) {
            'verification' => 'vérification de votre compte',
            'password_reset' => 'réinitialisation de votre mot de passe',
            'login' => 'connexion à votre compte',
            default => 'votre demande',
        };
    }
}
