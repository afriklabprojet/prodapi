<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class PharmacyStatementMail extends Mailable
{
    use Queueable, SerializesModels;

    public array $statementData;

    /**
     * Create a new message instance.
     *
     * @param array $statementData Keys: pharmacy, transactions, period_start, period_end,
     *                              total_credits, total_debits, balance, format, frequency_label
     */
    public function __construct(array $statementData)
    {
        $this->statementData = $statementData;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        $pharmacyName = $this->statementData['pharmacy']->name ?? 'Pharmacie';
        $periodEnd = $this->statementData['period_end']?->format('d/m/Y') ?? '';

        return new Envelope(
            subject: "Relevé de compte - {$pharmacyName} - {$periodEnd}",
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            markdown: 'emails.pharmacy-statement',
            with: [
                'pharmacy' => $this->statementData['pharmacy'],
                'transactions' => $this->statementData['transactions'],
                'periodStart' => $this->statementData['period_start'],
                'periodEnd' => $this->statementData['period_end'],
                'totalCredits' => $this->statementData['total_credits'],
                'totalDebits' => $this->statementData['total_debits'],
                'balance' => $this->statementData['balance'],
                'format' => $this->statementData['format'] ?? 'pdf',
                'frequencyLabel' => $this->statementData['frequency_label'] ?? '',
            ],
        );
    }
}
