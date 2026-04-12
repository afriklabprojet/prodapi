@extends('layouts.page')

@section('title', e($heroTitle) . ' — DR PHARMA')
@section('meta_description',
    'Guide complet pour utiliser l\'application DR-PHARMA Pharmacie : gestion des commandes,
    stock, mode garde et bien plus.')

@section('styles')
    .content { padding: 64px 0 96px; }
    .content .container { max-width: 900px; }

    .guide-intro {
    text-align: center; margin-bottom: 48px;
    font-size: 16px; color: var(--gray-500); line-height: 1.8;
    }

    .guide-nav {
    display: flex; flex-wrap: wrap; gap: 8px;
    justify-content: center; margin-bottom: 48px;
    }
    .guide-nav a {
    padding: 8px 20px; border-radius: var(--radius-full);
    font-size: 14px; font-weight: 600; color: var(--gray-600);
    background: var(--gray-100); transition: all .2s;
    }
    .guide-nav a:hover, .guide-nav a.active {
    background: var(--brand-100); color: var(--brand-700);
    }

    .guide-section {
    margin-bottom: 56px; scroll-margin-top: 100px;
    }
    .guide-section-header {
    display: flex; align-items: center; gap: 16px;
    margin-bottom: 24px; padding-bottom: 16px;
    border-bottom: 2px solid var(--brand-100);
    }
    .guide-section-icon {
    width: 48px; height: 48px; border-radius: var(--radius-xl);
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0; font-size: 24px;
    }
    .guide-section-icon.green { background: var(--brand-100); color: var(--brand-700); }
    .guide-section-icon.blue { background: #dbeafe; color: #1d4ed8; }
    .guide-section-icon.amber { background: #fef3c7; color: #b45309; }
    .guide-section-icon.purple { background: #ede9fe; color: #6d28d9; }
    .guide-section-icon.rose { background: #ffe4e6; color: #be123c; }
    .guide-section-icon.cyan { background: #cffafe; color: #0e7490; }

    .guide-section h2 {
    font-size: 22px; font-weight: 800; color: var(--gray-900);
    }
    .guide-section h2 small {
    display: block; font-size: 13px; font-weight: 500;
    color: var(--gray-400); margin-top: 4px;
    }

    .guide-step {
    background: var(--gray-50); border-radius: var(--radius-xl);
    padding: 24px; margin-bottom: 16px;
    border: 1px solid var(--gray-100);
    }
    .guide-step h3 {
    font-size: 16px; font-weight: 700; color: var(--gray-800);
    margin-bottom: 8px; display: flex; align-items: center; gap: 10px;
    }
    .guide-step h3 .step-num {
    width: 28px; height: 28px; border-radius: 50%;
    background: var(--brand-600); color: #fff;
    display: flex; align-items: center; justify-content: center;
    font-size: 13px; font-weight: 800; flex-shrink: 0;
    }
    .guide-step .step-content {
    font-size: 14px; line-height: 1.8; color: var(--gray-600);
    margin-left: 38px;
    }
    .guide-step .step-content ul { margin-top: 8px; }
    .guide-step .step-content ul li {
    padding-left: 20px; position: relative;
    }
    .guide-step .step-content ul li::before {
    content: '✓'; position: absolute; left: 0;
    color: var(--brand-600); font-weight: 700;
    }

    .guide-tip {
    background: var(--brand-50); border-left: 4px solid var(--brand-500);
    border-radius: 0 var(--radius-lg) var(--radius-lg) 0;
    padding: 16px 20px; margin-top: 16px; margin-bottom: 16px;
    font-size: 14px; color: var(--brand-800); line-height: 1.7;
    }
    .guide-tip strong { color: var(--brand-700); }

    .guide-cta {
    text-align: center; padding: 48px 32px;
    background: var(--brand-50); border-radius: var(--radius-2xl);
    margin-top: 32px;
    }
    .guide-cta h3 {
    font-size: 20px; font-weight: 800; color: var(--gray-900);
    margin-bottom: 8px;
    }
    .guide-cta p { color: var(--gray-500); margin-bottom: 20px; }
    .guide-cta-links { display: flex; gap: 12px; justify-content: center; flex-wrap: wrap; }
    .guide-cta-links a {
    display: inline-flex; align-items: center; gap: 8px;
    padding: 12px 28px; border-radius: var(--radius-xl);
    font-weight: 700; font-size: 15px; transition: all .2s;
    }
    .guide-cta-links .btn-primary { background: var(--brand-600); color: #fff; }
    .guide-cta-links .btn-primary:hover { background: var(--brand-700); }
    .guide-cta-links .btn-secondary {
    background: #fff; color: var(--brand-700);
    border: 2px solid var(--brand-200);
    }
    .guide-cta-links .btn-secondary:hover { background: var(--brand-100); }
@endsection

@section('content')
    <section class="page-hero">
        <div class="container">
            <h1>{{ $heroTitle }}</h1>
            <p>{{ $heroSubtitle }}</p>
        </div>
    </section>

    <section class="content">
        <div class="container">

            @if ($intro)
                <p class="guide-intro">{!! $intro !!}</p>
            @endif

            <div class="guide-nav">
                @foreach ($sections as $section)
                    <a href="#{{ $section['id'] }}">{{ $section['title'] }}</a>
                @endforeach
            </div>

            @foreach ($sections as $section)
                <div class="guide-section" id="{{ $section['id'] }}">
                    <div class="guide-section-header">
                        <div class="guide-section-icon {{ $section['color'] }}">{{ $section['icon'] }}</div>
                        <h2>{{ $section['title'] }} <small>{{ $section['subtitle'] ?? '' }}</small></h2>
                    </div>

                    @foreach ($section['steps'] as $stepIndex => $step)
                        <div class="guide-step">
                            <h3><span class="step-num">{{ $stepIndex + 1 }}</span> {{ $step['title'] }}</h3>
                            <div class="step-content">{!! $step['content'] !!}</div>
                        </div>
                    @endforeach

                    @if (!empty($section['tip']))
                        <div class="guide-tip">
                            <strong>💡 Astuce :</strong> {{ $section['tip'] }}
                        </div>
                    @endif
                </div>
            @endforeach

            {{-- ===== CTA ===== --}}
            <div class="guide-cta">
                <h3>Besoin d'aide supplémentaire ?</h3>
                <p>Consultez notre FAQ ou contactez notre équipe support.</p>
                <div class="guide-cta-links">
                    <a href="/aide" class="btn-primary">
                        <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" width="18"
                            height="18">
                            <circle cx="12" cy="12" r="10" />
                            <path stroke-linecap="round" d="M9.09 9a3 3 0 015.83 1c0 2-3 3-3 3" />
                            <path stroke-linecap="round" d="M12 17h.01" />
                        </svg>
                        Centre d'aide
                    </a>
                    <a href="/contact" class="btn-secondary">
                        <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" width="18"
                            height="18">
                            <path stroke-linecap="round" stroke-linejoin="round"
                                d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                        </svg>
                        Contactez-nous
                    </a>
                </div>
            </div>

        </div>
    </section>
@endsection

@section('scripts')
    <script>
        document.querySelectorAll('.guide-nav a').forEach(function(link) {
            link.addEventListener('click', function(e) {
                var href = this.getAttribute('href');
                if (href.startsWith('#')) {
                    e.preventDefault();
                    var target = document.querySelector(href);
                    if (target) {
                        target.scrollIntoView({
                            behavior: 'smooth'
                        });
                        document.querySelectorAll('.guide-nav a').forEach(function(a) {
                            a.classList.remove('active');
                        });
                        this.classList.add('active');
                    }
                }
            });
        });

        window.addEventListener('scroll', function() {
            var sections = document.querySelectorAll('.guide-section');
            var links = document.querySelectorAll('.guide-nav a');
            var current = '';
            sections.forEach(function(section) {
                var top = section.offsetTop;
                if (pageYOffset >= top - 150) {
                    current = section.getAttribute('id');
                }
            });
            links.forEach(function(link) {
                link.classList.remove('active');
                if (link.getAttribute('href') === '#' + current) {
                    link.classList.add('active');
                }
            });
        });
    </script>
@endsection
