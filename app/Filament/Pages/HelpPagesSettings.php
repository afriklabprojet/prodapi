<?php

namespace App\Filament\Pages;

use App\Models\Setting;
use App\Models\User;
use Filament\Actions\Action;
use Filament\Forms\Components\Grid;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Tabs;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Auth;

class HelpPagesSettings extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-book-open';

    protected static ?string $navigationLabel = 'Pages d\'aide';

    protected static ?string $title = 'Gestion des pages d\'aide';

    protected static ?string $navigationGroup = 'Configuration';

    protected static ?int $navigationSort = 11;

    protected static ?string $slug = 'help-pages';

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
            // === GUIDE ===
            'guide_hero_title' => Setting::get('guide_hero_title', 'Guide d\'utilisation'),
            'guide_hero_subtitle' => Setting::get('guide_hero_subtitle', 'Apprenez à utiliser l\'application DR-PHARMA Pharmacie pour gérer votre officine efficacement.'),
            'guide_intro' => Setting::get('guide_intro', 'Ce guide vous accompagne pas à pas dans l\'utilisation de l\'application DR-PHARMA Pharmacie. Découvrez comment traiter les commandes, gérer votre stock, activer le mode garde et suivre vos performances.'),
            'guide_sections' => Setting::get('guide_sections', $this->defaultGuideSections()),

            // === FAQ ===
            'faq_hero_title' => Setting::get('faq_hero_title', 'Foire aux questions'),
            'faq_hero_subtitle' => Setting::get('faq_hero_subtitle', 'Trouvez des réponses rapides à toutes vos questions sur DR-PHARMA.'),
            'faq_categories' => Setting::get('faq_categories', $this->defaultFaqCategories()),

            // === TUTORIELS ===
            'tutorials_hero_title' => Setting::get('tutorials_hero_title', 'Tutoriels vidéo'),
            'tutorials_hero_subtitle' => Setting::get('tutorials_hero_subtitle', 'Apprenez à utiliser DR-PHARMA grâce à nos vidéos explicatives.'),
            'tutorials_intro' => Setting::get('tutorials_intro', 'Nos tutoriels vous guident pas à pas pour maîtriser toutes les fonctionnalités de l\'application DR-PHARMA, que vous soyez patient, pharmacien ou coursier.'),
            'tutorials_youtube_url' => Setting::get('tutorials_youtube_url', config('drpharma.brand.youtube')),
            'tutorials_videos' => Setting::get('tutorials_videos', $this->defaultTutorialVideos()),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Tabs::make('Pages')
                    ->tabs([
                        // =============================================
                        // TAB 1 : GUIDE D'UTILISATION
                        // =============================================
                        Tabs\Tab::make('📖 Guide d\'utilisation')
                            ->icon('heroicon-o-book-open')
                            ->schema([
                                Section::make('En-tête de page')
                                    ->schema([
                                        TextInput::make('guide_hero_title')
                                            ->label('Titre')
                                            ->required(),
                                        Textarea::make('guide_hero_subtitle')
                                            ->label('Sous-titre')
                                            ->rows(2)
                                            ->required(),
                                        Textarea::make('guide_intro')
                                            ->label('Texte d\'introduction')
                                            ->rows(3),
                                    ]),

                                Section::make('Sections du guide')
                                    ->description('Chaque section contient un titre, une description et des étapes')
                                    ->schema([
                                        Repeater::make('guide_sections')
                                            ->label('')
                                            ->schema([
                                                Grid::make(3)->schema([
                                                    TextInput::make('icon')
                                                        ->label('Icône (emoji)')
                                                        ->required()
                                                        ->maxLength(5)
                                                        ->helperText('Ex: 🛒, 📦, 📋'),
                                                    TextInput::make('title')
                                                        ->label('Titre')
                                                        ->required()
                                                        ->columnSpan(2),
                                                ]),
                                                Grid::make(2)->schema([
                                                    TextInput::make('subtitle')
                                                        ->label('Sous-titre'),
                                                    Select::make('color')
                                                        ->label('Couleur')
                                                        ->options([
                                                            'green' => '🟢 Vert',
                                                            'blue' => '🔵 Bleu',
                                                            'amber' => '🟡 Ambre',
                                                            'purple' => '🟣 Violet',
                                                            'rose' => '🔴 Rose',
                                                            'cyan' => '🔵 Cyan',
                                                        ])
                                                        ->required(),
                                                ]),
                                                TextInput::make('id')
                                                    ->label('Ancre (ID)')
                                                    ->helperText('Pour la navigation interne (ex: commandes, stock)')
                                                    ->required(),
                                                Repeater::make('steps')
                                                    ->label('Étapes')
                                                    ->schema([
                                                        TextInput::make('title')
                                                            ->label('Titre de l\'étape')
                                                            ->required(),
                                                        Textarea::make('content')
                                                            ->label('Contenu (HTML autorisé)')
                                                            ->required()
                                                            ->rows(3)
                                                            ->helperText('Utiliser <strong>gras</strong>, <ul><li> pour les listes.'),
                                                    ])
                                                    ->minItems(1)
                                                    ->maxItems(8)
                                                    ->reorderable()
                                                    ->collapsible()
                                                    ->itemLabel(fn (array $state): ?string => $state['title'] ?? 'Étape'),
                                                Textarea::make('tip')
                                                    ->label('💡 Astuce (optionnel)')
                                                    ->rows(2),
                                            ])
                                            ->minItems(1)
                                            ->maxItems(10)
                                            ->reorderable()
                                            ->collapsible()
                                            ->itemLabel(fn (array $state): ?string => ($state['icon'] ?? '') . ' ' . ($state['title'] ?? 'Section')),
                                    ]),
                            ]),

                        // =============================================
                        // TAB 2 : FAQ
                        // =============================================
                        Tabs\Tab::make('❓ FAQ')
                            ->icon('heroicon-o-question-mark-circle')
                            ->schema([
                                Section::make('En-tête de page')
                                    ->schema([
                                        TextInput::make('faq_hero_title')
                                            ->label('Titre')
                                            ->required(),
                                        Textarea::make('faq_hero_subtitle')
                                            ->label('Sous-titre')
                                            ->rows(2)
                                            ->required(),
                                    ]),

                                Section::make('Catégories de FAQ')
                                    ->description('Organisez vos questions par catégorie')
                                    ->schema([
                                        Repeater::make('faq_categories')
                                            ->label('')
                                            ->schema([
                                                Grid::make(3)->schema([
                                                    TextInput::make('icon')
                                                        ->label('Icône (emoji)')
                                                        ->required()
                                                        ->maxLength(5),
                                                    TextInput::make('title')
                                                        ->label('Titre de la catégorie')
                                                        ->required()
                                                        ->columnSpan(2),
                                                ]),
                                                TextInput::make('filter')
                                                    ->label('Filtre (identifiant)')
                                                    ->helperText('Ex: patient, pharmacien, coursier, paiement')
                                                    ->required(),
                                                Repeater::make('questions')
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
                                                    ->maxItems(15)
                                                    ->reorderable()
                                                    ->collapsible()
                                                    ->itemLabel(fn (array $state): ?string => $state['question'] ?? 'Question'),
                                            ])
                                            ->minItems(1)
                                            ->maxItems(10)
                                            ->reorderable()
                                            ->collapsible()
                                            ->itemLabel(fn (array $state): ?string => ($state['icon'] ?? '') . ' ' . ($state['title'] ?? 'Catégorie')),
                                    ]),
                            ]),

                        // =============================================
                        // TAB 3 : TUTORIELS VIDÉO
                        // =============================================
                        Tabs\Tab::make('🎬 Tutoriels vidéo')
                            ->icon('heroicon-o-play')
                            ->schema([
                                Section::make('En-tête de page')
                                    ->schema([
                                        TextInput::make('tutorials_hero_title')
                                            ->label('Titre')
                                            ->required(),
                                        Textarea::make('tutorials_hero_subtitle')
                                            ->label('Sous-titre')
                                            ->rows(2)
                                            ->required(),
                                        Textarea::make('tutorials_intro')
                                            ->label('Texte d\'introduction')
                                            ->rows(3),
                                        TextInput::make('tutorials_youtube_url')
                                            ->label('URL de la chaîne YouTube')
                                            ->url()
                                            ->required(),
                                    ]),

                                Section::make('Vidéos')
                                    ->description('Les tutoriels vidéo affichés sur la page')
                                    ->schema([
                                        Repeater::make('tutorials_videos')
                                            ->label('')
                                            ->schema([
                                                TextInput::make('title')
                                                    ->label('Titre')
                                                    ->required(),
                                                Textarea::make('description')
                                                    ->label('Description')
                                                    ->required()
                                                    ->rows(2),
                                                Grid::make(2)->schema([
                                                    Select::make('badge')
                                                        ->label('Badge')
                                                        ->options([
                                                            'Patient' => 'Patient',
                                                            'Pharmacien' => 'Pharmacien',
                                                            'Coursier' => 'Coursier',
                                                        ])
                                                        ->required(),
                                                    TextInput::make('url')
                                                        ->label('Lien vidéo')
                                                        ->url()
                                                        ->helperText('URL YouTube de la vidéo'),
                                                ]),
                                            ])
                                            ->minItems(1)
                                            ->maxItems(12)
                                            ->reorderable()
                                            ->collapsible()
                                            ->itemLabel(fn (array $state): ?string => '[' . ($state['badge'] ?? '?') . '] ' . ($state['title'] ?? 'Vidéo')),
                                    ]),
                            ]),
                    ])
                    ->persistTabInQueryString(),
            ])
            ->statePath('data');
    }

    protected function getFormActions(): array
    {
        return [
            Action::make('save')
                ->label('💾 Enregistrer')
                ->action('save')
                ->color('primary')
                ->size('lg'),
        ];
    }

    public function save(): void
    {
        $data = $this->form->getState();

        // === GUIDE ===
        Setting::set('guide_hero_title', $data['guide_hero_title'], 'string');
        Setting::set('guide_hero_subtitle', $data['guide_hero_subtitle'], 'string');
        Setting::set('guide_intro', $data['guide_intro'] ?? '', 'string');
        Setting::set('guide_sections', json_encode($data['guide_sections']), 'json');

        // === FAQ ===
        Setting::set('faq_hero_title', $data['faq_hero_title'], 'string');
        Setting::set('faq_hero_subtitle', $data['faq_hero_subtitle'], 'string');
        Setting::set('faq_categories', json_encode($data['faq_categories']), 'json');

        // === TUTORIELS ===
        Setting::set('tutorials_hero_title', $data['tutorials_hero_title'], 'string');
        Setting::set('tutorials_hero_subtitle', $data['tutorials_hero_subtitle'], 'string');
        Setting::set('tutorials_intro', $data['tutorials_intro'] ?? '', 'string');
        Setting::set('tutorials_youtube_url', $data['tutorials_youtube_url'], 'string');
        Setting::set('tutorials_videos', json_encode($data['tutorials_videos']), 'json');

        Notification::make()
            ->title('Pages mises à jour')
            ->body('Les pages Guide, FAQ et Tutoriels ont été mises à jour avec succès.')
            ->success()
            ->send();
    }

    // =============================================
    // DONNÉES PAR DÉFAUT
    // =============================================

    private function defaultGuideSections(): array
    {
        return [
            [
                'id' => 'commandes',
                'icon' => '🛒',
                'title' => 'Traiter une commande',
                'subtitle' => 'Recevoir, confirmer et préparer les commandes clients',
                'color' => 'green',
                'steps' => [
                    ['title' => 'Recevoir une nouvelle commande', 'content' => 'Lorsqu\'un client passe commande près de votre pharmacie, vous recevez une notification push et sonore. La commande apparaît dans l\'onglet <strong>« Commandes »</strong> avec le statut <strong>« En attente »</strong>.'],
                    ['title' => 'Examiner la commande', 'content' => 'Appuyez sur la commande pour voir le détail : liste des produits, quantités, éventuelle ordonnance jointe, informations du client et mode de paiement choisi.'],
                    ['title' => 'Confirmer ou refuser', 'content' => 'Si tous les produits sont disponibles, appuyez sur <strong>« Confirmer »</strong>. Si un produit manque, vous pouvez proposer un substitut ou refuser la commande en indiquant le motif.'],
                    ['title' => 'Préparer la commande', 'content' => 'Une fois confirmée, préparez physiquement les médicaments. Quand tout est prêt, appuyez sur <strong>« Prêt pour récupération »</strong>. Un coursier sera automatiquement assigné pour la livraison.'],
                ],
                'tip' => 'Traitez les commandes rapidement ! Un temps de réponse court améliore votre classement et la satisfaction des clients.',
            ],
            [
                'id' => 'stock',
                'icon' => '📦',
                'title' => 'Gérer votre stock',
                'subtitle' => 'Ajouter, modifier et suivre vos produits',
                'color' => 'blue',
                'steps' => [
                    ['title' => 'Accéder à votre inventaire', 'content' => 'Rendez-vous dans l\'onglet <strong>« Stock »</strong> depuis le menu principal. Vous y trouverez la liste complète de vos produits avec les quantités et prix.'],
                    ['title' => 'Ajouter un produit', 'content' => 'Appuyez sur le bouton <strong>« + »</strong> en bas de l\'écran. Vous pouvez scanner le code-barres, rechercher dans la base DR-PHARMA, ou saisir manuellement les informations.'],
                    ['title' => 'Modifier un produit', 'content' => 'Appuyez sur un produit pour modifier son prix, sa quantité ou le retirer du catalogue. Vous pouvez aussi le marquer temporairement comme <strong>« Indisponible »</strong>.'],
                    ['title' => 'Alertes de stock bas', 'content' => 'Configurez des seuils d\'alerte pour être notifié automatiquement quand un produit est bientôt en rupture de stock.'],
                ],
                'tip' => 'Gardez votre stock à jour ! Un catalogue précis vous permet de recevoir plus de commandes et d\'éviter les refus.',
            ],
            [
                'id' => 'ordonnances',
                'icon' => '📋',
                'title' => 'Traiter les ordonnances',
                'subtitle' => 'Recevoir et valider les ordonnances des patients',
                'color' => 'amber',
                'steps' => [
                    ['title' => 'Réception d\'une ordonnance', 'content' => 'Quand un client envoie une photo d\'ordonnance, vous recevez une notification spéciale. L\'ordonnance apparaît dans les commandes avec le badge <strong>« Ordonnance »</strong>.'],
                    ['title' => 'Vérifier l\'ordonnance', 'content' => 'Examinez la photo de l\'ordonnance, vérifiez sa validité et les produits prescrits. Vous pouvez zoomer sur l\'image pour mieux lire.'],
                    ['title' => 'Créer le devis', 'content' => 'Sélectionnez les produits correspondants dans votre stock, ajustez les quantités et validez le devis. Le client recevra le montant total et pourra confirmer.'],
                ],
                'tip' => 'Si un médicament prescrit n\'est pas disponible, vous pouvez proposer un générique équivalent au client.',
            ],
            [
                'id' => 'mode-garde',
                'icon' => '🌙',
                'title' => 'Mode Garde',
                'subtitle' => 'Signaler votre pharmacie comme étant de garde',
                'color' => 'purple',
                'steps' => [
                    ['title' => 'Activer le mode garde', 'content' => 'Allez dans <strong>« Profil »</strong> → <strong>« Mode Garde »</strong>. Activez le toggle pour signaler votre pharmacie comme étant de garde. Votre pharmacie sera mise en avant auprès des clients.'],
                    ['title' => 'Définir les horaires', 'content' => 'Configurez les plages horaires de garde (ex : 20h - 8h). Vous pouvez programmer des gardes récurrentes ou ponctuelles.'],
                    ['title' => 'Désactiver le mode garde', 'content' => 'À la fin de votre période de garde, désactivez le mode pour revenir aux horaires normaux. Le système peut aussi le désactiver automatiquement.'],
                ],
                'tip' => 'Activez le mode garde lors des jours fériés et week-ends pour être visible par les patients en urgence.',
            ],
            [
                'id' => 'statistiques',
                'icon' => '📊',
                'title' => 'Statistiques & rapports',
                'subtitle' => 'Suivre vos performances et ventes',
                'color' => 'rose',
                'steps' => [
                    ['title' => 'Accéder aux statistiques', 'content' => 'Depuis le <strong>menu profil</strong>, appuyez sur <strong>« Rapports & Analytics »</strong>. Vous y trouverez un tableau de bord avec vos indicateurs clés.'],
                    ['title' => 'Indicateurs disponibles', 'content' => 'Nombre de commandes traitées, chiffre d\'affaires généré, taux d\'acceptation, temps moyen de traitement, produits les plus vendus.'],
                    ['title' => 'Filtrer par période', 'content' => 'Utilisez le sélecteur de dates pour afficher les statistiques sur une période précise : aujourd\'hui, cette semaine, ce mois ou une période personnalisée.'],
                ],
                'tip' => 'Consultez régulièrement vos statistiques pour identifier les produits les plus demandés et ajuster votre stock.',
            ],
            [
                'id' => 'profil',
                'icon' => '⚙️',
                'title' => 'Profil & paramètres',
                'subtitle' => 'Gérer les informations de votre pharmacie',
                'color' => 'cyan',
                'steps' => [
                    ['title' => 'Modifier les informations', 'content' => 'Dans <strong>« Profil »</strong> → <strong>« Ma Pharmacie »</strong>, modifiez le nom, l\'adresse, la photo, le numéro de téléphone et les horaires d\'ouverture.'],
                    ['title' => 'Gérer les notifications', 'content' => 'Configurez vos préférences de notification : nouvelles commandes, alertes de stock, messages du support.'],
                    ['title' => 'Changer de mot de passe', 'content' => 'Allez dans <strong>« Sécurité »</strong> pour modifier votre mot de passe. Nous recommandons de le changer régulièrement.'],
                ],
                'tip' => '',
            ],
        ];
    }

    private function defaultFaqCategories(): array
    {
        return [
            [
                'icon' => '🛒',
                'title' => 'Patients — Commandes & Livraisons',
                'filter' => 'patient',
                'questions' => [
                    ['question' => 'Comment passer une commande ?', 'answer' => 'Téléchargez l\'application DR-PHARMA, créez un compte, puis recherchez votre médicament par nom ou envoyez une photo de votre ordonnance. Ajoutez au panier, choisissez votre mode de paiement et validez.'],
                    ['question' => 'Quel est le délai de livraison ?', 'answer' => 'En moyenne, votre commande est livrée en moins de 45 minutes dans les zones couvertes d\'Abidjan.'],
                    ['question' => 'Comment suivre ma livraison ?', 'answer' => 'Une fois votre commande confirmée, vous pouvez suivre votre coursier en temps réel sur la carte dans l\'application.'],
                    ['question' => 'Puis-je annuler une commande ?', 'answer' => 'Oui, tant que la pharmacie n\'a pas encore préparé votre commande. Rendez-vous dans "Mes commandes" et appuyez sur "Annuler".'],
                    ['question' => 'Comment créer un compte ?', 'answer' => 'Téléchargez l\'application, appuyez sur "S\'inscrire" et suivez les étapes. Vous aurez besoin d\'un numéro de téléphone valide.'],
                ],
            ],
            [
                'icon' => '💊',
                'title' => 'Pharmaciens',
                'filter' => 'pharmacien',
                'questions' => [
                    ['question' => 'Comment traiter une commande ?', 'answer' => 'Dans l\'onglet "Commandes", appuyez sur une commande en attente, vérifiez les produits, puis utilisez les boutons "Confirmer" ou "Refuser".'],
                    ['question' => 'Comment ajouter un produit à mon stock ?', 'answer' => 'Allez dans l\'onglet "Stock", appuyez sur "+", puis scannez le code-barres ou entrez les informations manuellement.'],
                    ['question' => 'Comment activer le mode garde ?', 'answer' => 'Dans "Profil" → "Mode Garde", activez le toggle et définissez vos horaires de garde.'],
                    ['question' => 'Comment devenir pharmacie partenaire ?', 'answer' => 'Contactez-nous via le formulaire de contact ou par email à support@drlpharma.com.'],
                    ['question' => 'Comment voir mes statistiques de vente ?', 'answer' => 'Accédez à "Rapports & Analytics" depuis le menu profil pour voir vos statistiques détaillées.'],
                ],
            ],
            [
                'icon' => '🚴',
                'title' => 'Coursiers',
                'filter' => 'coursier',
                'questions' => [
                    ['question' => 'Comment accepter une livraison ?', 'answer' => 'Vous recevez une notification. Allez dans l\'onglet "Livraisons" et appuyez sur "Accepter".'],
                    ['question' => 'Comment recharger mon portefeuille ?', 'answer' => 'Profil → Portefeuille → Recharger. Paiement par Mobile Money ou carte bancaire.'],
                    ['question' => 'Comment confirmer une livraison ?', 'answer' => 'Demandez le code à 4 chiffres au client et entrez-le dans l\'application.'],
                    ['question' => 'Comment devenir coursier DR-PHARMA ?', 'answer' => 'Téléchargez l\'app Coursier, inscrivez-vous avec vos documents (CNI, permis). Validation sous 48h.'],
                ],
            ],
            [
                'icon' => '💳',
                'title' => 'Paiements',
                'filter' => 'paiement',
                'questions' => [
                    ['question' => 'Quels moyens de paiement sont acceptés ?', 'answer' => 'Orange Money, MTN Mobile Money, Moov Money, Wave, cartes bancaires (Visa/Mastercard) et cash à la livraison.'],
                    ['question' => 'Mon paiement a échoué, que faire ?', 'answer' => 'Vérifiez votre solde et votre connexion internet. Si le problème persiste, essayez un autre moyen de paiement.'],
                    ['question' => 'Comment obtenir un remboursement ?', 'answer' => 'Contactez notre support. Les remboursements sont traités sous 24 à 48 heures.'],
                ],
            ],
            [
                'icon' => '🔒',
                'title' => 'Compte & Sécurité',
                'filter' => 'patient',
                'questions' => [
                    ['question' => 'Mes données sont-elles sécurisées ?', 'answer' => 'Oui. Toutes les communications sont chiffrées (HTTPS/TLS). Vos données sont protégées conformément à notre politique de confidentialité.'],
                    ['question' => 'J\'ai oublié mon mot de passe, comment le réinitialiser ?', 'answer' => 'Sur l\'écran de connexion, appuyez sur "Mot de passe oublié ?" pour recevoir un code par SMS.'],
                ],
            ],
        ];
    }

    private function defaultTutorialVideos(): array
    {
        $yt = config('drpharma.brand.youtube');
        return [
            ['title' => 'Passer sa première commande', 'description' => 'Créer un compte, rechercher un médicament et commander en quelques minutes.', 'badge' => 'Patient', 'url' => $yt],
            ['title' => 'Envoyer une ordonnance', 'description' => 'Comment photographier et envoyer votre ordonnance à une pharmacie.', 'badge' => 'Patient', 'url' => $yt],
            ['title' => 'Gérer les commandes', 'description' => 'Recevoir, confirmer et préparer les commandes des patients.', 'badge' => 'Pharmacien', 'url' => $yt],
            ['title' => 'Gérer votre stock', 'description' => 'Ajouter des produits, mettre à jour les prix et gérer les ruptures.', 'badge' => 'Pharmacien', 'url' => $yt],
            ['title' => 'Première livraison', 'description' => 'Accepter, naviguer et confirmer votre première livraison.', 'badge' => 'Coursier', 'url' => $yt],
            ['title' => 'Recharger son portefeuille', 'description' => 'Comment recharger via Mobile Money ou carte bancaire.', 'badge' => 'Coursier', 'url' => $yt],
        ];
    }
}
