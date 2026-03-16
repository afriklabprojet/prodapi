<?php

namespace App\Services;

use App\Models\Order;
use App\Models\PaymentIntent;
use App\PaymentGateways\Contracts\PaymentGatewayInterface;
use App\PaymentGateways\JekoGateway;

class PaymentService
{
    /**
     * Obtenir le gateway approprié
     */
    protected function getGateway(string $provider): PaymentGatewayInterface
    {
        return match ($provider) {
            'jeko' => new JekoGateway(),
            default => throw new \Exception("Unknown payment provider: {$provider}. Only 'jeko' is supported."),
        };
    }

    /**
     * Initialiser un paiement
     */
    public function initiatePayment(Order $order, string $provider, array $customerData): PaymentIntent
    {
        $gateway = $this->getGateway($provider);
        return $gateway->initiate($order, $customerData);
    }

    /**
     * Vérifier un paiement
     */
    public function verifyPayment(PaymentIntent $paymentIntent): array
    {
        $gateway = $this->getGateway($paymentIntent->provider);
        return $gateway->verify($paymentIntent);
    }

    /**
     * Traiter un webhook
     */
    public function handleWebhook(string $provider, array $payload, ?string $signature = null): ?PaymentIntent
    {
        $gateway = $this->getGateway($provider);

        if (!$gateway->verifySignature($payload, $signature)) {
            throw new \Exception('Invalid webhook signature');
        }

        return $gateway->handleWebhook($payload);
    }
}
