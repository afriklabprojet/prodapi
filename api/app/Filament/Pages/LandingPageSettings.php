<?php

namespace App\Filament\Pages;

use App\Models\Setting;
use Filament\Actions\Action;
use Filament\Forms\Components\Grid;
use Filament\Forms\Components\Placeholder;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Concerns\InteractsWithForms;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;

class LandingPageSettings extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-globe-alt';

    protected static ?string $navigationLabel = 'Landing Page';

    protected static ?string $title = 'Gestion du Landing Page';

    protected static ?string $navigationGroup = 'Configuration';

    protected static ?int $navigationSort = 10;

    protected static ?string $slug = 'landing-page';

    protected static string $view = 'filament.pages.landing-page-settings';

    public ?array $data = [];

    public static function canAccess(): bool
    {
        /** @var User|null $user */
        $user = Auth::user();

        return $user?->isAdmin() ?? false;
    }

    public function mount(): void
    {
        /** @var User|null $user */
        $user = Auth::user();

        abort_unless($user?->isAdmin(), 403, 'Accès réservé à l\'administrateur');

        $this->form->fill([
            // === HERO ===
            'hero_badge' => Setting::get('landing_hero_badge', 'Disponible en Côte d\'Ivoire'),
            'hero_title_line1' => Setting::get('landing_hero_title_line1', 'Votre santé,'),
            'hero_title_line2' => Setting::get('landing_hero_title_line2', 'simplifiée.'),
            'hero_subtitle' => Setting::get('landing_hero_subtitle', 'Commandez vos médicaments, gérez votre pharmacie ou livrez en toute sécurité — tout depuis votre smartphone.'),
            'hero_cta_appstore_text' => Setting::get('landing_hero_cta_appstore_text', 'App Store'),
            'hero_cta_appstore_url' => Setting::get('landing_hero_cta_appstore_url', '#telecharger'),
            'hero_cta_playstore_text' => Setting::get('landing_hero_cta_playstore_text', 'Google Play'),
            'hero_cta_playstore_url' => Setting::get('landing_hero_cta_playstore_url', '#telecharger'),
            'hero_trust_1' => Setting::get('landing_hero_trust_1', 'Gratuit'),
            'hero_trust_2' => Setting::get('landing_hero_trust_2', 'Sécurisé'),
            'hero_trust_3' => Setting::get('landing_hero_trust_3', 'Rapide'),
            'hero_phone_title' => Setting::get('landing_hero_phone_title', 'DR-PHARMA'),
            'hero_phone_subtitle' => Setting::get('landing_hero_phone_subtitle', 'Votre pharmacie de poche'),

            // === STATS ===
            'stats_auto' => Setting::get('landing_stats_auto', true),
            'stats' => Setting::get('landing_stats', [
                ['value' => '500', 'suffix' => '+', 'label' => 'Pharmacies partenaires'],
                ['value' => '10000', 'suffix' => '+', 'label' => 'Utilisateurs actifs'],
                ['value' => '2000', 'suffix' => '+', 'label' => 'Médicaments référencés'],
                ['value' => '98', 'suffix' => '%', 'label' => 'Satisfaction client'],
            ]),

            // === FEATURES ===
            'features_badge' => Setting::get('landing_features_badge', 'Fonctionnalités'),
            'features_title' => Setting::get('landing_features_title', 'Tout ce dont vous avez besoin'),
            'features_title_highlight' => Setting::get('landing_features_title_highlight', 'besoin'),
            'features_subtitle' => Setting::get('landing_features_subtitle', 'Une plateforme complète qui connecte patients, pharmaciens et coursiers pour un accès simple et rapide aux médicaments.'),
            'features' => Setting::get('landing_features', [
                ['title' => 'Recherche intelligente', 'description' => 'Trouvez vos médicaments en quelques secondes parmi plus de 2000 références. Recherche par nom, catégorie ou symptôme.', 'icon_color' => 'green'],
                ['title' => 'Ordonnances numériques', 'description' => 'Envoyez une photo de votre ordonnance et recevez vos médicaments sans vous déplacer. Rapide et sécurisé.', 'icon_color' => 'blue'],
                ['title' => 'Suivi GPS en temps réel', 'description' => 'Suivez votre livreur en direct sur la carte. Notifications à chaque étape pour une transparence totale.', 'icon_color' => 'amber'],
                ['title' => 'Paiement sécurisé', 'description' => 'Mobile Money, carte bancaire ou paiement à la livraison. Vos transactions sont 100% sécurisées et chiffrées.', 'icon_color' => 'purple'],
                ['title' => 'Livraison express', 'description' => 'Recevez vos médicaments en moins de 45 minutes. Notre réseau de coursiers couvre tout Abidjan.', 'icon_color' => 'rose'],
                ['title' => 'Tableau de bord pharmacie', 'description' => 'Gérez vos stocks, commandes et statistiques depuis un dashboard intuitif. Analyses en temps réel.', 'icon_color' => 'cyan'],
            ]),

            // === STEPS ===
            'steps_badge' => Setting::get('landing_steps_badge', 'Processus'),
            'steps_title' => Setting::get('landing_steps_title', 'Comment ça marche ?'),
            'steps_title_highlight' => Setting::get('landing_steps_title_highlight', 'marche ?'),
            'steps_subtitle' => Setting::get('landing_steps_subtitle', 'En seulement 3 étapes, recevez vos médicaments à domicile.'),
            'steps' => Setting::get('landing_steps', [
                ['title' => 'Recherchez', 'description' => 'Tapez le nom du médicament ou envoyez une photo de votre ordonnance directement dans l\'app.', 'color' => 'green'],
                ['title' => 'Commandez', 'description' => 'Choisissez la pharmacie la plus proche, ajoutez au panier et payez en toute sécurité.', 'color' => 'blue'],
                ['title' => 'Recevez', 'description' => 'Un coursier récupère votre commande et vous la livre en moins de 45 minutes. Suivez-le en direct !', 'color' => 'amber'],
            ]),

            // === APPS ===
            'apps_badge' => Setting::get('landing_apps_badge', 'Nos Applications'),
            'apps_title' => Setting::get('landing_apps_title', '3 apps, 1 écosystème'),
            'apps_title_highlight' => Setting::get('landing_apps_title_highlight', '1 écosystème'),
            'apps_subtitle' => Setting::get('landing_apps_subtitle', 'Chaque acteur de la chaîne dispose de son application dédiée, connectée en temps réel.'),
            'apps' => Setting::get('landing_apps', [
                [
                    'tag' => 'PATIENT',
                    'title' => 'App Patient',
                    'description' => 'Commandez vos médicaments, envoyez vos ordonnances et suivez vos livraisons en temps réel.',
                    'color' => 'green',
                    'features' => 'Recherche & commande|Upload d\'ordonnance|Suivi GPS en direct|Paiement Mobile Money',
                ],
                [
                    'tag' => 'PHARMACIE',
                    'title' => 'App Pharmacien',
                    'description' => 'Gérez votre officine digitale : stocks, commandes, statistiques et relation client.',
                    'color' => 'blue',
                    'features' => 'Gestion de stock avancée|Traitement d\'ordonnances|Dashboard analytique|Notifications temps réel',
                ],
                [
                    'tag' => 'COURSIER',
                    'title' => 'App Coursier',
                    'description' => 'Optimisez vos tournées, acceptez des courses et augmentez vos revenus quotidiens.',
                    'color' => 'amber',
                    'features' => 'Navigation GPS optimisée|Système de challenges|Statistiques de gains|Paiement automatique',
                ],
            ]),

            // === TESTIMONIALS ===
            'testimonials_badge' => Setting::get('landing_testimonials_badge', 'Témoignages'),
            'testimonials_title' => Setting::get('landing_testimonials_title', 'Ils nous font confiance'),
            'testimonials_title_highlight' => Setting::get('landing_testimonials_title_highlight', 'confiance'),
            'testimonials' => Setting::get('landing_testimonials', [
                [
                    'quote' => 'Depuis que j\'utilise DR-PHARMA, je ne fais plus la queue en pharmacie. Mes médicaments arrivent chez moi en 30 minutes. C\'est révolutionnaire !',
                    'name' => 'Aminata K.',
                    'role' => 'Patiente — Cocody, Abidjan',
                    'initials' => 'AK',
                    'color' => 'green',
                    'rating' => 5,
                ],
                [
                    'quote' => 'DR-PHARMA a modernisé ma pharmacie. Je gère mes stocks et commandes facilement. Mon chiffre d\'affaires a augmenté de 40% en 3 mois !',
                    'name' => 'Dr. Yao D.',
                    'role' => 'Pharmacien — Plateau, Abidjan',
                    'initials' => 'DY',
                    'color' => 'blue',
                    'rating' => 5,
                ],
                [
                    'quote' => 'Grâce aux challenges et au système de bonus, je gagne bien ma vie. L\'app est intuitive et les courses sont bien payées. Top !',
                    'name' => 'Kouadio S.',
                    'role' => 'Coursier — Yopougon, Abidjan',
                    'initials' => 'KS',
                    'color' => 'amber',
                    'rating' => 5,
                ],
            ]),

            // === FAQ ===
            'faq_badge' => Setting::get('landing_faq_badge', 'FAQ'),
            'faq_title' => Setting::get('landing_faq_title', 'Questions fréquentes'),
            'faq_title_highlight' => Setting::get('landing_faq_title_highlight', 'fréquentes'),
            'faqs' => Setting::get('landing_faqs', [
                ['question' => 'Comment commander mes médicaments ?', 'answer' => 'Téléchargez l\'app Patient, créez votre compte et recherchez votre médicament ou envoyez une photo de votre ordonnance. Choisissez une pharmacie, payez et recevez votre commande à domicile en moins de 45 minutes.'],
                ['question' => 'L\'application est-elle gratuite ?', 'answer' => 'Oui ! Le téléchargement et l\'inscription sont entièrement gratuits. Vous ne payez que le prix des médicaments et les frais de livraison (à partir de 300 FCFA).'],
                ['question' => 'Quels sont les moyens de paiement acceptés ?', 'answer' => 'Nous acceptons Orange Money, MTN Mobile Money, Moov Money, Wave, les cartes bancaires (Visa/Mastercard) et le paiement à la livraison (cash).'],
                ['question' => 'Comment devenir pharmacie partenaire ?', 'answer' => 'Téléchargez l\'app Pharmacien, remplissez le formulaire d\'inscription avec vos documents officiels (licence, registre de commerce). Notre équipe validera votre compte sous 48h.'],
                ['question' => 'Dans quelles zones livrez-vous ?', 'answer' => 'Nous couvrons actuellement tout le district d\'Abidjan : Cocody, Plateau, Marcory, Treichville, Yopougon, Abobo, Adjamé, Koumassi, Port-Bouët et Bingerville. Extension prochaine à Bouaké et Yamoussoukro.'],
                ['question' => 'Comment devenir coursier DR-PHARMA ?', 'answer' => 'Téléchargez l\'app Coursier, inscrivez-vous avec vos pièces d\'identité et permis de conduire. Après vérification, vous pourrez commencer à accepter des livraisons et gagner de l\'argent.'],
            ]),

            // === CTA ===
            'cta_title_line1' => Setting::get('landing_cta_title_line1', 'Prêt à simplifier'),
            'cta_title_line2' => Setting::get('landing_cta_title_line2', 'votre accès aux médicaments ?'),
            'cta_highlight' => Setting::get('landing_cta_highlight', 'médicaments'),
            'cta_subtitle' => Setting::get('landing_cta_subtitle', 'Rejoignez des milliers d\'utilisateurs en Côte d\'Ivoire. Téléchargez l\'application gratuitement et commencez dès maintenant.'),
            'cta_appstore_url' => Setting::get('landing_cta_appstore_url', '#'),
            'cta_appstore_text' => Setting::get('landing_cta_appstore_text', 'App Store'),
            'cta_playstore_url' => Setting::get('landing_cta_playstore_url', '#'),
            'cta_playstore_text' => Setting::get('landing_cta_playstore_text', 'Google Play'),
            'cta_trust_1' => Setting::get('landing_cta_trust_1', '100% Sécurisé'),
            'cta_trust_2' => Setting::get('landing_cta_trust_2', 'Gratuit'),
            'cta_trust_3' => Setting::get('landing_cta_trust_3', 'Livraison < 45 min'),
            'cta_trust_4' => Setting::get('landing_cta_trust_4', '4.8★ sur les stores'),

            // === FOOTER ===
            'footer_description' => Setting::get('landing_footer_description', 'La plateforme santé digitale N°1 en Côte d\'Ivoire. Connecter les patients, pharmaciens et coursiers.'),
            'footer_email' => Setting::get('landing_footer_email', 'contact@drlpharma.com'),
            'footer_phone' => Setting::get('landing_footer_phone', '+225 07 01 159 572'),
            'footer_address' => Setting::get('landing_footer_address', 'Abidjan, Côte d\'Ivoire'),
            'footer_facebook_url' => Setting::get('landing_footer_facebook_url', '#'),
            'footer_instagram_url' => Setting::get('landing_footer_instagram_url', '#'),
            'footer_twitter_url' => Setting::get('landing_footer_twitter_url', '#'),
            'footer_linkedin_url' => Setting::get('landing_footer_linkedin_url', '#'),
            'footer_copyright' => Setting::get('landing_footer_copyright', '© 2026 DR-PHARMA. Tous droits réservés. Fait en Côte d\'Ivoire'),

            // === SEO ===
            'seo_title' => Setting::get('landing_seo_title', 'DR-PHARMA — Votre Santé, Simplifiée'),
            'seo_description' => Setting::get('landing_seo_description', 'DR-PHARMA — La plateforme santé digitale N°1 en Côte d\'Ivoire. Commandez vos médicaments, gérez votre pharmacie, livrez en toute sécurité.'),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                // === SEO ===
                Section::make('SEO & Métadonnées')
                    ->description('Titre et description affichés dans Google et les réseaux sociaux')
                    ->icon('heroicon-o-magnifying-glass')
                    ->collapsible()
                    ->collapsed()
                    ->schema([
                        TextInput::make('seo_title')
                            ->label('Titre de la page (SEO)')
                            ->required()
                            ->maxLength(70)
                            ->helperText('Apparaît dans l\'onglet du navigateur et les résultats Google.'),
                        Textarea::make('seo_description')
                            ->label('Meta description')
                            ->required()
                            ->maxLength(160)
                            ->rows(2)
                            ->helperText('Description affichée dans les résultats Google. Max 160 caractères.'),
                    ])->columns(1),

                // === HERO ===
                Section::make('🦸 Section Hero (Accueil)')
                    ->description('La section principale visible en haut de page')
                    ->icon('heroicon-o-home')
                    ->schema([
                        TextInput::make('hero_badge')
                            ->label('Badge (texte)')
                            ->required()
                            ->helperText('Ex: "Disponible en Côte d\'Ivoire"'),
                        Grid::make(2)->schema([
                            TextInput::make('hero_title_line1')
                                ->label('Titre — Ligne 1')
                                ->required(),
                            TextInput::make('hero_title_line2')
                                ->label('Titre — Ligne 2 (en dégradé)')
                                ->required()
                                ->helperText('Ce texte sera affiché avec un dégradé vert.'),
                        ]),
                        Textarea::make('hero_subtitle')
                            ->label('Sous-titre')
                            ->required()
                            ->rows(2),
                        Grid::make(2)->schema([
                            TextInput::make('hero_cta_appstore_url')
                                ->label('Lien App Store')
                                ->url()
                                ->helperText('URL vers votre app sur l\'App Store Apple.'),
                            TextInput::make('hero_cta_playstore_url')
                                ->label('Lien Google Play')
                                ->url()
                                ->helperText('URL vers votre app sur Google Play.'),
                        ]),
                        Grid::make(3)->schema([
                            TextInput::make('hero_trust_1')
                                ->label('Argument de confiance 1')
                                ->required(),
                            TextInput::make('hero_trust_2')
                                ->label('Argument de confiance 2')
                                ->required(),
                            TextInput::make('hero_trust_3')
                                ->label('Argument de confiance 3')
                                ->required(),
                        ]),
                        Grid::make(2)->schema([
                            TextInput::make('hero_phone_title')
                                ->label('Titre du téléphone')
                                ->required(),
                            TextInput::make('hero_phone_subtitle')
                                ->label('Sous-titre du téléphone')
                                ->required(),
                        ]),
                    ]),

                // === STATS ===
                Section::make('📊 Statistiques')
                    ->description('Les chiffres clés affichés sous le hero')
                    ->icon('heroicon-o-chart-bar')
                    ->collapsible()
                    ->schema([
                        Toggle::make('stats_auto')
                            ->label('Stats automatiques (depuis la base de données)')
                            ->helperText('Activé = les stats sont calculées automatiquement (pharmacies, commandes, coursiers...). Désactivé = vous saisissez les valeurs manuellement ci-dessous.')
                            ->live()
                            ->default(true),
                        Placeholder::make('stats_info')
                            ->label('')
                            ->content('✅ Les statistiques sont calculées en temps réel depuis la base de données avec un cache de 10 minutes.')
                            ->visible(fn ($get) => $get('stats_auto') === true),
                        Repeater::make('stats')
                            ->label('Statistiques manuelles')
                            ->visible(fn ($get) => $get('stats_auto') === false)
                            ->schema([
                                TextInput::make('value')
                                    ->label('Valeur (nombre)')
                                    ->required()
                                    ->numeric(),
                                TextInput::make('suffix')
                                    ->label('Suffixe')
                                    ->required()
                                    ->helperText('Ex: +, %, etc.')
                                    ->maxLength(5),
                                TextInput::make('label')
                                    ->label('Libellé')
                                    ->required(),
                            ])
                            ->columns(3)
                            ->minItems(1)
                            ->maxItems(6)
                            ->defaultItems(4)
                            ->reorderable()
                            ->collapsible()
                            ->itemLabel(fn (array $state): ?string => ($state['label'] ?? '') . ' — ' . ($state['value'] ?? '') . ($state['suffix'] ?? '')),
                    ]),

                // === FEATURES ===
                Section::make('⚡ Fonctionnalités')
                    ->description('Les fonctionnalités principales affichées en cartes')
                    ->icon('heroicon-o-bolt')
                    ->collapsible()
                    ->schema([
                        Grid::make(2)->schema([
                            TextInput::make('features_badge')
                                ->label('Badge'),
                            TextInput::make('features_title')
                                ->label('Titre de la section'),
                        ]),
                        Grid::make(2)->schema([
                            TextInput::make('features_title_highlight')
                                ->label('Mot en dégradé')
                                ->helperText('Ce mot sera affiché en dégradé vert dans le titre.'),
                            Textarea::make('features_subtitle')
                                ->label('Sous-titre')
                                ->rows(2),
                        ]),
                        Repeater::make('features')
                            ->label('Liste des fonctionnalités')
                            ->schema([
                                TextInput::make('title')
                                    ->label('Titre')
                                    ->required(),
                                Textarea::make('description')
                                    ->label('Description')
                                    ->required()
                                    ->rows(2),
                                Select::make('icon_color')
                                    ->label('Couleur de l\'icône')
                                    ->options([
                                        'green' => '🟢 Vert',
                                        'blue' => '🔵 Bleu',
                                        'amber' => '🟡 Ambre',
                                        'purple' => '🟣 Violet',
                                        'rose' => '🔴 Rose',
                                        'cyan' => '🔵 Cyan',
                                    ])
                                    ->required(),
                            ])
                            ->columns(3)
                            ->minItems(1)
                            ->maxItems(9)
                            ->defaultItems(6)
                            ->reorderable()
                            ->collapsible()
                            ->itemLabel(fn (array $state): ?string => $state['title'] ?? 'Fonctionnalité'),
                    ]),

                // === STEPS ===
                Section::make('🔢 Comment ça marche')
                    ->description('Les étapes du processus')
                    ->icon('heroicon-o-arrow-path')
                    ->collapsible()
                    ->collapsed()
                    ->schema([
                        Grid::make(2)->schema([
                            TextInput::make('steps_badge')->label('Badge'),
                            TextInput::make('steps_title')->label('Titre'),
                        ]),
                        Grid::make(2)->schema([
                            TextInput::make('steps_title_highlight')->label('Mot en dégradé'),
                            Textarea::make('steps_subtitle')->label('Sous-titre')->rows(2),
                        ]),
                        Repeater::make('steps')
                            ->label('Étapes')
                            ->schema([
                                TextInput::make('title')
                                    ->label('Titre')
                                    ->required(),
                                Textarea::make('description')
                                    ->label('Description')
                                    ->required()
                                    ->rows(2),
                                Select::make('color')
                                    ->label('Couleur')
                                    ->options([
                                        'green' => '🟢 Vert',
                                        'blue' => '🔵 Bleu',
                                        'amber' => '🟡 Ambre',
                                    ])
                                    ->required(),
                            ])
                            ->columns(3)
                            ->minItems(1)
                            ->maxItems(5)
                            ->defaultItems(3)
                            ->reorderable()
                            ->collapsible()
                            ->itemLabel(fn (array $state): ?string => $state['title'] ?? 'Étape'),
                    ]),

                // === APPS ===
                Section::make('📱 Applications')
                    ->description('Les 3 applications de l\'écosystème')
                    ->icon('heroicon-o-device-phone-mobile')
                    ->collapsible()
                    ->collapsed()
                    ->schema([
                        Grid::make(2)->schema([
                            TextInput::make('apps_badge')->label('Badge'),
                            TextInput::make('apps_title')->label('Titre'),
                        ]),
                        Grid::make(2)->schema([
                            TextInput::make('apps_title_highlight')->label('Mot en dégradé'),
                            Textarea::make('apps_subtitle')->label('Sous-titre')->rows(2),
                        ]),
                        Repeater::make('apps')
                            ->label('Applications')
                            ->schema([
                                TextInput::make('tag')
                                    ->label('Tag (ex: PATIENT)')
                                    ->required(),
                                TextInput::make('title')
                                    ->label('Titre')
                                    ->required(),
                                Textarea::make('description')
                                    ->label('Description')
                                    ->required()
                                    ->rows(2),
                                Select::make('color')
                                    ->label('Couleur')
                                    ->options([
                                        'green' => '🟢 Vert',
                                        'blue' => '🔵 Bleu',
                                        'amber' => '🟡 Ambre',
                                    ])
                                    ->required(),
                                Textarea::make('features')
                                    ->label('Fonctionnalités (séparées par |)')
                                    ->required()
                                    ->rows(2)
                                    ->helperText('Séparez chaque fonctionnalité par | (ex: GPS|Paiement|Chat)'),
                            ])
                            ->columns(2)
                            ->minItems(1)
                            ->maxItems(4)
                            ->defaultItems(3)
                            ->reorderable()
                            ->collapsible()
                            ->itemLabel(fn (array $state): ?string => ($state['tag'] ?? '') . ' — ' . ($state['title'] ?? '')),
                    ]),

                // === TESTIMONIALS ===
                Section::make('💬 Témoignages')
                    ->description('Les avis des utilisateurs')
                    ->icon('heroicon-o-chat-bubble-left-right')
                    ->collapsible()
                    ->collapsed()
                    ->schema([
                        Grid::make(2)->schema([
                            TextInput::make('testimonials_badge')->label('Badge'),
                            TextInput::make('testimonials_title')->label('Titre'),
                        ]),
                        TextInput::make('testimonials_title_highlight')->label('Mot en dégradé'),
                        Repeater::make('testimonials')
                            ->label('Témoignages')
                            ->schema([
                                Textarea::make('quote')
                                    ->label('Citation')
                                    ->required()
                                    ->rows(3),
                                Grid::make(3)->schema([
                                    TextInput::make('name')
                                        ->label('Nom')
                                        ->required(),
                                    TextInput::make('role')
                                        ->label('Rôle / Localisation')
                                        ->required(),
                                    TextInput::make('initials')
                                        ->label('Initiales (avatar)')
                                        ->required()
                                        ->maxLength(3),
                                ]),
                                Grid::make(2)->schema([
                                    Select::make('color')
                                        ->label('Couleur avatar')
                                        ->options([
                                            'green' => '🟢 Vert',
                                            'blue' => '🔵 Bleu',
                                            'amber' => '🟡 Ambre',
                                        ])
                                        ->required(),
                                    Select::make('rating')
                                        ->label('Note (étoiles)')
                                        ->options([
                                            1 => '⭐',
                                            2 => '⭐⭐',
                                            3 => '⭐⭐⭐',
                                            4 => '⭐⭐⭐⭐',
                                            5 => '⭐⭐⭐⭐⭐',
                                        ])
                                        ->required()
                                        ->default(5),
                                ]),
                            ])
                            ->minItems(1)
                            ->maxItems(6)
                            ->defaultItems(3)
                            ->reorderable()
                            ->collapsible()
                            ->itemLabel(fn (array $state): ?string => ($state['name'] ?? 'Témoignage') . ' — ' . ($state['role'] ?? '')),
                    ]),

                // === FAQ ===
                Section::make('❓ FAQ')
                    ->description('Questions fréquemment posées')
                    ->icon('heroicon-o-question-mark-circle')
                    ->collapsible()
                    ->collapsed()
                    ->schema([
                        Grid::make(2)->schema([
                            TextInput::make('faq_badge')->label('Badge'),
                            TextInput::make('faq_title')->label('Titre'),
                        ]),
                        TextInput::make('faq_title_highlight')->label('Mot en dégradé'),
                        Repeater::make('faqs')
                            ->label('Questions / Réponses')
                            ->schema([
                                TextInput::make('question')
                                    ->label('Question')
                                    ->required()
                                    ->columnSpanFull(),
                                Textarea::make('answer')
                                    ->label('Réponse')
                                    ->required()
                                    ->rows(3)
                                    ->columnSpanFull(),
                            ])
                            ->minItems(1)
                            ->maxItems(12)
                            ->defaultItems(6)
                            ->reorderable()
                            ->collapsible()
                            ->itemLabel(fn (array $state): ?string => $state['question'] ?? 'Question'),
                    ]),

                // === CTA ===
                Section::make('🚀 Section Téléchargement (CTA)')
                    ->description('Le bloc d\'appel à l\'action pour télécharger les apps')
                    ->icon('heroicon-o-arrow-down-tray')
                    ->collapsible()
                    ->collapsed()
                    ->schema([
                        Grid::make(2)->schema([
                            TextInput::make('cta_title_line1')
                                ->label('Titre — Ligne 1')
                                ->required(),
                            TextInput::make('cta_title_line2')
                                ->label('Titre — Ligne 2')
                                ->required(),
                        ]),
                        TextInput::make('cta_highlight')
                            ->label('Mot en surbrillance')
                            ->helperText('Ce mot sera coloré différemment dans le titre.'),
                        Textarea::make('cta_subtitle')
                            ->label('Sous-titre')
                            ->rows(2),
                        Grid::make(2)->schema([
                            TextInput::make('cta_appstore_url')
                                ->label('Lien App Store')
                                ->url(),
                            TextInput::make('cta_playstore_url')
                                ->label('Lien Google Play')
                                ->url(),
                        ]),
                        Grid::make(2)->schema([
                            TextInput::make('cta_appstore_text')
                                ->label('Texte bouton App Store')
                                ->default('App Store'),
                            TextInput::make('cta_playstore_text')
                                ->label('Texte bouton Google Play')
                                ->default('Google Play'),
                        ]),
                        Grid::make(4)->schema([
                            TextInput::make('cta_trust_1')->label('Trust 1'),
                            TextInput::make('cta_trust_2')->label('Trust 2'),
                            TextInput::make('cta_trust_3')->label('Trust 3'),
                            TextInput::make('cta_trust_4')->label('Trust 4'),
                        ]),
                    ]),

                // === FOOTER ===
                Section::make('🏠 Pied de page (Footer)')
                    ->description('Informations de contact et réseaux sociaux')
                    ->icon('heroicon-o-building-office')
                    ->collapsible()
                    ->collapsed()
                    ->schema([
                        Textarea::make('footer_description')
                            ->label('Description')
                            ->rows(2),
                        Grid::make(3)->schema([
                            TextInput::make('footer_email')
                                ->label('Email')
                                ->email(),
                            TextInput::make('footer_phone')
                                ->label('Téléphone')
                                ->tel(),
                            TextInput::make('footer_address')
                                ->label('Adresse'),
                        ]),
                        Grid::make(4)->schema([
                            TextInput::make('footer_facebook_url')
                                ->label('Facebook')
                                ->url(),
                            TextInput::make('footer_instagram_url')
                                ->label('Instagram')
                                ->url(),
                            TextInput::make('footer_twitter_url')
                                ->label('X (Twitter)')
                                ->url(),
                            TextInput::make('footer_linkedin_url')
                                ->label('LinkedIn')
                                ->url(),
                        ]),
                        TextInput::make('footer_copyright')
                            ->label('Copyright')
                            ->columnSpanFull(),
                    ]),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        // SEO
        Setting::set('landing_seo_title', $data['seo_title'], 'string');
        Setting::set('landing_seo_description', $data['seo_description'], 'string');

        // Hero
        Setting::set('landing_hero_badge', $data['hero_badge'], 'string');
        Setting::set('landing_hero_title_line1', $data['hero_title_line1'], 'string');
        Setting::set('landing_hero_title_line2', $data['hero_title_line2'], 'string');
        Setting::set('landing_hero_subtitle', $data['hero_subtitle'], 'string');
        Setting::set('landing_hero_cta_appstore_text', $data['hero_cta_appstore_text'] ?? 'App Store', 'string');
        Setting::set('landing_hero_cta_appstore_url', $data['hero_cta_appstore_url'], 'string');
        Setting::set('landing_hero_cta_playstore_text', $data['hero_cta_playstore_text'] ?? 'Google Play', 'string');
        Setting::set('landing_hero_cta_playstore_url', $data['hero_cta_playstore_url'], 'string');
        Setting::set('landing_hero_trust_1', $data['hero_trust_1'], 'string');
        Setting::set('landing_hero_trust_2', $data['hero_trust_2'], 'string');
        Setting::set('landing_hero_trust_3', $data['hero_trust_3'], 'string');
        Setting::set('landing_hero_phone_title', $data['hero_phone_title'], 'string');
        Setting::set('landing_hero_phone_subtitle', $data['hero_phone_subtitle'], 'string');

        // Stats
        Setting::set('landing_stats_auto', $data['stats_auto'] ? true : false, 'boolean');
        Setting::set('landing_stats', json_encode($data['stats']), 'json');

        // Vider le cache des stats pour appliquer immédiatement
        Cache::forget('landing_stats_live');

        // Features
        Setting::set('landing_features_badge', $data['features_badge'], 'string');
        Setting::set('landing_features_title', $data['features_title'], 'string');
        Setting::set('landing_features_title_highlight', $data['features_title_highlight'], 'string');
        Setting::set('landing_features_subtitle', $data['features_subtitle'], 'string');
        Setting::set('landing_features', json_encode($data['features']), 'json');

        // Steps
        Setting::set('landing_steps_badge', $data['steps_badge'], 'string');
        Setting::set('landing_steps_title', $data['steps_title'], 'string');
        Setting::set('landing_steps_title_highlight', $data['steps_title_highlight'], 'string');
        Setting::set('landing_steps_subtitle', $data['steps_subtitle'], 'string');
        Setting::set('landing_steps', json_encode($data['steps']), 'json');

        // Apps
        Setting::set('landing_apps_badge', $data['apps_badge'], 'string');
        Setting::set('landing_apps_title', $data['apps_title'], 'string');
        Setting::set('landing_apps_title_highlight', $data['apps_title_highlight'], 'string');
        Setting::set('landing_apps_subtitle', $data['apps_subtitle'], 'string');
        Setting::set('landing_apps', json_encode($data['apps']), 'json');

        // Testimonials
        Setting::set('landing_testimonials_badge', $data['testimonials_badge'], 'string');
        Setting::set('landing_testimonials_title', $data['testimonials_title'], 'string');
        Setting::set('landing_testimonials_title_highlight', $data['testimonials_title_highlight'], 'string');
        Setting::set('landing_testimonials', json_encode($data['testimonials']), 'json');

        // FAQ
        Setting::set('landing_faq_badge', $data['faq_badge'], 'string');
        Setting::set('landing_faq_title', $data['faq_title'], 'string');
        Setting::set('landing_faq_title_highlight', $data['faq_title_highlight'], 'string');
        Setting::set('landing_faqs', json_encode($data['faqs']), 'json');

        // CTA
        Setting::set('landing_cta_title_line1', $data['cta_title_line1'], 'string');
        Setting::set('landing_cta_title_line2', $data['cta_title_line2'], 'string');
        Setting::set('landing_cta_highlight', $data['cta_highlight'], 'string');
        Setting::set('landing_cta_subtitle', $data['cta_subtitle'], 'string');
        Setting::set('landing_cta_appstore_url', $data['cta_appstore_url'], 'string');
        Setting::set('landing_cta_appstore_text', $data['cta_appstore_text'] ?? 'App Store', 'string');
        Setting::set('landing_cta_playstore_url', $data['cta_playstore_url'], 'string');
        Setting::set('landing_cta_playstore_text', $data['cta_playstore_text'] ?? 'Google Play', 'string');
        Setting::set('landing_cta_trust_1', $data['cta_trust_1'], 'string');
        Setting::set('landing_cta_trust_2', $data['cta_trust_2'], 'string');
        Setting::set('landing_cta_trust_3', $data['cta_trust_3'], 'string');
        Setting::set('landing_cta_trust_4', $data['cta_trust_4'], 'string');

        // Footer
        Setting::set('landing_footer_description', $data['footer_description'], 'string');
        Setting::set('landing_footer_email', $data['footer_email'], 'string');
        Setting::set('landing_footer_phone', $data['footer_phone'], 'string');
        Setting::set('landing_footer_address', $data['footer_address'], 'string');
        Setting::set('landing_footer_facebook_url', $data['footer_facebook_url'], 'string');
        Setting::set('landing_footer_instagram_url', $data['footer_instagram_url'], 'string');
        Setting::set('landing_footer_twitter_url', $data['footer_twitter_url'], 'string');
        Setting::set('landing_footer_linkedin_url', $data['footer_linkedin_url'], 'string');
        Setting::set('landing_footer_copyright', $data['footer_copyright'], 'string');

        Notification::make()
            ->success()
            ->title('Landing page mis à jour avec succès')
            ->body('Les modifications seront visibles immédiatement sur la page d\'accueil.')
            ->send();
    }

    protected function getFormActions(): array
    {
        return [
            Action::make('save')
                ->label('💾 Enregistrer les modifications')
                ->submit('save')
                ->icon('heroicon-o-check-circle')
                ->color('success'),
            Action::make('preview')
                ->label('👁 Prévisualiser')
                ->url('/')
                ->openUrlInNewTab()
                ->icon('heroicon-o-eye')
                ->color('gray'),
        ];
    }
}
