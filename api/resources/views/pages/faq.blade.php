@extends('layouts.page')

@section('title', e($heroTitle) . ' — DR PHARMA')
@section('meta_description',
    'Questions fréquentes sur DR-PHARMA : commandes, paiements, livraison, compte et plus
    encore.')

@section('styles')
    .content { padding: 64px 0 96px; }
    .content .container { max-width: 800px; }

    .search-box {
    display: flex; align-items: center; gap: 12px;
    background: var(--gray-50); border: 2px solid var(--gray-200);
    border-radius: 16px; padding: 16px 20px; margin-bottom: 32px;
    transition: border-color .2s;
    }
    .search-box:focus-within { border-color: var(--brand-500); }
    .search-box svg { width: 20px; height: 20px; color: var(--gray-400); flex-shrink: 0; }
    .search-box input {
    border: none; background: none; width: 100%; font-size: 16px;
    font-family: inherit; color: var(--gray-800); outline: none;
    }
    .search-box input::placeholder { color: var(--gray-400); }

    .faq-tabs {
    display: flex; gap: 8px; justify-content: center;
    flex-wrap: wrap; margin-bottom: 40px;
    }
    .faq-tab {
    padding: 8px 20px; border-radius: var(--radius-full);
    font-size: 14px; font-weight: 600; color: var(--gray-600);
    background: var(--gray-100); cursor: pointer;
    border: none; font-family: inherit; transition: all .2s;
    }
    .faq-tab:hover, .faq-tab.active {
    background: var(--brand-100); color: var(--brand-700);
    }

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
    .faq-a.open { max-height: 500px; padding: 16px 20px; }

    .no-results {
    text-align: center; padding: 48px 0; color: var(--gray-400);
    display: none;
    }
    .no-results svg { width: 48px; height: 48px; margin: 0 auto 16px; }
    .no-results p { font-size: 16px; }

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
            <h1>{{ $heroTitle }}</h1>
            <p>{{ $heroSubtitle }}</p>
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

            @php
                $filters = collect($categories)->pluck('filter')->unique()->values();
                $filterLabels = [
                    'patient' => 'Patients',
                    'pharmacien' => 'Pharmaciens',
                    'coursier' => 'Coursiers',
                    'paiement' => 'Paiements',
                ];
            @endphp
            <div class="faq-tabs">
                <button class="faq-tab active" onclick="filterCategory('all', this)">Tout</button>
                @foreach ($filters as $filter)
                    <button class="faq-tab"
                        onclick="filterCategory('{{ e($filter) }}', this)">{{ $filterLabels[$filter] ?? ucfirst($filter) }}</button>
                @endforeach
            </div>

            @foreach ($categories as $cat)
                <div class="faq-section" data-section data-category="{{ e($cat['filter']) }}">
                    <h2>{{ $cat['icon'] }} {{ $cat['title'] }}</h2>
                    @foreach ($cat['questions'] as $qa)
                        <div class="faq-item" data-faq>
                            <button class="faq-q" onclick="toggleFaq(this)">{{ $qa['question'] }} <svg viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                                </svg></button>
                            <div class="faq-a">{{ $qa['answer'] }}</div>
                        </div>
                    @endforeach
                </div>
            @endforeach

            <div id="no-results" class="no-results">
                <svg fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                    <circle cx="11" cy="11" r="8" />
                    <path stroke-linecap="round" d="M21 21l-4.35-4.35" />
                </svg>
                <p>Aucune question trouvée pour votre recherche.</p>
            </div>

            <div class="help-contact">
                <h3>Vous ne trouvez pas la réponse ?</h3>
                <p>Notre équipe support est là pour vous aider.</p>
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
            var anyVisible = false;
            document.querySelectorAll('[data-faq]').forEach(function(item) {
                var visible = item.textContent.toLowerCase().includes(q);
                item.style.display = visible ? '' : 'none';
                if (visible) anyVisible = true;
            });
            document.querySelectorAll('[data-section]').forEach(function(section) {
                var visible = section.querySelectorAll('[data-faq]:not([style*="display: none"])');
                section.style.display = visible.length ? '' : 'none';
            });
            document.getElementById('no-results').style.display = anyVisible ? 'none' : 'block';
        }

        function filterCategory(category, btn) {
            document.querySelectorAll('.faq-tab').forEach(function(t) {
                t.classList.remove('active');
            });
            btn.classList.add('active');
            document.getElementById('search').value = '';
            document.querySelectorAll('[data-section]').forEach(function(section) {
                if (category === 'all') {
                    section.style.display = '';
                } else {
                    section.style.display = section.dataset.category === category ? '' : 'none';
                }
            });
            document.querySelectorAll('[data-faq]').forEach(function(item) {
                item.style.display = '';
            });
            document.getElementById('no-results').style.display = 'none';
        }
    </script>
@endsection
