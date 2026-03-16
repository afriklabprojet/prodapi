<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\PaymentGateways\JekoGateway;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class WebhookController extends Controller
{
    /**
     * Webhook Jeko
     * 
     * Note: According to official Jeko documentation, the signature header is "Jeko-Signature"
     */
    public function jeko(Request $request)
    {
        Log::info('Jeko webhook endpoint hit', [
            'payload' => $request->all(),
            'headers' => $request->headers->all(),
        ]);

        try {
            $gateway = new JekoGateway();
            $payload = $request->all();
            // Official header is "Jeko-Signature" according to Jeko documentation
            $signature = $request->header('Jeko-Signature');

            // Vérifier la signature
            if (!$gateway->verifySignature($payload, $signature)) {
                Log::warning('Jeko webhook signature verification failed');
                return response()->json(['error' => 'Invalid signature'], 403);
            }

            // Traiter le webhook
            $paymentIntent = $gateway->handleWebhook($payload);

            if (!$paymentIntent) {
                return response()->json(['error' => 'Payment not found'], 404);
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Webhook processed',
            ]);
        } catch (\Exception $e) {
            Log::error('Jeko webhook error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'error' => 'Webhook processing failed',
            ], 500);
        }
    }
}

