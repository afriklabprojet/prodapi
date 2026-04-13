<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="{{ $landing['seo_description'] }}">
    <title>{{ $landing['seo_title'] }}</title>

    <!-- Open Graph -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="{{ url('/') }}">
    <meta property="og:title" content="{{ $landing['seo_title'] }}">
    <meta property="og:description" content="{{ $landing['seo_description'] }}">
    <meta property="og:image" content="{{ asset('images/og-image.png') }}">
    <meta property="og:locale" content="fr_CI">
    <meta property="og:site_name" content="DR-PHARMA">

    <!-- Twitter -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{{ $landing['seo_title'] }}">
    <meta name="twitter:description" content="{{ $landing['seo_description'] }}">
    <meta name="twitter:image" content="{{ asset('images/og-image.png') }}">

    <link rel="canonical" href="{{ url('/') }}">
    <link rel="icon" type="image/png" sizes="32x32" href="{{ asset('favicon.png') }}">
    <link rel="apple-touch-icon" sizes="180x180" href="{{ asset('apple-touch-icon.png') }}">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

    <style>
    /* ============================================ */
    /* RESET                                        */
    /* ============================================ */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html { scroll-behavior: smooth; -webkit-text-size-adjust: 100%; }
    body {
        font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        color: #1a1a2e;
        background: #fafbfc;
        overflow-x: hidden;
        line-height: 1.6;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
    }
    img { max-width: 100%; display: block; }
    a { text-decoration: none; color: inherit; }
    ul { list-style: none; }
    button { border: none; background: none; cursor: pointer; font: inherit; }

    /* ============================================ */
    /* DESIGN TOKENS                                */
    /* ============================================ */
    :root {
        /* Brand — Emerald */
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

        /* Navy depth */
        --navy-800: #0f172a;
        --navy-900: #0a0f1e;
        --navy-950: #060a14;

        /* Neutrals */
        --gray-50: #f8fafc;
        --gray-100: #f1f5f9;
        --gray-200: #e2e8f0;
        --gray-300: #cbd5e1;
        --gray-400: #94a3b8;
        --gray-500: #64748b;
        --gray-600: #475569;
        --gray-700: #334155;
        --gray-800: #1e293b;
        --gray-900: #0f172a;

        /* Accents */
        --blue-500: #3b82f6;
        --blue-600: #2563eb;
        --amber-400: #fbbf24;
        --amber-500: #f59e0b;
        --purple-500: #a855f7;
        --rose-500: #f43f5e;
        --cyan-500: #06b6d4;

        /* Spacing */
        --section-y: clamp(80px, 10vw, 120px);

        /* Radius */
        --r-sm: 8px;
        --r-md: 12px;
        --r-lg: 16px;
        --r-xl: 20px;
        --r-2xl: 24px;
        --r-full: 9999px;

        /* Shadows */
        --shadow-sm: 0 1px 2px rgba(0,0,0,.05);
        --shadow-md: 0 4px 12px rgba(0,0,0,.08);
        --shadow-lg: 0 8px 30px rgba(0,0,0,.1);
        --shadow-xl: 0 20px 40px rgba(0,0,0,.12);
        --shadow-brand: 0 8px 30px rgba(5,150,105,.2);
        --shadow-glow: 0 0 60px rgba(16,185,129,.15);
    }

    /* ============================================ */
    /* LAYOUT                                       */
    /* ============================================ */
    .container {
        width: 100%;
        max-width: 1200px;
        margin: 0 auto;
        padding: 0 20px;
    }
    @media (min-width: 640px) { .container { padding: 0 24px; } }
    @media (min-width: 1024px) { .container { padding: 0 32px; } }

    .section { padding: var(--section-y) 0; }

    /* ============================================ */
    /* TYPOGRAPHY                                   */
    /* ============================================ */
    .section-header { text-align: center; margin-bottom: 56px; }
    .badge {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 6px 16px 6px 12px;
        border-radius: var(--r-full);
        background: var(--brand-50);
        color: var(--brand-700);
        font-size: 12px;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.08em;
        border: 1px solid var(--brand-200);
        margin-bottom: 20px;
    }
    .badge-dot {
        width: 6px; height: 6px;
        background: var(--brand-500);
        border-radius: 50%;
        box-shadow: 0 0 8px var(--brand-400);
        animation: pulse-dot 2s ease-in-out infinite;
    }
    .section-title {
        font-size: clamp(28px, 5vw, 48px);
        font-weight: 800;
        line-height: 1.12;
        letter-spacing: -0.03em;
        color: var(--gray-900);
    }
    .section-title .highlight {
        background: linear-gradient(135deg, var(--brand-600), var(--brand-400));
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
    }
    .section-subtitle {
        margin-top: 16px;
        font-size: 17px;
        color: var(--gray-500);
        max-width: 560px;
        margin-left: auto;
        margin-right: auto;
        line-height: 1.7;
    }

    /* ============================================ */
    /* BUTTONS                                      */
    /* ============================================ */
    .btn {
        display: inline-flex; align-items: center; gap: 10px;
        padding: 14px 28px;
        border-radius: var(--r-xl);
        font-weight: 700; font-size: 15px;
        transition: all .3s cubic-bezier(.4,0,.2,1);
        cursor: pointer; border: none;
        position: relative; overflow: hidden;
    }
    .btn svg { width: 18px; height: 18px; flex-shrink: 0; }
    .btn-brand {
        background: linear-gradient(135deg, var(--brand-600), var(--brand-500));
        color: #fff;
        box-shadow: var(--shadow-brand);
    }
    .btn-brand:hover {
        transform: translateY(-2px);
        box-shadow: 0 12px 35px rgba(5,150,105,.3);
    }
    .btn-dark {
        background: var(--navy-800);
        color: #fff;
        box-shadow: var(--shadow-lg);
    }
    .btn-dark:hover {
        background: var(--gray-800);
        transform: translateY(-2px);
    }
    .btn-outline {
        background: transparent;
        color: var(--gray-700);
        border: 2px solid var(--gray-200);
    }
    .btn-outline:hover {
        border-color: var(--brand-500);
        color: var(--brand-600);
        transform: translateY(-2px);
    }
    .btn-glass {
        background: rgba(255,255,255,.1);
        color: #fff;
        border: 1px solid rgba(255,255,255,.2);
        backdrop-filter: blur(12px);
    }
    .btn-glass:hover {
        background: rgba(255,255,255,.2);
        transform: translateY(-2px);
    }

    /* ============================================ */
    /* ANIMATIONS                                   */
    /* ============================================ */
    @keyframes pulse-dot {
        0%, 100% { opacity: 1; transform: scale(1); }
        50% { opacity: .5; transform: scale(1.4); }
    }
    @keyframes float-slow {
        0%, 100% { transform: translateY(0); }
        50% { transform: translateY(-16px); }
    }
    @keyframes gradient-flow {
        0% { background-position: 0% 50%; }
        50% { background-position: 100% 50%; }
        100% { background-position: 0% 50%; }
    }
    @keyframes fade-up {
        from { opacity: 0; transform: translateY(32px); }
        to { opacity: 1; transform: translateY(0); }
    }
    @keyframes slide-in-right {
        from { opacity: 0; transform: translateX(40px); }
        to { opacity: 1; transform: translateX(0); }
    }
    @keyframes count-in {
        from { opacity: 0; transform: scale(.8); }
        to { opacity: 1; transform: scale(1); }
    }
    .reveal {
        opacity: 0;
        transform: translateY(32px);
        transition: all .7s cubic-bezier(.25,.46,.45,.94);
    }
    .reveal.active {
        opacity: 1;
        transform: translateY(0);
    }

    /* ============================================ */
    /* SCROLLBAR                                    */
    /* ============================================ */
    ::-webkit-scrollbar { width: 5px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: var(--brand-500); border-radius: 3px; }

    /* ============================================ */
    /* NAVBAR                                       */
    /* ============================================ */
    .navbar {
        position: fixed; top: 0; width: 100%; z-index: 100;
        transition: all .4s cubic-bezier(.4,0,.2,1);
        padding: 10px 0;
    }
    .navbar.scrolled {
        background: rgba(255,255,255,.88);
        backdrop-filter: blur(20px) saturate(180%);
        -webkit-backdrop-filter: blur(20px) saturate(180%);
        box-shadow: 0 1px 0 rgba(0,0,0,.05), 0 4px 24px rgba(0,0,0,.04);
        padding: 4px 0;
    }
    .navbar-inner {
        display: flex; align-items: center; justify-content: space-between;
        height: 64px;
    }
    .navbar-logo {
        display: flex; align-items: center; gap: 10px;
        transition: transform .3s;
    }
    .navbar-logo:hover { transform: scale(1.02); }
    .navbar-logo-icon {
        width: 40px; height: 40px;
        border-radius: var(--r-md);
        overflow: hidden;
        box-shadow: var(--shadow-sm);
    }
    .navbar-logo-icon img { width: 100%; height: 100%; object-fit: contain; }
    .navbar-brand {
        font-size: 19px; font-weight: 800; letter-spacing: -.02em;
    }
    .navbar-brand .dr { color: var(--gray-900); }
    .navbar-brand .sep { color: var(--gray-300); }
    .navbar-brand .pharma { color: var(--brand-600); }

    .nav-links {
        display: none; align-items: center; gap: 2px;
    }
    .nav-link {
        padding: 8px 14px; font-size: 14px; font-weight: 500;
        color: var(--gray-600); border-radius: var(--r-sm);
        transition: all .2s;
    }
    .nav-link:hover { color: var(--brand-600); background: var(--brand-50); }

    .nav-cta { display: none; }

    .hamburger {
        display: flex; flex-direction: column; gap: 5px;
        padding: 8px; border-radius: var(--r-sm);
        transition: background .2s;
    }
    .hamburger:hover { background: var(--gray-100); }
    .hamburger span {
        width: 22px; height: 2px;
        background: var(--gray-700); border-radius: 2px;
        transition: all .3s;
    }
    .hamburger.active span:nth-child(1) { transform: rotate(45deg) translate(5px, 5px); }
    .hamburger.active span:nth-child(2) { opacity: 0; }
    .hamburger.active span:nth-child(3) { transform: rotate(-45deg) translate(5px, -5px); }

    .mobile-menu {
        display: none; position: fixed; top: 76px; left: 0; right: 0;
        background: rgba(255,255,255,.97);
        backdrop-filter: blur(20px);
        padding: 16px 20px 24px;
        border-bottom: 1px solid var(--gray-200);
        z-index: 99;
    }
    .mobile-menu.open { display: flex; flex-direction: column; gap: 4px; }
    .mobile-link {
        padding: 12px 16px; font-size: 15px; font-weight: 500;
        color: var(--gray-700); border-radius: var(--r-sm);
        transition: all .2s;
    }
    .mobile-link:hover { background: var(--brand-50); color: var(--brand-600); }
    .mobile-menu .btn { margin-top: 12px; text-align: center; justify-content: center; }

    @media (min-width: 1024px) {
        .nav-links { display: flex; }
        .nav-cta { display: flex; }
        .hamburger { display: none; }
    }

    /* ============================================ */
    /* HERO                                         */
    /* ============================================ */
    .hero {
        position: relative;
        min-height: 100vh;
        display: flex; align-items: center;
        padding: 120px 0 80px;
        overflow: hidden;
    }
    .hero::before {
        content: '';
        position: absolute; inset: 0;
        background:
            radial-gradient(ellipse 80% 60% at 20% 40%, rgba(16,185,129,.08), transparent),
            radial-gradient(ellipse 60% 50% at 80% 30%, rgba(59,130,246,.06), transparent),
            radial-gradient(ellipse 50% 40% at 50% 80%, rgba(168,85,247,.04), transparent);
        pointer-events: none;
    }
    /* Mesh dots pattern */
    .hero::after {
        content: '';
        position: absolute; inset: 0;
        background-image: radial-gradient(circle at 1px 1px, var(--gray-200) .5px, transparent 0);
        background-size: 32px 32px;
        opacity: .4;
        pointer-events: none;
    }
    .hero-grid {
        display: grid;
        grid-template-columns: 1fr;
        gap: 48px;
        align-items: center;
        position: relative;
        z-index: 1;
    }
    .hero-text { max-width: 560px; }
    .hero-title {
        font-size: clamp(36px, 6vw, 60px);
        font-weight: 900;
        line-height: 1.05;
        letter-spacing: -0.04em;
        color: var(--gray-900);
        margin-bottom: 24px;
    }
    .hero-title .line2 {
        background: linear-gradient(135deg, var(--brand-600) 0%, var(--brand-400) 50%, var(--blue-500) 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        background-size: 200% 200%;
        animation: gradient-flow 4s ease infinite;
    }
    .hero-subtitle {
        font-size: 18px; line-height: 1.7;
        color: var(--gray-500);
        margin-bottom: 36px;
        max-width: 480px;
    }
    .hero-buttons { display: flex; flex-wrap: wrap; gap: 12px; margin-bottom: 32px; }

    .hero-trust {
        display: flex; flex-wrap: wrap; gap: 24px;
    }
    .hero-trust-item {
        display: flex; align-items: center; gap: 8px;
        font-size: 13px; font-weight: 600; color: var(--gray-500);
    }
    .hero-trust-icon {
        width: 20px; height: 20px;
        border-radius: 50%;
        background: var(--brand-50);
        display: flex; align-items: center; justify-content: center;
        flex-shrink: 0;
    }
    .hero-trust-icon svg { width: 10px; height: 10px; color: var(--brand-600); }

    /* Phone mockup */
    .hero-visual {
        position: relative;
        display: flex;
        justify-content: center;
        align-items: center;
    }
    .phone-mockup {
        position: relative;
        width: 280px;
        aspect-ratio: 9/19;
        background: linear-gradient(145deg, #1a1a2e, #16213e);
        border-radius: 40px;
        padding: 12px;
        box-shadow:
            0 40px 80px rgba(0,0,0,.15),
            0 0 0 1px rgba(255,255,255,.1) inset,
            0 0 100px rgba(16,185,129,.1);
        animation: float-slow 6s ease-in-out infinite;
    }
    .phone-screen {
        width: 100%;
        height: 100%;
        background: linear-gradient(160deg, var(--brand-600), var(--brand-500), #34d399);
        border-radius: 30px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 12px;
        overflow: hidden;
        position: relative;
    }
    .phone-screen::before {
        content: '';
        position: absolute; top: 0; left: 50%; transform: translateX(-50%);
        width: 120px; height: 24px;
        background: #1a1a2e;
        border-radius: 0 0 16px 16px;
    }
    .phone-logo-text {
        font-size: 22px; font-weight: 900;
        color: #fff;
        letter-spacing: -.02em;
        text-shadow: 0 2px 8px rgba(0,0,0,.2);
    }
    .phone-tagline {
        font-size: 11px; font-weight: 500;
        color: rgba(255,255,255,.8);
        letter-spacing: .05em;
    }
    /* Floating elements around phone */
    .float-card {
        position: absolute;
        background: #fff;
        border-radius: var(--r-lg);
        padding: 12px 16px;
        box-shadow: var(--shadow-lg);
        font-size: 12px;
        font-weight: 600;
        display: flex; align-items: center; gap: 8px;
        white-space: nowrap;
        z-index: 2;
    }
    .float-card-icon {
        width: 28px; height: 28px;
        border-radius: var(--r-sm);
        display: flex; align-items: center; justify-content: center;
        flex-shrink: 0;
    }
    .float-card-1 {
        top: 15%; left: -10%;
        animation: float-slow 5s ease-in-out infinite;
    }
    .float-card-2 {
        bottom: 25%; right: -10%;
        animation: float-slow 6s ease-in-out 1s infinite;
    }
    .float-card-3 {
        bottom: 8%; left: -5%;
        animation: float-slow 7s ease-in-out 2s infinite;
    }

    @media (min-width: 1024px) {
        .hero-grid { grid-template-columns: 1fr 1fr; gap: 64px; }
        .hero-text { max-width: 100%; }
    }

    /* ============================================ */
    /* STATS BAR                                    */
    /* ============================================ */
    .stats-bar {
        position: relative;
        margin-top: -40px;
        z-index: 10;
        padding-bottom: 40px;
    }
    .stats-inner {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 1px;
        background: var(--gray-200);
        border-radius: var(--r-2xl);
        overflow: hidden;
        box-shadow: var(--shadow-xl);
    }
    .stat-item {
        background: #fff;
        padding: 28px 24px;
        text-align: center;
    }
    .stat-number {
        font-size: clamp(28px, 4vw, 40px);
        font-weight: 900;
        color: var(--brand-600);
        letter-spacing: -.03em;
        line-height: 1;
    }
    .stat-label {
        margin-top: 6px;
        font-size: 13px;
        font-weight: 500;
        color: var(--gray-500);
    }
    @media (min-width: 768px) {
        .stats-inner { grid-template-columns: repeat(4, 1fr); }
        .stat-item { padding: 36px 24px; }
    }

    /* ============================================ */
    /* FEATURES — Bento Grid                        */
    /* ============================================ */
    .features { background: #fff; }
    .features-grid {
        display: grid;
        grid-template-columns: 1fr;
        gap: 16px;
    }
    .feature-card {
        background: var(--gray-50);
        border: 1px solid var(--gray-100);
        border-radius: var(--r-xl);
        padding: 28px;
        transition: all .3s cubic-bezier(.4,0,.2,1);
        position: relative;
        overflow: hidden;
    }
    .feature-card::before {
        content: '';
        position: absolute; top: 0; left: 0; right: 0;
        height: 3px;
        border-radius: 3px 3px 0 0;
        opacity: 0;
        transition: opacity .3s;
    }
    .feature-card:hover {
        border-color: transparent;
        box-shadow: var(--shadow-lg);
        transform: translateY(-4px);
    }
    .feature-card:hover::before { opacity: 1; }

    .feature-card[data-color="green"]::before { background: linear-gradient(90deg, var(--brand-500), var(--brand-400)); }
    .feature-card[data-color="blue"]::before { background: linear-gradient(90deg, var(--blue-600), var(--blue-500)); }
    .feature-card[data-color="amber"]::before { background: linear-gradient(90deg, var(--amber-500), var(--amber-400)); }
    .feature-card[data-color="purple"]::before { background: linear-gradient(90deg, var(--purple-500), #c084fc); }
    .feature-card[data-color="rose"]::before { background: linear-gradient(90deg, var(--rose-500), #fb7185); }
    .feature-card[data-color="cyan"]::before { background: linear-gradient(90deg, var(--cyan-500), #22d3ee); }

    .feature-icon {
        width: 48px; height: 48px;
        border-radius: var(--r-md);
        display: flex; align-items: center; justify-content: center;
        margin-bottom: 20px;
    }
    .feature-icon svg { width: 24px; height: 24px; }

    .feature-icon-green { background: var(--brand-50); color: var(--brand-600); }
    .feature-icon-blue { background: #eff6ff; color: var(--blue-600); }
    .feature-icon-amber { background: #fffbeb; color: var(--amber-500); }
    .feature-icon-purple { background: #faf5ff; color: var(--purple-500); }
    .feature-icon-rose { background: #fff1f2; color: var(--rose-500); }
    .feature-icon-cyan { background: #ecfeff; color: var(--cyan-500); }

    .feature-title {
        font-size: 17px; font-weight: 700;
        color: var(--gray-800);
        margin-bottom: 8px;
    }
    .feature-desc {
        font-size: 14px; line-height: 1.65;
        color: var(--gray-500);
    }

    @media (min-width: 640px) {
        .features-grid { grid-template-columns: repeat(2, 1fr); }
    }
    @media (min-width: 1024px) {
        .features-grid { grid-template-columns: repeat(3, 1fr); }
    }

    /* ============================================ */
    /* STEPS — Timeline                             */
    /* ============================================ */
    .steps { background: var(--gray-50); }
    .steps-list {
        display: flex;
        flex-direction: column;
        gap: 0;
        max-width: 640px;
        margin: 0 auto;
    }
    .step-item {
        display: flex;
        gap: 24px;
        position: relative;
        padding-bottom: 40px;
    }
    .step-item:last-child { padding-bottom: 0; }
    .step-line {
        display: flex; flex-direction: column; align-items: center;
        flex-shrink: 0;
    }
    .step-number {
        width: 48px; height: 48px;
        border-radius: 50%;
        display: flex; align-items: center; justify-content: center;
        font-size: 18px; font-weight: 800;
        color: #fff;
        flex-shrink: 0;
        position: relative;
        z-index: 1;
    }
    .step-number[data-color="green"] { background: linear-gradient(135deg, var(--brand-600), var(--brand-400)); box-shadow: 0 4px 15px rgba(5,150,105,.3); }
    .step-number[data-color="blue"] { background: linear-gradient(135deg, var(--blue-600), var(--blue-500)); box-shadow: 0 4px 15px rgba(37,99,235,.3); }
    .step-number[data-color="amber"] { background: linear-gradient(135deg, var(--amber-500), var(--amber-400)); box-shadow: 0 4px 15px rgba(245,158,11,.3); }

    .step-connector {
        flex: 1;
        width: 2px;
        background: linear-gradient(to bottom, var(--gray-300), var(--gray-200));
        margin-top: 8px;
    }
    .step-item:last-child .step-connector { display: none; }

    .step-content { padding-top: 6px; }
    .step-title {
        font-size: 20px; font-weight: 800;
        color: var(--gray-800);
        margin-bottom: 6px;
    }
    .step-desc {
        font-size: 15px; line-height: 1.65;
        color: var(--gray-500);
    }

    /* ============================================ */
    /* APPS — Cards with glass                      */
    /* ============================================ */
    .apps-section {
        background:
            linear-gradient(135deg, var(--navy-900) 0%, var(--navy-800) 50%, #0d1f3c 100%);
        position: relative;
        overflow: hidden;
    }
    .apps-section::before {
        content: '';
        position: absolute; inset: 0;
        background:
            radial-gradient(ellipse 40% 50% at 20% 20%, rgba(16,185,129,.08), transparent),
            radial-gradient(ellipse 40% 50% at 80% 80%, rgba(59,130,246,.06), transparent);
        pointer-events: none;
    }
    .apps-section .section-title { color: #fff; }
    .apps-section .section-title .highlight {
        background: linear-gradient(135deg, var(--brand-400), #34d399);
        -webkit-background-clip: text; background-clip: text;
    }
    .apps-section .section-subtitle { color: rgba(255,255,255,.5); }
    .apps-section .badge {
        background: rgba(16,185,129,.15);
        border-color: rgba(16,185,129,.3);
        color: var(--brand-400);
    }

    .apps-grid {
        display: grid;
        grid-template-columns: 1fr;
        gap: 20px;
        position: relative;
        z-index: 1;
    }
    .app-card {
        background: rgba(255,255,255,.05);
        border: 1px solid rgba(255,255,255,.08);
        border-radius: var(--r-2xl);
        padding: 32px;
        backdrop-filter: blur(10px);
        transition: all .3s;
    }
    .app-card:hover {
        background: rgba(255,255,255,.08);
        border-color: rgba(255,255,255,.15);
        transform: translateY(-4px);
    }
    .app-tag {
        display: inline-block;
        padding: 4px 12px;
        border-radius: var(--r-full);
        font-size: 11px;
        font-weight: 800;
        letter-spacing: .08em;
        text-transform: uppercase;
        margin-bottom: 16px;
    }
    .app-tag-green { background: rgba(16,185,129,.15); color: var(--brand-400); }
    .app-tag-blue { background: rgba(59,130,246,.15); color: #60a5fa; }
    .app-tag-amber { background: rgba(245,158,11,.15); color: var(--amber-400); }

    .app-title {
        font-size: 22px; font-weight: 800;
        color: #fff;
        margin-bottom: 8px;
    }
    .app-desc {
        font-size: 14px; color: rgba(255,255,255,.5);
        margin-bottom: 20px;
    }
    .app-features {
        display: flex; flex-direction: column; gap: 10px;
    }
    .app-feature {
        display: flex; align-items: center; gap: 10px;
        font-size: 13px; font-weight: 500;
        color: rgba(255,255,255,.7);
    }
    .app-feature-dot {
        width: 6px; height: 6px;
        border-radius: 50%;
        flex-shrink: 0;
    }
    .app-feature-dot-green { background: var(--brand-400); }
    .app-feature-dot-blue { background: #60a5fa; }
    .app-feature-dot-amber { background: var(--amber-400); }

    @media (min-width: 768px) {
        .apps-grid { grid-template-columns: repeat(3, 1fr); }
    }

    /* ============================================ */
    /* TESTIMONIALS                                 */
    /* ============================================ */
    .testimonials { background: #fff; }
    .testimonials-grid {
        display: grid;
        grid-template-columns: 1fr;
        gap: 20px;
    }
    .testimonial-card {
        background: var(--gray-50);
        border: 1px solid var(--gray-100);
        border-radius: var(--r-xl);
        padding: 28px;
        transition: all .3s;
    }
    .testimonial-card:hover {
        box-shadow: var(--shadow-md);
        border-color: var(--gray-200);
    }
    .testimonial-stars {
        display: flex; gap: 2px;
        margin-bottom: 16px;
    }
    .testimonial-stars svg {
        width: 16px; height: 16px;
        color: var(--amber-400);
        fill: var(--amber-400);
    }
    .testimonial-stars svg.empty {
        color: var(--gray-200);
        fill: var(--gray-200);
    }
    .testimonial-quote {
        font-size: 15px; line-height: 1.7;
        color: var(--gray-700);
        margin-bottom: 20px;
        font-style: italic;
    }
    .testimonial-author {
        display: flex; align-items: center; gap: 12px;
    }
    .testimonial-avatar {
        width: 40px; height: 40px;
        border-radius: 50%;
        display: flex; align-items: center; justify-content: center;
        font-size: 14px; font-weight: 800;
        color: #fff;
    }
    .testimonial-avatar-green { background: linear-gradient(135deg, var(--brand-600), var(--brand-400)); }
    .testimonial-avatar-blue { background: linear-gradient(135deg, var(--blue-600), var(--blue-500)); }
    .testimonial-avatar-amber { background: linear-gradient(135deg, var(--amber-500), var(--amber-400)); }
    .testimonial-name {
        font-size: 14px; font-weight: 700;
        color: var(--gray-800);
    }
    .testimonial-role {
        font-size: 12px;
        color: var(--gray-400);
    }

    @media (min-width: 768px) {
        .testimonials-grid { grid-template-columns: repeat(3, 1fr); }
    }

    /* ============================================ */
    /* FAQ                                          */
    /* ============================================ */
    .faq-section { background: var(--gray-50); }
    .faq-list {
        max-width: 720px;
        margin: 0 auto;
        display: flex; flex-direction: column;
        gap: 12px;
    }
    .faq-item {
        background: #fff;
        border: 1px solid var(--gray-200);
        border-radius: var(--r-lg);
        overflow: hidden;
        transition: all .3s;
    }
    .faq-item.open {
        border-color: var(--brand-200);
        box-shadow: 0 4px 12px rgba(5,150,105,.08);
    }
    .faq-question {
        width: 100%;
        display: flex; align-items: center; justify-content: space-between;
        gap: 16px;
        padding: 20px 24px;
        font-size: 15px; font-weight: 600;
        color: var(--gray-800);
        text-align: left;
        cursor: pointer;
        transition: color .2s;
    }
    .faq-question:hover { color: var(--brand-600); }
    .faq-chevron {
        width: 20px; height: 20px;
        flex-shrink: 0;
        color: var(--gray-400);
        transition: transform .3s;
    }
    .faq-item.open .faq-chevron { transform: rotate(180deg); color: var(--brand-500); }
    .faq-answer {
        max-height: 0;
        overflow: hidden;
        transition: max-height .3s ease, padding .3s ease;
    }
    .faq-item.open .faq-answer {
        max-height: 300px;
    }
    .faq-answer-inner {
        padding: 0 24px 20px;
        font-size: 14px; line-height: 1.7;
        color: var(--gray-500);
    }

    /* ============================================ */
    /* CTA                                          */
    /* ============================================ */
    .cta-section {
        background:
            linear-gradient(135deg, var(--brand-700) 0%, var(--brand-600) 40%, var(--brand-500) 100%);
        position: relative;
        overflow: hidden;
    }
    .cta-section::before {
        content: '';
        position: absolute; inset: 0;
        background:
            radial-gradient(circle at 20% 50%, rgba(255,255,255,.08), transparent 50%),
            radial-gradient(circle at 80% 50%, rgba(255,255,255,.05), transparent 50%);
        pointer-events: none;
    }
    .cta-section::after {
        content: '';
        position: absolute; inset: 0;
        background-image: radial-gradient(circle at 1px 1px, rgba(255,255,255,.06) .5px, transparent 0);
        background-size: 28px 28px;
        pointer-events: none;
    }
    .cta-inner {
        position: relative; z-index: 1;
        text-align: center;
        max-width: 640px;
        margin: 0 auto;
    }
    .cta-inner h2 {
        font-size: clamp(28px, 5vw, 44px);
        font-weight: 900;
        color: #fff;
        line-height: 1.15;
        letter-spacing: -.03em;
        margin-bottom: 16px;
    }
    .cta-inner h2 .cta-highlight {
        color: rgba(255,255,255,.6);
    }
    .cta-inner p {
        font-size: 17px; color: rgba(255,255,255,.7);
        margin-bottom: 36px;
        line-height: 1.7;
    }
    .cta-buttons {
        display: flex; flex-wrap: wrap;
        justify-content: center;
        gap: 12px;
        margin-bottom: 32px;
    }
    .cta-trust {
        display: flex; flex-wrap: wrap;
        justify-content: center;
        gap: 20px;
    }
    .cta-trust-item {
        display: flex; align-items: center; gap: 6px;
        font-size: 13px; font-weight: 500;
        color: rgba(255,255,255,.6);
    }
    .cta-trust-item svg { width: 14px; height: 14px; }

    /* ============================================ */
    /* FOOTER                                       */
    /* ============================================ */
    .footer {
        background: var(--navy-950);
        color: rgba(255,255,255,.5);
        padding: 64px 0 32px;
    }
    .footer-grid {
        display: grid;
        grid-template-columns: 1fr;
        gap: 40px;
        margin-bottom: 48px;
    }
    .footer-brand .navbar-brand { margin-bottom: 16px; display: inline-block; }
    .footer-brand .navbar-brand .dr { color: #fff; }
    .footer-brand .navbar-brand .pharma { color: var(--brand-400); }
    .footer-desc {
        font-size: 14px; line-height: 1.7;
        max-width: 280px;
        margin-bottom: 20px;
    }
    .footer-social {
        display: flex; gap: 12px;
    }
    .footer-social a {
        width: 36px; height: 36px;
        border-radius: var(--r-sm);
        background: rgba(255,255,255,.05);
        border: 1px solid rgba(255,255,255,.08);
        display: flex; align-items: center; justify-content: center;
        transition: all .3s;
    }
    .footer-social a:hover {
        background: var(--brand-600);
        border-color: var(--brand-500);
    }
    .footer-social a svg { width: 16px; height: 16px; color: rgba(255,255,255,.6); }
    .footer-social a:hover svg { color: #fff; }

    .footer-heading {
        font-size: 13px; font-weight: 700;
        color: rgba(255,255,255,.8);
        text-transform: uppercase;
        letter-spacing: .08em;
        margin-bottom: 16px;
    }
    .footer-links { display: flex; flex-direction: column; gap: 10px; }
    .footer-link {
        font-size: 14px; color: rgba(255,255,255,.4);
        transition: color .2s;
    }
    .footer-link:hover { color: var(--brand-400); }

    .footer-contact-item {
        display: flex; align-items: flex-start; gap: 10px;
        font-size: 14px;
        margin-bottom: 10px;
    }
    .footer-contact-item svg { width: 16px; height: 16px; flex-shrink: 0; margin-top: 2px; color: var(--brand-400); }

    .footer-bottom {
        border-top: 1px solid rgba(255,255,255,.06);
        padding-top: 24px;
        display: flex; flex-wrap: wrap;
        justify-content: space-between;
        gap: 16px;
        font-size: 13px;
    }
    .footer-legal {
        display: flex; flex-wrap: wrap; gap: 20px;
    }
    .footer-legal a { color: rgba(255,255,255,.3); transition: color .2s; }
    .footer-legal a:hover { color: var(--brand-400); }

    @media (min-width: 768px) {
        .footer-grid { grid-template-columns: 2fr 1fr 1fr 1fr; }
    }
    </style>
</head>
<body>

    <!-- ============================================ -->
    <!-- NAVBAR                                       -->
    <!-- ============================================ -->
    <nav class="navbar" id="navbar">
        <div class="container">
            <div class="navbar-inner">
                <a href="/" class="navbar-logo">
                    <div class="navbar-logo-icon">
                        <img src="{{ asset('images/logo.png') }}" alt="DR-PHARMA">
                    </div>
                    <div class="navbar-brand">
                        <span class="dr">DR</span><span class="sep">-</span><span class="pharma">PHARMA</span>
                    </div>
                </a>

                <div class="nav-links">
                    <a href="#fonctionnalites" class="nav-link">Fonctionnalités</a>
                    <a href="#comment-ca-marche" class="nav-link">Comment ça marche</a>
                    <a href="#applications" class="nav-link">Applications</a>
                    <a href="#temoignages" class="nav-link">Témoignages</a>
                    <a href="#faq" class="nav-link">FAQ</a>
                    <a href="/contact" class="nav-link">Contact</a>
                </div>

                <div class="nav-cta">
                    <a href="#telecharger" class="btn btn-brand" style="padding: 10px 22px; font-size: 14px;">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                        Télécharger
                    </a>
                </div>

                <button class="hamburger" id="hamburger" aria-label="Menu">
                    <span></span><span></span><span></span>
                </button>
            </div>
        </div>

        <div class="mobile-menu" id="mobile-menu">
            <a href="#fonctionnalites" class="mobile-link">Fonctionnalités</a>
            <a href="#comment-ca-marche" class="mobile-link">Comment ça marche</a>
            <a href="#applications" class="mobile-link">Applications</a>
            <a href="#temoignages" class="mobile-link">Témoignages</a>
            <a href="#faq" class="mobile-link">FAQ</a>
            <a href="/contact" class="mobile-link">Contact</a>
            <a href="#telecharger" class="btn btn-brand" style="justify-content: center;">Télécharger l'app</a>
        </div>
    </nav>


    <!-- ============================================ -->
    <!-- HERO                                         -->
    <!-- ============================================ -->
    <section class="hero">
        <div class="container">
            <div class="hero-grid">
                <div class="hero-text">
                    <div>
                        <span class="badge">
                            <span class="badge-dot"></span>
                            {{ $landing['hero_badge'] }}
                        </span>
                    </div>
                    <h1 class="hero-title">
                        {{ $landing['hero_title_line1'] }}<br>
                        <span class="line2">{{ $landing['hero_title_line2'] }}</span>
                    </h1>
                    <p class="hero-subtitle">{{ $landing['hero_subtitle'] }}</p>

                    <div class="hero-buttons">
                        <a href="{{ $landing['hero_cta_playstore_url'] }}" class="btn btn-brand">
                            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 01-.61-.92V2.734a1 1 0 01.609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.199l2.302 2.302-2.302 2.302-2.698-2.302 2.698-2.302zM5.864 2.658L16.8 8.99l-2.302 2.302-8.635-8.635z"/></svg>
                            Google Play
                        </a>
                        <a href="{{ $landing['hero_cta_appstore_url'] }}" class="btn btn-dark">
                            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83z"/><path d="M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
                            App Store
                        </a>
                    </div>

                    <div class="hero-trust">
                        <div class="hero-trust-item">
                            <span class="hero-trust-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                            </span>
                            {{ $landing['hero_trust_1'] }}
                        </div>
                        <div class="hero-trust-item">
                            <span class="hero-trust-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                            </span>
                            {{ $landing['hero_trust_2'] }}
                        </div>
                        <div class="hero-trust-item">
                            <span class="hero-trust-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                            </span>
                            {{ $landing['hero_trust_3'] }}
                        </div>
                    </div>
                </div>

                <div class="hero-visual">
                    <div class="phone-mockup">
                        <div class="phone-screen">
                            <div class="phone-logo-text">{{ $landing['hero_phone_title'] }}</div>
                            <div class="phone-tagline">{{ $landing['hero_phone_subtitle'] }}</div>
                        </div>
                    </div>

                    <div class="float-card float-card-1">
                        <div class="float-card-icon" style="background: var(--brand-50);">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--brand-600)" stroke-width="2.5" stroke-linecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                        </div>
                        <span style="color: var(--gray-700);">Commande confirmée</span>
                    </div>

                    <div class="float-card float-card-2">
                        <div class="float-card-icon" style="background: #eff6ff;">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--blue-600)" stroke-width="2.5" stroke-linecap="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                        </div>
                        <span style="color: var(--gray-700);">Livraison en 35 min</span>
                    </div>

                    <div class="float-card float-card-3">
                        <div class="float-card-icon" style="background: #faf5ff;">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--purple-500)" stroke-width="2.5" stroke-linecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                        </div>
                        <span style="color: var(--gray-700);">Données protégées</span>
                    </div>
                </div>
            </div>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- STATS                                        -->
    <!-- ============================================ -->
    <section class="stats-bar">
        <div class="container">
            <div class="stats-inner">
                @foreach($landing['stats'] as $stat)
                <div class="stat-item reveal">
                    <div class="stat-number" data-count="{{ $stat['value'] }}">0{{ $stat['suffix'] }}</div>
                    <div class="stat-label">{{ $stat['label'] }}</div>
                </div>
                @endforeach
            </div>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- FEATURES                                     -->
    <!-- ============================================ -->
    <section id="fonctionnalites" class="section features">
        <div class="container">
            <div class="section-header reveal">
                <span class="badge"><span class="badge-dot"></span>{{ $landing['features_badge'] }}</span>
                <h2 class="section-title">{!! str_replace(
                    $landing['features_title_highlight'],
                    '<span class="highlight">' . $landing['features_title_highlight'] . '</span>',
                    e($landing['features_title'])
                ) !!}</h2>
                <p class="section-subtitle">{{ $landing['features_subtitle'] }}</p>
            </div>

            <div class="features-grid">
                @php
                $featureIcons = [
                    'green' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>',
                    'blue' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>',
                    'amber' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>',
                    'purple' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>',
                    'rose' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="M12 5l7 7-7 7"/></svg>',
                    'cyan' => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>',
                ];
                @endphp

                @foreach($landing['features'] as $i => $feature)
                <div class="feature-card reveal" data-color="{{ $feature['icon_color'] }}" style="transition-delay: {{ $i * 80 }}ms;">
                    <div class="feature-icon feature-icon-{{ $feature['icon_color'] }}">
                        {!! $featureIcons[$feature['icon_color']] ?? $featureIcons['green'] !!}
                    </div>
                    <h3 class="feature-title">{{ $feature['title'] }}</h3>
                    <p class="feature-desc">{{ $feature['description'] }}</p>
                </div>
                @endforeach
            </div>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- STEPS                                        -->
    <!-- ============================================ -->
    <section id="comment-ca-marche" class="section steps">
        <div class="container">
            <div class="section-header reveal">
                <span class="badge"><span class="badge-dot"></span>{{ $landing['steps_badge'] }}</span>
                <h2 class="section-title">{!! str_replace(
                    $landing['steps_title_highlight'],
                    '<span class="highlight">' . $landing['steps_title_highlight'] . '</span>',
                    e($landing['steps_title'])
                ) !!}</h2>
                <p class="section-subtitle">{{ $landing['steps_subtitle'] }}</p>
            </div>

            <div class="steps-list">
                @foreach($landing['steps'] as $i => $step)
                <div class="step-item reveal" style="transition-delay: {{ $i * 150 }}ms;">
                    <div class="step-line">
                        <div class="step-number" data-color="{{ $step['color'] }}">{{ $i + 1 }}</div>
                        <div class="step-connector"></div>
                    </div>
                    <div class="step-content">
                        <h3 class="step-title">{{ $step['title'] }}</h3>
                        <p class="step-desc">{{ $step['description'] }}</p>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- APPS                                         -->
    <!-- ============================================ -->
    <section id="applications" class="section apps-section">
        <div class="container">
            <div class="section-header reveal">
                <span class="badge"><span class="badge-dot"></span>{{ $landing['apps_badge'] }}</span>
                <h2 class="section-title">{!! str_replace(
                    $landing['apps_title_highlight'],
                    '<span class="highlight">' . $landing['apps_title_highlight'] . '</span>',
                    e($landing['apps_title'])
                ) !!}</h2>
                <p class="section-subtitle">{{ $landing['apps_subtitle'] }}</p>
            </div>

            <div class="apps-grid">
                @foreach($landing['apps'] as $i => $app)
                <div class="app-card reveal" style="transition-delay: {{ $i * 100 }}ms;">
                    <span class="app-tag app-tag-{{ $app['color'] }}">{{ $app['tag'] }}</span>
                    <h3 class="app-title">{{ $app['title'] }}</h3>
                    <p class="app-desc">{{ $app['description'] }}</p>
                    <div class="app-features">
                        @foreach(explode('|', $app['features']) as $feat)
                        <div class="app-feature">
                            <span class="app-feature-dot app-feature-dot-{{ $app['color'] }}"></span>
                            {{ $feat }}
                        </div>
                        @endforeach
                    </div>
                </div>
                @endforeach
            </div>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- TESTIMONIALS                                 -->
    <!-- ============================================ -->
    <section id="temoignages" class="section testimonials">
        <div class="container">
            <div class="section-header reveal">
                <span class="badge"><span class="badge-dot"></span>{{ $landing['testimonials_badge'] }}</span>
                <h2 class="section-title">{!! str_replace(
                    $landing['testimonials_title_highlight'],
                    '<span class="highlight">' . $landing['testimonials_title_highlight'] . '</span>',
                    e($landing['testimonials_title'])
                ) !!}</h2>
            </div>

            <div class="testimonials-grid">
                @foreach($landing['testimonials'] as $i => $t)
                <div class="testimonial-card reveal" style="transition-delay: {{ $i * 100 }}ms;">
                    <div class="testimonial-stars">
                        @for($s = 1; $s <= 5; $s++)
                        <svg viewBox="0 0 24 24" class="{{ $s <= $t['rating'] ? '' : 'empty' }}"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                        @endfor
                    </div>
                    <p class="testimonial-quote">"{{ $t['quote'] }}"</p>
                    <div class="testimonial-author">
                        <div class="testimonial-avatar testimonial-avatar-{{ $t['color'] }}">{{ $t['initials'] }}</div>
                        <div>
                            <div class="testimonial-name">{{ $t['name'] }}</div>
                            <div class="testimonial-role">{{ $t['role'] }}</div>
                        </div>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- FAQ                                          -->
    <!-- ============================================ -->
    <section id="faq" class="section faq-section">
        <div class="container">
            <div class="section-header reveal">
                <span class="badge"><span class="badge-dot"></span>{{ $landing['faq_badge'] }}</span>
                <h2 class="section-title">{!! str_replace(
                    $landing['faq_title_highlight'],
                    '<span class="highlight">' . $landing['faq_title_highlight'] . '</span>',
                    e($landing['faq_title'])
                ) !!}</h2>
            </div>

            <div class="faq-list">
                @foreach($landing['faqs'] as $i => $faq)
                <div class="faq-item reveal" style="transition-delay: {{ $i * 80 }}ms;">
                    <button class="faq-question" onclick="this.parentElement.classList.toggle('open')">
                        {{ $faq['question'] }}
                        <svg class="faq-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>
                    </button>
                    <div class="faq-answer">
                        <div class="faq-answer-inner">{{ $faq['answer'] }}</div>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- CTA                                          -->
    <!-- ============================================ -->
    <section id="telecharger" class="section cta-section">
        <div class="container">
            <div class="cta-inner reveal">
                <h2>
                    {{ $landing['cta_title_line1'] }}<br>
                    <span class="cta-highlight">{!! str_replace(
                        $landing['cta_highlight'],
                        '<span style="color:#fff;">' . $landing['cta_highlight'] . '</span>',
                        e($landing['cta_title_line2'])
                    ) !!}</span>
                </h2>
                <p>{{ $landing['cta_subtitle'] }}</p>

                <div class="cta-buttons">
                    <a href="{{ $landing['cta_playstore_url'] }}" class="btn btn-glass">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 01-.61-.92V2.734a1 1 0 01.609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.199l2.302 2.302-2.302 2.302-2.698-2.302 2.698-2.302zM5.864 2.658L16.8 8.99l-2.302 2.302-8.635-8.635z"/></svg>
                        Google Play
                    </a>
                    <a href="{{ $landing['cta_appstore_url'] }}" class="btn btn-glass">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83z"/><path d="M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
                        App Store
                    </a>
                </div>

                <div class="cta-trust">
                    <div class="cta-trust-item">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                        {{ $landing['cta_trust_1'] }}
                    </div>
                    <div class="cta-trust-item">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                        {{ $landing['cta_trust_2'] }}
                    </div>
                    <div class="cta-trust-item">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                        {{ $landing['cta_trust_3'] }}
                    </div>
                    <div class="cta-trust-item">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z"/></svg>
                        {{ $landing['cta_trust_4'] }}
                    </div>
                </div>
            </div>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- FOOTER                                       -->
    <!-- ============================================ -->
    <footer class="footer">
        <div class="container">
            <div class="footer-grid">
                <div class="footer-brand">
                    <div class="navbar-brand" style="font-size: 22px;">
                        <span class="dr">DR</span><span class="sep" style="color:rgba(255,255,255,.2);">-</span><span class="pharma">PHARMA</span>
                    </div>
                    <p class="footer-desc">{{ $landing['footer_description'] }}</p>

                    <div class="footer-social">
                        @if($landing['footer_facebook_url'] && $landing['footer_facebook_url'] !== '#')
                        <a href="{{ $landing['footer_facebook_url'] }}" target="_blank" rel="noopener" aria-label="Facebook">
                            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M18 2h-3a5 5 0 00-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 011-1h3z"/></svg>
                        </a>
                        @endif
                        @if($landing['footer_instagram_url'] && $landing['footer_instagram_url'] !== '#')
                        <a href="{{ $landing['footer_instagram_url'] }}" target="_blank" rel="noopener" aria-label="Instagram">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="20" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1112.63 8 4 4 0 0116 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/></svg>
                        </a>
                        @endif
                        @if($landing['footer_twitter_url'] && $landing['footer_twitter_url'] !== '#')
                        <a href="{{ $landing['footer_twitter_url'] }}" target="_blank" rel="noopener" aria-label="Twitter">
                            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>
                        </a>
                        @endif
                        @if($landing['footer_linkedin_url'] && $landing['footer_linkedin_url'] !== '#')
                        <a href="{{ $landing['footer_linkedin_url'] }}" target="_blank" rel="noopener" aria-label="LinkedIn">
                            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M16 8a6 6 0 016 6v7h-4v-7a2 2 0 00-2-2 2 2 0 00-2 2v7h-4v-7a6 6 0 016-6zM2 9h4v12H2zM4 6a2 2 0 100-4 2 2 0 000 4z"/></svg>
                        </a>
                        @endif
                    </div>
                </div>

                <div>
                    <h4 class="footer-heading">Navigation</h4>
                    <div class="footer-links">
                        <a href="#fonctionnalites" class="footer-link">Fonctionnalités</a>
                        <a href="#comment-ca-marche" class="footer-link">Comment ça marche</a>
                        <a href="#applications" class="footer-link">Applications</a>
                        <a href="#temoignages" class="footer-link">Témoignages</a>
                        <a href="#faq" class="footer-link">FAQ</a>
                    </div>
                </div>

                <div>
                    <h4 class="footer-heading">Légal</h4>
                    <div class="footer-links">
                        <a href="/cgu" class="footer-link">Conditions d'utilisation</a>
                        <a href="/confidentialite" class="footer-link">Politique de confidentialité</a>
                        <a href="/aide" class="footer-link">Centre d'aide</a>
                        <a href="/contact" class="footer-link">Contact</a>
                    </div>
                </div>

                <div>
                    <h4 class="footer-heading">Contact</h4>
                    <div class="footer-contact-item">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                        <span>{{ $landing['footer_email'] }}</span>
                    </div>
                    <div class="footer-contact-item">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72 12.84 12.84 0 00.7 2.81 2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45 12.84 12.84 0 002.81.7A2 2 0 0122 16.92z"/></svg>
                        <span>{{ $landing['footer_phone'] }}</span>
                    </div>
                    <div class="footer-contact-item">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                        <span>{{ $landing['footer_address'] }}</span>
                    </div>
                </div>
            </div>

            <div class="footer-bottom">
                <span>{{ $landing['footer_copyright'] }}</span>
                <div class="footer-legal">
                    <a href="/cgu">CGU</a>
                    <a href="/confidentialite">Confidentialité</a>
                    <a href="/contact">Contact</a>
                </div>
            </div>
        </div>
    </footer>


    <!-- ============================================ -->
    <!-- SCRIPTS                                      -->
    <!-- ============================================ -->
    <script>
    (function() {
        'use strict';

        // Navbar scroll effect
        var navbar = document.getElementById('navbar');
        var lastScroll = 0;
        window.addEventListener('scroll', function() {
            var y = window.pageYOffset;
            if (y > 20) {
                navbar.classList.add('scrolled');
            } else {
                navbar.classList.remove('scrolled');
            }
            lastScroll = y;
        }, { passive: true });

        // Mobile menu
        var hamburger = document.getElementById('hamburger');
        var mobileMenu = document.getElementById('mobile-menu');
        hamburger.addEventListener('click', function() {
            hamburger.classList.toggle('active');
            mobileMenu.classList.toggle('open');
        });
        // Close on link click
        mobileMenu.querySelectorAll('a').forEach(function(link) {
            link.addEventListener('click', function() {
                hamburger.classList.remove('active');
                mobileMenu.classList.remove('open');
            });
        });

        // Smooth scroll for anchor links
        document.querySelectorAll('a[href^="#"]').forEach(function(a) {
            a.addEventListener('click', function(e) {
                var target = document.querySelector(this.getAttribute('href'));
                if (target) {
                    e.preventDefault();
                    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            });
        });

        // Scroll reveal
        var revealObserver = new IntersectionObserver(function(entries) {
            entries.forEach(function(entry) {
                if (entry.isIntersecting) {
                    entry.target.classList.add('active');
                    revealObserver.unobserve(entry.target);
                }
            });
        }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });
        document.querySelectorAll('.reveal').forEach(function(el) {
            revealObserver.observe(el);
        });

        // Animated counters
        var counterObserver = new IntersectionObserver(function(entries) {
            entries.forEach(function(entry) {
                if (entry.isIntersecting) {
                    var el = entry.target;
                    var target = parseInt(el.getAttribute('data-count'));
                    if (!target || el.dataset.counted) return;
                    el.dataset.counted = 'true';

                    var suffix = el.textContent.replace(/[0-9]/g, '');
                    var duration = 1800;
                    var start = Date.now();

                    function easeOut(t) { return 1 - Math.pow(1 - t, 3); }

                    function tick() {
                        var elapsed = Date.now() - start;
                        var progress = Math.min(elapsed / duration, 1);
                        var current = Math.floor(easeOut(progress) * target);
                        el.textContent = current.toLocaleString('fr-FR') + suffix;
                        if (progress < 1) requestAnimationFrame(tick);
                    }
                    requestAnimationFrame(tick);
                    counterObserver.unobserve(el);
                }
            });
        }, { threshold: 0.3 });
        document.querySelectorAll('.stat-number[data-count]').forEach(function(el) {
            counterObserver.observe(el);
        });

    })();
    </script>

</body>
</html>
