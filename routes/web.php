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
        'seo_title' => Setting::get('landing_seo_title', 'DR-PHARMA — Votre Santé, Simplifiée'),
        'seo_description' => Setting::get('landing_seo_description', 'DR-PHARMA — La plateforme santé digitale N°1 en Côte d\'Ivoire. Commandez vos médicaments, gérez votre pharmacie, livrez en toute sécurité.'),

        // Hero
        'hero_badge' => Setting::get('landing_hero_badge', 'Disponible en Côte d\'Ivoire'),
        'hero_title_line1' => Setting::get('landing_hero_title_line1', 'Votre santé,'),
        'hero_title_line2' => Setting::get('landing_hero_title_line2', 'simplifiée.'),
        'hero_subtitle' => Setting::get('landing_hero_subtitle', 'Commandez vos médicaments, gérez votre pharmacie ou livrez en toute sécurité — tout depuis votre smartphone.'),
        'hero_cta_appstore_url' => Setting::get('landing_hero_cta_appstore_url', '#telecharger'),
        'hero_cta_playstore_url' => Setting::get('landing_hero_cta_playstore_url', '#telecharger'),
        'hero_trust_1' => Setting::get('landing_hero_trust_1', 'Gratuit'),
        'hero_trust_2' => Setting::get('landing_hero_trust_2', 'Sécurisé'),
        'hero_trust_3' => Setting::get('landing_hero_trust_3', 'Rapide'),
        'hero_phone_title' => Setting::get('landing_hero_phone_title', 'DR-PHARMA'),
        'hero_phone_subtitle' => Setting::get('landing_hero_phone_subtitle', 'Votre pharmacie de poche'),

        // Stats
        'stats' => Setting::get('landing_stats', [
            ['value' => '500', 'suffix' => '+', 'label' => 'Pharmacies partenaires'],
            ['value' => '10000', 'suffix' => '+', 'label' => 'Utilisateurs actifs'],
            ['value' => '2000', 'suffix' => '+', 'label' => 'Médicaments référencés'],
            ['value' => '98', 'suffix' => '%', 'label' => 'Satisfaction client'],
        ]),

        // Features
        'features_badge' => Setting::get('landing_features_badge', 'Fonctionnalités'),
        'features_title' => Setting::get('landing_features_title', 'Tout ce dont vous avez besoin'),
        'features_title_highlight' => Setting::get('landing_features_title_highlight', 'besoin'),
        'features_subtitle' => Setting::get('landing_features_subtitle', 'Une plateforme complète qui connecte patients, pharmaciens et coursiers pour un accès simple et rapide aux médicaments.'),
        'features' => Setting::get('landing_features', [
            ['title' => 'Recherche intelligente', 'description' => 'Trouvez vos médicaments en quelques secondes parmi plus de 2000 références.', 'icon_color' => 'green'],
            ['title' => 'Ordonnances numériques', 'description' => 'Envoyez une photo de votre ordonnance et recevez vos médicaments sans vous déplacer.', 'icon_color' => 'blue'],
            ['title' => 'Suivi GPS en temps réel', 'description' => 'Suivez votre livreur en direct sur la carte.', 'icon_color' => 'amber'],
            ['title' => 'Paiement sécurisé', 'description' => 'Mobile Money, carte bancaire ou paiement à la livraison.', 'icon_color' => 'purple'],
            ['title' => 'Livraison express', 'description' => 'Recevez vos médicaments en moins de 45 minutes.', 'icon_color' => 'rose'],
            ['title' => 'Tableau de bord pharmacie', 'description' => 'Gérez vos stocks, commandes et statistiques depuis un dashboard intuitif.', 'icon_color' => 'cyan'],
        ]),

        // Steps
        'steps_badge' => Setting::get('landing_steps_badge', 'Processus'),
        'steps_title' => Setting::get('landing_steps_title', 'Comment ça marche ?'),
        'steps_title_highlight' => Setting::get('landing_steps_title_highlight', 'marche ?'),
        'steps_subtitle' => Setting::get('landing_steps_subtitle', 'En seulement 3 étapes, recevez vos médicaments à domicile.'),
        'steps' => Setting::get('landing_steps', [
            ['title' => 'Recherchez', 'description' => 'Tapez le nom du médicament ou envoyez une photo de votre ordonnance.', 'color' => 'green'],
            ['title' => 'Commandez', 'description' => 'Choisissez la pharmacie la plus proche, ajoutez au panier et payez.', 'color' => 'blue'],
            ['title' => 'Recevez', 'description' => 'Un coursier récupère votre commande et vous la livre en moins de 45 minutes.', 'color' => 'amber'],
        ]),

        // Apps
        'apps_badge' => Setting::get('landing_apps_badge', 'Nos Applications'),
        'apps_title' => Setting::get('landing_apps_title', '3 apps, 1 écosystème'),
        'apps_title_highlight' => Setting::get('landing_apps_title_highlight', '1 écosystème'),
        'apps_subtitle' => Setting::get('landing_apps_subtitle', 'Chaque acteur de la chaîne dispose de son application dédiée, connectée en temps réel.'),
        'apps' => Setting::get('landing_apps', [
            ['tag' => 'PATIENT', 'title' => 'App Patient', 'description' => 'Commandez vos médicaments.', 'color' => 'green', 'features' => 'Recherche & commande|Upload d\'ordonnance|Suivi GPS en direct|Paiement Mobile Money'],
            ['tag' => 'PHARMACIE', 'title' => 'App Pharmacien', 'description' => 'Gérez votre officine digitale.', 'color' => 'blue', 'features' => 'Gestion de stock|Traitement d\'ordonnances|Dashboard analytique|Notifications temps réel'],
            ['tag' => 'COURSIER', 'title' => 'App Coursier', 'description' => 'Optimisez vos tournées.', 'color' => 'amber', 'features' => 'Navigation GPS|Système de challenges|Statistiques de gains|Paiement automatique'],
        ]),

        // Testimonials
        'testimonials_badge' => Setting::get('landing_testimonials_badge', 'Témoignages'),
        'testimonials_title' => Setting::get('landing_testimonials_title', 'Ils nous font confiance'),
        'testimonials_title_highlight' => Setting::get('landing_testimonials_title_highlight', 'confiance'),
        'testimonials' => Setting::get('landing_testimonials', [
            ['quote' => 'Depuis que j\'utilise DR-PHARMA, je ne fais plus la queue en pharmacie.', 'name' => 'Aminata K.', 'role' => 'Patiente — Cocody, Abidjan', 'initials' => 'AK', 'color' => 'green', 'rating' => 5],
            ['quote' => 'DR-PHARMA a modernisé ma pharmacie.', 'name' => 'Dr. Yao D.', 'role' => 'Pharmacien — Plateau, Abidjan', 'initials' => 'DY', 'color' => 'blue', 'rating' => 5],
            ['quote' => 'Grâce aux challenges et au système de bonus, je gagne bien ma vie.', 'name' => 'Kouadio S.', 'role' => 'Coursier — Yopougon, Abidjan', 'initials' => 'KS', 'color' => 'amber', 'rating' => 5],
        ]),

        // FAQ
        'faq_badge' => Setting::get('landing_faq_badge', 'FAQ'),
        'faq_title' => Setting::get('landing_faq_title', 'Questions fréquentes'),
        'faq_title_highlight' => Setting::get('landing_faq_title_highlight', 'fréquentes'),
        'faqs' => Setting::get('landing_faqs', [
            ['question' => 'Comment commander mes médicaments ?', 'answer' => 'Téléchargez l\'app Patient, créez votre compte et recherchez votre médicament.'],
            ['question' => 'L\'application est-elle gratuite ?', 'answer' => 'Oui ! Le téléchargement et l\'inscription sont entièrement gratuits.'],
            ['question' => 'Quels sont les moyens de paiement acceptés ?', 'answer' => 'Nous acceptons Orange Money, MTN, Moov, Wave, les cartes bancaires et le cash.'],
        ]),

        // CTA
        'cta_title_line1' => Setting::get('landing_cta_title_line1', 'Prêt à simplifier'),
        'cta_title_line2' => Setting::get('landing_cta_title_line2', 'votre accès aux médicaments ?'),
        'cta_highlight' => Setting::get('landing_cta_highlight', 'médicaments'),
        'cta_subtitle' => Setting::get('landing_cta_subtitle', 'Rejoignez des milliers d\'utilisateurs en Côte d\'Ivoire.'),
        'cta_appstore_url' => Setting::get('landing_cta_appstore_url', '#'),
        'cta_playstore_url' => Setting::get('landing_cta_playstore_url', '#'),
        'cta_trust_1' => Setting::get('landing_cta_trust_1', '100% Sécurisé'),
        'cta_trust_2' => Setting::get('landing_cta_trust_2', 'Gratuit'),
        'cta_trust_3' => Setting::get('landing_cta_trust_3', 'Livraison < 45 min'),
        'cta_trust_4' => Setting::get('landing_cta_trust_4', '4.8★ sur les stores'),

        // Footer
        'footer_description' => Setting::get('landing_footer_description', 'La plateforme santé digitale N°1 en Côte d\'Ivoire.'),
        'footer_email' => Setting::get('landing_footer_email', 'contact@drlpharma.com'),
        'footer_phone' => Setting::get('landing_footer_phone', '+225 07 01 159 572'),
        'footer_address' => Setting::get('landing_footer_address', 'Abidjan, Côte d\'Ivoire'),
        'footer_facebook_url' => Setting::get('landing_footer_facebook_url', 'https://web.facebook.com/profile.php?id=61588488598146'),
        'footer_instagram_url' => Setting::get('landing_footer_instagram_url', '#'),
        'footer_twitter_url' => Setting::get('landing_footer_twitter_url', '#'),
        'footer_linkedin_url' => Setting::get('landing_footer_linkedin_url', '#'),
        'footer_copyright' => Setting::get('landing_footer_copyright', '© 2026 DR-PHARMA. Tous droits réservés. Fait en Côte d\'Ivoire'),
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
