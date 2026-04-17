@extends('layouts.page')

@section('title', 'Centre d\'aide — DR PHARMA')
@section('meta_description', 'Trouvez rapidement des réponses à vos questions sur l\'application DR PHARMA.')
@section('nav_aide', 'active')

@section('styles')
    .content { padding: 64px 0 96px; }
    .content .container { max-width: 800px; }

    .search-box {
    display: flex; align-items: center; gap: 12px;
    background: var(--gray-50); border: 2px solid var(--gray-200);
    border-radius: 16px; padding: 16px 20px; margin-bottom: 48px;
    transition: border-color .2s;
    }
    .search-box:focus-within { border-color: var(--brand-500); }
    .search-box svg { width: 20px; height: 20px; color: var(--gray-400); flex-shrink: 0; }
    .search-box input {
    border: none; background: none; width: 100%; font-size: 16px;
    font-family: inherit; color: var(--gray-800); outline: none;
    }
    .search-box input::placeholder { color: var(--gray-400); }

    .faq-section { margin-bottom: 40px; }
    .faq-section h2 {
    font-size: 20px; font-weight: 800; color: var(--gray-900);
    margin-bottom: 16px; padding-bottom: 8px;
    border-bottom: 2px solid var(--brand-100);
    }

    .faq-item {
    border: 1px solid var(--gray-100); border-radius: 12px;
    margin-bottom: 8px; overflow: hidden;
    }
    .faq-q {
    width: 100%; display: flex; align-items: center;
    justify-content: space-between; padding: 16px 20px;
    font-size: 15px; font-weight: 600; color: var(--gray-800);
    background: none; border: none; cursor: pointer;
    font-family: inherit; text-align: left; gap: 12px;
    transition: background .2s;
    }
    .faq-q:hover { background: var(--gray-50); }
    .faq-q svg {
    width: 18px; height: 18px; flex-shrink: 0;
    color: var(--gray-400); transition: transform .3s;
    }
    .faq-a {
    max-height: 0; overflow: hidden; transition: max-height .3s ease, padding .3s ease;
    font-size: 14px; line-height: 1.7; color: var(--gray-600);
    padding: 0 20px; background: var(--gray-50);
    }
    .faq-a.open { max-height: 300px; padding: 16px 20px; }

    .help-contact {
    text-align: center; padding: 48px 32px;
    background: var(--brand-50); border-radius: 20px;
    margin-top: 32px;
    }
    .help-contact h3 {
    font-size: 20px; font-weight: 800; color: var(--gray-900); margin-bottom: 8px;
    }
    .help-contact p { color: var(--gray-500); margin-bottom: 20px; }
    .help-contact a {
    display: inline-flex; align-items: center; gap: 8px;
    padding: 12px 28px; background: var(--brand-600); color: #fff;
    border-radius: 12px; font-weight: 700; font-size: 15px;
    transition: background .2s;
    }
    .help-contact a:hover { background: var(--brand-700); }
@endsection

@section('content')
    <section class="page-hero">
        <div class="container">
            <h1>Centre d'aide</h1>
            <p>Trouvez rapidement des réponses à vos questions sur DR-PHARMA.</p>
        </div>
    </section>

    <section class="content">
        <div class="container">

            <div class="search-box">
                <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <circle cx="11" cy="11" r="8" />
                    <path stroke-linecap="round" d="M21 21l-4.35-4.35" />
                </svg>
                <input type="text" id="search" placeholder="Rechercher une question…" oninput="filterFAQ(this.value)">
            </div>

            <div class="faq-section" data-section>
                <h2>🛒 Commandes & Livraisons</h2>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">Comment passer une commande ? <svg viewBox="0 0 24 24"
                            fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">Téléchargez l'application DR-PHARMA Patient, créez un compte puis recherchez votre
                        médicament par nom ou envoyez une photo de votre ordonnance. Ajoutez au panier, choisissez votre
                        mode de paiement et validez.</div>
                </div>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">Quel est le délai de livraison ? <svg
                            viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">En moyenne, votre commande est livrée en moins de 45 minutes dans les zones
                        couvertes d'Abidjan. Le temps peut varier selon la distance et la disponibilité des coursiers.</div>
                </div>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">Comment suivre ma livraison ? <svg viewBox="0 0 24 24"
                            fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">Une fois votre commande confirmée, vous pouvez suivre votre coursier en temps réel
                        sur la carte directement dans l'application.</div>
                </div>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">Puis-je annuler une commande ? <svg viewBox="0 0 24 24"
                            fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">Oui, tant que la pharmacie n'a pas encore préparé votre commande. Rendez-vous dans
                        "Mes commandes" et appuyez sur "Annuler".</div>
                </div>
            </div>

            <div class="faq-section" data-section>
                <h2>💳 Paiements</h2>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">Quels moyens de paiement sont acceptés ? <svg
                            viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">Nous acceptons Orange Money, MTN Mobile Money, Moov Money, Wave, les cartes
                        bancaires (Visa/Mastercard) et le paiement à la livraison (cash).</div>
                </div>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">Mon paiement a échoué, que faire ? <svg
                            viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">Vérifiez que votre solde est suffisant et que vous avez une bonne connexion
                        internet. Si le problème persiste, essayez un autre moyen de paiement ou contactez notre support.
                    </div>
                </div>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">Comment obtenir un remboursement ? <svg
                            viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">En cas de problème avec votre commande, contactez notre support. Les remboursements
                        sont traités sous 24 à 48 heures sur votre moyen de paiement d'origine.</div>
                </div>
            </div>

            <div class="faq-section" data-section>
                <h2>👤 Compte & Sécurité</h2>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">Comment créer un compte ? <svg viewBox="0 0 24 24"
                            fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">Téléchargez l'application, appuyez sur "S'inscrire" et suivez les étapes. Vous aurez
                        besoin d'un numéro de téléphone valide pour la vérification par OTP.</div>
                </div>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">J'ai oublié mon mot de passe, comment le
                        réinitialiser ? <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">Sur l'écran de connexion, appuyez sur "Mot de passe oublié ?" et suivez les
                        instructions pour recevoir un code de réinitialisation par SMS.</div>
                </div>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">Mes données sont-elles sécurisées ? <svg
                            viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">Oui. Toutes les communications sont chiffrées (HTTPS/TLS). Vos données personnelles
                        et médicales sont protégées conformément à notre politique de confidentialité.</div>
                </div>
            </div>

            <div class="faq-section" data-section>
                <h2>💊 Pharmaciens & Coursiers</h2>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">Comment devenir pharmacie partenaire ? <svg
                            viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">Contactez-nous via le formulaire de contact ou par email. Un membre de notre équipe
                        vous accompagnera dans l'inscription et la configuration de votre officine sur la plateforme.</div>
                </div>
                <div class="faq-item" data-faq>
                    <button class="faq-q" onclick="toggleFaq(this)">Comment devenir coursier DR-PHARMA ? <svg
                            viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                        </svg></button>
                    <div class="faq-a">Téléchargez l'application DR-PHARMA Coursier et complétez votre inscription avec
                        vos documents (CNI, permis). Votre candidature sera examinée sous 48h.</div>
                </div>
            </div>

            <div class="help-contact">
                <h3>Besoin d'aide supplémentaire ?</h3>
                <p>Notre équipe support est disponible pour vous aider.</p>
                <a href="/contact">
                    <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" width="20"
                        height="20">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                    Contactez-nous
                </a>
            </div>

        </div>
    </section>
@endsection

@section('scripts')
    <script>
        function toggleFaq(btn) {
            var answer = btn.nextElementSibling;
            var chevron = btn.querySelector('svg');
            var isOpen = answer.classList.contains('open');
            document.querySelectorAll('.faq-a').forEach(function(a) {
                a.classList.remove('open');
            });
            document.querySelectorAll('.faq-q svg').forEach(function(c) {
                c.style.transform = '';
            });
            if (!isOpen) {
                answer.classList.add('open');
                chevron.style.transform = 'rotate(180deg)';
            }
        }

        function filterFAQ(query) {
            var q = query.toLowerCase();
            document.querySelectorAll('[data-faq]').forEach(function(item) {
                item.style.display = item.textContent.toLowerCase().includes(q) ? '' : 'none';
            });
            document.querySelectorAll('[data-section]').forEach(function(section) {
                var visible = section.querySelectorAll('[data-faq]:not([style*="display: none"])');
                section.style.display = visible.length ? '' : 'none';
            });
        }
    </script>
@endsection
