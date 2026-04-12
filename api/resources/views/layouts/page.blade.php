<!DOCTYPE html>
<html lang="fr">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="@yield('meta_description', 'DR PHARMA — La plateforme santé digitale N°1 en Côte d\'Ivoire.')">
    <title>@yield('title', 'DR PHARMA')</title>

    <!-- Open Graph / WhatsApp -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="{{ url()->current() }}">
    <meta property="og:title" content="@yield('title', 'DR PHARMA')">
    <meta property="og:description" content="@yield('meta_description', 'DR PHARMA — La plateforme santé digitale N°1 en Côte d\'Ivoire.')">
    <meta property="og:image" content="{{ asset('images/og-image.png') }}">
    <meta property="og:locale" content="fr_CI">

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="@yield('title', 'DR PHARMA')">
    <meta name="twitter:description" content="@yield('meta_description', 'DR PHARMA — La plateforme santé digitale N°1 en Côte d\'Ivoire.')">

    <!-- Canonical -->
    <link rel="canonical" href="{{ url()->current() }}">

    <!-- Favicon -->
    <link rel="icon" type="image/png" sizes="32x32" href="{{ asset('favicon.png') }}">
    <link rel="apple-touch-icon" sizes="180x180" href="{{ asset('apple-touch-icon.png') }}">

    <!-- CSRF -->
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link
        href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800;900&display=swap"
        rel="stylesheet">
    <style>
        /* ============================================ */
        /* RESET & BASE                                 */
        /* ============================================ */
        *,
        *::before,
        *::after {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        html {
            scroll-behavior: smooth;
            -webkit-text-size-adjust: 100%;
        }

        body {
            font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            color: #1f2937;
            background: #fff;
            overflow-x: hidden;
            line-height: 1.6;
            -webkit-font-smoothing: antialiased;
        }

        img {
            max-width: 100%;
            display: block;
        }

        a {
            text-decoration: none;
            color: inherit;
        }

        ul {
            list-style: none;
        }

        button {
            border: none;
            background: none;
            cursor: pointer;
            font: inherit;
        }

        /* ============================================ */
        /* VARIABLES                                    */
        /* ============================================ */
        :root {
            --brand-50: #ecfdf5;
            --brand-100: #d1fae5;
            --brand-200: #a7f3d0;
            --brand-300: #6ee7b7;
            --brand-400: #34d399;
            --brand-500: #10b981;
            --brand-600: #059669;
            --brand-700: #047857;
            --brand-800: #065f46;
            --brand-900: #064e3b;
            --brand-950: #022c22;
            --gray-50: #f9fafb;
            --gray-100: #f3f4f6;
            --gray-200: #e5e7eb;
            --gray-300: #d1d5db;
            --gray-400: #9ca3af;
            --gray-500: #6b7280;
            --gray-600: #4b5563;
            --gray-700: #374151;
            --gray-800: #1f2937;
            --gray-900: #111827;
            --gray-950: #030712;
            --radius-lg: 12px;
            --radius-xl: 16px;
            --radius-2xl: 20px;
            --radius-3xl: 24px;
            --radius-full: 9999px;
            --shadow-sm: 0 1px 2px rgba(0, 0, 0, .05);
            --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, .1), 0 2px 4px -2px rgba(0, 0, 0, .1);
            --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, .1), 0 4px 6px -4px rgba(0, 0, 0, .1);
            --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, .1), 0 8px 10px -6px rgba(0, 0, 0, .1);
        }

        /* ============================================ */
        /* UTILITY                                      */
        /* ============================================ */
        .container {
            width: 100%;
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
        }

        @media(min-width:640px) {
            .container {
                padding: 0 24px;
            }
        }

        @media(min-width:1024px) {
            .container {
                padding: 0 32px;
            }
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 14px 28px;
            border-radius: var(--radius-2xl);
            font-weight: 700;
            font-size: 15px;
            transition: all .3s ease;
            cursor: pointer;
            border: none;
        }

        .btn-primary {
            background: var(--brand-600);
            color: #fff;
            box-shadow: 0 8px 20px rgba(5, 150, 105, .25);
        }

        .btn-primary:hover {
            background: var(--brand-700);
            transform: translateY(-2px);
            box-shadow: 0 12px 30px rgba(5, 150, 105, .35);
        }

        /* ============================================ */
        /* SCROLLBAR                                    */
        /* ============================================ */
        ::-webkit-scrollbar {
            width: 6px;
        }

        ::-webkit-scrollbar-track {
            background: var(--gray-100);
        }

        ::-webkit-scrollbar-thumb {
            background: var(--brand-600);
            border-radius: 3px;
        }

        /* ============================================ */
        /* NAVBAR                                       */
        /* ============================================ */
        .navbar {
            position: fixed;
            top: 0;
            width: 100%;
            z-index: 100;
            transition: all .4s ease;
        }

        .navbar.scrolled {
            background: rgba(255, 255, 255, .85);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            box-shadow: 0 4px 30px rgba(0, 0, 0, .06);
        }

        .navbar-inner {
            display: flex;
            align-items: center;
            justify-content: space-between;
            height: 80px;
        }

        .navbar-logo {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .navbar-logo-icon {
            width: 44px;
            height: 44px;
            background: var(--brand-600);
            border-radius: var(--radius-xl);
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 4px 14px rgba(5, 150, 105, .3);
            transition: transform .3s;
        }

        .navbar-logo:hover .navbar-logo-icon {
            transform: scale(1.1);
        }

        .navbar-logo-icon svg {
            width: 24px;
            height: 24px;
            color: #fff;
        }

        .navbar-brand {
            font-size: 20px;
            font-weight: 800;
            letter-spacing: -.02em;
        }

        .navbar-brand span:first-child {
            color: var(--brand-700);
        }

        .navbar-brand span:nth-child(2) {
            color: var(--gray-400);
        }

        .navbar-brand span:last-child {
            color: var(--gray-700);
        }

        .nav-links {
            display: none;
            align-items: center;
            gap: 4px;
        }

        .nav-link {
            padding: 8px 16px;
            font-size: 14px;
            font-weight: 500;
            color: var(--gray-600);
            border-radius: 8px;
            transition: all .2s;
        }

        .nav-link:hover {
            color: var(--brand-600);
            background: var(--brand-50);
        }

        .nav-link.active {
            color: var(--brand-700);
            background: var(--brand-100);
            font-weight: 700;
        }

        .nav-cta {
            display: none;
        }

        .nav-cta .btn {
            padding: 10px 24px;
            font-size: 14px;
        }

        @media(min-width:768px) {

            .nav-links,
            .nav-cta {
                display: flex;
                align-items: center;
            }

            .hamburger {
                display: none !important;
            }
        }

        /* Hamburger */
        .hamburger {
            width: 40px;
            height: 40px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 5px;
            border-radius: 8px;
            transition: background .2s;
        }

        .hamburger:hover {
            background: var(--gray-100);
        }

        .hamburger span {
            display: block;
            height: 2px;
            background: var(--gray-700);
            border-radius: 2px;
            transition: all .3s ease;
        }

        .hamburger span:nth-child(1) {
            width: 24px;
        }

        .hamburger span:nth-child(2) {
            width: 24px;
        }

        .hamburger span:nth-child(3) {
            width: 16px;
        }

        .hamburger.open span:nth-child(1) {
            transform: rotate(45deg) translate(4px, 5px);
        }

        .hamburger.open span:nth-child(2) {
            opacity: 0;
        }

        .hamburger.open span:nth-child(3) {
            width: 24px;
            transform: rotate(-45deg) translate(4px, -5px);
        }

        /* Mobile menu */
        .mobile-menu {
            position: fixed;
            inset: 80px 0 0 0;
            background: rgba(255, 255, 255, .97);
            backdrop-filter: blur(20px);
            z-index: 90;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 40px 24px;
            transform: translateX(100%);
            transition: transform .35s ease;
        }

        .mobile-menu.open {
            transform: translateX(0);
        }

        .mobile-menu a {
            width: 100%;
            text-align: center;
            padding: 18px 0;
            font-size: 18px;
            font-weight: 500;
            color: var(--gray-700);
            border-bottom: 1px solid var(--gray-100);
            transition: color .2s;
        }

        .mobile-menu a:hover,
        .mobile-menu a.active {
            color: var(--brand-600);
        }

        .mobile-menu a.active {
            font-weight: 700;
            background: var(--brand-50);
            border-radius: 12px;
        }

        .mobile-menu .btn {
            margin-top: 24px;
            width: 100%;
            justify-content: center;
            font-size: 18px;
        }

        @media(min-width:768px) {
            .mobile-menu {
                display: none;
            }
        }


        /* ============================================ */
        /* PAGE HERO                                    */
        /* ============================================ */
        .page-hero {
            background: linear-gradient(135deg, var(--brand-50), var(--brand-100));
            padding: 180px 0 60px;
            text-align: center;
        }

        .page-hero h1 {
            font-size: clamp(28px, 5vw, 42px);
            font-weight: 900;
            color: var(--gray-900);
            margin-bottom: 12px;
        }

        .page-hero p {
            font-size: 18px;
            color: var(--gray-500);
            max-width: 560px;
            margin: 0 auto;
        }

        /* ============================================ */
        /* FOOTER                                       */
        /* ============================================ */
        .footer {
            background: var(--gray-950);
            color: var(--gray-400);
            padding: 80px 0 32px;
        }

        .footer-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 48px;
            margin-bottom: 64px;
        }

        @media(min-width:768px) {
            .footer-grid {
                grid-template-columns: 2fr 1fr 1fr 1fr;
            }
        }

        .footer-brand {
            grid-column: 1 / -1;
        }

        @media(min-width:768px) {
            .footer-brand {
                grid-column: auto;
            }
        }

        .footer-logo {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 24px;
        }

        .footer-logo-icon {
            width: 40px;
            height: 40px;
            background: var(--brand-600);
            border-radius: var(--radius-xl);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .footer-logo-icon svg {
            width: 20px;
            height: 20px;
            color: #fff;
        }

        .footer-logo span {
            font-size: 18px;
            font-weight: 700;
            color: #fff;
        }

        .footer-brand>p {
            font-size: 14px;
            line-height: 1.7;
            margin-bottom: 24px;
        }

        .social-links {
            display: flex;
            gap: 12px;
        }

        .social-link {
            width: 40px;
            height: 40px;
            background: var(--gray-800);
            border-radius: var(--radius-xl);
            display: flex;
            align-items: center;
            justify-content: center;
            transition: background .2s;
        }

        .social-link:hover {
            background: var(--brand-600);
        }

        .social-link svg {
            width: 20px;
            height: 20px;
            fill: currentColor;
            color: var(--gray-400);
        }

        .social-link:hover svg {
            color: #fff;
        }

        .footer-col h4 {
            font-size: 13px;
            font-weight: 700;
            color: #fff;
            text-transform: uppercase;
            letter-spacing: .05em;
            margin-bottom: 24px;
        }

        .footer-col ul {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .footer-col a {
            font-size: 14px;
            transition: color .2s;
        }

        .footer-col a:hover {
            color: var(--brand-400);
        }

        .footer-contact {
            border-top: 1px solid rgba(255, 255, 255, .08);
            padding-top: 32px;
            margin-bottom: 32px;
            display: flex;
            flex-wrap: wrap;
            justify-content: center;
            gap: 24px;
            font-size: 14px;
        }

        .footer-contact a,
        .footer-contact span {
            display: flex;
            align-items: center;
            gap: 8px;
            transition: color .2s;
        }

        .footer-contact a:hover {
            color: var(--brand-400);
        }

        .footer-contact svg {
            width: 16px;
            height: 16px;
        }

        .footer-bottom {
            border-top: 1px solid rgba(255, 255, 255, .08);
            padding-top: 32px;
            text-align: center;
            font-size: 12px;
            color: var(--gray-500);
        }

        /* ============================================ */
        /* PAGE-SPECIFIC STYLES                         */
        /* ============================================ */
        @yield('styles')
    </style>
</head>

<body>

    <!-- NAVBAR -->
    <nav class="navbar" id="navbar">
        <div class="container">
            <div class="navbar-inner">
                <a href="/" class="navbar-logo">
                    <div class="navbar-logo-icon">
                        <img src="{{ asset('images/logo.png') }}" alt="DR-PHARMA" width="32" height="32"
                            style="border-radius: 8px;">
                    </div>
                    <div class="navbar-brand"><span>DR</span><span>-</span><span>PHARMA</span></div>
                </a>

                <div class="nav-links">
                    <a href="/#fonctionnalites" class="nav-link">Fonctionnalités</a>
                    <a href="/#comment-ca-marche" class="nav-link">Comment ça marche</a>
                    <a href="/#applications" class="nav-link">Applications</a>
                    <a href="/#temoignages" class="nav-link">Témoignages</a>
                    <a href="/#faq" class="nav-link">FAQ</a>
                    <a href="/contact" class="nav-link">Contact</a>
                </div>

                <div class="nav-cta">
                    <a href="/#telecharger" class="btn btn-primary">Télécharger</a>
                </div>

                <button class="hamburger" id="hamburger" aria-label="Menu">
                    <span></span><span></span><span></span>
                </button>
            </div>
        </div>

        <div class="mobile-menu" id="mobile-menu">
            <a href="/#fonctionnalites" class="mobile-link">Fonctionnalités</a>
            <a href="/#comment-ca-marche" class="mobile-link">Comment ça marche</a>
            <a href="/#applications" class="mobile-link">Applications</a>
            <a href="/#temoignages" class="mobile-link">Témoignages</a>
            <a href="/#faq" class="mobile-link">FAQ</a>
            <a href="/contact" class="mobile-link">Contact</a>
            <a href="/#telecharger" class="btn btn-primary">Télécharger l'app</a>
        </div>
    </nav>

    @yield('content')

    <!-- FOOTER -->
    <footer class="footer">
        <div class="container">
            <div class="footer-grid">
                <div class="footer-brand">
                    <div class="footer-logo">
                        <div class="footer-logo-icon">
                            <img src="{{ asset('images/logo.png') }}" alt="DR-PHARMA" width="24" height="24"
                                style="border-radius: 6px;">
                        </div>
                        <span>DR-PHARMA</span>
                    </div>
                    <p>{{ \App\Models\Setting::get('landing_footer_description', 'La plateforme santé digitale N°1 en Côte d\'Ivoire.') }}
                    </p>
                    <div class="social-links">
                        <a href="{{ \App\Models\Setting::get('landing_footer_facebook_url', '#') }}"
                            class="social-link" aria-label="Facebook"><svg viewBox="0 0 24 24">
                                <path
                                    d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
                            </svg></a>
                    </div>
                </div>

                <div class="footer-col">
                    <h4>Produits</h4>
                    <ul>
                        <li><a href="/#applications">App Patient</a></li>
                        <li><a href="/#applications">App Pharmacien</a></li>
                        <li><a href="/#applications">App Coursier</a></li>
                    </ul>
                </div>

                <div class="footer-col">
                    <h4>Entreprise</h4>
                    <ul>
                        <li><a href="/aide">À propos</a></li>
                        <li><a href="/contact">Nous contacter</a></li>
                    </ul>
                </div>

                <div class="footer-col">
                    <h4>Support</h4>
                    <ul>
                        <li><a href="/aide">Centre d'aide</a></li>
                        <li><a href="/guide">Guide d'utilisation</a></li>
                        <li><a href="/faq">FAQ</a></li>
                        <li><a href="/tutoriels">Tutoriels vidéo</a></li>
                        <li><a href="/contact">Contact</a></li>
                        <li><a href="/confidentialite">Confidentialité</a></li>
                        <li><a href="/cgu">CGU</a></li>
                    </ul>
                </div>
            </div>

            <div class="footer-contact">
                <a href="mailto:{{ \App\Models\Setting::get('landing_footer_email', 'contact@drlpharma.com') }}">
                    <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                    {{ \App\Models\Setting::get('landing_footer_email', 'contact@drlpharma.com') }}
                </a>
                <a
                    href="tel:{{ str_replace(' ', '', \App\Models\Setting::get('landing_footer_phone', '+225 07 01 159 572')) }}">
                    <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                    </svg>
                    {{ \App\Models\Setting::get('landing_footer_phone', '+225 07 01 159 572') }}
                </a>
                <span>
                    <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    {{ \App\Models\Setting::get('landing_footer_address', 'Abidjan, Côte d\'Ivoire') }}
                </span>
            </div>

            <div class="footer-bottom">
                {{ \App\Models\Setting::get('landing_footer_copyright', '© ' . date('Y') . ' DR-PHARMA. Tous droits réservés. Fait en Côte d\'Ivoire') }}
            </div>
        </div>
    </footer>

    <!-- JAVASCRIPT -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {

            // Navbar — toujours scrolled sur les sous-pages
            var navbar = document.getElementById('navbar');
            navbar.classList.add('scrolled');
            window.addEventListener('scroll', function() {
                if (window.pageYOffset > 50) {
                    navbar.classList.add('scrolled');
                } else {
                    navbar.classList.add('scrolled');
                }
            });

            // Mobile menu
            var hamburger = document.getElementById('hamburger');
            var mobileMenu = document.getElementById('mobile-menu');
            hamburger.addEventListener('click', function() {
                hamburger.classList.toggle('open');
                mobileMenu.classList.toggle('open');
                document.body.style.overflow = mobileMenu.classList.contains('open') ? 'hidden' : '';
            });
            document.querySelectorAll('.mobile-link').forEach(function(link) {
                link.addEventListener('click', function() {
                    hamburger.classList.remove('open');
                    mobileMenu.classList.remove('open');
                    document.body.style.overflow = '';
                });
            });
        });
    </script>
    @yield('scripts')
</body>

</html>
