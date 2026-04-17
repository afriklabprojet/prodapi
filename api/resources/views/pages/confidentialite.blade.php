@extends('layouts.page')

@section('title', 'Politique de Confidentialité — DR PHARMA')
@section('meta_description', 'Politique de Confidentialité de l\'application DR PHARMA — DRL NEGOCE SARL.')
@section('nav_confidentialite', 'active')

@section('styles')
    .container-narrow { width: 100%; max-width: 800px; margin: 0 auto; padding: 0 20px; }

    .legal-content { padding: 64px 0 96px; }
    .legal-content h2 {
    font-size: 22px; font-weight: 800; color: var(--gray-900);
    margin: 40px 0 16px; padding-bottom: 8px;
    border-bottom: 2px solid var(--brand-100);
    }
    .legal-content h2:first-child { margin-top: 0; }
    .legal-content p { color: var(--gray-600); margin-bottom: 16px; line-height: 1.8; font-size: 15px; }
    .legal-content ul { margin: 8px 0 16px 24px; list-style: disc; }
    .legal-content ul li { color: var(--gray-600); margin-bottom: 6px; font-size: 15px; line-height: 1.7; }
    .legal-content strong { color: var(--gray-800); }
    .legal-content a { color: var(--brand-600); font-weight: 600; }
    .legal-content a:hover { text-decoration: underline; }

    .info-card {
    background: var(--gray-50); border: 1px solid var(--gray-100);
    border-radius: 16px; padding: 24px; margin-bottom: 16px;
    }
    .info-card p { margin-bottom: 4px; font-size: 14px; }

    .toc {
    background: var(--gray-50); border: 1px solid var(--gray-100);
    border-radius: 16px; padding: 24px; margin-bottom: 40px;
    }
    .toc h4 {
    font-size: 14px; font-weight: 700; text-transform: uppercase;
    letter-spacing: .05em; color: var(--gray-400); margin-bottom: 12px;
    }
    .toc ol { list-style: decimal; margin-left: 20px; }
    .toc li { margin-bottom: 6px; }
    .toc a { font-size: 14px; color: var(--brand-600); font-weight: 500; }
    .toc a:hover { text-decoration: underline; }
@endsection

@section('content')
    <section class="page-hero">
        <div class="container">
            <h1>Politique de Confidentialité</h1>
            <p>Application DR PHARMA</p>
        </div>
    </section>

    <section class="legal-content">
        <div class="container-narrow">

            <div class="toc">
                <h4>Sommaire</h4>
                <ol>
                    <li><a href="#introduction">Introduction</a></li>
                    <li><a href="#collecte">Données collectées</a></li>
                    <li><a href="#utilisation">Utilisation des données</a></li>
                    <li><a href="#partage">Partage des données</a></li>
                    <li><a href="#stockage">Stockage et sécurité</a></li>
                    <li><a href="#droits">Droits des utilisateurs</a></li>
                    <li><a href="#cookies">Cookies et technologies similaires</a></li>
                    <li><a href="#modification">Modification de la politique</a></li>
                    <li><a href="#contact">Contact</a></li>
                </ol>
            </div>

            <h2 id="introduction">1. Introduction</h2>
            <p>DRL NEGOCE SARL, société éditrice de l'application DR PHARMA, s'engage à protéger la vie privée de ses
                utilisateurs.</p>
            <p>La présente Politique de Confidentialité décrit les pratiques relatives à la collecte, l'utilisation et la
                protection des données personnelles.</p>

            <h2 id="collecte">2. Données collectées</h2>
            <p>Dans le cadre de l'utilisation de l'application, les données suivantes peuvent être collectées :</p>
            <ul>
                <li>Nom et prénom</li>
                <li>Numéro de téléphone</li>
                <li>Adresse email</li>
                <li>Adresse de livraison</li>
                <li>Données de localisation (géolocalisation)</li>
                <li>Historique des commandes</li>
                <li>Informations de paiement</li>
            </ul>

            <h2 id="utilisation">3. Utilisation des données</h2>
            <p>Les données sont utilisées pour les finalités suivantes :</p>
            <ul>
                <li>Gestion des commandes et des livraisons</li>
                <li>Communication avec l'utilisateur (suivi de commande, notifications)</li>
                <li>Amélioration des services de l'application</li>
                <li>Prévention de la fraude et sécurité du service</li>
            </ul>

            <h2 id="partage">4. Partage des données</h2>
            <p>Les données personnelles peuvent être partagées avec :</p>
            <ul>
                <li>Les pharmacies partenaires (pour la préparation des commandes)</li>
                <li>Les livreurs partenaires (pour la gestion de la livraison)</li>
                <li>Les prestataires techniques (hébergement, services de paiement)</li>
            </ul>
            <p>Aucune donnée personnelle n'est vendue à des tiers à des fins commerciales.</p>

            <h2 id="stockage">5. Stockage et sécurité</h2>
            <p>DRL NEGOCE SARL met en œuvre les mesures techniques et organisationnelles appropriées pour garantir la
                sécurité et la confidentialité des données collectées.</p>
            <p>Les données sont hébergées sur des serveurs sécurisés et accessibles uniquement au personnel autorisé.</p>

            <h2 id="droits">6. Droits des utilisateurs</h2>
            <p>Conformément à la réglementation applicable, chaque utilisateur dispose des droits suivants :</p>
            <ul>
                <li>Droit d'accès à ses données personnelles</li>
                <li>Droit de rectification en cas d'erreur</li>
                <li>Droit de suppression de son compte et de ses données</li>
                <li>Droit d'opposition au traitement de ses données</li>
            </ul>
            <p>Pour exercer ces droits, l'utilisateur peut contacter DRL NEGOCE SARL à l'adresse ci-dessous.</p>
            <p>L'utilisateur peut également saisir l'ARTCI (Autorité de Régulation des Télécommunications/TIC de Côte
                d'Ivoire) en cas de litige relatif à la gestion de ses données personnelles.</p>

            <h2 id="cookies">7. Cookies et technologies similaires</h2>
            <p>L'application peut utiliser des cookies ou technologies similaires pour :</p>
            <ul>
                <li>améliorer l'expérience utilisateur,</li>
                <li>mesurer l'audience,</li>
                <li>proposer un service personnalisé.</li>
            </ul>
            <p>L'utilisateur peut gérer ses préférences depuis les paramètres de son appareil.</p>

            <h2 id="modification">8. Modification de la politique</h2>
            <p>DRL NEGOCE SARL se réserve le droit de modifier la présente Politique de Confidentialité à tout moment.</p>
            <p>Les utilisateurs seront informés de toute mise à jour via l'application.</p>

            <h2 id="contact">9. Contact</h2>
            <p>Pour toute question relative à la protection de vos données personnelles, vous pouvez nous contacter :</p>
            <div class="info-card">
                <p><strong>Adresse :</strong> COCODY ANGRE terminus 81/82, en face de la banque UBA</p>
                <p><strong>Email :</strong> <a href="mailto:contact@drlpharma.com">contact@drlpharma.com</a></p>
            </div>

        </div>
    </section>
@endsection
