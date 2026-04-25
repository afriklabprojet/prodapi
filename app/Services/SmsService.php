<?php

namespace App\Services;

use App\Services\Infobip\InfobipClientFactory;
use Infobip\Api\SmsApi;
use Infobip\Api\TfaApi;
use Infobip\ApiException;
use Infobip\Model\SmsDestination;
use Infobip\Model\SmsMessage;
use Infobip\Model\SmsRequest;
use Infobip\Model\SmsTextContent;
use Infobip\Model\SmsPreviewRequest;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class SmsService
{
    protected string $provider;
    protected string $sender;
    protected mixed $smsApi = null;
    protected mixed $tfaApi = null;
    protected InfobipClientFactory $clientFactory;

    public function __construct(?InfobipClientFactory $clientFactory = null)
    {
        $this->provider = config('sms.default', 'infobip');
        $this->sender = config('sms.infobip.sender', 'DR-PHARMA');
        $this->clientFactory = $clientFactory ?? app(InfobipClientFactory::class);

        if ($this->provider === 'infobip' && $this->clientFactory->isSmsConfigured()) {
            $this->smsApi = $this->clientFactory->smsApi();
            $this->tfaApi = $this->clientFactory->tfaApi();
        }
    }

    public function send(string $phone, string $message, array $options = []): bool
    {
        $phone = $this->normalizePhone($phone);

        // Respecter le opt-out SMS (réglementaire)
        if ($this->isOptedOut($phone) && !($options['force'] ?? false)) {
            Log::info("SMS blocked: phone opted out", ['phone' => $phone]);
            return false;
        }

        return match ($this->provider) {
            'infobip' => $this->sendViaInfobip($phone, $message, $options),
            'twilio' => $this->sendViaTwilio($phone, $message),
            'africastalking' => $this->sendViaAfricasTalking($phone, $message),
            default => $this->logOnly($phone, $message),
        };
    }

    /**
     * Vérifier si un numéro a demandé le opt-out SMS
     */
    public function isOptedOut(string $phone): bool
    {
        return \Illuminate\Support\Facades\Cache::has("sms_optout:{$phone}");
    }

    public function sendViaInfobip(string $phone, string $message, array $options = []): bool
    {
        if (!$this->smsApi) {
            Log::warning('Infobip SMS SDK not configured');
            return $this->logOnly($phone, $message);
        }

        try {
            $destination = new SmsDestination(to: $phone);
            if (!empty($options['messageId'])) {
                $destination->setMessageId($options['messageId']);
            }

            $smsMessage = new SmsMessage(
                destinations: [$destination],
                content: new SmsTextContent(text: $message),
                sender: $options['from'] ?? $this->sender,
            );

            $request = new SmsRequest(messages: [$smsMessage]);
            $smsResponse = $this->smsApi->sendSmsMessages($request);

            $bulkId = $smsResponse->getBulkId();
            $messages = $smsResponse->getMessages() ?? [];

            if (!empty($messages)) {
                $firstMsg = $messages[0];
                $statusGroupName = $firstMsg->getStatus()?->getGroupName() ?? 'UNKNOWN';
                $statusName      = $firstMsg->getStatus()?->getName() ?? 'UNKNOWN';
                $statusDesc      = $firstMsg->getStatus()?->getDescription() ?? '';
                $messageId       = $firstMsg->getMessageId();

                // Statuts de rejet immédiats — l'API accepte la requête mais le SMS ne partira pas
                $rejectedGroups = ['REJECTED', 'UNDELIVERABLE'];
                $isRejected = in_array($statusGroupName, $rejectedGroups)
                    || str_starts_with($statusName, 'REJECTED_');

                if ($isRejected) {
                    Log::error('Infobip SMS rejeté', [
                        'phone'       => $phone,
                        'messageId'   => $messageId,
                        'bulkId'      => $bulkId,
                        'status'      => $statusName,
                        'description' => $statusDesc,
                    ]);
                    return false;
                }

                Log::info('SMS envoyé via Infobip SDK', [
                    'phone'     => $phone,
                    'messageId' => $messageId,
                    'bulkId'    => $bulkId,
                    'status'    => $statusGroupName,
                ]);

                if ($messageId) {
                    Cache::put("sms_msg_{$messageId}", [
                        'phone'    => $phone,
                        'sent_at'  => now()->toIso8601String(),
                        'status'   => $statusGroupName,
                    ], now()->addHours(48));

                    // Verify delivery report after a short delay
                    // Infobip may accept (PENDING) then reject async (NOT_ENOUGH_CREDITS)
                    usleep(1500000); // 1.5 seconds
                    if ($this->isMessageRejected($messageId)) {
                        Log::error('Infobip SMS rejected after delivery check', [
                            'phone' => $phone,
                            'messageId' => $messageId,
                        ]);
                        return false;
                    }
                }

                return true;
            }

            Log::error('Infobip SMS SDK: aucun message dans la réponse', ['phone' => $phone]);
            return false;

        } catch (ApiException $e) {
            Log::error('Infobip SMS SDK ApiException', [
                'phone' => $phone,
                'code' => $e->getCode(),
                'error' => $e->getMessage(),
                'responseBody' => $e->getResponseBody(),
            ]);
            return false;
        } catch (\Exception $e) {
            Log::error('Exception Infobip SMS SDK', ['phone' => $phone, 'error' => $e->getMessage()]);
            return false;
        }
    }

    /**
     * Check delivery report to detect async rejections (e.g. NOT_ENOUGH_CREDITS).
     * Returns true if message was rejected.
     */
    protected function isMessageRejected(string $messageId): bool
    {
        try {
            $baseUrl = config('sms.infobip.base_url');
            $apiKey = config('sms.infobip.api_key');

            $response = Http::withHeaders([
                'Authorization' => "App {$apiKey}",
            ])->get("{$baseUrl}/sms/1/reports", [
                'messageId' => $messageId,
                'limit' => 1,
            ]);

            if ($response->ok()) {
                $results = $response->json('results', []);
                if (!empty($results)) {
                    $statusGroup = $results[0]['status']['groupName'] ?? '';
                    if (in_array($statusGroup, ['REJECTED', 'UNDELIVERABLE'])) {
                        Log::warning('Infobip delivery report: rejected', [
                            'messageId' => $messageId,
                            'status' => $results[0]['status']['name'] ?? 'unknown',
                            'description' => $results[0]['status']['description'] ?? '',
                        ]);
                        return true;
                    }
                }
            }
        } catch (\Exception $e) {
            Log::warning('Failed to check Infobip delivery report', ['error' => $e->getMessage()]);
        }

        return false;
    }

    public function sendBulk(array $phones, string $message, array $options = []): array
    {
        if (!$this->smsApi) {
            return ['success' => false, 'sent' => 0, 'failed' => count($phones)];
        }

        try {
            $destinations = array_map(
                fn($phone) => new SmsDestination(to: $this->normalizePhone($phone)),
                $phones
            );

            $smsMessage = new SmsMessage(
                destinations: $destinations,
                content: new SmsTextContent(text: $message),
                sender: $options['from'] ?? $this->sender,
            );

            $request = new SmsRequest(messages: [$smsMessage]);
            $smsResponse = $this->smsApi->sendSmsMessages($request);

            $bulkId = $smsResponse->getBulkId();
            $responseMessages = $smsResponse->getMessages() ?? [];

            $rejectedGroups = ['REJECTED', 'UNDELIVERABLE'];
            $sent = 0;
            $rejections = [];
            foreach ($responseMessages as $m) {
                $groupName  = $m->getStatus()?->getGroupName() ?? 'UNKNOWN';
                $statusName = $m->getStatus()?->getName() ?? 'UNKNOWN';
                $isRejected = in_array($groupName, $rejectedGroups) || str_starts_with($statusName, 'REJECTED_');
                if ($isRejected) {
                    $rejections[] = [
                        'messageId'   => $m->getMessageId(),
                        'status'      => $statusName,
                        'description' => $m->getStatus()?->getDescription() ?? '',
                    ];
                } else {
                    $sent++;
                }
            }

            if (!empty($rejections)) {
                Log::error('Infobip bulk SMS — rejets détectés', [
                    'bulkId'     => $bulkId,
                    'total'      => count($phones),
                    'sent'       => $sent,
                    'rejected'   => count($rejections),
                    'rejections' => $rejections,
                ]);
            }

            Log::info('SMS bulk envoyé via Infobip SDK', [
                'total'  => count($phones),
                'sent'   => $sent,
                'bulkId' => $bulkId,
            ]);

            return [
                'success'  => true,
                'bulkId'   => $bulkId,
                'sent'     => $sent,
                'failed'   => count($phones) - $sent,
                'messages' => array_map(fn($m) => [
                    'messageId' => $m->getMessageId(),
                    'status'    => $m->getStatus()?->getGroupName(),
                ], $responseMessages),
            ];

        } catch (ApiException $e) {
            Log::error('Infobip bulk ApiException', ['code' => $e->getCode(), 'error' => $e->getMessage()]);
            return ['success' => false, 'sent' => 0, 'failed' => count($phones), 'error' => $e->getMessage()];
        } catch (\Exception $e) {
            return ['success' => false, 'sent' => 0, 'failed' => count($phones), 'error' => $e->getMessage()];
        }
    }

    public function sendMultiple(array $messagesData, array $options = []): array
    {
        if (!$this->smsApi) {
            return ['success' => false, 'error' => 'Not configured'];
        }

        try {
            $smsMessages = [];
            foreach ($messagesData as $item) {
                $smsMessages[] = new SmsMessage(
                    destinations: [new SmsDestination(to: $this->normalizePhone($item['phone']))],
                    content: new SmsTextContent(text: $item['message']),
                    sender: $item['from'] ?? $this->sender,
                );
            }

            $request = new SmsRequest(messages: $smsMessages);
            $smsResponse = $this->smsApi->sendSmsMessages($request);

            $bulkId = $smsResponse->getBulkId();
            $responseMessages = $smsResponse->getMessages() ?? [];

            Log::info('SMS multiples envoyés via Infobip SDK', [
                'count' => count($messagesData),
                'bulkId' => $bulkId,
            ]);

            return [
                'success' => true,
                'bulkId' => $bulkId,
                'messages' => array_map(fn($m) => [
                    'messageId' => $m->getMessageId(),
                    'status' => $m->getStatus()?->getGroupName(),
                ], $responseMessages),
            ];
        } catch (\Exception $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function sendFlash(string $phone, string $message): bool
    {
        return $this->send($phone, $message, ['flash' => true]);
    }

    public function schedule(string $phone, string $message, string $sendAt, ?string $bulkId = null): array
    {
        $phone = $this->normalizePhone($phone);
        if (!$this->smsApi) {
            return ['success' => false, 'error' => 'Not configured'];
        }

        try {
            $payload = [
                'messages' => [[
                    'destinations' => [['to' => $phone]],
                    'from' => $this->sender,
                    'text' => $message,
                ]],
                'options' => ['schedule' => ['sendAt' => $sendAt]],
            ];

            if ($bulkId) {
                $payload['options']['schedule']['bulkId'] = $bulkId;
            }

            $notifyUrl = config('sms.infobip.notify_url');
            if ($notifyUrl) {
                $payload['messages'][0]['notifyUrl'] = $notifyUrl;
                $payload['messages'][0]['notifyContentType'] = 'application/json';
            }

            $response = $this->infobipHttp('POST', '/sms/3/messages', $payload);

            if ($response->successful()) {
                $data = $response->json();
                Log::info('SMS programmé via Infobip', [
                    'phone' => $phone,
                    'sendAt' => $sendAt,
                    'bulkId' => $data['bulkId'] ?? $bulkId,
                ]);
                return ['success' => true, 'bulkId' => $data['bulkId'] ?? $bulkId, 'messages' => $data['messages'] ?? []];
            }

            return ['success' => false, 'error' => $response->body()];
        } catch (\Exception $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    public function getScheduled(string $bulkId): ?array
    {
        if (!$this->smsApi) return null;
        try {
            $response = $this->infobipHttp('GET', "/sms/1/bulks?bulkId={$bulkId}");
            return $response->successful() ? $response->json() : null;
        } catch (\Exception $e) {
            Log::error('Erreur récupération SMS programmés', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function reschedule(string $bulkId, string $newSendAt): ?array
    {
        if (!$this->smsApi) return null;
        try {
            $response = $this->infobipHttp('PUT', "/sms/1/bulks?bulkId={$bulkId}", ['sendAt' => $newSendAt]);
            if ($response->successful()) {
                Log::info('SMS reprogrammé', ['bulkId' => $bulkId, 'newSendAt' => $newSendAt]);
                return $response->json();
            }
            return null;
        } catch (\Exception $e) {
            Log::error('Erreur reprogrammation SMS', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function cancelScheduled(string $bulkId): bool
    {
        if (!$this->smsApi) return false;
        try {
            $response = $this->infobipHttp('PUT', "/sms/1/bulks/status?bulkId={$bulkId}", ['status' => 'CANCELED']);
            return $response->successful();
        } catch (\Exception $e) {
            Log::error('Erreur annulation SMS programmé', ['error' => $e->getMessage()]);
            return false;
        }
    }

    public function getDeliveryReports(array $filters = []): ?array
    {
        if (!$this->smsApi) return null;

        try {
            $deliveryResult = $this->smsApi->getOutboundSmsMessageDeliveryReports(
                bulkId: $filters['bulkId'] ?? null,
                messageId: $filters['messageId'] ?? null,
                limit: $filters['limit'] ?? 50,
            );

            $results = [];
            foreach ($deliveryResult->getResults() ?? [] as $report) {
                $results[] = [
                    'messageId' => $report->getMessageId(),
                    'bulkId' => $report->getBulkId(),
                    'to' => $report->getTo(),
                    'sentAt' => $report->getSentAt()?->format('c'),
                    'doneAt' => $report->getDoneAt()?->format('c'),
                    'smsCount' => $report->getSmsCount(),
                    'status' => [
                        'groupName' => $report->getStatus()?->getGroupName(),
                        'name' => $report->getStatus()?->getName(),
                        'description' => $report->getStatus()?->getDescription(),
                    ],
                    'price' => $report->getPrice() ? [
                        'pricePerMessage' => $report->getPrice()->getPricePerMessage(),
                        'currency' => $report->getPrice()->getCurrency(),
                    ] : null,
                    'error' => $report->getError() ? [
                        'groupName' => $report->getError()->getGroupName(),
                        'name' => $report->getError()->getName(),
                        'description' => $report->getError()->getDescription(),
                    ] : null,
                ];
            }

            return ['results' => $results];
        } catch (ApiException $e) {
            Log::error('Erreur delivery reports SDK', ['code' => $e->getCode(), 'error' => $e->getMessage()]);
            return null;
        } catch (\Exception $e) {
            Log::error('Erreur récupération delivery reports', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function getLogs(array $filters = []): ?array
    {
        if (!$this->smsApi) return null;

        try {
            $logsResult = $this->smsApi->getOutboundSmsMessageLogs(
                from: $filters['from'] ?? null,
                to: $filters['to'] ?? null,
                bulkId: $filters['bulkId'] ?? null,
                messageId: $filters['messageId'] ?? null,
                sentSince: isset($filters['sentSince']) ? new \DateTime($filters['sentSince']) : null,
                sentUntil: isset($filters['sentUntil']) ? new \DateTime($filters['sentUntil']) : null,
                limit: $filters['limit'] ?? 50,
                mcc: $filters['mcc'] ?? null,
                mnc: $filters['mnc'] ?? null,
            );

            $results = [];
            foreach ($logsResult->getResults() ?? [] as $log) {
                $results[] = [
                    'messageId' => $log->getMessageId(),
                    'bulkId' => $log->getBulkId(),
                    'to' => $log->getTo(),
                    'from' => $log->getFrom(),
                    'sentAt' => $log->getSentAt()?->format('c'),
                    'doneAt' => $log->getDoneAt()?->format('c'),
                    'smsCount' => $log->getSmsCount(),
                    'status' => [
                        'groupName' => $log->getStatus()?->getGroupName(),
                        'name' => $log->getStatus()?->getName(),
                    ],
                ];
            }

            return ['results' => $results];
        } catch (ApiException $e) {
            Log::error('Erreur logs SMS SDK', ['code' => $e->getCode(), 'error' => $e->getMessage()]);
            return null;
        } catch (\Exception $e) {
            Log::error('Erreur récupération logs SMS', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function getMessageStatus(string $messageId): ?array
    {
        $reports = $this->getDeliveryReports(['messageId' => $messageId, 'limit' => 1]);
        return $reports['results'][0] ?? null;
    }

    public function preview(string $text, ?string $transliteration = null): ?array
    {
        if (!$this->smsApi) return null;

        try {
            $previewRequest = new SmsPreviewRequest(text: $text);
            if ($transliteration) {
                $previewRequest->setTransliteration($transliteration);
            }

            $previewResponse = $this->smsApi->previewSmsMessage($previewRequest);
            $previews = $previewResponse->getPreviews() ?? [];

            if (!empty($previews)) {
                $preview = $previews[0];
                return [
                    'original_text' => $previewResponse->getOriginalText() ?? $text,
                    'text_preview' => $preview->getTextPreview() ?? $text,
                    'message_count' => $preview->getMessageCount() ?? 1,
                    'characters_remaining' => $preview->getCharactersRemaining() ?? 0,
                    'configuration' => $preview->getConfiguration() ?? null,
                ];
            }
            return null;
        } catch (\Exception $e) {
            Log::error('Erreur preview SMS', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function confirmConversion(string $messageId): bool
    {
        if (!$this->smsApi) return false;
        try {
            $response = $this->infobipHttp('POST', "/ct/1/log/end/{$messageId}");
            return $response->successful();
        } catch (\Exception $e) {
            Log::error('Erreur confirmation conversion', ['error' => $e->getMessage()]);
            return false;
        }
    }

    public function getInboundMessages(int $limit = 50): ?array
    {
        if (!$this->smsApi) return null;
        try {
            $response = $this->infobipHttp('GET', "/sms/1/inbox/reports?limit={$limit}");
            return $response->successful() ? $response->json() : null;
        } catch (\Exception $e) {
            Log::error('Erreur récupération SMS entrants', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function create2faApplication(string $name, array $config = []): ?array
    {
        if (!$this->smsApi) return null;
        try {
            $response = $this->infobipHttp('POST', '/2fa/2/applications', [
                'name' => $name,
                'enabled' => true,
                'configuration' => array_merge([
                    'pinAttempts' => config('sms.infobip.2fa.pin_attempts', 5),
                    'allowMultiplePinVerifications' => true,
                    'pinTimeToLive' => config('sms.infobip.2fa.pin_ttl', '10m'),
                    'verifyPinLimit' => config('sms.infobip.2fa.verify_limit', '1/3s'),
                    'sendPinPerApplicationLimit' => config('sms.infobip.2fa.send_limit_app', '5000/12h'),
                    'sendPinPerPhoneNumberLimit' => config('sms.infobip.2fa.send_limit_phone', '3/1d'),
                ], $config),
            ]);

            if ($response->successful()) {
                $data = $response->json();
                Log::info('2FA application créée', ['appId' => $data['applicationId'] ?? null]);
                return $data;
            }
            return null;
        } catch (\Exception $e) {
            Log::error('Erreur création 2FA application', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function create2faMessageTemplate(string $appId, array $template = []): ?array
    {
        if (!$this->smsApi) return null;
        try {
            $response = $this->infobipHttp('POST', "/2fa/2/applications/{$appId}/messages", array_merge([
                'messageText' => config('sms.infobip.2fa.message_text', 'DR-PHARMA: Votre code est {{pin}}. Valide {{timeToLive}}.'),
                'pinLength' => config('sms.infobip.2fa.pin_length', 4),
                'pinType' => config('sms.infobip.2fa.pin_type', 'NUMERIC'),
                'language' => 'fr',
                'senderId' => $this->sender,
                'repeatDTMF' => '1#',
                'speechRate' => 1,
            ], $template));

            if ($response->successful()) {
                $data = $response->json();
                Log::info('2FA template créé', ['messageId' => $data['messageId'] ?? null]);
                return $data;
            }
            return null;
        } catch (\Exception $e) {
            Log::error('Erreur création 2FA template', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function sendPin(string $phone, ?string $appId = null, ?string $messageId = null): ?array
    {
        if (!$this->smsApi) return null;

        $phone = $this->normalizePhone($phone);
        $appId = $appId ?? config('sms.infobip.2fa.application_id');
        $messageId = $messageId ?? config('sms.infobip.2fa.message_id');

        if (!$appId || !$messageId) {
            Log::warning('Infobip 2FA application_id ou message_id non configuré');
            return null;
        }

        try {
            $payload = ['applicationId' => $appId, 'messageId' => $messageId, 'to' => $phone];

            $placeholders = config('sms.infobip.2fa.placeholders', []);
            if (!empty($placeholders)) {
                $payload['placeholders'] = $placeholders;
            }

            $response = $this->infobipHttp('POST', '/2fa/2/pin', $payload);

            if ($response->successful()) {
                $data = $response->json();
                $pinId = $data['pinId'] ?? null;
                Log::info('PIN OTP envoyé via Infobip 2FA', [
                    'phone' => $phone,
                    'pinId' => $pinId,
                    'smsStatus' => $data['smsStatus'] ?? 'UNKNOWN',
                ]);
                if ($pinId) {
                    Cache::put("infobip_pin_{$phone}", $pinId, now()->addMinutes(15));
                }
                return $data;
            }

            Log::error('Envoi PIN OTP échoué', ['phone' => $phone, 'error' => $response->body()]);
            return null;
        } catch (\Exception $e) {
            Log::error('Exception envoi PIN', ['phone' => $phone, 'error' => $e->getMessage()]);
            return null;
        }
    }

    public function verifyPin(string $pinId, string $pin): ?array
    {
        if (!$this->smsApi) return null;
        try {
            $response = $this->infobipHttp('POST', "/2fa/2/pin/{$pinId}/verify", ['pin' => $pin]);
            if ($response->successful()) {
                $data = $response->json();
                Log::info('Vérification PIN', ['pinId' => $pinId, 'verified' => $data['verified'] ?? false]);
                return $data;
            }
            if ($response->status() === 401) {
                return ['verified' => false, 'attemptsRemaining' => 0];
            }
            return null;
        } catch (\Exception $e) {
            Log::error('Exception vérification PIN', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function resendPin(string $pinId): ?array
    {
        if (!$this->smsApi) return null;
        try {
            $response = $this->infobipHttp('POST', "/2fa/2/pin/{$pinId}/resend");
            if ($response->successful()) {
                $data = $response->json();
                Log::info('PIN renvoyé', ['pinId' => $data['pinId'] ?? $pinId]);
                return $data;
            }
            return null;
        } catch (\Exception $e) {
            Log::error('Exception renvoi PIN', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function getPinStatus(string $pinId): ?array
    {
        if (!$this->smsApi) return null;
        try {
            $response = $this->infobipHttp('GET', "/2fa/2/pin/{$pinId}/status");
            return $response->successful() ? $response->json() : null;
        } catch (\Exception $e) {
            Log::error('Exception statut PIN', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function getBalance(): ?array
    {
        if (!$this->smsApi) {
            if ($this->provider === 'africastalking') return $this->getAfricasTalkingBalance();
            return null;
        }
        try {
            $response = $this->infobipHttp('GET', '/account/1/balance');
            return $response->successful() ? $response->json() : null;
        } catch (\Exception $e) {
            Log::error('Erreur balance Infobip', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function checkBalance(): ?array
    {
        return $this->getBalance();
    }

    protected function sendViaTwilio(string $phone, string $message): bool
    {
        $accountSid = config('sms.twilio.sid');
        $authToken = config('sms.twilio.token');
        $fromNumber = config('sms.twilio.from');

        if (!$accountSid || !$authToken || !$fromNumber) {
            return $this->logOnly($phone, $message);
        }

        try {
            $twilioBase = config('services.twilio.base_url', 'https://api.twilio.com/2010-04-01');
            $response = Http::withBasicAuth($accountSid, $authToken)
                ->asForm()
                ->post("{$twilioBase}/Accounts/{$accountSid}/Messages.json", [
                    'To' => $phone, 'From' => $fromNumber, 'Body' => $message,
                ]);

            if ($response->successful()) {
                Log::info('SMS envoyé via Twilio', ['phone' => $phone, 'sid' => $response->json('sid')]);
                return true;
            }
            Log::error('Twilio SMS échoué', ['phone' => $phone, 'error' => $response->json()]);
            return false;
        } catch (\Exception $e) {
            Log::error('Exception Twilio', ['phone' => $phone, 'error' => $e->getMessage()]);
            return false;
        }
    }

    protected function sendViaAfricasTalking(string $phone, string $message): bool
    {
        $apiKey = config('sms.africastalking.api_key');
        $username = config('sms.africastalking.username');
        $senderId = config('sms.africastalking.sender_id', 'DR-PHARMA');

        if (!$apiKey || !$username) {
            return $this->logOnly($phone, $message);
        }

        try {
            $atBase = config('services.africas_talking.base_url', 'https://api.africastalking.com/version1');
            $response = Http::withHeaders([
                'apiKey' => $apiKey,
                'Content-Type' => 'application/x-www-form-urlencoded',
                'Accept' => 'application/json',
            ])->asForm()->post("{$atBase}/messaging", [
                'username' => $username, 'to' => $phone, 'message' => $message, 'from' => $senderId,
            ]);

            if ($response->successful()) {
                $data = $response->json();
                $recipients = $data['SMSMessageData']['Recipients'] ?? [];
                if (!empty($recipients) && $recipients[0]['status'] === 'Success') {
                    Log::info("SMS envoyé via Africa's Talking", ['phone' => $phone]);
                    return true;
                }
                return false;
            }
            return false;
        } catch (\Exception $e) {
            Log::error("Exception Africa's Talking", ['phone' => $phone, 'error' => $e->getMessage()]);
            return false;
        }
    }

    protected function getAfricasTalkingBalance(): ?array
    {
        $apiKey = config('sms.africastalking.api_key');
        $username = config('sms.africastalking.username');
        if (!$apiKey || !$username) return null;

        try {
            $atBase = config('services.africas_talking.base_url', 'https://api.africastalking.com/version1');
            $response = Http::withHeaders(['apiKey' => $apiKey, 'Accept' => 'application/json'])
                ->get("{$atBase}/user?username={$username}");
            return $response->successful() ? $response->json('UserData') : null;
        } catch (\Exception $e) {
            return null;
        }
    }

    protected function infobipHttp(string $method, string $endpoint, array $data = []): \Illuminate\Http\Client\Response
    {
        $baseUrl = rtrim(config('sms.infobip.base_url', ''), '/');
        $apiKey = config('sms.infobip.api_key', '');

        $request = Http::withHeaders([
            'Authorization' => "App {$apiKey}",
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
        ])->timeout(config('sms.infobip.timeout', 30));

        $url = $baseUrl . $endpoint;

        return match (strtoupper($method)) {
            'GET' => $request->get($url),
            'POST' => $request->post($url, $data),
            'PUT' => $request->put($url, $data),
            'DELETE' => $request->delete($url),
            default => throw new \InvalidArgumentException("Méthode HTTP non supportée: {$method}"),
        };
    }

    public function isInfobipConfigured(): bool
    {
        return $this->clientFactory->isSmsConfigured();
    }

    public function isConfigured(): bool
    {
        return match ($this->provider) {
            'infobip' => $this->isInfobipConfigured(),
            'twilio' => !empty(config('sms.twilio.sid')) && !empty(config('sms.twilio.token')),
            'africastalking' => !empty(config('sms.africastalking.api_key')),
            default => false,
        };
    }

    protected function logOnly(string $phone, string $message): bool
    {
        Log::info('SMS (log only)', ['phone' => $phone, 'message' => $message]);
        return true;
    }

    public function normalizePhone(string $phone): string
    {
        $phone = preg_replace('/[^\d+]/', '', $phone);
        $countryCode = config('sms.default_country_code', '+225');

        // Numéros CI: 10 chiffres commençant par 0 — le 0 fait partie du numéro
        if (str_starts_with($phone, '0') && strlen($phone) == 10) {
            $phone = $countryCode . $phone;
        }

        if (!str_starts_with($phone, '+')) {
            $codeWithoutPlus = ltrim($countryCode, '+');
            if (!str_starts_with($phone, $codeWithoutPlus)) {
                $phone = $countryCode . $phone;
            } else {
                $phone = '+' . $phone;
            }
        }

        return $phone;
    }

    public function getProvider(): string
    {
        return $this->provider;
    }
}
