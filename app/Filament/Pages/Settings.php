<?php

namespace App\Filament\Pages;

use App\Models\Setting;
use App\Models\User;
use Filament\Actions\Action;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Auth;

class Settings extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';
    
    protected static ?string $navigationLabel = 'Paramètres système';
    
    protected static ?string $navigationGroup = 'Configuration';
    
    protected static ?string $slug = 'system-settings';

    protected static string $view = 'filament.pages.settings';

    public ?array $data = [];

    /**
     * Seul l'admin peut accéder à cette page
     */
    public static function canAccess(): bool
    {
        /** @var User|null $user */
        $user = Auth::user();

        return $user?->isAdmin() ?? false;
    }

    public function mount(): void
    {
        // Double vérification de l'accès admin
        /** @var User|null $user */
        $user = Auth::user();
        abort_unless($user?->isAdmin(), 403, 'Accès réservé à l\'administrateur');
        
        $this->form->fill([
            'search_radius_km' => Setting::get('search_radius_km', 20),
            // Commissions
            'default_commission_rate_platform' => Setting::get('default_commission_rate_platform', 10),
            'default_commission_rate_pharmacy' => Setting::get('default_commission_rate_pharmacy', 85),
            'default_commission_rate_courier' => Setting::get('default_commission_rate_courier', 5),
            'courier_commission_amount' => Setting::get('courier_commission_amount', 200),
            'courier_commission_percentage' => Setting::get('courier_commission_percentage', 15),
            'minimum_wallet_balance' => Setting::get('minimum_wallet_balance', 200),
            'delivery_fee_base' => Setting::get('delivery_fee_base', 200),
            'delivery_fee_per_km' => Setting::get('delivery_fee_per_km', 100),
            'delivery_fee_min' => Setting::get('delivery_fee_min', 300),
            'delivery_fee_max' => Setting::get('delivery_fee_max', 5000),
            // Frais de service et paiement (ajoutés au prix pour que la pharmacie reçoive le prix exact)
            'service_fee_fixed' => Setting::get('service_fee_fixed', 100),
            'service_fee_percentage' => Setting::get('service_fee_percentage', 2),
            'service_fee_min' => Setting::get('service_fee_min', 100),
            'service_fee_max' => Setting::get('service_fee_max', 2000),
            'payment_processing_fee' => Setting::get('payment_processing_fee', 50),
            'payment_processing_percentage' => Setting::get('payment_processing_percentage', 1.5),
            'apply_service_fee' => Setting::get('apply_service_fee', true),
            'apply_payment_fee' => Setting::get('apply_payment_fee', true),
            'minimum_withdrawal_amount' => Setting::get('minimum_withdrawal_amount', 500),
            // Aide & Support
            'support_phone' => Setting::get('support_phone', '+225 07 01 159 572'),
            'support_email' => Setting::get('support_email', 'support@drlpharma.com'),
            'support_whatsapp' => Setting::get('support_whatsapp', '+225 07 01 159 572'),
            'website_url' => Setting::get('website_url', config('drpharma.brand.website')),
            'tutorials_url' => Setting::get('tutorials_url', config('drpharma.brand.youtube')),
            'guide_url' => Setting::get('guide_url', config('drpharma.urls.guide')),
            'faq_url' => Setting::get('faq_url', config('drpharma.urls.faq')),
            'terms_url' => Setting::get('terms_url', config('drpharma.urls.terms')),
            'privacy_url' => Setting::get('privacy_url', config('drpharma.urls.privacy')),
            // Modes de paiement
            'payment_mode_platform_enabled' => Setting::get('payment_mode_platform_enabled', true),
            'payment_mode_cash_enabled' => Setting::get('payment_mode_cash_enabled', false),
            'payment_mode_wallet_enabled' => Setting::get('payment_mode_wallet_enabled', true),
            // Paramètres minuterie d'attente
            'waiting_timeout_minutes' => Setting::get('waiting_timeout_minutes', 10),
            'waiting_fee_per_minute' => Setting::get('waiting_fee_per_minute', 100),
            'waiting_free_minutes' => Setting::get('waiting_free_minutes', 2),
            // Paramètres sonneries notifications
            'sound_delivery_assigned' => Setting::get('sound_delivery_assigned', 'delivery_alert'),
            'sound_new_order' => Setting::get('sound_new_order', 'order_received'),
            'sound_courier_arrived' => Setting::get('sound_courier_arrived', 'courier_arrived'),
            'sound_delivery_timeout' => Setting::get('sound_delivery_timeout', 'timeout_alert'),
            'notification_vibrate_enabled' => Setting::get('notification_vibrate_enabled', true),
            'notification_led_enabled' => Setting::get('notification_led_enabled', true),
            'notification_led_color' => Setting::get('notification_led_color', '#FF6B00'),
            // Paramètres seuil de retrait
            'withdrawal_threshold_min' => Setting::get('withdrawal_threshold_min', 10000),
            'withdrawal_threshold_max' => Setting::get('withdrawal_threshold_max', 500000),
            'withdrawal_threshold_default' => Setting::get('withdrawal_threshold_default', 50000),
            'withdrawal_threshold_step' => Setting::get('withdrawal_threshold_step', 5000),
            'auto_withdraw_enabled_global' => Setting::get('auto_withdraw_enabled_global', true),
            'withdrawal_require_pin' => Setting::get('withdrawal_require_pin', true),
            'withdrawal_require_mobile_money' => Setting::get('withdrawal_require_mobile_money', true),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Section::make('Paramètres Généraux')
                    ->schema([
                        TextInput::make('search_radius_km')
                            ->label('Rayon de recherche par défaut (km)')
                            ->numeric()
                            ->required()
                            ->helperText('Distance maximale pour rechercher un livreur autour de la pharmacie.'),
                    ])->columns(2),

                Section::make('Commissions par Défaut')
                    ->description('Répartition des commissions sur chaque commande. Ces taux s\'appliquent aux nouvelles pharmacies. Vous pouvez personnaliser les taux par pharmacie depuis la fiche de chaque pharmacie.')
                    ->icon('heroicon-o-calculator')
                    ->schema([
                        TextInput::make('default_commission_rate_platform')
                            ->label('🏛️ Taux plateforme par défaut (%)')
                            ->numeric()
                            ->suffix('%')
                            ->minValue(0)
                            ->maxValue(100)
                            ->required()
                            ->helperText('Part de la plateforme sur le total de la commande (défaut pour nouvelles pharmacies).'),
                        TextInput::make('default_commission_rate_pharmacy')
                            ->label('🏥 Taux pharmacie par défaut (%)')
                            ->numeric()
                            ->suffix('%')
                            ->minValue(0)
                            ->maxValue(100)
                            ->required()
                            ->helperText('Part de la pharmacie sur le total de la commande (défaut pour nouvelles pharmacies).'),
                        TextInput::make('default_commission_rate_courier')
                            ->label('🚴 Taux livreur par défaut (%)')
                            ->numeric()
                            ->suffix('%')
                            ->minValue(0)
                            ->maxValue(100)
                            ->required()
                            ->helperText('Part du livreur sur le total de la commande (défaut pour nouvelles pharmacies).'),
                    ])->columns(2),

                Section::make('Livreurs & Livraison')
                    ->description('Paramètres financiers pour les livreurs')
                    ->icon('heroicon-o-truck')
                    ->schema([
                        TextInput::make('courier_commission_percentage')
                            ->label('Commission plateforme par livraison (%)')
                            ->numeric()
                            ->suffix('%')
                            ->required()
                            ->minValue(0)
                            ->maxValue(100)
                            ->helperText('Pourcentage prélevé sur les frais de livraison à chaque livraison terminée. Ex: 15 = 15%.'),
                        TextInput::make('courier_commission_amount')
                            ->label('Commission minimum par livraison (FCFA)')
                            ->numeric()
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Utilisé si les frais de livraison sont à 0 (fallback).'),
                        TextInput::make('minimum_wallet_balance')
                            ->label('Solde minimum requis (FCFA)')
                            ->numeric()
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Solde minimum pour qu\'un livreur puisse accepter des livraisons.'),
                        TextInput::make('delivery_fee_base')
                            ->label('Frais de départ (FCFA)')
                            ->numeric()
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Montant fixe de départ pour toute livraison.'),
                        TextInput::make('delivery_fee_per_km')
                            ->label('Frais par kilomètre (FCFA/km)')
                            ->numeric()
                            ->suffix('FCFA/km')
                            ->required()
                            ->helperText('Montant ajouté par kilomètre parcouru.'),
                        TextInput::make('delivery_fee_min')
                            ->label('Frais minimum (FCFA)')
                            ->numeric()
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Montant minimum facturé quelle que soit la distance.'),
                        TextInput::make('delivery_fee_max')
                            ->label('Frais maximum (FCFA)')
                            ->numeric()
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Plafond maximum des frais de livraison.'),
                        TextInput::make('minimum_withdrawal_amount')
                            ->label('Retrait minimum (FCFA)')
                            ->numeric()
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Montant minimum pour un retrait vers Mobile Money.'),
                    ])->columns(2),

                Section::make('Frais de Service & Paiement')
                    ->description('Ces frais sont ajoutés au prix des médicaments. La pharmacie reçoit le prix exact qu\'elle a fixé.')
                    ->icon('heroicon-o-banknotes')
                    ->schema([
                        Toggle::make('apply_service_fee')
                            ->label('Activer les frais de service')
                            ->helperText('Appliquer les frais de service sur chaque commande.')
                            ->default(true)
                            ->columnSpanFull(),
                        TextInput::make('service_fee_fixed')
                            ->label('Frais de service fixes par commande (FCFA)')
                            ->numeric()
                            ->suffix('FCFA')
                            ->minValue(0)
                            ->required()
                            ->helperText('Montant fixe prélevé par commande et reversé à la plateforme (ex: 100 FCFA).'),
                        TextInput::make('service_fee_percentage')
                            ->label('Frais de service (%)')
                            ->numeric()
                            ->suffix('%')
                            ->minValue(0)
                            ->maxValue(20)
                            ->required()
                            ->helperText('Pourcentage appliqué sur le sous-total des médicaments (ex: 3%).'),
                        TextInput::make('service_fee_min')
                            ->label('Frais de service minimum (FCFA)')
                            ->numeric()
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Montant minimum des frais de service quelle que soit la commande.'),
                        TextInput::make('service_fee_max')
                            ->label('Frais de service maximum (FCFA)')
                            ->numeric()
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Plafond maximum des frais de service.'),
                        Toggle::make('apply_payment_fee')
                            ->label('Activer les frais de paiement')
                            ->helperText('Appliquer les frais de traitement de paiement en ligne.')
                            ->default(true)
                            ->columnSpanFull(),
                        TextInput::make('payment_processing_fee')
                            ->label('Frais fixes de paiement (FCFA)')
                            ->numeric()
                            ->suffix('FCFA')
                            ->minValue(0)
                            ->required()
                            ->helperText('Montant fixe ajouté pour chaque paiement en ligne (ex: 50 FCFA).'),
                        TextInput::make('payment_processing_percentage')
                            ->label('Frais de paiement (%)')
                            ->numeric()
                            ->suffix('%')
                            ->minValue(0)
                            ->maxValue(10)
                            ->required()
                            ->helperText('Pourcentage appliqué sur le total pour les paiements en ligne (ex: 1.5%).'),
                    ])->columns(2),

                Section::make('Aide & Support')
                    ->description('Informations de contact et ressources affichées dans les applications mobiles')
                    ->icon('heroicon-o-lifebuoy')
                    ->schema([
                        TextInput::make('support_phone')
                            ->label('Téléphone Support')
                            ->tel()
                            ->placeholder('+225 XX XX XX XX XX')
                            ->required()
                            ->helperText('Numéro de téléphone pour le support client.'),
                        TextInput::make('support_email')
                            ->label('Email Support')
                            ->email()
                            ->placeholder('support@drlpharma.com')
                            ->required()
                            ->helperText('Adresse email pour le support client.'),
                        TextInput::make('support_whatsapp')
                            ->label('WhatsApp Support')
                            ->tel()
                            ->placeholder('+225 XX XX XX XX XX')
                            ->required()
                            ->helperText('Numéro WhatsApp pour le chat en direct (format international).'),
                        TextInput::make('website_url')
                            ->label('Site Web')
                            ->url()
                            ->placeholder(config('drpharma.brand.website'))
                            ->required()
                            ->helperText('URL du site web principal.'),
                        TextInput::make('tutorials_url')
                            ->label('URL Tutoriels Vidéo')
                            ->url()
                            ->placeholder(config('drpharma.brand.youtube'))
                            ->helperText('Lien vers les tutoriels vidéo (YouTube, etc.).'),
                        TextInput::make('guide_url')
                            ->label('URL Guide Utilisateur')
                            ->url()
                            ->placeholder(config('drpharma.urls.guide'))
                            ->helperText('Lien vers le guide utilisateur en ligne.'),
                        TextInput::make('faq_url')
                            ->label('URL FAQ')
                            ->url()
                            ->placeholder(config('drpharma.urls.faq'))
                            ->helperText('Lien vers la page FAQ.'),
                        TextInput::make('terms_url')
                            ->label('URL Conditions d\'utilisation')
                            ->url()
                            ->placeholder(config('drpharma.urls.terms'))
                            ->helperText('Lien vers les conditions générales d\'utilisation.'),
                        TextInput::make('privacy_url')
                            ->label('URL Politique de confidentialité')
                            ->url()
                            ->placeholder(config('drpharma.urls.privacy'))
                            ->helperText('Lien vers la politique de confidentialité.'),
                    ])->columns(3),

                Section::make('Modes de Paiement')
                    ->description('Activez ou désactivez les modes de paiement disponibles dans l\'application client')
                    ->icon('heroicon-o-credit-card')
                    ->schema([
                        Toggle::make('payment_mode_platform_enabled')
                            ->label('Paiement en ligne (Mobile Money)')
                            ->helperText('Permet aux clients de payer via Mobile Money (Orange, MTN, Wave) lors de la commande.')
                            ->default(true),
                        Toggle::make('payment_mode_wallet_enabled')
                            ->label('Paiement par portefeuille')
                            ->helperText('Permet aux clients de payer avec leur solde de portefeuille DR-PHARMA.')
                            ->default(true),
                        Toggle::make('payment_mode_cash_enabled')
                            ->label('Paiement à la livraison (espèces)')
                            ->helperText('Permet aux clients de payer en espèces lors de la réception de la commande.')
                            ->default(false),
                    ])->columns(3),

                Section::make('Minuterie d\'attente livraison')
                    ->description('Paramètres pour gérer le temps d\'attente du livreur chez le client')
                    ->schema([
                        TextInput::make('waiting_timeout_minutes')
                            ->label('Délai max d\'attente (minutes)')
                            ->numeric()
                            ->minValue(5)
                            ->maxValue(60)
                            ->suffix('min')
                            ->required()
                            ->helperText('Durée maximale d\'attente avant annulation automatique de la livraison.'),
                        TextInput::make('waiting_fee_per_minute')
                            ->label('Frais d\'attente par minute (FCFA)')
                            ->numeric()
                            ->minValue(0)
                            ->suffix('FCFA/min')
                            ->required()
                            ->helperText('Montant facturé au client par minute d\'attente du livreur.'),
                        TextInput::make('waiting_free_minutes')
                            ->label('Minutes gratuites')
                            ->numeric()
                            ->minValue(0)
                            ->maxValue(10)
                            ->suffix('min')
                            ->required()
                            ->helperText('Nombre de minutes gratuites avant de commencer la facturation.'),
                    ])->columns(3),

                Section::make('Sonneries des Notifications')
                    ->description('Configurez les sons joués pour chaque type de notification push')
                    ->icon('heroicon-o-bell-alert')
                    ->collapsible()
                    ->schema([
                        Select::make('sound_delivery_assigned')
                            ->label('🚨 Nouvelle livraison (Livreur)')
                            ->options($this->getAvailableSounds())
                            ->required()
                            ->helperText('Son joué quand un livreur reçoit une nouvelle assignation de livraison.'),
                        Select::make('sound_new_order')
                            ->label('🛒 Nouvelle commande (Pharmacie)')
                            ->options($this->getAvailableSounds())
                            ->required()
                            ->helperText('Son joué quand une pharmacie reçoit une nouvelle commande.'),
                        Select::make('sound_courier_arrived')
                            ->label('📍 Livreur arrivé (Client)')
                            ->options($this->getAvailableSounds())
                            ->required()
                            ->helperText('Son joué quand le livreur est arrivé chez le client.'),
                        Select::make('sound_delivery_timeout')
                            ->label('⏰ Annulation timeout')
                            ->options($this->getAvailableSounds())
                            ->required()
                            ->helperText('Son joué lors d\'une annulation automatique pour dépassement de délai.'),
                    ])->columns(2),

                Section::make('Options de Notification')
                    ->description('Paramètres additionnels pour les notifications push')
                    ->icon('heroicon-o-device-phone-mobile')
                    ->collapsible()
                    ->schema([
                        Toggle::make('notification_vibrate_enabled')
                            ->label('Activer la vibration')
                            ->helperText('Le téléphone vibrera lors de la réception d\'une notification importante.')
                            ->default(true),
                        Toggle::make('notification_led_enabled')
                            ->label('Activer le LED de notification')
                            ->helperText('La LED du téléphone clignotera lors de la réception d\'une notification.')
                            ->default(true),
                        TextInput::make('notification_led_color')
                            ->label('Couleur du LED')
                            ->type('color')
                            ->default('#FF6B00')
                            ->helperText('Couleur du clignotement LED pour les notifications.'),
                    ])->columns(3),

                Section::make('Seuil de Retrait Automatique')
                    ->description('Configurez les limites et paramètres globaux du seuil de retrait pour les pharmacies')
                    ->icon('heroicon-o-banknotes')
                    ->collapsible()
                    ->schema([
                        TextInput::make('withdrawal_threshold_min')
                            ->label('Seuil minimum (FCFA)')
                            ->numeric()
                            ->minValue(1000)
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Montant minimum que les pharmacies peuvent définir comme seuil.'),
                        TextInput::make('withdrawal_threshold_max')
                            ->label('Seuil maximum (FCFA)')
                            ->numeric()
                            ->maxValue(5000000)
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Montant maximum autorisé pour le seuil de retrait.'),
                        TextInput::make('withdrawal_threshold_default')
                            ->label('Seuil par défaut (FCFA)')
                            ->numeric()
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Valeur par défaut pour les nouvelles pharmacies.'),
                        TextInput::make('withdrawal_threshold_step')
                            ->label('Pas d\'incrémentation (FCFA)')
                            ->numeric()
                            ->minValue(1000)
                            ->suffix('FCFA')
                            ->required()
                            ->helperText('Intervalle de sélection du slider dans l\'app mobile.'),
                        Toggle::make('auto_withdraw_enabled_global')
                            ->label('Autoriser le retrait automatique')
                            ->helperText('Permettre aux pharmacies d\'activer le retrait automatique.')
                            ->default(true),
                        Toggle::make('withdrawal_require_pin')
                            ->label('Exiger un code PIN')
                            ->helperText('Les pharmacies doivent configurer un code PIN pour les retraits.')
                            ->default(true),
                        Toggle::make('withdrawal_require_mobile_money')
                            ->label('Exiger Mobile Money configuré')
                            ->helperText('Le retrait automatique nécessite un compte Mobile Money enregistré.')
                            ->default(true),
                    ])->columns(2),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        Setting::set('search_radius_km', $data['search_radius_km'], 'integer');
        Setting::set('default_commission_rate_platform', $data['default_commission_rate_platform'], 'float');
        Setting::set('default_commission_rate_pharmacy', $data['default_commission_rate_pharmacy'], 'float');
        Setting::set('default_commission_rate_courier', $data['default_commission_rate_courier'], 'float');
        Setting::set('courier_commission_percentage', $data['courier_commission_percentage'], 'float');
        Setting::set('courier_commission_amount', $data['courier_commission_amount'], 'integer');
        Setting::set('minimum_wallet_balance', $data['minimum_wallet_balance'], 'integer');
        Setting::set('delivery_fee_base', $data['delivery_fee_base'], 'integer');
        Setting::set('delivery_fee_per_km', $data['delivery_fee_per_km'], 'integer');
        Setting::set('delivery_fee_min', $data['delivery_fee_min'], 'integer');
        Setting::set('delivery_fee_max', $data['delivery_fee_max'], 'integer');
        // Frais de service et paiement
        Setting::set('service_fee_fixed', $data['service_fee_fixed'], 'integer');
        Setting::set('service_fee_percentage', $data['service_fee_percentage'], 'float');
        Setting::set('service_fee_min', $data['service_fee_min'], 'integer');
        Setting::set('service_fee_max', $data['service_fee_max'], 'integer');
        Setting::set('payment_processing_fee', $data['payment_processing_fee'], 'integer');
        Setting::set('payment_processing_percentage', $data['payment_processing_percentage'], 'float');
        Setting::set('apply_service_fee', $data['apply_service_fee'], 'boolean');
        Setting::set('apply_payment_fee', $data['apply_payment_fee'], 'boolean');
        Setting::set('minimum_withdrawal_amount', $data['minimum_withdrawal_amount'], 'integer');
        // Aide & Support
        Setting::set('support_phone', $data['support_phone'], 'string');
        Setting::set('support_email', $data['support_email'], 'string');
        Setting::set('support_whatsapp', $data['support_whatsapp'], 'string');
        Setting::set('website_url', $data['website_url'], 'string');
        Setting::set('tutorials_url', $data['tutorials_url'] ?? '', 'string');
        Setting::set('guide_url', $data['guide_url'] ?? '', 'string');
        Setting::set('faq_url', $data['faq_url'] ?? '', 'string');
        Setting::set('terms_url', $data['terms_url'] ?? '', 'string');
        Setting::set('privacy_url', $data['privacy_url'] ?? '', 'string');
        // Modes de paiement
        Setting::set('payment_mode_platform_enabled', $data['payment_mode_platform_enabled'], 'boolean');
        Setting::set('payment_mode_cash_enabled', $data['payment_mode_cash_enabled'], 'boolean');
        Setting::set('payment_mode_wallet_enabled', $data['payment_mode_wallet_enabled'], 'boolean');
        // Paramètres minuterie d'attente
        Setting::set('waiting_timeout_minutes', $data['waiting_timeout_minutes'], 'integer');
        Setting::set('waiting_fee_per_minute', $data['waiting_fee_per_minute'], 'integer');
        Setting::set('waiting_free_minutes', $data['waiting_free_minutes'], 'integer');
        // Paramètres sonneries notifications
        Setting::set('sound_delivery_assigned', $data['sound_delivery_assigned'], 'string');
        Setting::set('sound_new_order', $data['sound_new_order'], 'string');
        Setting::set('sound_courier_arrived', $data['sound_courier_arrived'], 'string');
        Setting::set('sound_delivery_timeout', $data['sound_delivery_timeout'], 'string');
        Setting::set('notification_vibrate_enabled', $data['notification_vibrate_enabled'], 'boolean');
        Setting::set('notification_led_enabled', $data['notification_led_enabled'], 'boolean');
        Setting::set('notification_led_color', $data['notification_led_color'], 'string');
        // Paramètres seuil de retrait
        Setting::set('withdrawal_threshold_min', $data['withdrawal_threshold_min'], 'integer');
        Setting::set('withdrawal_threshold_max', $data['withdrawal_threshold_max'], 'integer');
        Setting::set('withdrawal_threshold_default', $data['withdrawal_threshold_default'], 'integer');
        Setting::set('withdrawal_threshold_step', $data['withdrawal_threshold_step'], 'integer');
        Setting::set('auto_withdraw_enabled_global', $data['auto_withdraw_enabled_global'], 'boolean');
        Setting::set('withdrawal_require_pin', $data['withdrawal_require_pin'], 'boolean');
        Setting::set('withdrawal_require_mobile_money', $data['withdrawal_require_mobile_money'], 'boolean');

        Notification::make() 
            ->success()
            ->title('Paramètres enregistrés avec succès')
            ->send();
    }

    /**
     * Liste des sonneries disponibles pour les notifications
     */
    protected function getAvailableSounds(): array
    {
        return [
            'default' => '🔔 Par défaut',
            'delivery_alert' => '🚨 Alerte livraison (urgente)',
            'order_received' => '🛒 Commande reçue',
            'courier_arrived' => '📍 Arrivée livreur',
            'timeout_alert' => '⏰ Alerte timeout',
            'success_chime' => '✅ Succès',
            'warning_tone' => '⚠️ Avertissement',
            'urgent_bell' => '🔔 Cloche urgente',
            'soft_notification' => '🔕 Notification douce',
            'cash_register' => '💰 Caisse enregistreuse',
            'doorbell' => '🚪 Sonnette',
            'message_tone' => '💬 Ton de message',
            'none' => '🔇 Aucun son (silencieux)',
        ];
    }

    protected function getFormActions(): array
    {
        return [
            Action::make('save')
                ->label('Enregistrer')
                ->submit('save'),
        ];
    }
}
