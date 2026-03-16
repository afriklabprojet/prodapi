<?php

namespace App\Services\Infobip;

use Infobip\Configuration;
use Infobip\Api\SmsApi;
use Infobip\Api\WhatsAppApi;
use Infobip\Api\TfaApi;

/**
 * Factory pour créer les clients Infobip SDK typés.
 * 
 * Centralise la configuration (host + apiKey) et fournit
 * des instances réutilisables des API classes du SDK officiel.
 * 
 * @see https://github.com/infobip/infobip-api-php-client
 */
class InfobipClientFactory
{
    protected Configuration $smsConfiguration;
    protected Configuration $whatsAppConfiguration;
    protected ?SmsApi $smsApi = null;
    protected ?WhatsAppApi $whatsAppApi = null;
    protected ?TfaApi $tfaApi = null;

    public function __construct()
    {
        // Configuration SMS (peut avoir un base_url/api_key différent de WhatsApp)
        $this->smsConfiguration = new Configuration(
            host: config('sms.infobip.base_url', ''),
            apiKey: config('sms.infobip.api_key', ''),
        );

        // Configuration WhatsApp
        $this->whatsAppConfiguration = new Configuration(
            host: config('whatsapp.base_url', ''),
            apiKey: config('whatsapp.api_key', ''),
        );
    }

    /**
     * Get SMS API client (singleton per request)
     */
    public function smsApi(): SmsApi
    {
        if ($this->smsApi === null) {
            $this->smsApi = new SmsApi(config: $this->smsConfiguration);
        }
        return $this->smsApi;
    }

    /**
     * Get WhatsApp API client (singleton per request)
     */
    public function whatsAppApi(): WhatsAppApi
    {
        if ($this->whatsAppApi === null) {
            $this->whatsAppApi = new WhatsAppApi(config: $this->whatsAppConfiguration);
        }
        return $this->whatsAppApi;
    }

    /**
     * Get TFA (2FA/OTP) API client (singleton per request)
     * Uses SMS configuration by default
     */
    public function tfaApi(): TfaApi
    {
        if ($this->tfaApi === null) {
            $this->tfaApi = new TfaApi(config: $this->smsConfiguration);
        }
        return $this->tfaApi;
    }

    /**
     * Get the SMS Configuration object
     */
    public function getSmsConfiguration(): Configuration
    {
        return $this->smsConfiguration;
    }

    /**
     * Get the WhatsApp Configuration object
     */
    public function getWhatsAppConfiguration(): Configuration
    {
        return $this->whatsAppConfiguration;
    }

    /**
     * Check if SMS is configured
     */
    public function isSmsConfigured(): bool
    {
        return !empty(config('sms.infobip.base_url'))
            && !empty(config('sms.infobip.api_key'));
    }

    /**
     * Check if WhatsApp is configured
     */
    public function isWhatsAppConfigured(): bool
    {
        return config('whatsapp.enabled', false)
            && !empty(config('whatsapp.base_url'))
            && !empty(config('whatsapp.api_key'))
            && !empty(config('whatsapp.sender_number'));
    }
}
