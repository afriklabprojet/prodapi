<?php

namespace App\Mail;

use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class OrderStatusMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $orderReference;
    public string $status;
    public array $details;

    public function __construct(string|Order $orderReference, string $status, array $details = [])
    {
        $this->orderReference = $orderReference instanceof Order
            ? ($orderReference->reference ?? (string) $orderReference->id)
            : $orderReference;
        $this->status = $status;
        $this->details = $details;
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: "Commande {$this->orderReference} — " . $this->statusLabel(),
        );
    }

    public function content(): Content
    {
        return new Content(
            markdown: 'emails.order-status',
            with: [
                'orderReference' => $this->orderReference,
                'status' => $this->status,
                'details' => $this->details,
            ],
        );
    }

    private function statusLabel(): string
    {
        return match ($this->status) {
            'confirmed' => 'Confirmée',
            'ready' => 'Prête',
            'picked_up', 'in_transit' => 'En cours de livraison',
            'delivered' => 'Livrée',
            'cancelled' => 'Annulée',
            default => ucfirst(str_replace('_', ' ', $this->status)),
        };
    }
}
