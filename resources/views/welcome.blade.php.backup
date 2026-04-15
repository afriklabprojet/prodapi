<!DOCTYPE html>
<html lang="fr">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="{{ $landing['seo_description'] }}">
    <title>{{ $landing['seo_title'] }}</title>

    <!-- Open Graph / Facebook / WhatsApp -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="{{ url('/') }}">
    <meta property="og:title" content="{{ $landing['seo_title'] }}">
    <meta property="og:description" content="{{ $landing['seo_description'] }}">
    <meta property="og:image" content="{{ asset('images/og-image.png') }}">
    <meta property="og:locale" content="fr_CI">
    <meta property="og:site_name" content="DR-PHARMA">

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{{ $landing['seo_title'] }}">
    <meta name="twitter:description" content="{{ $landing['seo_description'] }}">
    <meta name="twitter:image" content="{{ asset('images/og-image.png') }}">

    <!-- Canonical -->
    <link rel="canonical" href="{{ url('/') }}">

    <!-- Favicon -->
    <link rel="icon" type="image/png" sizes="32x32" href="{{ asset('favicon.png') }}">
    <link rel="apple-touch-icon" sizes="180x180" href="{{ asset('apple-touch-icon.png') }}">

    <!-- CSRF Token -->
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
            --blue-100: #dbeafe;
            --blue-600: #2563eb;
            --blue-800: #1e40af;
            --amber-100: #fef3c7;
            --amber-200: #fde68a;
            --amber-400: #fbbf24;
            --amber-500: #f59e0b;
            --amber-600: #d97706;
            --amber-700: #b45309;
            --orange-600: #ea580c;
            --purple-100: #f3e8ff;
            --purple-600: #9333ea;
            --rose-100: #ffe4e6;
            --rose-500: #f43f5e;
            --rose-600: #e11d48;
            --cyan-100: #cffafe;
            --cyan-600: #0891b2;
            --red-500: #ef4444;
            --radius-lg: 12px;
            --radius-xl: 16px;
            --radius-2xl: 20px;
            --radius-3xl: 24px;
            --radius-full: 9999px;
            --shadow-sm: 0 1px 2px rgba(0, 0, 0, .05);
            --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, .1), 0 2px 4px -2px rgba(0, 0, 0, .1);
            --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, .1), 0 4px 6px -4px rgba(0, 0, 0, .1);
            --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, .1), 0 8px 10px -6px rgba(0, 0, 0, .1);
            --shadow-2xl: 0 25px 50px -12px rgba(0, 0, 0, .25);
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

        .section {
            padding: 96px 0;
        }

        .section-header {
            text-align: center;
            margin-bottom: 64px;
        }

        .badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 6px 16px;
            border-radius: var(--radius-full);
            background: var(--brand-100);
            color: var(--brand-700);
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 16px;
        }

        .badge-dot {
            width: 8px;
            height: 8px;
            background: var(--brand-500);
            border-radius: 50%;
        }

        .section-title {
            font-size: clamp(28px, 5vw, 48px);
            font-weight: 900;
            line-height: 1.15;
            letter-spacing: -0.025em;
            color: var(--gray-900);
        }

        .section-subtitle {
            margin-top: 16px;
            font-size: 18px;
            color: var(--gray-500);
            max-width: 640px;
            margin-left: auto;
            margin-right: auto;
            line-height: 1.7;
        }

        .gradient-text {
            background: linear-gradient(135deg, var(--brand-600), var(--brand-400));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .grid-2 {
            display: grid;
            grid-template-columns: 1fr;
            gap: 32px;
        }

        .grid-3 {
            display: grid;
            grid-template-columns: 1fr;
            gap: 32px;
        }

        .grid-4 {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 32px;
        }

        @media(min-width:768px) {
            .grid-2 {
                grid-template-columns: repeat(2, 1fr);
            }

            .grid-3 {
                grid-template-columns: repeat(2, 1fr);
            }

            .grid-4 {
                grid-template-columns: repeat(4, 1fr);
            }
        }

        @media(min-width:1024px) {
            .grid-3 {
                grid-template-columns: repeat(3, 1fr);
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
            transition: all 0.3s ease;
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

        .btn-dark {
            background: var(--gray-900);
            color: #fff;
            box-shadow: var(--shadow-xl);
        }

        .btn-dark:hover {
            background: var(--gray-800);
            transform: translateY(-2px);
        }

        .btn-glass {
            background: rgba(255, 255, 255, .12);
            color: #fff;
            border: 1px solid rgba(255, 255, 255, .2);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
        }

        .btn-glass:hover {
            background: rgba(255, 255, 255, .22);
            transform: translateY(-2px);
        }

        .btn svg {
            width: 20px;
            height: 20px;
        }

        /* ============================================ */
        /* ANIMATIONS                                   */
        /* ============================================ */
        @keyframes float {

            0%,
            100% {
                transform: translateY(0)
            }

            50% {
                transform: translateY(-20px)
            }
        }

        @keyframes pulse-soft {

            0%,
            100% {
                opacity: 1
            }

            50% {
                opacity: .6
            }
        }

        @keyframes slide-up {
            0% {
                opacity: 0;
                transform: translateY(40px)
            }

            100% {
                opacity: 1;
                transform: translateY(0)
            }
        }

        @keyframes gradient-shift {
            0% {
                background-position: 0% 50%
            }

            50% {
                background-position: 100% 50%
            }

            100% {
                background-position: 0% 50%
            }
        }

        .animate-float {
            animation: float 6s ease-in-out infinite;
        }

        .animate-float-d {
            animation: float 6s ease-in-out 2s infinite;
        }

        .animate-float-s {
            animation: float 8s ease-in-out 1s infinite;
        }

        .animate-pulse-soft {
            animation: pulse-soft 3s ease-in-out infinite;
        }

        .reveal {
            opacity: 0;
            transform: translateY(40px);
            transition: all .8s cubic-bezier(.25, .46, .45, .94);
        }

        .reveal.active {
            opacity: 1;
            transform: translateY(0);
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
            border-radius: var(--radius-xl);
            overflow: hidden;
            transition: transform .3s;
        }

        .navbar-logo:hover .navbar-logo-icon {
            transform: scale(1.1);
        }

        .navbar-logo-icon img {
            width: 100%;
            height: 100%;
            object-fit: contain;
        }

        .navbar-brand {
            font-size: 20px;
            font-weight: 800;
            letter-spacing: -.02em;
        }

        .navbar-brand span:first-child {
            color: var(--gray-900);
        }

        .navbar-brand span:nth-child(2) {
            color: var(--gray-400);
        }

        .navbar-brand span:last-child {
            color: var(--brand-600);
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

        .mobile-menu a:hover {
            color: var(--brand-600);
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
        /* HERO                                         */
        /* ============================================ */
        .hero {
            min-height: 100vh;
            display: flex;
            align-items: center;
            padding-top: 80px;
            position: relative;
            overflow: hidden;
            background: linear-gradient(135deg, var(--brand-50) 0%, #f0fdf4 50%, #d1fae5 100%);
        }

        .hero-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 48px;
            align-items: center;
            position: relative;
            z-index: 5;
        }

        @media(min-width:1024px) {
            .hero-grid {
                grid-template-columns: 1fr 1fr;
                gap: 32px;
            }

            .hero-text {
                text-align: left;
            }

            .hero-text .hero-actions {
                justify-content: flex-start;
            }

            .hero-text .trust-row {
                justify-content: flex-start;
            }
        }

        .hero-text {
            text-align: center;
        }

        .hero-text h1 {
            font-size: clamp(36px, 6vw, 68px);
            font-weight: 900;
            line-height: 1.1;
            letter-spacing: -.03em;
            animation: slide-up .8s ease-out;
        }

        .hero-text p {
            margin-top: 24px;
            font-size: clamp(16px, 2vw, 20px);
            color: var(--gray-600);
            max-width: 520px;
            line-height: 1.7;
            animation: slide-up .8s ease-out .2s both;
        }

        @media(min-width:1024px) {
            .hero-text p {
                margin-left: 0;
                margin-right: 0;
            }
        }

        @media(max-width:1023px) {
            .hero-text p {
                margin-left: auto;
                margin-right: auto;
            }
        }

        .hero-actions {
            margin-top: 40px;
            display: flex;
            flex-wrap: wrap;
            gap: 16px;
            justify-content: center;
            animation: slide-up .8s ease-out .4s both;
        }

        .trust-row {
            margin-top: 40px;
            display: flex;
            flex-wrap: wrap;
            gap: 24px;
            justify-content: center;
            font-size: 14px;
            color: var(--gray-500);
            animation: slide-up .8s ease-out .4s both;
        }

        .trust-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .trust-item svg {
            width: 20px;
            height: 20px;
            color: var(--brand-500);
            flex-shrink: 0;
        }

        /* Phone */
        .hero-phone-wrap {
            display: flex;
            justify-content: center;
        }

        @media(min-width:1024px) {
            .hero-phone-wrap {
                justify-content: flex-end;
            }
        }

        .phone {
            width: 260px;
            height: 520px;
            border-radius: 36px;
            border: 4px solid var(--gray-800);
            position: relative;
            overflow: hidden;
            background: linear-gradient(180deg, var(--brand-800), var(--brand-600), var(--brand-500));
            box-shadow: 0 25px 60px -15px rgba(0, 0, 0, .3), inset 0 1px 0 rgba(255, 255, 255, .1);
        }

        .phone::before {
            content: '';
            position: absolute;
            top: 0;
            left: 50%;
            transform: translateX(-50%);
            width: 120px;
            height: 28px;
            background: var(--gray-800);
            border-radius: 0 0 16px 16px;
            z-index: 10;
        }

        .phone-content {
            position: absolute;
            inset: 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 32px 24px 24px;
            color: #fff;
        }

        .phone-logo-box {
            width: 64px;
            height: 64px;
            border-radius: var(--radius-2xl);
            overflow: hidden;
            margin-bottom: 16px;
        }

        .phone-logo-box img {
            width: 100%;
            height: 100%;
            object-fit: contain;
        }

        .phone-content h3 {
            font-size: 18px;
            font-weight: 700;
        }

        .phone-content .phone-sub {
            font-size: 13px;
            color: rgba(255, 255, 255, .7);
            text-align: center;
            margin-top: 4px;
        }

        .phone-cards {
            margin-top: 24px;
            width: 100%;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .phone-card {
            background: rgba(255, 255, 255, .15);
            backdrop-filter: blur(8px);
            border-radius: var(--radius-xl);
            padding: 12px;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .phone-card-icon {
            width: 40px;
            height: 40px;
            background: rgba(255, 255, 255, .2);
            border-radius: var(--radius-lg);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }

        .phone-card-icon svg {
            width: 20px;
            height: 20px;
            color: #fff;
        }

        .phone-card p:first-of-type {
            font-size: 12px;
            font-weight: 600;
        }

        .phone-card p:last-of-type {
            font-size: 10px;
            color: rgba(255, 255, 255, .6);
        }

        .hero-wave {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            z-index: 2;
        }

        .hero-wave svg {
            display: block;
            width: 100%;
        }

        /* ============================================ */
        /* STATS                                        */
        /* ============================================ */
        .stats {
            padding: 64px 0;
            background: #fff;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 32px;
        }

        @media(min-width:768px) {
            .stats-grid {
                grid-template-columns: repeat(4, 1fr);
            }
        }

        .stat {
            text-align: center;
        }

        .stat-number {
            font-size: clamp(32px, 5vw, 48px);
            font-weight: 900;
            background: linear-gradient(135deg, var(--brand-600), var(--brand-400));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 8px;
        }

        .stat-label {
            font-size: 14px;
            color: var(--gray-500);
            font-weight: 500;
        }

        /* ============================================ */
        /* FEATURES                                     */
        /* ============================================ */
        .features {
            background: var(--gray-50);
        }

        .feature-card {
            background: #fff;
            border-radius: var(--radius-2xl);
            padding: 32px;
            border: 1px solid var(--gray-100);
            transition: transform .4s ease, box-shadow .4s ease;
        }

        .feature-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 25px 50px -12px rgba(5, 150, 105, .12);
        }

        .feature-icon {
            width: 56px;
            height: 56px;
            border-radius: var(--radius-2xl);
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 24px;
        }

        .feature-icon svg {
            width: 28px;
            height: 28px;
        }

        .feature-card h3 {
            font-size: 20px;
            font-weight: 700;
            margin-bottom: 12px;
        }

        .feature-card p {
            color: var(--gray-500);
            line-height: 1.7;
            font-size: 15px;
        }

        .icon-green {
            background: var(--brand-100);
        }

        .icon-green svg {
            color: var(--brand-600);
        }

        .icon-blue {
            background: var(--blue-100);
        }

        .icon-blue svg {
            color: var(--blue-600);
        }

        .icon-amber {
            background: var(--amber-100);
        }

        .icon-amber svg {
            color: var(--amber-600);
        }

        .icon-purple {
            background: var(--purple-100);
        }

        .icon-purple svg {
            color: var(--purple-600);
        }

        .icon-rose {
            background: var(--rose-100);
        }

        .icon-rose svg {
            color: var(--rose-600);
        }

        .icon-cyan {
            background: var(--cyan-100);
        }

        .icon-cyan svg {
            color: var(--cyan-600);
        }

        /* ============================================ */
        /* STEPS                                        */
        /* ============================================ */
        .steps {
            background: #fff;
        }

        .steps-row {
            position: relative;
        }

        .steps-line {
            display: none;
            position: absolute;
            top: 50px;
            left: 16%;
            right: 16%;
            height: 2px;
            background: linear-gradient(90deg, var(--brand-200), var(--brand-400), var(--brand-200));
            z-index: 0;
        }

        @media(min-width:1024px) {
            .steps-line {
                display: block;
            }
        }

        .step {
            text-align: center;
            position: relative;
            z-index: 1;
        }

        .step-icon-wrap {
            display: inline-flex;
            position: relative;
            margin-bottom: 32px;
        }

        .step-icon {
            width: 96px;
            height: 96px;
            border-radius: var(--radius-3xl);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .step-icon svg {
            width: 48px;
            height: 48px;
        }

        .step-num {
            position: absolute;
            top: -8px;
            right: -8px;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            font-weight: 700;
            color: #fff;
            box-shadow: var(--shadow-lg);
        }

        .step h3 {
            font-size: 20px;
            font-weight: 700;
            margin-bottom: 12px;
        }

        .step p {
            color: var(--gray-500);
            max-width: 300px;
            margin: 0 auto;
            line-height: 1.7;
            font-size: 15px;
        }

        .step-green .step-icon {
            background: var(--brand-100);
            transform: rotate(3deg);
        }

        .step-green .step-icon svg {
            color: var(--brand-600);
        }

        .step-green .step-num {
            background: var(--brand-600);
        }

        .step-blue .step-icon {
            background: var(--blue-100);
            transform: rotate(-2deg);
        }

        .step-blue .step-icon svg {
            color: var(--blue-600);
        }

        .step-blue .step-num {
            background: var(--blue-600);
        }

        .step-amber .step-icon {
            background: var(--amber-100);
            transform: rotate(2deg);
        }

        .step-amber .step-icon svg {
            color: var(--amber-600);
        }

        .step-amber .step-num {
            background: var(--amber-600);
        }

        /* ============================================ */
        /* APPS                                         */
        /* ============================================ */
        .apps {
            background: linear-gradient(180deg, var(--gray-50), #fff);
        }

        .app-card {
            border-radius: var(--radius-3xl);
            padding: 32px;
            color: #fff;
            position: relative;
            overflow: hidden;
            transition: transform .4s ease, box-shadow .4s ease;
        }

        .app-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, .2);
        }

        .app-card-bg1,
        .app-card-bg2 {
            position: absolute;
            border-radius: 50%;
            background: rgba(255, 255, 255, .06);
        }

        .app-card-bg1 {
            width: 160px;
            height: 160px;
            top: -40px;
            right: -40px;
        }

        .app-card-bg2 {
            width: 128px;
            height: 128px;
            bottom: -40px;
            left: -40px;
        }

        .app-green {
            background: linear-gradient(135deg, var(--brand-600), var(--brand-800));
        }

        .app-blue {
            background: linear-gradient(135deg, var(--blue-600), var(--blue-800));
        }

        .app-amber {
            background: linear-gradient(135deg, var(--amber-500), var(--orange-600));
        }

        .app-card-inner {
            position: relative;
            z-index: 2;
        }

        .app-icon-box {
            width: 64px;
            height: 64px;
            background: rgba(255, 255, 255, .2);
            backdrop-filter: blur(8px);
            border-radius: var(--radius-2xl);
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 24px;
            transition: transform .3s;
        }

        .app-card:hover .app-icon-box {
            transform: scale(1.1);
        }

        .app-icon-box svg {
            width: 32px;
            height: 32px;
            color: #fff;
        }

        .app-tag {
            display: inline-block;
            padding: 4px 12px;
            background: rgba(255, 255, 255, .2);
            border-radius: var(--radius-full);
            font-size: 12px;
            font-weight: 700;
            margin-bottom: 16px;
        }

        .app-card h3 {
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 12px;
        }

        .app-card>.app-card-inner>p {
            color: rgba(255, 255, 255, .8);
            margin-bottom: 24px;
            line-height: 1.7;
            font-size: 15px;
        }

        .app-list {
            display: flex;
            flex-direction: column;
            gap: 10px;
            margin-bottom: 32px;
        }

        .app-list li {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 14px;
            color: rgba(255, 255, 255, .9);
        }

        .app-list li svg {
            width: 16px;
            height: 16px;
            flex-shrink: 0;
        }

        .app-card-link {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            font-weight: 600;
            color: #fff;
            transition: gap .3s;
        }

        .app-card:hover .app-card-link {
            gap: 12px;
        }

        .app-card-link svg {
            width: 16px;
            height: 16px;
        }

        /* ============================================ */
        /* TESTIMONIALS                                 */
        /* ============================================ */
        .testimonials {
            background: #fff;
        }

        .testimonial-card {
            background: var(--gray-50);
            border-radius: var(--radius-2xl);
            padding: 32px;
            border: 1px solid var(--gray-100);
            position: relative;
            transition: transform .4s ease;
        }

        .testimonial-card:hover {
            transform: scale(1.03);
        }

        .testimonial-quote {
            position: absolute;
            top: 24px;
            right: 32px;
        }

        .testimonial-quote svg {
            width: 40px;
            height: 40px;
        }

        .stars {
            display: flex;
            gap: 4px;
            margin-bottom: 16px;
        }

        .stars svg {
            width: 20px;
            height: 20px;
            color: var(--amber-400);
        }

        .testimonial-card blockquote {
            color: var(--gray-600);
            line-height: 1.7;
            margin-bottom: 24px;
            font-size: 15px;
        }

        .testimonial-author {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .avatar {
            width: 48px;
            height: 48px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 18px;
        }

        .avatar-green {
            background: var(--brand-200);
            color: var(--brand-700);
        }

        .avatar-blue {
            background: var(--blue-100);
            color: var(--blue-600);
        }

        .avatar-amber {
            background: var(--amber-200);
            color: var(--amber-700);
        }

        .author-name {
            font-weight: 700;
            font-size: 14px;
        }

        .author-role {
            font-size: 12px;
            color: var(--gray-400);
        }

        /* ============================================ */
        /* FAQ                                          */
        /* ============================================ */
        .faq {
            background: var(--gray-50);
        }

        .faq-list {
            max-width: 720px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .faq-item {
            background: #fff;
            border-radius: var(--radius-2xl);
            border: 1px solid var(--gray-100);
            overflow: hidden;
        }

        .faq-toggle {
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 24px;
            text-align: left;
            font-weight: 600;
            color: var(--gray-800);
            font-size: 16px;
            cursor: pointer;
            transition: background .2s;
        }

        .faq-toggle:hover {
            background: var(--gray-50);
        }

        .faq-chevron {
            width: 20px;
            height: 20px;
            color: var(--gray-400);
            flex-shrink: 0;
            transition: transform .3s ease;
        }

        .faq-answer {
            max-height: 0;
            overflow: hidden;
            padding: 0 24px;
            color: var(--gray-500);
            line-height: 1.7;
            font-size: 15px;
            transition: max-height .4s ease, padding .4s ease;
        }

        .faq-answer.open {
            max-height: 300px;
            padding: 0 24px 20px;
        }

        /* ============================================ */
        /* CTA                                          */
        /* ============================================ */
        .cta-section {
            padding: 96px 0;
            background: var(--brand-900);
            position: relative;
            overflow: hidden;
            text-align: center;
        }

        .cta-inner {
            position: relative;
            z-index: 5;
        }

        .cta-logo {
            width: 80px;
            height: 80px;
            border-radius: var(--radius-3xl);
            overflow: hidden;
            margin: 0 auto 32px;
            box-shadow: 0 0 30px rgba(16, 185, 129, .3);
        }

        .cta-logo img {
            width: 100%;
            height: 100%;
            object-fit: contain;
        }

        .cta-section h2 {
            font-size: clamp(28px, 5vw, 48px);
            font-weight: 900;
            color: #fff;
            line-height: 1.2;
            margin-bottom: 24px;
        }

        .cta-section h2 span {
            color: var(--brand-300);
        }

        .cta-section>.cta-inner>p {
            font-size: 18px;
            color: var(--brand-200);
            max-width: 640px;
            margin: 0 auto 40px;
            line-height: 1.7;
        }

        .store-buttons {
            display: flex;
            flex-wrap: wrap;
            gap: 16px;
            justify-content: center;
            margin-bottom: 48px;
        }

        .store-btn {
            display: flex;
            align-items: center;
            gap: 12px;
            background: rgba(255, 255, 255, .1);
            border: 1px solid rgba(255, 255, 255, .2);
            border-radius: var(--radius-2xl);
            padding: 12px 24px;
            backdrop-filter: blur(12px);
            transition: all .3s ease;
        }

        .store-btn:hover {
            background: rgba(255, 255, 255, .2);
            transform: translateY(-4px);
        }

        .store-btn svg {
            width: 28px;
            height: 28px;
            color: #fff;
            flex-shrink: 0;
        }

        .store-btn-text {
            text-align: left;
        }

        .store-btn-text small {
            font-size: 12px;
            color: rgba(255, 255, 255, .6);
        }

        .store-btn-text strong {
            display: block;
            font-size: 16px;
            color: #fff;
            font-weight: 700;
        }

        .cta-trust {
            display: flex;
            flex-wrap: wrap;
            justify-content: center;
            gap: 20px;
            font-size: 13px;
            color: rgba(255, 255, 255, .5);
        }

        .cta-trust span {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .cta-trust svg {
            width: 16px;
            height: 16px;
            flex-shrink: 0;
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
            border-radius: var(--radius-xl);
            overflow: hidden;
        }

        .footer-logo-icon img {
            width: 100%;
            height: 100%;
            object-fit: contain;
        }

        .footer-logo span,
        .footer-brand-text {
            font-size: 18px;
            font-weight: 700;
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
    </style>
</head>

<body>

    <!-- ============================================ -->
    <!-- NAVBAR                                       -->
    <!-- ============================================ -->
    <nav class="navbar" id="navbar">
        <div class="container">
            <div class="navbar-inner">
                <a href="#" class="navbar-logo">
                    <div class="navbar-logo-icon">
                        <img src="{{ asset('images/logo.png') }}" alt="DR-PHARMA">
                    </div>
                    <div class="navbar-brand"><span>DR</span><span>-</span><span>PHARMA</span></div>
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
                    <a href="#telecharger" class="btn btn-primary">Télécharger</a>
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
            <a href="#telecharger" class="btn btn-primary">Télécharger l'app</a>
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
                            <span class="badge-dot animate-pulse-soft"></span>
                            {{ $landing['hero_badge'] }}
                        </span>
                    </div>

                    <h1>{{ $landing['hero_title_line1'] }}<br><span
                            class="gradient-text">{{ $landing['hero_title_line2'] }}</span></h1>

                    <p>{{ $landing['hero_subtitle'] }}</p>

                    <div class="hero-actions">
                        <a href="{{ $landing['hero_cta_appstore_url'] }}" class="btn btn-primary">
                            <svg fill="currentColor" viewBox="0 0 24 24">
                                <path
                                    d="M17.05 20.28c-.98.95-2.05.88-3.08.41-1.09-.49-2.09-.51-3.24 0-1.44.64-2.2.52-3.06-.41C3.79 16.17 4.36 9.04 8.71 8.78c1.23.06 2.09.7 2.81.75.97-.2 1.9-.88 2.96-.8 1.27.1 2.23.58 2.86 1.48-2.57 1.55-1.97 4.96.34 5.92-.46 1.22-1.06 2.43-2.16 3.65l1.53.5zM12.03 8.7c-.13-2.27 1.75-4.2 3.97-4.38.28 2.5-2.29 4.54-3.97 4.38z" />
                            </svg>
                            App Store
                        </a>
                        <a href="{{ $landing['hero_cta_playstore_url'] }}" class="btn btn-dark">
                            <svg fill="currentColor" viewBox="0 0 24 24">
                                <path
                                    d="M3.18 23.49L14.66 12 3.18.51C2.93.74 2.75 1.13 2.75 1.65v20.7c0 .52.18.91.43 1.14zM19.26 10.32l-3.22-1.86L12.27 12l3.77 3.54 3.22-1.86c.58-.34.93-.84.93-1.36s-.35-1.02-.93-1.36v-.64zM5.03 1.34l10.04 5.78L12.27 12 5.03 1.34zM5.03 22.66L12.27 12l2.8 5.12L5.03 22.66z" />
                            </svg>
                            Google Play
                        </a>
                    </div>

                    <div class="trust-row">
                        <span class="trust-item">
                            <svg fill="currentColor" viewBox="0 0 20 20">
                                <path fill-rule="evenodd"
                                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                                    clip-rule="evenodd" />
                            </svg>
                            {{ $landing['hero_trust_1'] }}
                        </span>
                        <span class="trust-item">
                            <svg fill="currentColor" viewBox="0 0 20 20">
                                <path fill-rule="evenodd"
                                    d="M2.166 4.999A11.954 11.954 0 0010 1.944 11.954 11.954 0 0017.834 5c.11.65.166 1.32.166 2.001 0 5.225-3.34 9.67-8 11.317C5.34 16.67 2 12.225 2 7c0-.682.057-1.35.166-2.001zm11.541 3.708a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                                    clip-rule="evenodd" />
                            </svg>
                            {{ $landing['hero_trust_2'] }}
                        </span>
                        <span class="trust-item">
                            <svg fill="currentColor" viewBox="0 0 20 20">
                                <path fill-rule="evenodd"
                                    d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z"
                                    clip-rule="evenodd" />
                            </svg>
                            {{ $landing['hero_trust_3'] }}
                        </span>
                    </div>
                </div>

                <div class="hero-phone-wrap">
                    <div class="phone">
                        <div class="phone-content">
                            <div class="phone-logo-box">
                                <img src="{{ asset('images/logo.png') }}" alt="DR-PHARMA">
                            </div>
                            <h3>{{ $landing['hero_phone_title'] }}</h3>
                            <p class="phone-sub">{{ $landing['hero_phone_subtitle'] }}</p>
                            <div class="phone-cards">
                                <div class="phone-card">
                                    <div class="phone-card-icon"><svg fill="none" stroke="currentColor"
                                            stroke-width="2" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                                        </svg></div>
                                    <div>
                                        <p>Rechercher</p>
                                        <p>Trouvez votre médicament</p>
                                    </div>
                                </div>
                                <div class="phone-card">
                                    <div class="phone-card-icon"><svg fill="none" stroke="currentColor"
                                            stroke-width="2" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 100 4 2 2 0 000-4z" />
                                        </svg></div>
                                    <div>
                                        <p>Commander</p>
                                        <p>Livraison rapide</p>
                                    </div>
                                </div>
                                <div class="phone-card">
                                    <div class="phone-card-icon"><svg fill="none" stroke="currentColor"
                                            stroke-width="2" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round"
                                                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                        </svg></div>
                                    <div>
                                        <p>Suivi en temps réel</p>
                                        <p>GPS intégré</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="hero-wave">
            <svg viewBox="0 0 1440 120" fill="none">
                <path
                    d="M0 60L48 54C96 48 192 36 288 42C384 48 480 72 576 78C672 84 768 72 864 60C960 48 1056 36 1152 36C1248 36 1344 48 1392 54L1440 60V120H0V60Z"
                    fill="white" />
            </svg>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- STATS                                        -->
    <!-- ============================================ -->
    <section class="stats">
        <div class="container">
            <div class="stats-grid reveal">
                @foreach ($landing['stats'] as $stat)
                    <div class="stat">
                        <div class="stat-number"><span class="counter"
                                data-target="{{ $stat['value'] }}">0</span>{{ $stat['suffix'] }}</div>
                        <p class="stat-label">{{ $stat['label'] }}</p>
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
                <span class="badge">{{ $landing['features_badge'] }}</span>
                <h2 class="section-title">{!! str_replace(
                    $landing['features_title_highlight'],
                    '<span class="gradient-text">' . e($landing['features_title_highlight']) . '</span>',
                    e($landing['features_title']),
                ) !!}</h2>
                <p class="section-subtitle">{{ $landing['features_subtitle'] }}</p>
            </div>

            @php
                $featureIcons = [
                    'green' =>
                        '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>',
                    'blue' =>
                        '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>',
                    'amber' =>
                        '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>',
                    'purple' =>
                        '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>',
                    'rose' =>
                        '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>',
                    'cyan' =>
                        '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>',
                ];
            @endphp

            <div class="grid-3">
                @foreach ($landing['features'] as $feature)
                    <div class="feature-card reveal">
                        <div class="feature-icon icon-{{ $feature['icon_color'] }}">
                            {!! $featureIcons[$feature['icon_color']] ?? $featureIcons['green'] !!}
                        </div>
                        <h3>{{ $feature['title'] }}</h3>
                        <p>{{ $feature['description'] }}</p>
                    </div>
                @endforeach
            </div>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- COMMENT CA MARCHE                            -->
    <!-- ============================================ -->
    <section id="comment-ca-marche" class="section steps">
        <div class="container">
            <div class="section-header reveal">
                <span class="badge">{{ $landing['steps_badge'] }}</span>
                <h2 class="section-title">{!! str_replace(
                    $landing['steps_title_highlight'],
                    '<span class="gradient-text">' . e($landing['steps_title_highlight']) . '</span>',
                    e($landing['steps_title']),
                ) !!}</h2>
                <p class="section-subtitle">{{ $landing['steps_subtitle'] }}</p>
            </div>

            @php
                $stepIcons = [
                    '<svg fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>',
                    '<svg fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 100 4 2 2 0 000-4z"/></svg>',
                    '<svg fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"/></svg>',
                ];
            @endphp

            <div class="steps-row">
                <div class="steps-line"></div>
                <div class="grid-3">
                    @foreach ($landing['steps'] as $index => $step)
                        <div class="step step-{{ $step['color'] }} reveal">
                            <div class="step-icon-wrap">
                                <div class="step-icon">
                                    {!! $stepIcons[$index] ?? $stepIcons[0] !!}
                                </div>
                                <div class="step-num">{{ $index + 1 }}</div>
                            </div>
                            <h3>{{ $step['title'] }}</h3>
                            <p>{{ $step['description'] }}</p>
                        </div>
                    @endforeach
                </div>
            </div>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- APPLICATIONS                                 -->
    <!-- ============================================ -->
    <section id="applications" class="section apps">
        <div class="container">
            <div class="section-header reveal">
                <span class="badge">{{ $landing['apps_badge'] }}</span>
                <h2 class="section-title">{!! str_replace(
                    $landing['apps_title_highlight'],
                    '<span class="gradient-text">' . e($landing['apps_title_highlight']) . '</span>',
                    e($landing['apps_title']),
                ) !!}</h2>
                <p class="section-subtitle">{{ $landing['apps_subtitle'] }}</p>
            </div>

            @php
                $appIcons = [
                    'green' =>
                        '<svg fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"/></svg>',
                    'blue' =>
                        '<svg fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3H21m-3.75 3H21"/></svg>',
                    'amber' =>
                        '<svg fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M8.25 18.75a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 01-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 00-3.213-9.193 2.056 2.056 0 00-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 00-10.026 0 1.106 1.106 0 00-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"/></svg>',
                ];
                $checkSvg =
                    '<svg fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>';
                $arrowSvg =
                    '<svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3"/></svg>';
            @endphp

            <div class="grid-3">
                @foreach ($landing['apps'] as $app)
                    <div class="app-card app-{{ $app['color'] }} reveal">
                        <div class="app-card-bg1"></div>
                        <div class="app-card-bg2"></div>
                        <div class="app-card-inner">
                            <div class="app-icon-box">
                                {!! $appIcons[$app['color']] ?? $appIcons['green'] !!}
                            </div>
                            <span class="app-tag">{{ $app['tag'] }}</span>
                            <h3>{{ $app['title'] }}</h3>
                            <p>{{ $app['description'] }}</p>
                            <ul class="app-list">
                                @foreach (explode('|', $app['features']) as $feat)
                                    <li>{!! $checkSvg !!}{{ trim($feat) }}</li>
                                @endforeach
                            </ul>
                            <a href="#telecharger" class="app-card-link">Télécharger {!! $arrowSvg !!}</a>
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
                <span class="badge">{{ $landing['testimonials_badge'] }}</span>
                <h2 class="section-title">{!! str_replace(
                    $landing['testimonials_title_highlight'],
                    '<span class="gradient-text">' . e($landing['testimonials_title_highlight']) . '</span>',
                    e($landing['testimonials_title']),
                ) !!}</h2>
            </div>

            @php
                $quoteColors = [
                    'green' => 'var(--brand-200)',
                    'blue' => 'var(--blue-100)',
                    'amber' => 'var(--amber-200)',
                ];
                $quoteSvg =
                    '<svg fill="currentColor" viewBox="0 0 24 24"><path d="M14.017 21v-7.391c0-5.704 3.731-9.57 8.983-10.609l.995 2.151c-2.432.917-3.995 3.638-3.995 5.849h4v10H14.017zm-14.017 0v-7.391c0-5.704 3.748-9.57 9-10.609l.996 2.151C7.563 6.068 6 8.789 6 11h4v10H0z"/></svg>';
                $starSvg =
                    '<svg fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>';
            @endphp

            <div class="grid-3">
                @foreach ($landing['testimonials'] as $testimonial)
                    <div class="testimonial-card reveal">
                        <div class="testimonial-quote"
                            style="color: {{ $quoteColors[$testimonial['color']] ?? $quoteColors['green'] }};">
                            {!! $quoteSvg !!}
                        </div>
                        <div class="stars">
                            @for ($i = 0; $i < ($testimonial['rating'] ?? 5); $i++)
                                {!! $starSvg !!}
                            @endfor
                        </div>
                        <blockquote>"{{ $testimonial['quote'] }}"</blockquote>
                        <div class="testimonial-author">
                            <div class="avatar avatar-{{ $testimonial['color'] }}">{{ $testimonial['initials'] }}
                            </div>
                            <div>
                                <p class="author-name">{{ $testimonial['name'] }}</p>
                                <p class="author-role">{{ $testimonial['role'] }}</p>
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
    <section id="faq" class="section faq">
        <div class="container">
            <div class="section-header reveal">
                <span class="badge">{{ $landing['faq_badge'] }}</span>
                <h2 class="section-title">{!! str_replace(
                    $landing['faq_title_highlight'],
                    '<span class="gradient-text">' . e($landing['faq_title_highlight']) . '</span>',
                    e($landing['faq_title']),
                ) !!}</h2>
            </div>

            <div class="faq-list reveal">
                @foreach ($landing['faqs'] as $faq)
                    <div class="faq-item">
                        <button class="faq-toggle">
                            <span>{{ $faq['question'] }}</span>
                            <svg class="faq-chevron" fill="none" stroke="currentColor" stroke-width="2"
                                viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                            </svg>
                        </button>
                        <div class="faq-answer">{{ $faq['answer'] }}</div>
                    </div>
                @endforeach
            </div>
        </div>
    </section>


    <!-- ============================================ -->
    <!-- CTA / TELECHARGER                            -->
    <!-- ============================================ -->
    <section id="telecharger" class="cta-section">
        <div class="container">
            <div class="cta-inner reveal">
                <div class="cta-logo">
                    <img src="{{ asset('images/logo.png') }}" alt="DR-PHARMA">
                </div>
                <h2>{!! str_replace(
                    $landing['cta_highlight'],
                    '<span>' . e($landing['cta_highlight']) . '</span>',
                    e($landing['cta_title_line1'] . ' ' . $landing['cta_title_line2']),
                ) !!}</h2>
                <p>{{ $landing['cta_subtitle'] }}</p>
                <div class="store-buttons">
                    <a href="{{ $landing['cta_appstore_url'] }}" class="store-btn">
                        <svg fill="currentColor" viewBox="0 0 24 24">
                            <path
                                d="M17.05 20.28c-.98.95-2.05.88-3.08.41-1.09-.49-2.09-.51-3.24 0-1.44.64-2.2.52-3.06-.41C3.79 16.17 4.36 9.04 8.71 8.78c1.23.06 2.09.7 2.81.75.97-.2 1.9-.88 2.96-.8 1.27.1 2.23.58 2.86 1.48-2.57 1.55-1.97 4.96.34 5.92-.46 1.22-1.06 2.43-2.16 3.65l1.53.5zM12.03 8.7c-.13-2.27 1.75-4.2 3.97-4.38.28 2.5-2.29 4.54-3.97 4.38z" />
                        </svg>
                        <div class="store-btn-text"><small>Télécharger sur</small><strong>App Store</strong></div>
                    </a>
                    <a href="{{ $landing['cta_playstore_url'] }}" class="store-btn">
                        <svg fill="currentColor" viewBox="0 0 24 24">
                            <path
                                d="M3.18 23.49L14.66 12 3.18.51C2.93.74 2.75 1.13 2.75 1.65v20.7c0 .52.18.91.43 1.14zM19.26 10.32l-3.22-1.86L12.27 12l3.77 3.54 3.22-1.86c.58-.34.93-.84.93-1.36s-.35-1.02-.93-1.36v-.64zM5.03 1.34l10.04 5.78L12.27 12 5.03 1.34zM5.03 22.66L12.27 12l2.8 5.12L5.03 22.66z" />
                        </svg>
                        <div class="store-btn-text"><small>Disponible sur</small><strong>Google Play</strong></div>
                    </a>
                </div>
                <div class="cta-trust">
                    <span><svg fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd"
                                d="M2.166 4.999A11.954 11.954 0 0010 1.944 11.954 11.954 0 0017.834 5c.11.65.166 1.32.166 2.001 0 5.225-3.34 9.67-8 11.317C5.34 16.67 2 12.225 2 7c0-.682.057-1.35.166-2.001zm11.541 3.708a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                                clip-rule="evenodd" />
                        </svg> {{ $landing['cta_trust_1'] }}</span>
                    <span><svg fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd"
                                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                                clip-rule="evenodd" />
                        </svg> {{ $landing['cta_trust_2'] }}</span>
                    <span><svg fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd"
                                d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z"
                                clip-rule="evenodd" />
                        </svg> {{ $landing['cta_trust_3'] }}</span>
                    <span><svg fill="currentColor" viewBox="0 0 20 20">
                            <path
                                d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                        </svg> {{ $landing['cta_trust_4'] }}</span>
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
                    <div class="footer-logo">
                        <div class="footer-logo-icon">
                            <img src="{{ asset('images/logo.png') }}" alt="DR-PHARMA">
                        </div>
                        <span class="footer-brand-text"><span style="color:#fff">DR</span><span
                                style="color:var(--gray-500)">-</span><span
                                style="color:var(--brand-400)">PHARMA</span></span>
                    </div>
                    <p>{{ $landing['footer_description'] }}</p>
                    <div class="social-links">
                        <a href="{{ $landing['footer_facebook_url'] }}" class="social-link" target="_blank"
                            rel="noopener noreferrer" aria-label="Facebook"><svg viewBox="0 0 24 24">
                                <path
                                    d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
                            </svg></a>
                    </div>
                </div>

                <div class="footer-col">
                    <h4>Produits</h4>
                    <ul>
                        <li><a href="#applications">App Patient</a></li>
                        <li><a href="#applications">App Pharmacien</a></li>
                        <li><a href="#applications">App Coursier</a></li>
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
                        <li><a href="/contact">Contact</a></li>
                        <li><a href="/confidentialite">Confidentialité</a></li>
                        <li><a href="/cgu">CGU</a></li>
                    </ul>
                </div>
            </div>

            <div class="footer-contact">
                <a href="mailto:{{ $landing['footer_email'] }}">
                    <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                    {{ $landing['footer_email'] }}
                </a>
                <a href="tel:{{ str_replace(' ', '', $landing['footer_phone']) }}">
                    <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                    </svg>
                    {{ $landing['footer_phone'] }}
                </a>
                <span>
                    <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    {{ $landing['footer_address'] }}
                </span>
            </div>

            <div class="footer-bottom">
                {{ $landing['footer_copyright'] }}
            </div>
        </div>
    </footer>


    <!-- ============================================ -->
    <!-- JAVASCRIPT                                   -->
    <!-- ============================================ -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {

            // Navbar scroll
            var navbar = document.getElementById('navbar');
            window.addEventListener('scroll', function() {
                if (window.pageYOffset > 50) {
                    navbar.classList.add('scrolled');
                } else {
                    navbar.classList.remove('scrolled');
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

            // Reveal on scroll
            var reveals = document.querySelectorAll('.reveal');
            var observer = new IntersectionObserver(function(entries) {
                entries.forEach(function(entry) {
                    if (entry.isIntersecting) entry.target.classList.add('active');
                });
            }, {
                threshold: 0.1,
                rootMargin: '0px 0px -60px 0px'
            });
            reveals.forEach(function(el) {
                observer.observe(el);
            });

            // Counter animation
            var counters = document.querySelectorAll('.counter');
            var done = false;
            var cObserver = new IntersectionObserver(function(entries) {
                entries.forEach(function(entry) {
                    if (entry.isIntersecting && !done) {
                        done = true;
                        counters.forEach(function(c) {
                            var target = parseInt(c.getAttribute('data-target'));
                            var dur = 2000,
                                step = target / (dur / 16),
                                cur = 0;
                            (function tick() {
                                cur += step;
                                if (cur < target) {
                                    c.textContent = Math.ceil(cur).toLocaleString(
                                        'fr-FR');
                                    requestAnimationFrame(tick);
                                } else {
                                    c.textContent = target.toLocaleString('fr-FR');
                                }
                            })();
                        });
                    }
                });
            }, {
                threshold: 0.5
            });
            counters.forEach(function(c) {
                cObserver.observe(c);
            });

            // FAQ
            document.querySelectorAll('.faq-toggle').forEach(function(btn) {
                btn.addEventListener('click', function() {
                    var item = btn.parentElement;
                    var answer = item.querySelector('.faq-answer');
                    var chevron = btn.querySelector('.faq-chevron');
                    var isOpen = answer.classList.contains('open');
                    document.querySelectorAll('.faq-answer').forEach(function(a) {
                        a.classList.remove('open');
                    });
                    document.querySelectorAll('.faq-chevron').forEach(function(c) {
                        c.style.transform = '';
                    });
                    if (!isOpen) {
                        answer.classList.add('open');
                        chevron.style.transform = 'rotate(180deg)';
                    }
                });
            });

            // Smooth scroll
            document.querySelectorAll('a[href^="#"]').forEach(function(a) {
                a.addEventListener('click', function(e) {
                    var href = a.getAttribute('href');
                    if (href === '#') return;
                    e.preventDefault();
                    var t = document.querySelector(href);
                    if (t) {
                        var pos = t.getBoundingClientRect().top + window.pageYOffset - 80;
                        window.scrollTo({
                            top: pos,
                            behavior: 'smooth'
                        });
                    }
                });
            });
        });
    </script>

</body>

</html>
