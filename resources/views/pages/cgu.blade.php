@extends('layouts.page')

@section('title', 'Conditions Générales d\'Utilisation — DR PHARMA')
@section('meta_description', 'Conditions Générales d\'Utilisation de l\'application DR PHARMA — DRL NEGOCE SARL.')
@section('nav_cgu', 'active')

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
            <h1>Conditions Générales d'Utilisation</h1>
            <p>Application DR PHARMA</p>
        </div>
    </section>

    <section class="legal-content">
        <div class="container-narrow">

            <div class="toc">
                <h4>Sommaire</h4>
                <ol>
                    <li><a href="#informations">Informations légales</a></li>
                    <li><a href="#objet">Objet de l'application</a></li>
                    <li><a href="#acceptation">Acceptation des conditions</a></li>
                    <li><a href="#acces">Conditions d'accès</a></li>
                    <li><a href="#compte">Création et gestion du compte</a></li>
                    <li><a href="#commande">Commande de médicaments</a></li>
                    <li><a href="#livraison">Livraison</a></li>
                    <li><a href="#prix">Prix et paiement</a></li>
                    <li><a href="#responsabilites">Responsabilités et avertissement médical</a></li>
                    <li><a href="#suspension">Suspension ou suppression de compte</a></li>
                    <li><a href="#disponibilite">Disponibilité du service</a></li>
                    <li><a href="#modification">Modification des conditions</a></li>
                    <li><a href="#droit">Droit applicable et juridiction</a></li>
                </ol>
            </div>

            <h2 id="informations">1. Informations légales</h2>
            <p>L'application DR PHARMA est éditée par :</p>
            <div class="info-card">
                <p><strong>Raison sociale :</strong> DRL NEGOCE SARL</p>
                <p><strong>Forme juridique :</strong> Société à Responsabilité Limitée (SARL)</p>
                <p><strong>RCCM :</strong> CI-ABJ-03-2018-B13-33505</p>
                <p><strong>Siège social :</strong> COCODY ANGRE terminus 81/82, en face de la banque UBA – Abidjan, Côte
                    d'Ivoire</p>
                <p><strong>Email de contact :</strong> <a href="mailto:contact@drlpharma.com">contact@drlpharma.com</a></p>
            </div>

            <h2 id="objet">2. Objet de l'application</h2>
            <p>DR PHARMA est une application mobile permettant aux utilisateurs de :</p>
            <ul>
                <li>commander des médicaments depuis leur domicile,</li>
                <li>auprès de pharmacies partenaires légalement agréées à Abidjan,</li>
                <li>et de se faire livrer par des livreurs partenaires.</li>
            </ul>
            <p>DRL NEGOCE SARL agit exclusivement en tant qu'intermédiaire technologique et ne vend pas directement de
                médicaments.</p>

            <h2 id="acceptation">3. Acceptation des conditions</h2>
            <p>Toute utilisation de l'application implique l'acceptation pleine et entière des présentes Conditions
                Générales d'Utilisation.</p>
            <p>En cas de désaccord, l'utilisateur doit cesser immédiatement l'utilisation de l'application.</p>

            <h2 id="acces">4. Conditions d'accès</h2>
            <p>L'application est accessible :</p>
            <ul>
                <li>aux personnes âgées d'au moins 18 ans,</li>
                <li>disposant de la capacité juridique,</li>
                <li>résidant en République de Côte d'Ivoire.</li>
            </ul>
            <p>La création d'un compte utilisateur est nécessaire pour accéder aux services.</p>

            <h2 id="compte">5. Création et gestion du compte</h2>
            <p>L'utilisateur s'engage à :</p>
            <ul>
                <li>fournir des informations exactes, complètes et à jour,</li>
                <li>préserver la confidentialité de ses identifiants,</li>
                <li>informer DR PHARMA de toute utilisation non autorisée.</li>
            </ul>
            <p>L'utilisateur est seul responsable de l'utilisation de son compte.</p>

            <h2 id="commande">6. Commande de médicaments</h2>
            <ul>
                <li>Les médicaments proposés proviennent exclusivement de pharmacies partenaires agréées.</li>
                <li>Certains médicaments sont délivrés uniquement sur présentation d'une ordonnance médicale valide.</li>
                <li>DRL NEGOCE SARL se réserve le droit de refuser toute commande non conforme à la réglementation
                    pharmaceutique en vigueur.</li>
            </ul>

            <h2 id="livraison">7. Livraison</h2>
            <ul>
                <li>La livraison est assurée par des livreurs partenaires indépendants.</li>
                <li>Les délais indiqués sont estimatifs et peuvent varier selon la disponibilité, la circulation ou des cas
                    de force majeure.</li>
                <li>DRL NEGOCE SARL ne peut être tenue responsable des retards indépendants de sa volonté.</li>
            </ul>

            <h2 id="prix">8. Prix et paiement</h2>
            <ul>
                <li>Les prix des médicaments sont fixés par les pharmacies partenaires.</li>
                <li>Les frais de livraison sont clairement indiqués avant validation de la commande.</li>
                <li>Le paiement est effectué via les moyens proposés sur l'application.</li>
            </ul>

            <h2 id="responsabilites">9. Responsabilités et avertissement médical</h2>
            <ul>
                <li>DR PHARMA ne fournit aucun conseil médical.</li>
                <li>DRL NEGOCE SARL ne peut être tenue responsable d'une mauvaise utilisation des médicaments ou de
                    l'automédication.</li>
                <li>L'utilisateur est invité à consulter un professionnel de santé avant toute prise de médicament.</li>
            </ul>

            <h2 id="suspension">10. Suspension ou suppression de compte</h2>
            <p>DRL NEGOCE SARL se réserve le droit de suspendre ou supprimer un compte en cas :</p>
            <ul>
                <li>de violation des présentes CGU,</li>
                <li>de fraude ou tentative de fraude,</li>
                <li>de comportement contraire aux lois en vigueur.</li>
            </ul>

            <h2 id="disponibilite">11. Disponibilité du service</h2>
            <p>DR PHARMA peut être temporairement indisponible pour maintenance, mise à jour ou en cas de problème
                technique.</p>
            <p>Aucune indemnisation ne pourra être exigée à ce titre.</p>

            <h2 id="modification">12. Modification des conditions</h2>
            <p>DRL NEGOCE SARL se réserve le droit de modifier les présentes CGU à tout moment.</p>
            <p>Les utilisateurs seront informés via l'application.</p>

            <h2 id="droit">13. Droit applicable et juridiction</h2>
            <p>Les présentes CGU sont régies par les lois en vigueur en République de Côte d'Ivoire.</p>
            <p>Tout litige relève des juridictions compétentes ivoiriennes.</p>

        </div>
    </section>
@endsection
