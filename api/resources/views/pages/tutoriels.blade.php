@extends('layouts.page')

@section('title', e($heroTitle) . ' — DR PHARMA')
@section('meta_description',
    'Regardez nos tutoriels vidéo pour apprendre à utiliser DR-PHARMA : commandes, livraisons,
    gestion de pharmacie et plus.')

@section('styles')
    .content { padding: 64px 0 96px; }
    .content .container { max-width: 900px; }

    .tutorials-intro {
    text-align: center; margin-bottom: 48px;
    font-size: 16px; color: var(--gray-500); line-height: 1.8;
    }

    .video-grid {
    display: grid; grid-template-columns: 1fr;
    gap: 24px; margin-bottom: 48px;
    }
    @media(min-width: 640px) {
    .video-grid { grid-template-columns: 1fr 1fr; }
    }

    .video-card {
    border: 1px solid var(--gray-100); border-radius: var(--radius-2xl);
    overflow: hidden; background: #fff;
    transition: all .3s; box-shadow: var(--shadow-sm);
    text-decoration: none;
    }
    .video-card:hover {
    box-shadow: var(--shadow-lg); transform: translateY(-4px);
    }

    .video-thumb {
    position: relative; background: var(--gray-100);
    padding-top: 56.25%;
    }
    .video-thumb-inner {
    position: absolute; inset: 0;
    display: flex; align-items: center; justify-content: center;
    background: linear-gradient(135deg, var(--brand-100), var(--brand-200));
    }
    .video-thumb-inner svg {
    width: 56px; height: 56px; color: var(--brand-600);
    filter: drop-shadow(0 4px 12px rgba(5,150,105,.3));
    transition: transform .3s;
    }
    .video-card:hover .video-thumb-inner svg {
    transform: scale(1.1);
    }
    .video-badge {
    position: absolute; top: 12px; left: 12px;
    background: var(--brand-600); color: #fff;
    padding: 4px 12px; border-radius: var(--radius-full);
    font-size: 11px; font-weight: 700; text-transform: uppercase;
    }

    .video-info { padding: 20px; }
    .video-info h3 {
    font-size: 16px; font-weight: 700; color: var(--gray-800);
    margin-bottom: 6px;
    }
    .video-info p {
    font-size: 13px; color: var(--gray-500); line-height: 1.6;
    }

    .yt-cta {
    text-align: center; padding: 48px 32px;
    background: var(--brand-50); border-radius: var(--radius-2xl);
    }
    .yt-cta h3 {
    font-size: 20px; font-weight: 800; color: var(--gray-900);
    margin-bottom: 8px;
    }
    .yt-cta p { color: var(--gray-500); margin-bottom: 24px; }
    .yt-cta a {
    display: inline-flex; align-items: center; gap: 10px;
    padding: 14px 32px; background: #ff0000; color: #fff;
    border-radius: var(--radius-xl); font-weight: 700; font-size: 15px;
    transition: all .2s;
    }
    .yt-cta a:hover { background: #cc0000; transform: translateY(-2px); }
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
                <p class="tutorials-intro">{!! $intro !!}</p>
            @endif

            <div class="video-grid">
                @foreach ($videos as $video)
                    <a href="{{ $video['url'] ?? $youtubeUrl }}" target="_blank" rel="noopener" class="video-card">
                        <div class="video-thumb">
                            <div class="video-thumb-inner">
                                <svg viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M8 5v14l11-7z" />
                                </svg>
                                <span class="video-badge">{{ $video['badge'] }}</span>
                            </div>
                        </div>
                        <div class="video-info">
                            <h3>{{ $video['title'] }}</h3>
                            <p>{{ $video['description'] }}</p>
                        </div>
                    </a>
                @endforeach
            </div>

            <div class="yt-cta">
                <h3>Retrouvez tous nos tutoriels sur YouTube</h3>
                <p>Abonnez-vous à notre chaîne pour ne manquer aucune nouveauté.</p>
                <a href="{{ $youtubeUrl }}" target="_blank" rel="noopener">
                    <svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor">
                        <path
                            d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
                    </svg>
                    S'abonner à DR-PHARMA
                </a>
            </div>

        </div>
    </section>
@endsection
