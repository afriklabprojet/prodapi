@extends('layouts.page')

@section('title', 'Contact — DR PHARMA')
@section('meta_description', 'Contactez l\'équipe DR PHARMA. Une question, un partenariat ou besoin d\'aide ? Nous vous
    répondons rapidement.')
@section('nav_contact', 'active')

@section('styles')
    /* ── Hero ─────────────────────────────── */
    .contact-hero {
    background: linear-gradient(135deg, var(--brand-50) 0%, #e0f5ec 50%, var(--brand-100) 100%);
    padding: 160px 0 80px;
    text-align: center;
    position: relative;
    overflow: hidden;
    }
    .contact-hero::before {
    content: '';
    position: absolute;
    top: -120px; right: -120px;
    width: 320px; height: 320px;
    background: radial-gradient(circle, rgba(5,150,105,.08), transparent 70%);
    border-radius: 50%;
    }
    .contact-hero::after {
    content: '';
    position: absolute;
    bottom: -80px; left: -80px;
    width: 240px; height: 240px;
    background: radial-gradient(circle, rgba(5,150,105,.06), transparent 70%);
    border-radius: 50%;
    }
    .hero-icon {
    width: 72px; height: 72px;
    background: var(--brand-600);
    border-radius: 20px;
    display: flex; align-items: center; justify-content: center;
    margin: 0 auto 20px;
    box-shadow: 0 12px 32px rgba(5,150,105,.25);
    }
    .hero-icon svg { width: 36px; height: 36px; color: #fff; }
    .contact-hero h1 {
    font-size: clamp(28px, 5vw, 44px);
    font-weight: 900;
    color: var(--gray-900);
    margin-bottom: 12px;
    }
    .contact-hero p {
    font-size: 18px; color: var(--gray-500);
    max-width: 520px; margin: 0 auto;
    line-height: 1.6;
    }

    /* ── Section ──────────────────────────── */
    .contact-content { padding: 64px 0 96px; }
    .contact-content .container { max-width: 1000px; }

    /* ── Cards ────────────────────────────── */
    .contact-cards {
    display: grid; grid-template-columns: 1fr; gap: 20px;
    margin-bottom: 56px;
    }
    @media(min-width:640px) { .contact-cards { grid-template-columns: repeat(2, 1fr); } }
    @media(min-width:900px) { .contact-cards { grid-template-columns: repeat(4, 1fr); } }

    .contact-card {
    background: #fff; border: 1px solid var(--gray-100);
    border-radius: 20px; padding: 32px 24px; text-align: center;
    transition: box-shadow .3s, transform .3s;
    position: relative;
    }
    .contact-card:hover {
    box-shadow: 0 20px 48px rgba(0,0,0,.08);
    transform: translateY(-6px);
    }
    .contact-card .badge {
    position: absolute; top: 16px; right: 16px;
    background: var(--brand-50); color: var(--brand-600);
    font-size: 11px; font-weight: 700; padding: 4px 10px;
    border-radius: 20px; letter-spacing: .3px;
    }
    .contact-icon {
    width: 56px; height: 56px;
    border-radius: 16px;
    display: flex; align-items: center; justify-content: center;
    margin: 0 auto 16px;
    }
    .contact-icon svg { width: 24px; height: 24px; }
    .contact-icon.email { background: #eff6ff; }
    .contact-icon.email svg { color: #3b82f6; }
    .contact-icon.phone { background: #fef3c7; }
    .contact-icon.phone svg { color: #f59e0b; }
    .contact-icon.whatsapp { background: #dcfce7; }
    .contact-icon.whatsapp svg { color: #22c55e; }
    .contact-icon.location { background: #fce4ec; }
    .contact-icon.location svg { color: #ef4444; }

    .contact-card h3 {
    font-size: 16px; font-weight: 700;
    color: var(--gray-900); margin-bottom: 4px;
    }
    .contact-card p {
    font-size: 13px; color: var(--gray-400); margin-bottom: 10px;
    }
    .card-link {
    display: block; font-size: 14px; font-weight: 600;
    transition: color .2s; margin-top: 2px;
    }
    .card-link.blue { color: #3b82f6; }
    .card-link.blue:hover { color: #2563eb; }
    .card-link.amber { color: #f59e0b; }
    .card-link.amber:hover { color: #d97706; }
    .card-link.green { color: #22c55e; }
    .card-link.green:hover { color: #16a34a; }
    .card-link.red { color: #ef4444; }

    /* ── Form ─────────────────────────────── */
    .form-section {
    background: #fff;
    border: 1px solid var(--gray-100);
    border-radius: 28px;
    padding: 48px 40px;
    box-shadow: 0 4px 24px rgba(0,0,0,.04);
    }
    .form-header { text-align: center; margin-bottom: 36px; }
    .form-header h2 {
    font-size: 26px; font-weight: 800;
    color: var(--gray-900); margin-bottom: 8px;
    }
    .form-header p { color: var(--gray-500); font-size: 15px; line-height: 1.6; }

    .form-grid {
    display: grid; grid-template-columns: 1fr; gap: 20px;
    }
    @media(min-width:640px) { .form-grid { grid-template-columns: 1fr 1fr; } }
    .form-group { display: flex; flex-direction: column; gap: 6px; }
    .form-group.full { grid-column: 1 / -1; }
    .form-group label {
    font-size: 13px; font-weight: 600; color: var(--gray-700);
    }
    .form-group input, .form-group select, .form-group textarea {
    padding: 14px 18px;
    border: 2px solid var(--gray-200);
    border-radius: 14px;
    font-family: inherit; font-size: 15px;
    color: var(--gray-800); background: var(--gray-50);
    transition: border-color .2s, background .2s, box-shadow .2s;
    outline: none;
    }
    .form-group input:focus, .form-group select:focus, .form-group textarea:focus {
    border-color: var(--brand-500);
    background: #fff;
    box-shadow: 0 0 0 4px rgba(5,150,105,.1);
    }
    .form-group input::placeholder, .form-group textarea::placeholder {
    color: var(--gray-300);
    }
    .form-group textarea { min-height: 140px; resize: vertical; }
    .form-group .error-text {
    font-size: 12px; color: #ef4444; display: none;
    }
    .form-group.has-error input,
    .form-group.has-error select,
    .form-group.has-error textarea {
    border-color: #ef4444;
    }
    .form-group.has-error .error-text { display: block; }

    .form-submit { grid-column: 1 / -1; text-align: center; padding-top: 12px; }
    .btn-submit {
    display: inline-flex; align-items: center; gap: 10px;
    padding: 16px 40px;
    background: var(--brand-600); color: #fff;
    border: none; border-radius: 16px;
    font-size: 16px; font-weight: 700;
    font-family: inherit; cursor: pointer;
    transition: background .2s, transform .15s, box-shadow .2s;
    box-shadow: 0 4px 16px rgba(5,150,105,.25);
    }
    .btn-submit:hover {
    background: var(--brand-700);
    transform: translateY(-2px);
    box-shadow: 0 8px 24px rgba(5,150,105,.3);
    }
    .btn-submit:active { transform: translateY(0); }
    .btn-submit:disabled {
    opacity: .6; cursor: not-allowed; transform: none;
    }
    .btn-submit svg { width: 18px; height: 18px; }
    .btn-submit .spinner {
    width: 18px; height: 18px;
    border: 2px solid rgba(255,255,255,.3);
    border-top-color: #fff;
    border-radius: 50%;
    animation: spin .6s linear infinite;
    display: none;
    }
    .btn-submit.loading .spinner { display: block; }
    .btn-submit.loading svg:not(.spinner) { display: none; }
    @keyframes spin { to { transform: rotate(360deg); } }

    /* ── Success / Error flash ────────────── */
    .form-result {
    text-align: center; padding: 48px 24px;
    display: none;
    }
    .form-result.show { display: block; }
    .result-icon {
    width: 72px; height: 72px;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    margin: 0 auto 20px;
    }
    .result-icon.success { background: var(--brand-50); }
    .result-icon.success svg { color: var(--brand-600); }
    .result-icon.error { background: #fef2f2; }
    .result-icon.error svg { color: #ef4444; }
    .result-icon svg { width: 36px; height: 36px; }
    .form-result h3 {
    font-size: 22px; font-weight: 800;
    color: var(--gray-900); margin-bottom: 8px;
    }
    .form-result p { color: var(--gray-500); font-size: 15px; line-height: 1.6; }
    .btn-reset {
    display: inline-block; margin-top: 20px;
    padding: 12px 28px;
    background: var(--brand-50); color: var(--brand-600);
    border: none; border-radius: 12px;
    font-size: 14px; font-weight: 600;
    font-family: inherit; cursor: pointer;
    transition: background .2s;
    }
    .btn-reset:hover { background: var(--brand-100); }

    /* ── FAQ section ──────────────────────── */
    .faq-section { margin-top: 64px; }
    .faq-section h2 {
    font-size: 24px; font-weight: 800;
    color: var(--gray-900);
    text-align: center; margin-bottom: 32px;
    }
    .faq-grid { display: grid; grid-template-columns: 1fr; gap: 16px; }
    @media(min-width:768px) { .faq-grid { grid-template-columns: 1fr 1fr; } }
    .faq-item {
    background: var(--gray-50);
    border-radius: 16px; padding: 24px 28px;
    transition: background .2s;
    }
    .faq-item:hover { background: var(--brand-50); }
    .faq-item h4 {
    font-size: 15px; font-weight: 700;
    color: var(--gray-900); margin-bottom: 8px;
    }
    .faq-item p {
    font-size: 14px; color: var(--gray-500);
    line-height: 1.6; margin: 0;
    }

    @media(max-width:640px) {
    .form-section { padding: 32px 20px; border-radius: 20px; }
    }
@endsection

@section('content')
    <!-- HERO -->
    <section class="contact-hero">
        <div class="container">
            <div class="hero-icon">
                <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round"
                        d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
            </div>
            <h1>Comment pouvons-nous vous aider ?</h1>
            <p>Notre équipe est disponible pour répondre à toutes vos questions. Choisissez le canal qui vous convient.</p>
        </div>
    </section>

    <section class="contact-content">
        <div class="container">

            <!-- COORDONNÉES -->
            <div class="contact-cards">
                <!-- Email -->
                <div class="contact-card">
                    <span class="badge">24h</span>
                    <div class="contact-icon email">
                        <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                        </svg>
                    </div>
                    <h3>Email</h3>
                    <p>Réponse sous 24h ouvrées</p>
                    <a href="mailto:contact@drlpharma.com" class="card-link blue">contact@drlpharma.com</a>
                </div>

                <!-- Téléphone -->
                <div class="contact-card">
                    <span class="badge">Lun-Ven</span>
                    <div class="contact-icon phone">
                        <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                        </svg>
                    </div>
                    <h3>Téléphone</h3>
                    <p>Lun — Ven, 8h — 18h</p>
                    <a href="tel:+2250701159572" class="card-link amber">07 01 159 572</a>
                    <a href="tel:+2252722367192" class="card-link amber">27 22 367 192</a>
                </div>

                <!-- WhatsApp -->
                <div class="contact-card">
                    <span class="badge">Rapide</span>
                    <div class="contact-icon whatsapp">
                        <svg viewBox="0 0 24 24" fill="currentColor">
                            <path
                                d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z" />
                        </svg>
                    </div>
                    <h3>WhatsApp</h3>
                    <p>Réponse rapide via chat</p>
                    <a href="https://wa.me/2250701159572" target="_blank" rel="noopener" class="card-link green">Démarrer un
                        chat →</a>
                </div>

                <!-- Adresse -->
                <div class="contact-card">
                    <div class="contact-icon location">
                        <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                    </div>
                    <h3>Siège social</h3>
                    <p>DRL NEGOCE SARL</p>
                    <span class="card-link red" style="cursor:default;">Abidjan, Côte d'Ivoire</span>
                </div>
            </div>

            <!-- FORMULAIRE -->
            <div class="form-section" id="contact-form-section">
                <div class="form-header">
                    <h2>Envoyez-nous un message</h2>
                    <p>Remplissez le formulaire ci-dessous et nous vous répondrons dans les plus brefs délais.</p>
                </div>

                @if (session('success'))
                    <div class="form-result show" id="formSuccess">
                        <div class="result-icon success">
                            <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                            </svg>
                        </div>
                        <h3>Message envoyé !</h3>
                        <p>Merci de nous avoir contacté. Nous vous répondrons dans les meilleurs délais.</p>
                        <button class="btn-reset"
                            onclick="document.getElementById('formSuccess').classList.remove('show'); document.getElementById('contactForm').style.display='';">Envoyer
                            un autre message</button>
                    </div>
                @endif

                @if (session('error'))
                    <div class="form-result show" id="formError">
                        <div class="result-icon error">
                            <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                        </div>
                        <h3>Erreur d'envoi</h3>
                        <p>{{ session('error') }}</p>
                        <button class="btn-reset"
                            onclick="document.getElementById('formError').classList.remove('show'); document.getElementById('contactForm').style.display='';">Réessayer</button>
                    </div>
                @endif

                <form id="contactForm" method="POST" action="{{ route('contact.submit') }}" class="form-grid"
                    @if (session('success')) style="display:none" @endif>
                    @csrf
                    <div class="form-group">
                        <label for="name">Nom complet *</label>
                        <input type="text" id="name" name="name" placeholder="Ex: Kouamé Jean"
                            value="{{ old('name') }}" required>
                        @error('name')
                            <span class="error-text" style="display:block">{{ $message }}</span>
                        @enderror
                    </div>
                    <div class="form-group">
                        <label for="email">Email *</label>
                        <input type="email" id="email" name="email" placeholder="votre@email.com"
                            value="{{ old('email') }}" required>
                        @error('email')
                            <span class="error-text" style="display:block">{{ $message }}</span>
                        @enderror
                    </div>
                    <div class="form-group">
                        <label for="phone">Téléphone</label>
                        <input type="tel" id="phone" name="phone" placeholder="+225 07 XX XX XX XX"
                            value="{{ old('phone') }}">
                    </div>
                    <div class="form-group">
                        <label for="subject">Sujet *</label>
                        <select id="subject" name="subject" required>
                            <option value="">Choisir un sujet…</option>
                            <option value="question" {{ old('subject') === 'question' ? 'selected' : '' }}>Question
                                générale</option>
                            <option value="commande" {{ old('subject') === 'commande' ? 'selected' : '' }}>Problème de
                                commande</option>
                            <option value="paiement" {{ old('subject') === 'paiement' ? 'selected' : '' }}>Problème de
                                paiement</option>
                            <option value="livraison" {{ old('subject') === 'livraison' ? 'selected' : '' }}>Problème de
                                livraison</option>
                            <option value="partenariat" {{ old('subject') === 'partenariat' ? 'selected' : '' }}>Devenir
                                partenaire (Pharmacie)</option>
                            <option value="coursier" {{ old('subject') === 'coursier' ? 'selected' : '' }}>Devenir
                                coursier</option>
                            <option value="bug" {{ old('subject') === 'bug' ? 'selected' : '' }}>Signaler un bug
                            </option>
                            <option value="autre" {{ old('subject') === 'autre' ? 'selected' : '' }}>Autre</option>
                        </select>
                        @error('subject')
                            <span class="error-text" style="display:block">{{ $message }}</span>
                        @enderror
                    </div>
                    <div class="form-group full">
                        <label for="message">Message *</label>
                        <textarea id="message" name="message" placeholder="Décrivez votre demande en détail…" required>{{ old('message') }}</textarea>
                        @error('message')
                            <span class="error-text" style="display:block">{{ $message }}</span>
                        @enderror
                    </div>
                    <div class="form-submit">
                        <button type="submit" class="btn-submit" id="btnSubmit">
                            <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                    d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                            </svg>
                            <span class="spinner"></span>
                            Envoyer le message
                        </button>
                    </div>
                </form>
            </div>

            <!-- FAQ RAPIDE -->
            <div class="faq-section">
                <h2>Questions fréquentes</h2>
                <div class="faq-grid">
                    <div class="faq-item">
                        <h4>Comment passer une commande ?</h4>
                        <p>Téléchargez l'application DR PHARMA, recherchez vos médicaments, ajoutez-les au panier et validez
                            votre commande. Un coursier vous livrera rapidement.</p>
                    </div>
                    <div class="faq-item">
                        <h4>Quels sont les délais de livraison ?</h4>
                        <p>La livraison est effectuée en 30 à 60 minutes en moyenne dans Abidjan. Les délais peuvent varier
                            selon votre localisation.</p>
                    </div>
                    <div class="faq-item">
                        <h4>Comment devenir pharmacie partenaire ?</h4>
                        <p>Remplissez le formulaire ci-dessus avec le sujet « Devenir partenaire » ou contactez-nous
                            directement par téléphone.</p>
                    </div>
                    <div class="faq-item">
                        <h4>Quels moyens de paiement acceptez-vous ?</h4>
                        <p>Nous acceptons Orange Money, MTN MoMo, Wave, Moov Money et le paiement à la livraison (cash).</p>
                    </div>
                </div>
            </div>

        </div>
    </section>
@endsection

@section('scripts')
    <script>
        // Loading state on submit
        document.getElementById('contactForm')?.addEventListener('submit', function() {
            var btn = document.getElementById('btnSubmit');
            btn.classList.add('loading');
            btn.disabled = true;
        });
    </script>
@endsection
