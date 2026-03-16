<?php

namespace App\Services;

use App\Services\Infobip\InfobipClientFactory;
use Infobip\Api\WhatsAppApi;
use Infobip\ApiException;
use Infobip\Model\WhatsAppBulkMessage;
use Infobip\Model\WhatsAppDocumentContent;
use Infobip\Model\WhatsAppDocumentMessage;
use Infobip\Model\WhatsAppFailover;
use Infobip\Model\WhatsAppImageContent;
use Infobip\Model\WhatsAppImageMessage;
use Infobip\Model\WhatsAppInteractiveBodyContent;
use Infobip\Model\WhatsAppInteractiveOrderStatusActionContent;
use Infobip\Model\WhatsAppInteractiveOrderStatusContent;
use Infobip\Model\WhatsAppInteractiveOrderStatusMessage;
use Infobip\Model\WhatsAppLocationContent;
use Infobip\Model\WhatsAppLocationMessage;
use Infobip\Model\WhatsAppMessage;
use Infobip\Model\WhatsAppSingleMessageInfo;
use Infobip\Model\WhatsAppTemplateBodyContent;
use Infobip\Model\WhatsAppTemplateContent;
use Infobip\Model\WhatsAppTemplateDataContent;
use Infobip\Model\WhatsAppTemplateTextHeaderContent;
use Infobip\Model\WhatsAppTextContent;
use Infobip\Model\WhatsAppTextMessage;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WhatsAppService
{
    protected WhatsAppApi $whatsAppApi;
    protected InfobipClientFactory $factory;
    protected string $senderNumber;
    protected bool $enabled;

    public function __construct(InfobipClientFactory $factory)
    {
        $this->factory = $factory;
        $this->whatsAppApi = $factory->whatsAppApi();
        $this->senderNumber = config('whatsapp.sender_number', '');
        $this->enabled = config('whatsapp.enabled', false);
    }

    /**
     * Check if WhatsApp service is properly configured
     */
    public function isConfigured(): bool
    {
        return $this->enabled && $this->factory->isWhatsAppConfigured();
    }

    // ──────────────────────────────────────────────────────────────────────
    // TEXT MESSAGE (free-form, within 24h window)
    // Uses SDK: WhatsAppApi::sendWhatsAppTextMessage()
    // ──────────────────────────────────────────────────────────────────────

    /**
     * Send a free-form text message via WhatsApp.
     * Only works within the 24-hour messaging window.
     */
    public function sendText(string $to, string $text, bool $previewUrl = false): bool
    {
        $to = $this->normalizePhone($to);

        if (!$this->isConfigured()) {
            return $this->logOnly('text', $to, ['text' => $text]);
        }

        try {
            $content = new WhatsAppTextContent(
                text: $text,
                previewUrl: $previewUrl,
            );

            $message = new WhatsAppTextMessage(
                from: $this->senderNumber,
                to: $to,
                content: $content,
            );

            $response = $this->whatsAppApi->sendWhatsAppTextMessage($message);

            return $this->handleSdkResponse($response, 'text', $to);
        } catch (ApiException $e) {
            Log::error('WhatsApp text message API exception', [
                'to' => $to,
                'error' => $e->getMessage(),
                'code' => $e->getCode(),
                'responseBody' => $e->getResponseBody(),
            ]);
            return false;
        } catch (\Exception $e) {
            Log::error('WhatsApp text message exception', [
                'to' => $to,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // TEMPLATE MESSAGE (anytime, pre-approved by Meta)
    // Uses SDK: WhatsAppApi::sendWhatsAppTemplateMessage()
    // ──────────────────────────────────────────────────────────────────────

    /**
     * Send a template message via WhatsApp.
     * Can be sent anytime (outside the 24h window).
     *
     * @param string $to Recipient phone number
     * @param string $templateName Template name (lowercase, underscores)
     * @param string $language Language code (e.g., 'fr', 'en_GB')
     * @param array $placeholders Body placeholder values
     * @param array|null $header Header data ['type' => 'TEXT', 'placeholder' => 'value']
     * @param array|null $buttons Button data array
     */
    public function sendTemplate(
        string $to,
        string $templateName,
        string $language = 'fr',
        array $placeholders = [],
        ?array $header = null,
        ?array $buttons = null,
    ): bool {
        $to = $this->normalizePhone($to);

        if (!$this->isConfigured()) {
            return $this->logOnly('template', $to, [
                'template' => $templateName,
                'language' => $language,
                'placeholders' => $placeholders,
            ]);
        }

        try {
            // Build template data content
            $bodyContent = new WhatsAppTemplateBodyContent(
                placeholders: $placeholders,
            );

            $headerContent = null;
            if ($header && isset($header['type']) && $header['type'] === 'TEXT') {
                $headerContent = new WhatsAppTemplateTextHeaderContent(
                    placeholder: $header['placeholder'] ?? '',
                );
            }

            $templateData = new WhatsAppTemplateDataContent(
                body: $bodyContent,
                header: $headerContent,
                buttons: $buttons,
            );

            $templateContent = new WhatsAppTemplateContent(
                templateName: $templateName,
                templateData: $templateData,
                language: $language,
            );

            // Build SMS failover if configured
            $smsFailover = null;
            if (config('whatsapp.sms_failover.enabled', false)) {
                $smsFailover = new WhatsAppFailover(
                    from: config('whatsapp.sms_failover.sender', 'DR-PHARMA'),
                    text: $this->buildSmsFailoverText($templateName, $placeholders),
                );
            }

            // Build the message
            $whatsAppMessage = new WhatsAppMessage(
                from: $this->senderNumber,
                to: $to,
                content: $templateContent,
                smsFailover: $smsFailover,
            );

            $bulkMessage = new WhatsAppBulkMessage(
                messages: [$whatsAppMessage],
            );

            $response = $this->whatsAppApi->sendWhatsAppTemplateMessage($bulkMessage);

            // Template response returns WhatsAppBulkMessageInfo
            $messageId = null;
            $status = 'UNKNOWN';

            $messages = $response->getMessages();
            if (!empty($messages) && isset($messages[0])) {
                $firstMsg = $messages[0];
                if ($firstMsg instanceof WhatsAppSingleMessageInfo) {
                    $messageId = $firstMsg->getMessageId();
                    $statusObj = $firstMsg->getStatus();
                    $status = $statusObj?->getGroupName() ?? 'UNKNOWN';
                }
            }

            Log::info('WhatsApp template message sent', [
                'to' => $to,
                'template' => $templateName,
                'messageId' => $messageId,
                'status' => $status,
            ]);

            return true;
        } catch (ApiException $e) {
            Log::error('WhatsApp template message API exception', [
                'to' => $to,
                'template' => $templateName,
                'error' => $e->getMessage(),
                'code' => $e->getCode(),
                'responseBody' => $e->getResponseBody(),
            ]);
            return false;
        } catch (\Exception $e) {
            Log::error('WhatsApp template message exception', [
                'to' => $to,
                'template' => $templateName,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // IMAGE MESSAGE (free-form)
    // Uses SDK: WhatsAppApi::sendWhatsAppImageMessage()
    // ──────────────────────────────────────────────────────────────────────

    /**
     * Send an image message via WhatsApp.
     */
    public function sendImage(string $to, string $imageUrl, ?string $caption = null): bool
    {
        $to = $this->normalizePhone($to);

        if (!$this->isConfigured()) {
            return $this->logOnly('image', $to, ['url' => $imageUrl, 'caption' => $caption]);
        }

        try {
            $content = new WhatsAppImageContent(
                mediaUrl: $imageUrl,
                caption: $caption,
            );

            $message = new WhatsAppImageMessage(
                from: $this->senderNumber,
                to: $to,
                content: $content,
            );

            $response = $this->whatsAppApi->sendWhatsAppImageMessage($message);

            return $this->handleSdkResponse($response, 'image', $to);
        } catch (ApiException $e) {
            Log::error('WhatsApp image message API exception', [
                'to' => $to,
                'error' => $e->getMessage(),
                'code' => $e->getCode(),
                'responseBody' => $e->getResponseBody(),
            ]);
            return false;
        } catch (\Exception $e) {
            Log::error('WhatsApp image message exception', [
                'to' => $to,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // DOCUMENT MESSAGE (free-form)
    // Uses SDK: WhatsAppApi::sendWhatsAppDocumentMessage()
    // ──────────────────────────────────────────────────────────────────────

    /**
     * Send a document message via WhatsApp.
     */
    public function sendDocument(
        string $to,
        string $documentUrl,
        string $filename = 'document.pdf',
        ?string $caption = null,
    ): bool {
        $to = $this->normalizePhone($to);

        if (!$this->isConfigured()) {
            return $this->logOnly('document', $to, ['url' => $documentUrl, 'filename' => $filename]);
        }

        try {
            $content = new WhatsAppDocumentContent(
                mediaUrl: $documentUrl,
                caption: $caption,
                filename: $filename,
            );

            $message = new WhatsAppDocumentMessage(
                from: $this->senderNumber,
                to: $to,
                content: $content,
            );

            $response = $this->whatsAppApi->sendWhatsAppDocumentMessage($message);

            return $this->handleSdkResponse($response, 'document', $to);
        } catch (ApiException $e) {
            Log::error('WhatsApp document message API exception', [
                'to' => $to,
                'error' => $e->getMessage(),
                'code' => $e->getCode(),
                'responseBody' => $e->getResponseBody(),
            ]);
            return false;
        } catch (\Exception $e) {
            Log::error('WhatsApp document message exception', [
                'to' => $to,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // INTERACTIVE ORDER STATUS (WhatsApp-specific)
    // Uses SDK: WhatsAppApi::sendWhatsappInteractiveOrderStatusMessage()
    // ──────────────────────────────────────────────────────────────────────

    /**
     * Send an interactive order status message.
     * Perfect for DR-PHARMA order updates.
     *
     * Note: The order status SDK model requires a WhatsAppInteractiveOrderPaymentStatus
     * which is region-specific (Brazil, India). For Côte d'Ivoire / general usage,
     * we use raw HTTP fallback for the full interactive order status.
     * If no payment info is needed, we use the SDK typed model.
     */
    public function sendOrderStatus(
        string $to,
        string $orderReference,
        string $status,
        string $description,
        array $payment = [],
    ): bool {
        $to = $this->normalizePhone($to);

        if (!$this->isConfigured()) {
            return $this->logOnly('order_status', $to, [
                'order' => $orderReference,
                'status' => $status,
            ]);
        }

        $statusMap = [
            'confirmed' => 'PROCESSING',
            'preparing' => 'PROCESSING',
            'ready_for_pickup' => 'PARTIALLY_SHIPPED',
            'assigned' => 'SHIPPED',
            'on_the_way' => 'SHIPPED',
            'delivered' => 'COMPLETED',
            'cancelled' => 'CANCELED',
        ];

        $whatsappStatus = $statusMap[$status] ?? 'PROCESSING';

        // Use raw HTTP for order status because the SDK payment model
        // is region-specific and doesn't support generic payment data
        try {
            $body = [
                'from' => $this->senderNumber,
                'to' => $to,
                'content' => [
                    'body' => [
                        'text' => $description,
                    ],
                    'action' => [
                        'payment' => !empty($payment) ? $payment : new \stdClass(),
                        'status' => $whatsappStatus,
                        'description' => $description,
                    ],
                ],
            ];

            $response = $this->infobipHttp()
                ->post($this->getBaseUrl() . '/whatsapp/1/message/interactive/order-status', $body);

            return $this->handleHttpResponse($response, 'order_status', $to, ['order' => $orderReference]);
        } catch (\Exception $e) {
            Log::error('WhatsApp order status exception', [
                'to' => $to,
                'order' => $orderReference,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // LOCATION MESSAGE (free-form)
    // Uses SDK: WhatsAppApi::sendWhatsAppLocationMessage()
    // ──────────────────────────────────────────────────────────────────────

    /**
     * Send a location message (useful for delivery tracking).
     */
    public function sendLocation(
        string $to,
        float $latitude,
        float $longitude,
        ?string $name = null,
        ?string $address = null,
    ): bool {
        $to = $this->normalizePhone($to);

        if (!$this->isConfigured()) {
            return $this->logOnly('location', $to, [
                'lat' => $latitude,
                'lng' => $longitude,
                'name' => $name,
            ]);
        }

        try {
            $content = new WhatsAppLocationContent(
                latitude: $latitude,
                longitude: $longitude,
                name: $name,
                address: $address,
            );

            $message = new WhatsAppLocationMessage(
                from: $this->senderNumber,
                to: $to,
                content: $content,
            );

            $response = $this->whatsAppApi->sendWhatsAppLocationMessage($message);

            return $this->handleSdkResponse($response, 'location', $to);
        } catch (ApiException $e) {
            Log::error('WhatsApp location message API exception', [
                'to' => $to,
                'error' => $e->getMessage(),
                'code' => $e->getCode(),
                'responseBody' => $e->getResponseBody(),
            ]);
            return false;
        } catch (\Exception $e) {
            Log::error('WhatsApp location message exception', [
                'to' => $to,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // MARK AS READ
    // Uses SDK: WhatsAppApi::markWhatsAppMessageAsRead()
    // ──────────────────────────────────────────────────────────────────────

    /**
     * Mark a WhatsApp message as read.
     */
    public function markAsRead(string $messageId): bool
    {
        if (!$this->isConfigured()) {
            Log::info('WhatsApp markAsRead (log only)', ['messageId' => $messageId]);
            return true;
        }

        try {
            $this->whatsAppApi->markWhatsAppMessageAsRead(
                sender: $this->senderNumber,
                messageId: $messageId,
            );

            Log::info('WhatsApp message marked as read', ['messageId' => $messageId]);
            return true;
        } catch (ApiException $e) {
            Log::error('WhatsApp markAsRead API exception', [
                'messageId' => $messageId,
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // GET TEMPLATES
    // Uses SDK: WhatsAppApi::getWhatsAppTemplates()
    // ──────────────────────────────────────────────────────────────────────

    /**
     * Get all registered WhatsApp templates.
     */
    public function getTemplates(): array
    {
        if (!$this->isConfigured()) {
            return [];
        }

        try {
            $response = $this->whatsAppApi->getWhatsAppTemplates(
                sender: $this->senderNumber,
            );

            $templates = [];
            if ($response && method_exists($response, 'getTemplates')) {
                foreach ($response->getTemplates() as $template) {
                    $templates[] = [
                        'name' => $template->getName(),
                        'language' => $template->getLanguage(),
                        'status' => $template->getStatus(),
                        'category' => $template->getCategory(),
                    ];
                }
            }

            return $templates;
        } catch (ApiException $e) {
            Log::error('WhatsApp getTemplates API exception', [
                'error' => $e->getMessage(),
            ]);
            return [];
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // HELPERS
    // ──────────────────────────────────────────────────────────────────────

    /**
     * Handle SDK response (WhatsAppSingleMessageInfo)
     */
    protected function handleSdkResponse(
        WhatsAppSingleMessageInfo $response,
        string $type,
        string $to,
        array $extra = [],
    ): bool {
        $messageId = $response->getMessageId();
        $statusObj = $response->getStatus();
        $status = $statusObj?->getGroupName() ?? 'UNKNOWN';

        Log::info("WhatsApp {$type} message sent via SDK", array_merge([
            'to' => $to,
            'messageId' => $messageId,
            'status' => $status,
        ], $extra));

        return true;
    }

    /**
     * Handle raw HTTP response (for endpoints not fully supported by SDK)
     */
    protected function handleHttpResponse(
        \Illuminate\Http\Client\Response $response,
        string $type,
        string $to,
        array $extra = [],
    ): bool {
        if ($response->successful()) {
            $data = $response->json();
            $messageId = $data['messageId']
                ?? $data['messages'][0]['messageId'] ?? null;

            $status = $data['status']['groupName']
                ?? $data['messages'][0]['status']['groupName'] ?? 'UNKNOWN';

            Log::info("WhatsApp {$type} message sent via HTTP", array_merge([
                'to' => $to,
                'messageId' => $messageId,
                'status' => $status,
            ], $extra));

            return true;
        }

        Log::error("WhatsApp {$type} message failed", array_merge([
            'to' => $to,
            'http_status' => $response->status(),
            'error' => $response->json() ?? $response->body(),
        ], $extra));

        return false;
    }

    /**
     * Create HTTP client for raw API calls (fallback for SDK-unsupported endpoints)
     */
    protected function infobipHttp(): \Illuminate\Http\Client\PendingRequest
    {
        return Http::withHeaders([
            'Authorization' => 'App ' . config('whatsapp.api_key', ''),
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
        ])->timeout(30);
    }

    /**
     * Get the configured base URL
     */
    protected function getBaseUrl(): string
    {
        return rtrim(config('whatsapp.base_url', ''), '/');
    }

    /**
     * Log-only mode for development
     */
    protected function logOnly(string $type, string $to, array $data = []): bool
    {
        Log::info("WhatsApp {$type} (log only - not configured)", array_merge([
            'to' => $to,
        ], $data));

        return true;
    }

    /**
     * Normalize phone number to international format
     */
    public function normalizePhone(string $phone): string
    {
        // Remove all non-digit characters except +
        $phone = preg_replace('/[^\d+]/', '', $phone);

        $countryCode = config('whatsapp.default_country_code', '+225');

        // Local number starting with 0
        if (str_starts_with($phone, '0')) {
            $phone = $countryCode . substr($phone, 1);
        }

        // If no + prefix, check if it needs country code
        if (!str_starts_with($phone, '+')) {
            $codeWithoutPlus = ltrim($countryCode, '+');

            // If it doesn't start with the country code, add it
            if (!str_starts_with($phone, $codeWithoutPlus)) {
                $phone = $countryCode . $phone;
            } else {
                $phone = '+' . $phone;
            }
        }

        return $phone;
    }

    /**
     * Build SMS failover text from template data
     */
    protected function buildSmsFailoverText(string $templateName, array $placeholders): string
    {
        $templates = config('whatsapp.templates', []);

        if (isset($templates[$templateName]['sms_fallback'])) {
            $text = $templates[$templateName]['sms_fallback'];

            foreach ($placeholders as $i => $value) {
                $text = str_replace('{' . ($i + 1) . '}', $value, $text);
            }

            return $text;
        }

        return "DR-PHARMA: Vous avez un nouveau message. Ouvrez WhatsApp pour le consulter.";
    }
}
