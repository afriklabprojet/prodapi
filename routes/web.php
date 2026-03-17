<?php

use App\Models\Setting;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;
use App\Http\Controllers\Admin\PrivateDocumentController;

Route::get('/', function () {
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
        'hero_cta_playstore_url' => Setting::get('landing_hero_cta_playstore_url', '#telecharger'),
        'hero_trust_1' => Setting::get('landing_hero_trust_1', 'Téléchargement gratuit'),
        'hero_trust_2' => Setting::get('landing_hero_trust_2', 'Données protégées'),
        'hero_trust_3' => Setting::get('landing_hero_trust_3', 'Livraison rapide'),
        'hero_phone_title' => Setting::get('landing_hero_phone_title', 'DR-PHARMA'),
        'hero_phone_subtitle' => Setting::get('landing_hero_phone_subtitle', 'Commandez en quelques clics'),

        // Stats
        'stats' => Setting::get('landing_stats', [
            ['value' => '50', 'suffix' => '+', 'label' => 'Pharmacies inscrites'],
            ['value' => '1200', 'suffix' => '+', 'label' => 'Commandes livrées'],
            ['value' => '850', 'suffix' => '+', 'label' => 'Médicaments disponibles'],
            ['value' => '42', 'suffix' => ' min', 'label' => 'Délai moyen de livraison'],
        ]),

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
        'cta_playstore_url' => Setting::get('landing_cta_playstore_url', '#'),
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

// Routes pour servir les documents privés (admin uniquement)
// Ces routes doivent être APRÈS le middleware web mais AVANT les routes Filament
Route::middleware(['web'])->prefix('admin/documents')->group(function () {
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
