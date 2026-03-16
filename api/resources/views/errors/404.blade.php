@extends('layouts.page')

@section('title', '404 — Page non trouvée | DR PHARMA')
@section('meta_description', 'La page que vous recherchez n\'existe pas ou a été déplacée.')

@section('content')
    <div
        style="display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 60vh; padding: 40px 20px; text-align: center;">
        <div style="font-size: 120px; font-weight: 800; color: #22c55e; line-height: 1;">404</div>
        <h1 style="font-size: 28px; margin-top: 16px; color: #1a1a2e;">Page non trouvée</h1>
        <p style="font-size: 16px; color: #666; margin-top: 12px; max-width: 480px;">
            La page que vous recherchez n'existe pas, a été déplacée ou est temporairement indisponible.
        </p>
        <div style="margin-top: 32px; display: flex; gap: 16px; flex-wrap: wrap; justify-content: center;">
            <a href="/"
                style="display: inline-block; padding: 14px 28px; background: #22c55e; color: white; text-decoration: none; border-radius: 12px; font-weight: 600; transition: background 0.2s;">
                ← Retour à l'accueil
            </a>
            <a href="/aide"
                style="display: inline-block; padding: 14px 28px; background: transparent; color: #22c55e; text-decoration: none; border-radius: 12px; font-weight: 600; border: 2px solid #22c55e;">
                Centre d'aide
            </a>
        </div>
    </div>
@endsection
