<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;

class SupportSettingsController extends Controller
{
    /**
     * Récupère les paramètres d'aide et support pour les apps mobiles
     */
    public function index(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => [
                'support_phone' => Setting::get('support_phone', '+225 07 01 159 572'),
                'support_email' => Setting::get('support_email', 'support@drlpharma.com'),
                'support_whatsapp' => Setting::get('support_whatsapp', '+225 07 01 159 572'),
                'website_url' => Setting::get('website_url', config('drpharma.brand.website')),
                'tutorials_url' => Setting::get('tutorials_url', url('/tutoriels')),
                'guide_url' => Setting::get('guide_url', url('/guide')),
                'faq_url' => Setting::get('faq_url', url('/faq')),
                'terms_url' => Setting::get('terms_url', url('/cgu')),
                'privacy_url' => Setting::get('privacy_url', url('/confidentialite')),
            ],
        ]);
    }

    /**
     * Récupère les FAQ pour l'application coursier
     */
    public function courierFaq(): JsonResponse
    {
        $faqs = Setting::get('courier_faqs', $this->defaultCourierFaqs());

        return response()->json([
            'success' => true,
            'data' => $faqs,
        ]);
    }

    /**
     * Récupère les FAQ pour l'application client
     */
    public function customerFaq(): JsonResponse
    {
        $faqs = Setting::get('customer_faqs', $this->defaultCustomerFaqs());

        return response()->json([
            'success' => true,
            'data' => $faqs,
        ]);
    }

    /**
     * FAQ par défaut pour les coursiers
     */
    private function defaultCourierFaqs(): array
    {
        return [
            [
                'question' => 'Comment accepter une livraison ?',
                'answer' => 'Quand une nouvelle livraison est disponible, vous recevez une notification. Allez dans l\'onglet "Livraisons" et appuyez sur "Accepter" pour prendre en charge la commande.',
                'icon' => 'delivery_dining',
            ],
            [
                'question' => 'Comment recharger mon portefeuille ?',
                'answer' => 'Allez dans votre profil > Portefeuille > Recharger. Vous pouvez payer par Mobile Money (Orange Money, MTN, Moov) ou par carte bancaire via JEKO.',
                'icon' => 'account_balance_wallet',
            ],
            [
                'question' => 'Pourquoi je ne peux plus livrer ?',
                'answer' => 'Si votre solde est insuffisant pour couvrir les commissions, vous ne pouvez plus accepter de livraisons. Rechargez votre portefeuille pour continuer.',
                'icon' => 'block',
            ],
            [
                'question' => 'Comment fonctionne la commission ?',
                'answer' => 'Une commission est prélevée sur chaque livraison terminée. Le montant est défini par la plateforme et déduit automatiquement de votre portefeuille.',
                'icon' => 'percent',
            ],
            [
                'question' => 'Comment confirmer une livraison ?',
                'answer' => 'À la livraison, demandez le code de confirmation au client. Entrez ce code à 4 chiffres dans l\'application pour valider la livraison et recevoir votre paiement.',
                'icon' => 'check_circle',
            ],
            [
                'question' => 'Comment mettre à jour ma position GPS ?',
                'answer' => 'Activez la localisation sur votre téléphone. L\'application met à jour votre position automatiquement toutes les 30 secondes quand vous êtes en ligne.',
                'icon' => 'location_on',
            ],
            [
                'question' => 'Comment voir l\'itinéraire vers le client ?',
                'answer' => 'Quand vous avez une livraison en cours, appuyez sur le bouton "Navigation" pour ouvrir Google Maps avec l\'itinéraire vers le client.',
                'icon' => 'map',
            ],
            [
                'question' => 'Comment changer mon mot de passe ?',
                'answer' => 'Allez dans Profil > Paramètres > Changer le mot de passe. Entrez votre mot de passe actuel puis le nouveau mot de passe deux fois.',
                'icon' => 'lock',
            ],
            [
                'question' => 'Que faire si le client est absent ?',
                'answer' => 'Essayez d\'appeler le client. Si après plusieurs tentatives il reste injoignable, contactez le support via les paramètres pour signaler le problème.',
                'icon' => 'person_off',
            ],
            [
                'question' => 'Comment contacter le support ?',
                'answer' => 'Allez dans Paramètres > Aide & Support > Contacter le support. Vous pouvez appeler directement ou envoyer un email.',
                'icon' => 'support_agent',
            ],
        ];
    }

    /**
     * FAQ par défaut pour les clients
     */
    private function defaultCustomerFaqs(): array
    {
        return [
            [
                'question' => 'Comment passer une commande ?',
                'answer' => 'Recherchez une pharmacie proche, ajoutez les produits au panier, puis validez votre commande. Vous pouvez payer en ligne ou à la livraison.',
                'icon' => 'shopping_cart',
            ],
            [
                'question' => 'Comment suivre ma commande ?',
                'answer' => 'Allez dans "Mes commandes" pour voir le statut de votre commande en temps réel et la position du livreur sur la carte.',
                'icon' => 'location_on',
            ],
            [
                'question' => 'Quels sont les modes de paiement ?',
                'answer' => 'Vous pouvez payer par Mobile Money (Orange Money, MTN, Moov), par carte bancaire, ou en espèces à la livraison.',
                'icon' => 'payment',
            ],
            [
                'question' => 'Comment annuler une commande ?',
                'answer' => 'Vous pouvez annuler une commande tant qu\'elle n\'a pas été confirmée par la pharmacie. Allez dans "Mes commandes" et appuyez sur "Annuler".',
                'icon' => 'cancel',
            ],
            [
                'question' => 'Comment contacter le support ?',
                'answer' => 'Allez dans Profil > Aide & Support. Vous pouvez nous contacter par téléphone, email ou WhatsApp.',
                'icon' => 'support_agent',
            ],
        ];
    }
}
