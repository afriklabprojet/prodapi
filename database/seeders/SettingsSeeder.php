<?php

namespace Database\Seeders;

use App\Models\Setting;
use Illuminate\Database\Seeder;

class SettingsSeeder extends Seeder
{
    public function run(): void
    {
        $settings = [
            // ──────────────────────────────────────
            // DELIVERY
            // ──────────────────────────────────────
            ['key' => 'delivery_base_fee', 'value' => '500', 'type' => 'integer'],
            ['key' => 'delivery_fee_per_km', 'value' => '100', 'type' => 'integer'],
            ['key' => 'delivery_fee_base', 'value' => '200', 'type' => 'integer'],
            ['key' => 'delivery_per_km', 'value' => '200', 'type' => 'integer'],
            ['key' => 'delivery_fee_min', 'value' => '300', 'type' => 'integer'],
            ['key' => 'delivery_fee_max', 'value' => '5000', 'type' => 'integer'],
            ['key' => 'delivery_max_distance_km', 'value' => '20', 'type' => 'integer'],
            ['key' => 'delivery_timeout_minutes', 'value' => '30', 'type' => 'integer'],
            ['key' => 'free_delivery_threshold', 'value' => '0', 'type' => 'integer'],

            // ──────────────────────────────────────
            // COMMISSIONS
            // ──────────────────────────────────────
            ['key' => 'platform_commission_rate', 'value' => '0.10', 'type' => 'float'],
            ['key' => 'pharmacy_default_commission_rate', 'value' => '0.05', 'type' => 'float'],
            ['key' => 'courier_commission_rate', 'value' => '0.80', 'type' => 'float'],
            ['key' => 'default_commission_rate_platform', 'value' => '10', 'type' => 'integer'],
            ['key' => 'default_commission_rate_pharmacy', 'value' => '85', 'type' => 'integer'],
            ['key' => 'default_commission_rate_courier', 'value' => '5', 'type' => 'integer'],

            // ──────────────────────────────────────
            // FEES & PAYMENTS
            // ──────────────────────────────────────
            ['key' => 'minimum_order_amount', 'value' => '1000', 'type' => 'integer'],
            ['key' => 'minimum_order', 'value' => '1000', 'type' => 'integer'],
            ['key' => 'minimum_withdrawal_amount', 'value' => '500', 'type' => 'integer'],
            ['key' => 'payment_timeout_minutes', 'value' => '15', 'type' => 'integer'],
            ['key' => 'service_fee_percentage', 'value' => '2', 'type' => 'float'],
            ['key' => 'service_fee_percent', 'value' => '5', 'type' => 'float'],
            ['key' => 'service_fee_min', 'value' => '100', 'type' => 'integer'],
            ['key' => 'service_fee_max', 'value' => '2000', 'type' => 'integer'],
            ['key' => 'apply_service_fee', 'value' => '1', 'type' => 'boolean'],
            ['key' => 'apply_payment_fee', 'value' => '1', 'type' => 'boolean'],
            ['key' => 'payment_processing_fee', 'value' => '50', 'type' => 'integer'],
            ['key' => 'payment_processing_percentage', 'value' => '1.5', 'type' => 'float'],
            ['key' => 'payment_mode_platform_enabled', 'value' => '1', 'type' => 'boolean'],
            ['key' => 'payment_mode_cash_enabled', 'value' => '0', 'type' => 'boolean'],
            ['key' => 'payment_mode_wallet_enabled', 'value' => '1', 'type' => 'boolean'],

            // ──────────────────────────────────────
            // WAITING FEES
            // ──────────────────────────────────────
            ['key' => 'waiting_timeout_minutes', 'value' => '10', 'type' => 'integer'],
            ['key' => 'waiting_fee_per_minute', 'value' => '100', 'type' => 'integer'],
            ['key' => 'waiting_free_minutes', 'value' => '2', 'type' => 'integer'],

            // ──────────────────────────────────────
            // WITHDRAWALS
            // ──────────────────────────────────────
            ['key' => 'withdrawal_threshold_min', 'value' => '10000', 'type' => 'integer'],
            ['key' => 'withdrawal_threshold_max', 'value' => '500000', 'type' => 'integer'],
            ['key' => 'withdrawal_threshold_default', 'value' => '50000', 'type' => 'integer'],
            ['key' => 'withdrawal_threshold_step', 'value' => '5000', 'type' => 'integer'],
            ['key' => 'auto_withdraw_enabled_global', 'value' => '1', 'type' => 'boolean'],
            ['key' => 'withdrawal_require_pin', 'value' => '1', 'type' => 'boolean'],
            ['key' => 'withdrawal_require_mobile_money', 'value' => '1', 'type' => 'boolean'],

            // ──────────────────────────────────────
            // APP & SUPPORT
            // ──────────────────────────────────────
            ['key' => 'app_name', 'value' => 'DR-PHARMA', 'type' => 'string'],
            ['key' => 'app_version', 'value' => '1.0.0', 'type' => 'string'],
            ['key' => 'support_email', 'value' => config('drpharma.brand.support_email'), 'type' => 'string'],
            ['key' => 'support_phone', 'value' => '+2250701159572', 'type' => 'string'],
            ['key' => 'support_whatsapp', 'value' => '+2250701159572', 'type' => 'string'],
            ['key' => 'website_url', 'value' => config('drpharma.brand.website'), 'type' => 'string'],
            ['key' => 'tutorials_url', 'value' => '/tutoriels', 'type' => 'string'],
            ['key' => 'guide_url', 'value' => '/guide', 'type' => 'string'],
            ['key' => 'faq_url', 'value' => '/faq', 'type' => 'string'],
            ['key' => 'terms_url', 'value' => '/cgu', 'type' => 'string'],
            ['key' => 'privacy_url', 'value' => '/confidentialite', 'type' => 'string'],

            // ──────────────────────────────────────
            // LANDING — SEO
            // ──────────────────────────────────────
            ['key' => 'landing_seo_title', 'value' => 'DR-PHARMA — Votre Santé, Simplifiée', 'type' => 'string'],
            ['key' => 'landing_seo_description', 'value' => 'DR-PHARMA — La plateforme santé digitale N°1 en Côte d\'Ivoire. Commandez vos médicaments, gérez votre pharmacie, livrez en toute sécurité.', 'type' => 'string'],

            // ──────────────────────────────────────
            // LANDING — HERO
            // ──────────────────────────────────────
            ['key' => 'landing_hero_badge', 'value' => 'Disponible en Côte d\'Ivoire', 'type' => 'string'],
            ['key' => 'landing_hero_title_line1', 'value' => 'Votre santé,', 'type' => 'string'],
            ['key' => 'landing_hero_title_line2', 'value' => 'simplifiée.', 'type' => 'string'],
            ['key' => 'landing_hero_subtitle', 'value' => 'Commandez vos médicaments, gérez votre pharmacie ou livrez en toute sécurité — tout depuis votre smartphone.', 'type' => 'string'],
            ['key' => 'landing_hero_cta_appstore_text', 'value' => 'App Store', 'type' => 'string'],
            ['key' => 'landing_hero_cta_appstore_url', 'value' => '#telecharger', 'type' => 'string'],
            ['key' => 'landing_hero_cta_playstore_text', 'value' => 'Google Play', 'type' => 'string'],
            ['key' => 'landing_hero_cta_playstore_url', 'value' => '#telecharger', 'type' => 'string'],
            ['key' => 'landing_hero_trust_1', 'value' => 'Gratuit', 'type' => 'string'],
            ['key' => 'landing_hero_trust_2', 'value' => 'Sécurisé', 'type' => 'string'],
            ['key' => 'landing_hero_trust_3', 'value' => 'Rapide', 'type' => 'string'],
            ['key' => 'landing_hero_phone_title', 'value' => 'DR-PHARMA', 'type' => 'string'],
            ['key' => 'landing_hero_phone_subtitle', 'value' => 'Votre pharmacie de poche', 'type' => 'string'],

            // ──────────────────────────────────────
            // LANDING — STATS
            // ──────────────────────────────────────
            ['key' => 'landing_stats_auto', 'value' => '1', 'type' => 'boolean'],
            ['key' => 'landing_stats', 'value' => json_encode([
                ['value' => '500', 'suffix' => '+', 'label' => 'Pharmacies partenaires'],
                ['value' => '10000', 'suffix' => '+', 'label' => 'Utilisateurs actifs'],
                ['value' => '2000', 'suffix' => '+', 'label' => 'Médicaments référencés'],
                ['value' => '98', 'suffix' => '%', 'label' => 'Satisfaction client'],
            ]), 'type' => 'json'],

            // ──────────────────────────────────────
            // LANDING — FEATURES
            // ──────────────────────────────────────
            ['key' => 'landing_features_badge', 'value' => 'Fonctionnalités', 'type' => 'string'],
            ['key' => 'landing_features_title', 'value' => 'Tout ce dont vous avez besoin', 'type' => 'string'],
            ['key' => 'landing_features_title_highlight', 'value' => 'besoin', 'type' => 'string'],
            ['key' => 'landing_features_subtitle', 'value' => 'Une plateforme complète qui connecte patients, pharmaciens et coursiers pour un accès simple et rapide aux médicaments.', 'type' => 'string'],
            ['key' => 'landing_features', 'value' => json_encode([
                ['title' => 'Recherche intelligente', 'description' => 'Trouvez vos médicaments en quelques secondes parmi plus de 2000 références.', 'icon_color' => 'green'],
                ['title' => 'Ordonnances numériques', 'description' => 'Envoyez une photo de votre ordonnance et recevez vos médicaments sans vous déplacer.', 'icon_color' => 'blue'],
                ['title' => 'Suivi GPS en temps réel', 'description' => 'Suivez votre livreur en direct sur la carte avec notifications à chaque étape.', 'icon_color' => 'amber'],
                ['title' => 'Paiement sécurisé', 'description' => 'Mobile Money, carte bancaire ou paiement à la livraison. 100% sécurisé.', 'icon_color' => 'purple'],
                ['title' => 'Livraison express', 'description' => 'Recevez vos médicaments en moins de 45 minutes partout à Abidjan.', 'icon_color' => 'rose'],
                ['title' => 'Tableau de bord pharmacie', 'description' => 'Gérez vos stocks, commandes et statistiques depuis un dashboard intuitif.', 'icon_color' => 'cyan'],
            ]), 'type' => 'json'],

            // ──────────────────────────────────────
            // LANDING — STEPS
            // ──────────────────────────────────────
            ['key' => 'landing_steps_badge', 'value' => 'Processus', 'type' => 'string'],
            ['key' => 'landing_steps_title', 'value' => 'Comment ça marche ?', 'type' => 'string'],
            ['key' => 'landing_steps_title_highlight', 'value' => 'marche ?', 'type' => 'string'],
            ['key' => 'landing_steps_subtitle', 'value' => 'En seulement 3 étapes, recevez vos médicaments à domicile.', 'type' => 'string'],
            ['key' => 'landing_steps', 'value' => json_encode([
                ['title' => 'Recherchez', 'description' => 'Tapez le nom du médicament ou envoyez une photo de votre ordonnance.', 'color' => 'green'],
                ['title' => 'Commandez', 'description' => 'Choisissez la pharmacie la plus proche et payez en toute sécurité.', 'color' => 'blue'],
                ['title' => 'Recevez', 'description' => 'Un coursier vous livre en moins de 45 minutes. Suivez-le en direct !', 'color' => 'amber'],
            ]), 'type' => 'json'],

            // ──────────────────────────────────────
            // LANDING — APPS
            // ──────────────────────────────────────
            ['key' => 'landing_apps_badge', 'value' => 'Nos Applications', 'type' => 'string'],
            ['key' => 'landing_apps_title', 'value' => '3 apps, 1 écosystème', 'type' => 'string'],
            ['key' => 'landing_apps_title_highlight', 'value' => '1 écosystème', 'type' => 'string'],
            ['key' => 'landing_apps_subtitle', 'value' => 'Chaque acteur de la chaîne dispose de son application dédiée, connectée en temps réel.', 'type' => 'string'],
            ['key' => 'landing_apps', 'value' => json_encode([
                ['tag' => 'PATIENT', 'title' => 'App Patient', 'description' => 'Commandez vos médicaments, envoyez vos ordonnances et suivez vos livraisons.', 'color' => 'green', 'features' => 'Recherche & commande|Upload d\'ordonnance|Suivi GPS en direct|Paiement Mobile Money'],
                ['tag' => 'PHARMACIE', 'title' => 'App Pharmacien', 'description' => 'Gérez votre officine digitale : stocks, commandes, statistiques.', 'color' => 'blue', 'features' => 'Gestion de stock avancée|Traitement d\'ordonnances|Dashboard analytique|Notifications temps réel'],
                ['tag' => 'COURSIER', 'title' => 'App Coursier', 'description' => 'Optimisez vos tournées, acceptez des courses et augmentez vos revenus.', 'color' => 'amber', 'features' => 'Navigation GPS optimisée|Système de challenges|Statistiques de gains|Paiement automatique'],
            ]), 'type' => 'json'],

            // ──────────────────────────────────────
            // LANDING — TESTIMONIALS
            // ──────────────────────────────────────
            ['key' => 'landing_testimonials_badge', 'value' => 'Témoignages', 'type' => 'string'],
            ['key' => 'landing_testimonials_title', 'value' => 'Ils nous font confiance', 'type' => 'string'],
            ['key' => 'landing_testimonials_title_highlight', 'value' => 'confiance', 'type' => 'string'],
            ['key' => 'landing_testimonials', 'value' => json_encode([
                ['quote' => 'Depuis que j\'utilise DR-PHARMA, je ne fais plus la queue en pharmacie. Mes médicaments arrivent chez moi en 30 minutes !', 'name' => 'Aminata K.', 'role' => 'Patiente — Cocody, Abidjan', 'initials' => 'AK', 'color' => 'green', 'rating' => 5],
                ['quote' => 'DR-PHARMA a modernisé ma pharmacie. Mon chiffre d\'affaires a augmenté de 40% en 3 mois !', 'name' => 'Dr. Yao D.', 'role' => 'Pharmacien — Plateau, Abidjan', 'initials' => 'DY', 'color' => 'blue', 'rating' => 5],
                ['quote' => 'Grâce aux challenges et au système de bonus, je gagne bien ma vie. L\'app est intuitive et les courses bien payées.', 'name' => 'Kouadio S.', 'role' => 'Coursier — Yopougon, Abidjan', 'initials' => 'KS', 'color' => 'amber', 'rating' => 5],
            ]), 'type' => 'json'],

            // ──────────────────────────────────────
            // LANDING — FAQ
            // ──────────────────────────────────────
            ['key' => 'landing_faq_badge', 'value' => 'FAQ', 'type' => 'string'],
            ['key' => 'landing_faq_title', 'value' => 'Questions fréquentes', 'type' => 'string'],
            ['key' => 'landing_faq_title_highlight', 'value' => 'fréquentes', 'type' => 'string'],
            ['key' => 'landing_faqs', 'value' => json_encode([
                ['question' => 'Comment commander mes médicaments ?', 'answer' => 'Téléchargez l\'app Patient, créez votre compte et recherchez votre médicament ou envoyez une photo de votre ordonnance.'],
                ['question' => 'L\'application est-elle gratuite ?', 'answer' => 'Oui ! Le téléchargement et l\'inscription sont gratuits. Vous ne payez que les médicaments et les frais de livraison (à partir de 300 FCFA).'],
                ['question' => 'Quels sont les moyens de paiement ?', 'answer' => 'Orange Money, MTN Mobile Money, Moov Money, Wave, cartes bancaires (Visa/Mastercard) et paiement à la livraison.'],
                ['question' => 'Comment devenir pharmacie partenaire ?', 'answer' => 'Téléchargez l\'app Pharmacien, remplissez le formulaire avec vos documents officiels. Validation sous 48h.'],
                ['question' => 'Dans quelles zones livrez-vous ?', 'answer' => 'Tout le district d\'Abidjan : Cocody, Plateau, Marcory, Treichville, Yopougon, Abobo, Adjamé, Koumassi, Port-Bouët et Bingerville.'],
                ['question' => 'Comment devenir coursier ?', 'answer' => 'Téléchargez l\'app Coursier, inscrivez-vous avec vos pièces d\'identité et permis. Après vérification, commencez à livrer.'],
            ]), 'type' => 'json'],

            // ──────────────────────────────────────
            // LANDING — CTA
            // ──────────────────────────────────────
            ['key' => 'landing_cta_title_line1', 'value' => 'Prêt à simplifier', 'type' => 'string'],
            ['key' => 'landing_cta_title_line2', 'value' => 'votre accès aux médicaments ?', 'type' => 'string'],
            ['key' => 'landing_cta_highlight', 'value' => 'médicaments', 'type' => 'string'],
            ['key' => 'landing_cta_subtitle', 'value' => 'Rejoignez des milliers d\'utilisateurs en Côte d\'Ivoire. Téléchargez l\'application gratuitement.', 'type' => 'string'],
            ['key' => 'landing_cta_appstore_url', 'value' => '#', 'type' => 'string'],
            ['key' => 'landing_cta_appstore_text', 'value' => 'App Store', 'type' => 'string'],
            ['key' => 'landing_cta_playstore_url', 'value' => '#', 'type' => 'string'],
            ['key' => 'landing_cta_playstore_text', 'value' => 'Google Play', 'type' => 'string'],
            ['key' => 'landing_cta_trust_1', 'value' => '100% Sécurisé', 'type' => 'string'],
            ['key' => 'landing_cta_trust_2', 'value' => 'Gratuit', 'type' => 'string'],
            ['key' => 'landing_cta_trust_3', 'value' => 'Livraison < 45 min', 'type' => 'string'],
            ['key' => 'landing_cta_trust_4', 'value' => '4.8★ sur les stores', 'type' => 'string'],

            // ──────────────────────────────────────
            // LANDING — FOOTER
            // ──────────────────────────────────────
            ['key' => 'landing_footer_description', 'value' => 'La plateforme santé digitale N°1 en Côte d\'Ivoire. Connecter les patients, pharmaciens et coursiers.', 'type' => 'string'],
            ['key' => 'landing_footer_email', 'value' => 'contact@drlpharma.com', 'type' => 'string'],
            ['key' => 'landing_footer_phone', 'value' => '+225 07 01 159 572', 'type' => 'string'],
            ['key' => 'landing_footer_address', 'value' => 'Abidjan, Côte d\'Ivoire', 'type' => 'string'],
            ['key' => 'landing_footer_facebook_url', 'value' => '#', 'type' => 'string'],
            ['key' => 'landing_footer_instagram_url', 'value' => '#', 'type' => 'string'],
            ['key' => 'landing_footer_twitter_url', 'value' => '#', 'type' => 'string'],
            ['key' => 'landing_footer_linkedin_url', 'value' => '#', 'type' => 'string'],
            ['key' => 'landing_footer_copyright', 'value' => '© 2026 DR-PHARMA. Tous droits réservés. Fait en Côte d\'Ivoire', 'type' => 'string'],
        ];

        foreach ($settings as $setting) {
            Setting::updateOrCreate(
                ['key' => $setting['key']],
                $setting
            );
        }
    }
}
