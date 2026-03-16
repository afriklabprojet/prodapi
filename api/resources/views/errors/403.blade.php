@extends('layouts.page')

@section('title', '403 — Accès refusé | DR PHARMA')
@section('meta_description', 'Vous n\'avez pas les autorisations nécessaires pour accéder à cette page.')

@section('content')
    <div
        style="display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 60vh; padding: 40px 20px; text-align: center;">
        <div style="font-size: 120px; font-weight: 800; color: #f59e0b; line-height: 1;">403</div>
        <h1 style="font-size: 28px; margin-top: 16px; color: #1a1a2e;">Accès refusé</h1>
        <p style="font-size: 16px; color: #666; margin-top: 12px; max-width: 480px;">
            Vous n'avez pas les autorisations nécessaires pour accéder à cette page.
        </p>
        <div style="margin-top: 32px;">
            <a href="/"
                style="display: inline-block; padding: 14px 28px; background: #22c55e; color: white; text-decoration: none; border-radius: 12px; font-weight: 600;">
                ← Retour à l'accueil
            </a>
        </div>
    </div>
@endsection
