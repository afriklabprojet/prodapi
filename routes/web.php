<?php

use App\Models\Setting;
use App\Models\Pharmacy;
use App\Models\Order;
use App\Models\Product;
use App\Models\Delivery;
use App\Models\Customer;
use App\Models\Courier;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Http\Request;
use App\Http\Controllers\Admin\PrivateDocumentController;

Route::get('/', function () {
    // Stats : automatiques (BDD) ou manuelles (Filament)
    $useAutoStats = Setting::get('landing_stats_auto', true);
    if ($useAutoStats) {
        $stats = Cache::remember('landing_stats_live', 600, function () {
            $pharmacyCount = Pharmacy::count();
            $orderCount = Order::where('status', 'delivered')->count();
            $productCount = Product::count();
            $customerCount = Customer::count();
            $courierCount = Courier::count();

            $avgDelivery = Delivery::where('status', 'delivered')
                ->whereNotNull('assigned_at')
                ->whereNotNull('delivered_at')
                ->select(DB::raw('AVG(TIMESTAMPDIFF(MINUTE, assigned_at, delivered_at)) as avg_min'))
                ->value('avg_min');
            $avgMin = $avgDelivery ? round($avgDelivery) : 30;

            return [
                ['value' => (string) $pharmacyCount, 'suffix' => '', 'label' => 'Pharmacies partenaires'],
                ['value' => (string) ($orderCount ?: $customerCount), 'suffix' => '', 'label' => $orderCount ? 'Commandes livrées' : 'Utilisateurs inscrits'],
                ['value' => (string) ($productCount ?: $courierCount), 'suffix' => '', 'label' => $productCount ? 'Médicaments disponibles' : 'Coursiers actifs'],
                ['value' => (string) $avgMin, 'suffix' => ' min', 'label' => 'Délai moyen de livraison'],
            ];
        });
    } else {
        $stats = Setting::get('landing_stats', [
            ['value' => '6', 'suffix' => '', 'label' => 'Pharmacies partenaires'],
            ['value' => '1', 'suffix' => '', 'label' => 'Utilisateurs inscrits'],
            ['value' => '2', 'suffix' => '', 'label' => 'Coursiers actifs'],
            ['value' => '30', 'suffix' => ' min', 'label' => 'Délai moyen'],
        ]);
    }

    $landing = [
        // SEO
        'seo_title' => Setting::get('landing_seo_title', 'DR-PHARMA — Pharmacie en ligne, livraison à Abidjan'),
        'seo_description' => Setting::get('landing_seo_description', 'Commandez vos médicaments en ligne et faites-vous livrer à domicile à Abidjan. DR-PHARMA connecte patients, pharmacies et coursiers.'),

        // Hero
        'hero_badge' => Setting::get('landing_hero_badge', 'Disponible à Abidjan'),
        'hero_title_line1' => Setting::get('landing_hero_title_line1', 'Vos médicaments,'),
        'hero_title_line2' => Setting::get('landing_hero_title_line2', 'livrés chez vous.'),
        'hero_subtitle' => Setting::get('landing_hero_subtitle', 'Commandez depuis votre téléphone, on s\'occupe de la livraison. Fini les files d\'attente en pharmacie.'),
        'hero_cta_appstore_url' => Setting::get('landing_hero_cta_appstore_url', '#telecharger'),
        'hero_cta_appstore_text' => Setting::get('landing_hero_cta_appstore_text', 'App Store'),
        'hero_cta_playstore_url' => Setting::get('landing_hero_cta_playstore_url', '#telecharger'),
        'hero_cta_playstore_text' => Setting::get('landing_hero_cta_playstore_text', 'Google Play'),
        'hero_trust_1' => Setting::get('landing_hero_trust_1', 'Téléchargement gratuit'),
        'hero_trust_2' => Setting::get('landing_hero_trust_2', 'Données protégées'),
        'hero_trust_3' => Setting::get('landing_hero_trust_3', 'Livraison rapide'),
        'hero_phone_title' => Setting::get('landing_hero_phone_title', 'DR-PHARMA'),
        'hero_phone_subtitle' => Setting::get('landing_hero_phone_subtitle', 'Commandez en quelques clics'),

        // Stats — données réelles
        'stats' => $stats,

        // Features
        'features_badge' => Setting::get('landing_features_badge', 'L\'app en bref'),
        'features_title' => Setting::get('landing_features_title', 'Ce que vous pouvez faire'),
        'features_title_highlight' => Setting::get('landing_features_title_highlight', 'faire'),
        'features_subtitle' => Setting::get('landing_features_subtitle', 'Patients, pharmaciens et coursiers — chacun y trouve son compte.'),
        'features' => Setting::get('landing_features', [
            ['title' => 'Chercher un médicament', 'description' => 'Tapez le nom et trouvez les pharmacies qui l\'ont en stock près de chez vous.', 'icon_color' => 'green'],
            ['title' => 'Envoyer une ordonnance', 'description' => 'Prenez en photo votre ordonnance, la pharmacie prépare votre commande.', 'icon_color' => 'blue'],
            ['title' => 'Suivre la livraison', 'description' => 'Voyez où en est votre coursier sur la carte, en temps réel.', 'icon_color' => 'amber'],
            ['title' => 'Payer comme vous voulez', 'description' => 'Orange Money, MTN, Wave, carte bancaire ou cash à la livraison.', 'icon_color' => 'purple'],
            ['title' => 'Être livré rapidement', 'description' => 'Nos coursiers récupèrent vos médicaments et vous les apportent chez vous.', 'icon_color' => 'rose'],
            ['title' => 'Gérer sa pharmacie', 'description' => 'Les pharmaciens suivent leurs stocks, commandes et ventes depuis l\'app.', 'icon_color' => 'cyan'],
        ]),

        // Steps
        'steps_badge' => Setting::get('landing_steps_badge', 'Comment ça marche'),
        'steps_title' => Setting::get('landing_steps_title', 'En 3 étapes'),
        'steps_title_highlight' => Setting::get('landing_steps_title_highlight', '3 étapes'),
        'steps_subtitle' => Setting::get('landing_steps_subtitle', 'De la commande à la livraison, c\'est simple et rapide.'),
        'steps' => Setting::get('landing_steps', [
            ['title' => 'Cherchez', 'description' => 'Tapez le nom du médicament ou photographiez votre ordonnance.', 'color' => 'green'],
            ['title' => 'Commandez', 'description' => 'Choisissez une pharmacie, ajoutez au panier et payez.', 'color' => 'blue'],
            ['title' => 'Recevez', 'description' => 'Un coursier passe en pharmacie et vous livre directement.', 'color' => 'amber'],
        ]),

        // Apps
        'apps_badge' => Setting::get('landing_apps_badge', 'Nos apps'),
        'apps_title' => Setting::get('landing_apps_title', 'Une app pour chaque besoin'),
        'apps_title_highlight' => Setting::get('landing_apps_title_highlight', 'chaque besoin'),
        'apps_subtitle' => Setting::get('landing_apps_subtitle', 'Patient, pharmacien ou coursier : téléchargez l\'app qui vous correspond.'),
        'apps' => Setting::get('landing_apps', [
            ['tag' => 'PATIENT', 'title' => 'App Patient', 'description' => 'Pour commander et se faire livrer.', 'color' => 'green', 'features' => 'Recherche de médicaments|Envoi d\'ordonnance|Suivi de livraison|Paiement mobile ou cash'],
            ['tag' => 'PHARMACIE', 'title' => 'App Pharmacien', 'description' => 'Pour gérer les commandes et le stock.', 'color' => 'blue', 'features' => 'Gestion du stock|Traitement des ordonnances|Suivi des ventes|Alertes de commandes'],
            ['tag' => 'COURSIER', 'title' => 'App Coursier', 'description' => 'Pour livrer et suivre ses gains.', 'color' => 'amber', 'features' => 'Navigation GPS|Historique des courses|Suivi des gains|Bonus de performance'],
        ]),

        // Testimonials
        'testimonials_badge' => Setting::get('landing_testimonials_badge', 'Avis'),
        'testimonials_title' => Setting::get('landing_testimonials_title', 'Ce qu\'en disent nos utilisateurs'),
        'testimonials_title_highlight' => Setting::get('landing_testimonials_title_highlight', 'utilisateurs'),
        'testimonials' => Setting::get('landing_testimonials', [
            ['quote' => 'J\'ai commandé pour ma mère qui ne peut pas se déplacer. En 40 minutes c\'était livré. Vraiment pratique.', 'name' => 'Aminata K.', 'role' => 'Utilisatrice — Cocody', 'initials' => 'AK', 'color' => 'green', 'rating' => 5],
            ['quote' => 'Ça m\'évite de refuser des clients quand un produit manque. Je peux mieux gérer mon stock maintenant.', 'name' => 'Dr. Yao D.', 'role' => 'Pharmacien — Plateau', 'initials' => 'DY', 'color' => 'blue', 'rating' => 4],
            ['quote' => 'Je fais mes courses entre les livraisons, c\'est flexible. Les bonus du week-end sont bien aussi.', 'name' => 'Kouadio S.', 'role' => 'Coursier — Yopougon', 'initials' => 'KS', 'color' => 'amber', 'rating' => 5],
        ]),

        // FAQ
        'faq_badge' => Setting::get('landing_faq_badge', 'FAQ'),
        'faq_title' => Setting::get('landing_faq_title', 'Questions fréquentes'),
        'faq_title_highlight' => Setting::get('landing_faq_title_highlight', 'fréquentes'),
        'faqs' => Setting::get('landing_faqs', [
            ['question' => 'Comment je commande mes médicaments ?', 'answer' => 'Téléchargez l\'app, créez un compte avec votre numéro de téléphone, puis cherchez votre médicament ou envoyez une photo de votre ordonnance. Choisissez une pharmacie et validez.'],
            ['question' => 'C\'est payant ?', 'answer' => 'L\'app est gratuite. Vous payez uniquement vos médicaments et les frais de livraison.'],
            ['question' => 'Comment je paye ?', 'answer' => 'Par Orange Money, MTN MoMo, Moov Money, Wave, carte bancaire, ou en espèces à la livraison.'],
            ['question' => 'En combien de temps je suis livré ?', 'answer' => 'Ça dépend de votre quartier et de la pharmacie, mais en général entre 30 et 60 minutes à Abidjan.'],
            ['question' => 'Est-ce que mes données sont protégées ?', 'answer' => 'Oui. Vos données de santé sont chiffrées et ne sont partagées avec personne.'],
        ]),

        // CTA
        'cta_title_line1' => Setting::get('landing_cta_title_line1', 'Téléchargez DR-PHARMA'),
        'cta_title_line2' => Setting::get('landing_cta_title_line2', 'et commandez dès maintenant'),
        'cta_highlight' => Setting::get('landing_cta_highlight', 'dès maintenant'),
        'cta_subtitle' => Setting::get('landing_cta_subtitle', 'Disponible gratuitement sur Android et bientôt sur iOS.'),
        'cta_appstore_url' => Setting::get('landing_cta_appstore_url', '#'),
        'cta_appstore_text' => Setting::get('landing_cta_appstore_text', 'App Store'),
        'cta_playstore_url' => Setting::get('landing_cta_playstore_url', '#'),
        'cta_playstore_text' => Setting::get('landing_cta_playstore_text', 'Google Play'),
        'cta_trust_1' => Setting::get('landing_cta_trust_1', 'Données chiffrées'),
        'cta_trust_2' => Setting::get('landing_cta_trust_2', 'App gratuite'),
        'cta_trust_3' => Setting::get('landing_cta_trust_3', 'Livraison à Abidjan'),
        'cta_trust_4' => Setting::get('landing_cta_trust_4', 'Support par WhatsApp'),

        // Footer
        'footer_description' => Setting::get('landing_footer_description', 'Service de commande et livraison de médicaments à Abidjan, Côte d\'Ivoire.'),
        'footer_email' => Setting::get('landing_footer_email', 'contact@drlpharma.com'),
        'footer_phone' => Setting::get('landing_footer_phone', '+225 07 01 159 572'),
        'footer_address' => Setting::get('landing_footer_address', 'Abidjan, Côte d\'Ivoire'),
        'footer_facebook_url' => Setting::get('landing_footer_facebook_url', 'https://web.facebook.com/profile.php?id=61588488598146'),
        'footer_instagram_url' => Setting::get('landing_footer_instagram_url', '#'),
        'footer_twitter_url' => Setting::get('landing_footer_twitter_url', '#'),
        'footer_linkedin_url' => Setting::get('landing_footer_linkedin_url', '#'),
        'footer_copyright' => Setting::get('landing_footer_copyright', '© 2025 DR-PHARMA. Tous droits réservés.'),
    ];

    return view('welcome', compact('landing'));
});

// Pages statiques
Route::get('/aide', function () {
    return view('pages.aide');
})->name('aide');

Route::get('/contact', function () {
    return view('pages.contact');
})->name('contact');

Route::post('/contact', function (Request $request) {
    $validated = $request->validate([
        'name'    => 'required|string|max:100',
        'email'   => 'required|email|max:150',
        'phone'   => 'nullable|string|max:30',
        'subject' => 'required|string|in:question,commande,paiement,livraison,partenariat,coursier,bug,autre',
        'message' => 'required|string|max:5000',
    ]);

    $subjectLabels = [
        'question'    => 'Question générale',
        'commande'    => 'Problème de commande',
        'paiement'    => 'Problème de paiement',
        'livraison'   => 'Problème de livraison',
        'partenariat' => 'Devenir partenaire (Pharmacie)',
        'coursier'    => 'Devenir coursier',
        'bug'         => 'Signaler un bug',
        'autre'       => 'Autre',
    ];

    try {
        $to = Setting::get('landing_footer_email', 'contact@drlpharma.com');
        $subjectLabel = $subjectLabels[$validated['subject']] ?? $validated['subject'];

        Mail::send([], [], function ($mail) use ($validated, $to, $subjectLabel) {
            $body = "Nom : {$validated['name']}\n"
                  . "Email : {$validated['email']}\n"
                  . "Téléphone : " . ($validated['phone'] ?? '—') . "\n"
                  . "Sujet : {$subjectLabel}\n\n"
                  . "Message :\n{$validated['message']}";

            $mail->to($to)
                 ->replyTo($validated['email'], $validated['name'])
                 ->subject("[DR PHARMA Contact] {$subjectLabel}")
                 ->text($body);
        });

        Log::info('Contact form submitted', [
            'name' => $validated['name'],
            'email' => $validated['email'],
            'subject' => $validated['subject'],
        ]);

        return redirect()->route('contact')->with('success', true);
    } catch (\Exception $e) {
        Log::error('Contact form error: ' . $e->getMessage());
        return redirect()->route('contact')
            ->with('error', 'Une erreur est survenue. Veuillez réessayer ou nous contacter par téléphone.')
            ->withInput();
    }
})->name('contact.submit')->middleware('throttle:5,1');  // 5 requests per minute max

Route::get('/confidentialite', function () {
    return view('pages.confidentialite');
})->name('confidentialite');

Route::get('/cgu', function () {
    return view('pages.cgu');
})->name('cgu');

Route::get('/guide', function () {
    $defaultSections = [
        ['id' => 'commandes', 'icon' => '🛒', 'title' => 'Traiter une commande', 'subtitle' => 'Recevoir, confirmer et préparer les commandes clients', 'color' => 'green', 'steps' => [['title' => 'Recevoir une nouvelle commande', 'content' => 'Lorsqu\'un client passe commande près de votre pharmacie, vous recevez une notification push et sonore. La commande apparaît dans l\'onglet <strong>« Commandes »</strong> avec le statut <strong>« En attente »</strong>.'], ['title' => 'Examiner la commande', 'content' => 'Appuyez sur la commande pour voir le détail : liste des produits, quantités, éventuelle ordonnance jointe, informations du client et mode de paiement choisi.'], ['title' => 'Confirmer ou refuser', 'content' => 'Si tous les produits sont disponibles, appuyez sur <strong>« Confirmer »</strong>. Si un produit manque, vous pouvez proposer un substitut ou refuser la commande en indiquant le motif.'], ['title' => 'Préparer la commande', 'content' => 'Une fois confirmée, préparez physiquement les médicaments. Quand tout est prêt, appuyez sur <strong>« Prêt pour récupération »</strong>. Un coursier sera automatiquement assigné.']], 'tip' => 'Traitez les commandes rapidement ! Un temps de réponse court améliore votre classement et la satisfaction des clients.'],
        ['id' => 'stock', 'icon' => '📦', 'title' => 'Gérer votre stock', 'subtitle' => 'Ajouter, modifier et suivre vos produits', 'color' => 'blue', 'steps' => [['title' => 'Accéder à votre inventaire', 'content' => 'Rendez-vous dans l\'onglet <strong>« Stock »</strong> depuis le menu principal.'], ['title' => 'Ajouter un produit', 'content' => 'Appuyez sur le bouton <strong>« + »</strong>. Scannez le code-barres, recherchez dans la base DR-PHARMA, ou saisissez manuellement.'], ['title' => 'Modifier un produit', 'content' => 'Appuyez sur un produit pour modifier prix, quantité ou le marquer <strong>« Indisponible »</strong>.'], ['title' => 'Alertes de stock bas', 'content' => 'Configurez des seuils d\'alerte pour être notifié quand un produit est bientôt en rupture.']], 'tip' => 'Gardez votre stock à jour ! Un catalogue précis vous permet de recevoir plus de commandes.'],
        ['id' => 'ordonnances', 'icon' => '📋', 'title' => 'Traiter les ordonnances', 'subtitle' => 'Recevoir et valider les ordonnances des patients', 'color' => 'amber', 'steps' => [['title' => 'Réception d\'une ordonnance', 'content' => 'Quand un client envoie une photo d\'ordonnance, vous recevez une notification avec le badge <strong>« Ordonnance »</strong>.'], ['title' => 'Vérifier l\'ordonnance', 'content' => 'Examinez la photo, vérifiez sa validité et les produits prescrits.'], ['title' => 'Créer le devis', 'content' => 'Sélectionnez les produits dans votre stock, ajustez les quantités et validez le devis.']], 'tip' => 'Si un médicament prescrit n\'est pas disponible, proposez un générique équivalent.'],
        ['id' => 'mode-garde', 'icon' => '🌙', 'title' => 'Mode Garde', 'subtitle' => 'Signaler votre pharmacie comme étant de garde', 'color' => 'purple', 'steps' => [['title' => 'Activer le mode garde', 'content' => 'Allez dans <strong>« Profil »</strong> → <strong>« Mode Garde »</strong>. Activez le toggle.'], ['title' => 'Définir les horaires', 'content' => 'Configurez les plages horaires de garde (ex : 20h - 8h).'], ['title' => 'Désactiver le mode garde', 'content' => 'Désactivez le mode pour revenir aux horaires normaux.']], 'tip' => 'Activez le mode garde lors des jours fériés et week-ends.'],
        ['id' => 'statistiques', 'icon' => '📊', 'title' => 'Statistiques & rapports', 'subtitle' => 'Suivre vos performances et ventes', 'color' => 'rose', 'steps' => [['title' => 'Accéder aux statistiques', 'content' => 'Depuis le <strong>menu profil</strong>, appuyez sur <strong>« Rapports & Analytics »</strong>.'], ['title' => 'Indicateurs disponibles', 'content' => 'Commandes traitées, chiffre d\'affaires, taux d\'acceptation, temps moyen, produits les plus vendus.'], ['title' => 'Filtrer par période', 'content' => 'Affichez les statistiques sur une période précise.']], 'tip' => 'Consultez régulièrement vos statistiques pour ajuster votre stock.'],
        ['id' => 'profil', 'icon' => '⚙️', 'title' => 'Profil & paramètres', 'subtitle' => 'Gérer les informations de votre pharmacie', 'color' => 'cyan', 'steps' => [['title' => 'Modifier les informations', 'content' => 'Dans <strong>« Profil »</strong> → <strong>« Ma Pharmacie »</strong>, modifiez nom, adresse, photo, téléphone et horaires.'], ['title' => 'Gérer les notifications', 'content' => 'Configurez vos préférences de notification.'], ['title' => 'Changer de mot de passe', 'content' => 'Allez dans <strong>« Sécurité »</strong> pour modifier votre mot de passe.']], 'tip' => ''],
    ];

    return view('pages.guide', [
        'heroTitle' => Setting::get('guide_hero_title', 'Guide d\'utilisation'),
        'heroSubtitle' => Setting::get('guide_hero_subtitle', 'Apprenez à utiliser l\'application DR-PHARMA Pharmacie pour gérer votre officine efficacement.'),
        'intro' => Setting::get('guide_intro', 'Ce guide vous accompagne pas à pas dans l\'utilisation de l\'application <strong>DR-PHARMA Pharmacie</strong>. Découvrez comment traiter les commandes, gérer votre stock, activer le mode garde et suivre vos performances.'),
        'sections' => Setting::get('guide_sections', $defaultSections),
    ]);
})->name('guide');

Route::get('/faq', function () {
    $defaultCategories = [
        ['icon' => '🛒', 'title' => 'Patients — Commandes & Livraisons', 'filter' => 'patient', 'questions' => [['question' => 'Comment passer une commande ?', 'answer' => 'Téléchargez l\'application DR-PHARMA, créez un compte, puis recherchez votre médicament par nom ou envoyez une photo de votre ordonnance.'], ['question' => 'Quel est le délai de livraison ?', 'answer' => 'En moyenne, votre commande est livrée en moins de 45 minutes dans les zones couvertes d\'Abidjan.'], ['question' => 'Comment suivre ma livraison ?', 'answer' => 'Suivez votre coursier en temps réel sur la carte dans l\'application.'], ['question' => 'Puis-je annuler une commande ?', 'answer' => 'Oui, tant que la pharmacie n\'a pas encore préparé votre commande.'], ['question' => 'Comment créer un compte ?', 'answer' => 'Téléchargez l\'application, appuyez sur "S\'inscrire" et suivez les étapes.']]],
        ['icon' => '💊', 'title' => 'Pharmaciens', 'filter' => 'pharmacien', 'questions' => [['question' => 'Comment traiter une commande ?', 'answer' => 'Dans l\'onglet "Commandes", appuyez sur une commande en attente, vérifiez les produits, puis confirmez ou refusez.'], ['question' => 'Comment ajouter un produit à mon stock ?', 'answer' => 'Allez dans "Stock", appuyez sur "+", scannez le code-barres ou entrez les informations manuellement.'], ['question' => 'Comment activer le mode garde ?', 'answer' => 'Dans "Profil" → "Mode Garde", activez le toggle et définissez vos horaires.'], ['question' => 'Comment devenir pharmacie partenaire ?', 'answer' => 'Contactez-nous via le formulaire de contact ou par email à support@drlpharma.com.'], ['question' => 'Comment voir mes statistiques de vente ?', 'answer' => 'Accédez à "Rapports & Analytics" depuis le menu profil.']]],
        ['icon' => '🚴', 'title' => 'Coursiers', 'filter' => 'coursier', 'questions' => [['question' => 'Comment accepter une livraison ?', 'answer' => 'Allez dans "Livraisons" et appuyez sur "Accepter".'], ['question' => 'Comment recharger mon portefeuille ?', 'answer' => 'Profil → Portefeuille → Recharger via Mobile Money ou carte bancaire.'], ['question' => 'Comment confirmer une livraison ?', 'answer' => 'Demandez le code à 4 chiffres au client et entrez-le dans l\'application.'], ['question' => 'Comment devenir coursier DR-PHARMA ?', 'answer' => 'Téléchargez l\'app Coursier, inscrivez-vous avec vos documents. Validation sous 48h.']]],
        ['icon' => '💳', 'title' => 'Paiements', 'filter' => 'paiement', 'questions' => [['question' => 'Quels moyens de paiement sont acceptés ?', 'answer' => 'Orange Money, MTN Mobile Money, Moov Money, Wave, cartes bancaires et cash à la livraison.'], ['question' => 'Mon paiement a échoué, que faire ?', 'answer' => 'Vérifiez votre solde et connexion. Si le problème persiste, essayez un autre moyen de paiement.'], ['question' => 'Comment obtenir un remboursement ?', 'answer' => 'Contactez notre support. Remboursements traités sous 24 à 48 heures.']]],
        ['icon' => '🔒', 'title' => 'Compte & Sécurité', 'filter' => 'patient', 'questions' => [['question' => 'Mes données sont-elles sécurisées ?', 'answer' => 'Oui. Toutes les communications sont chiffrées (HTTPS/TLS).'], ['question' => 'J\'ai oublié mon mot de passe, comment le réinitialiser ?', 'answer' => 'Appuyez sur "Mot de passe oublié ?" sur l\'écran de connexion.']]],
    ];

    return view('pages.faq', [
        'heroTitle' => Setting::get('faq_hero_title', 'Foire aux questions'),
        'heroSubtitle' => Setting::get('faq_hero_subtitle', 'Trouvez des réponses rapides à toutes vos questions sur DR-PHARMA.'),
        'categories' => Setting::get('faq_categories', $defaultCategories),
    ]);
})->name('faq');

Route::get('/tutoriels', function () {
    $defaultVideos = [
        ['title' => 'Passer sa première commande', 'description' => 'Créer un compte, rechercher un médicament et commander en quelques minutes.', 'badge' => 'Patient', 'url' => 'https://www.youtube.com/@drlpharma'],
        ['title' => 'Envoyer une ordonnance', 'description' => 'Comment photographier et envoyer votre ordonnance à une pharmacie.', 'badge' => 'Patient', 'url' => 'https://www.youtube.com/@drlpharma'],
        ['title' => 'Gérer les commandes', 'description' => 'Recevoir, confirmer et préparer les commandes des patients.', 'badge' => 'Pharmacien', 'url' => 'https://www.youtube.com/@drlpharma'],
        ['title' => 'Gérer votre stock', 'description' => 'Ajouter des produits, mettre à jour les prix et gérer les ruptures.', 'badge' => 'Pharmacien', 'url' => 'https://www.youtube.com/@drlpharma'],
        ['title' => 'Première livraison', 'description' => 'Accepter, naviguer et confirmer votre première livraison.', 'badge' => 'Coursier', 'url' => 'https://www.youtube.com/@drlpharma'],
        ['title' => 'Recharger son portefeuille', 'description' => 'Comment recharger via Mobile Money ou carte bancaire.', 'badge' => 'Coursier', 'url' => 'https://www.youtube.com/@drlpharma'],
    ];

    return view('pages.tutoriels', [
        'heroTitle' => Setting::get('tutorials_hero_title', 'Tutoriels vidéo'),
        'heroSubtitle' => Setting::get('tutorials_hero_subtitle', 'Apprenez à utiliser DR-PHARMA grâce à nos vidéos explicatives.'),
        'intro' => Setting::get('tutorials_intro', 'Nos tutoriels vous guident pas à pas pour maîtriser toutes les fonctionnalités de l\'application DR-PHARMA, que vous soyez <strong>patient</strong>, <strong>pharmacien</strong> ou <strong>coursier</strong>.'),
        'youtubeUrl' => Setting::get('tutorials_youtube_url', 'https://www.youtube.com/@drlpharma'),
        'videos' => Setting::get('tutorials_videos', $defaultVideos),
    ]);
})->name('tutoriels');

// Aliases pour les URLs retournées par l'API support settings
Route::get('/terms', function () {
    return redirect()->route('cgu');
});

Route::get('/privacy', function () {
    return redirect()->route('confidentialite');
});

// Routes pour servir les documents privés (admin uniquement)
// SECURITY: auth + vérification rôle admin dans le contrôleur
Route::middleware(['web', 'auth'])->prefix('admin/documents')->group(function () {
    Route::get('/view/{path}', [PrivateDocumentController::class, 'show'])
        ->where('path', '.*')
        ->name('admin.documents.view');
    Route::get('/download/{path}', [PrivateDocumentController::class, 'download'])
        ->where('path', '.*')
        ->name('admin.documents.download');
});

// Proxy for images to handle CORS in development
Route::get('/img-proxy/{path}', function ($path) {
    // Sanitize path to prevent directory traversal
    $path = urldecode($path);
    $path = str_replace(['..', '\\'], '', $path);
    $path = ltrim($path, '/');
    
    if (!preg_match('/^[a-zA-Z0-9\/_\-\.]+$/', $path)) {
        abort(400);
    }
    
    $filePath = storage_path('app/public/' . $path);
    
    if (!file_exists($filePath)) {
        abort(404);
    }
    
    $file = \Illuminate\Support\Facades\File::get($filePath);
    $type = \Illuminate\Support\Facades\File::mimeType($filePath);
    
    // Only allow image MIME types
    if (!str_starts_with($type, 'image/')) {
        abort(403);
    }
    
    $allowedOrigin = config('app.url', '*');
    
    return response($file, 200)->header("Content-Type", $type)
        ->header("Access-Control-Allow-Origin", $allowedOrigin)
        ->header("Cache-Control", "public, max-age=86400");
})->where('path', '.*');
