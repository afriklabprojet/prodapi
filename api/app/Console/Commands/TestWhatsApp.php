<?php

namespace App\Console\Commands;

use App\Services\WhatsAppService;
use Illuminate\Console\Command;

class TestWhatsApp extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'drpharma:test-whatsapp
        {phone? : Numéro de téléphone du destinataire (ex: 2250708621167)}
        {--template=test_whatsapp_template_en : Nom du template à utiliser}
        {--lang=en : Langue du template (en, fr)}
        {--name=Lacina : Nom du destinataire (placeholder)}
        {--text= : Envoyer un message texte libre au lieu d\'un template}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Tester l\'envoi de messages WhatsApp via Infobip';

    /**
     * Execute the console command.
     */
    public function handle(WhatsAppService $whatsapp): int
    {
        $this->info('');
        $this->info('╔═══════════════════════════════════════════════════╗');
        $this->info('║         DR-PHARMA — Test WhatsApp Infobip        ║');
        $this->info('╚═══════════════════════════════════════════════════╝');
        $this->newLine();

        // ── Vérification de la configuration ────────────────────────────
        $this->info('🔧 Vérification de la configuration...');
        $this->newLine();

        $this->components->twoColumnDetail('WhatsApp activé', config('whatsapp.enabled') ? '<fg=green>OUI</>' : '<fg=red>NON</>');
        $this->components->twoColumnDetail('Base URL', config('whatsapp.base_url') ?: '<fg=red>Non configuré</>');
        $this->components->twoColumnDetail('API Key', config('whatsapp.api_key') ? '<fg=green>Configuré (masqué)</>' : '<fg=red>Non configuré</>');
        $this->components->twoColumnDetail('Numéro expéditeur', config('whatsapp.sender_number') ?: '<fg=red>Non configuré</>');
        $this->components->twoColumnDetail('SMS Failover', config('whatsapp.sms_failover.enabled') ? '<fg=green>OUI</>' : '<fg=yellow>NON</>');
        $this->newLine();

        if (! $whatsapp->isConfigured()) {
            $this->error('❌ WhatsApp n\'est pas correctement configuré.');
            $this->warn('Vérifiez les variables suivantes dans votre .env :');
            $this->line('  WHATSAPP_ENABLED=true');
            $this->line('  WHATSAPP_INFOBIP_BASE_URL=https://xxxxx.api.infobip.com');
            $this->line('  WHATSAPP_INFOBIP_API_KEY=votre_clé_api');
            $this->line('  WHATSAPP_SENDER_NUMBER=votre_numéro');

            return self::FAILURE;
        }

        $this->info('<fg=green>✅ Configuration WhatsApp OK</>');
        $this->newLine();

        // ── Récupération du numéro de téléphone ─────────────────────────
        $phone = $this->argument('phone')
            ?? $this->ask('📱 Numéro de téléphone du destinataire (format international)', '2250708621167');

        if (empty($phone)) {
            $this->error('❌ Numéro de téléphone requis.');

            return self::FAILURE;
        }

        // ── Envoi du message ────────────────────────────────────────────
        $freeText = $this->option('text');

        if ($freeText) {
            // Envoi d'un message texte libre
            $this->info("📤 Envoi d'un message texte libre à {$phone}...");
            $this->components->twoColumnDetail('Message', $freeText);
            $this->newLine();

            if (! $this->confirm('Confirmer l\'envoi ?', true)) {
                $this->warn('Envoi annulé.');

                return self::SUCCESS;
            }

            $result = $whatsapp->sendText($phone, $freeText);
        } else {
            // Envoi d'un template
            $templateName = $this->option('template');
            $language = $this->option('lang');
            $name = $this->option('name');

            $this->info("📤 Envoi du template '{$templateName}' à {$phone}...");
            $this->components->twoColumnDetail('Template', $templateName);
            $this->components->twoColumnDetail('Langue', $language);
            $this->components->twoColumnDetail('Placeholders', "['{$name}']");
            $this->newLine();

            // Vérifier si le template existe dans la config
            $templateConfig = config("whatsapp.templates.{$templateName}");
            if ($templateConfig) {
                $this->info('📋 Template trouvé dans la configuration :');
                $this->components->twoColumnDetail('Catégorie', $templateConfig['category'] ?? 'N/A');
                foreach ($templateConfig['placeholders'] ?? [] as $key => $desc) {
                    $this->components->twoColumnDetail("  {$key}", $desc);
                }
                $this->newLine();
            } else {
                $this->warn("⚠️  Template '{$templateName}' non trouvé dans config/whatsapp.php (il sera envoyé quand même).");
                $this->newLine();
            }

            if (! $this->confirm('Confirmer l\'envoi ?', true)) {
                $this->warn('Envoi annulé.');

                return self::SUCCESS;
            }

            $result = $whatsapp->sendTemplate(
                to: $phone,
                templateName: $templateName,
                language: $language,
                placeholders: [$name],
            );
        }

        // ── Résultat ────────────────────────────────────────────────────
        $this->newLine();

        if ($result) {
            $this->info('╔═══════════════════════════════════════════════════╗');
            $this->info('║   ✅ Message WhatsApp envoyé avec succès !       ║');
            $this->info('╚═══════════════════════════════════════════════════╝');
            $this->newLine();
            $this->line('Consultez les logs pour les détails (storage/logs/laravel.log).');

            return self::SUCCESS;
        } else {
            $this->error('╔═══════════════════════════════════════════════════╗');
            $this->error('║   ❌ Échec de l\'envoi du message WhatsApp        ║');
            $this->error('╚═══════════════════════════════════════════════════╝');
            $this->newLine();
            $this->warn('Vérifiez les logs pour plus de détails : storage/logs/laravel.log');
            $this->warn('Causes possibles :');
            $this->line('  • Template non approuvé sur le portail Infobip/Meta');
            $this->line('  • Numéro de téléphone invalide');
            $this->line('  • Clé API invalide ou expirée');
            $this->line('  • Le destinataire n\'a pas WhatsApp');

            return self::FAILURE;
        }
    }
}
