@extends('layouts.page')

@section('title', '500 — Erreur serveur | DR PHARMA')
@section('meta_description', 'Une erreur inattendue est survenue. Notre équipe a été notifiée.')

@section('content')
    <div
        style="display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 60vh; padding: 40px 20px; text-align: center;">
        <div style="font-size: 120px; font-weight: 800; color: #ef4444; line-height: 1;">500</div>
        <h1 style="font-size: 28px; margin-top: 16px; color: #1a1a2e;">Erreur serveur</h1>
        <p style="font-size: 16px; color: #666; margin-top: 12px; max-width: 480px;">
            Une erreur inattendue est survenue. Notre équipe technique a été notifiée et travaille à résoudre le problème.
        </p>
        <div style="margin-top: 32px; display: flex; gap: 16px; flex-wrap: wrap; justify-content: center;">
            <a href="/"
                style="display: inline-block; padding: 14px 28px; background: #22c55e; color: white; text-decoration: none; border-radius: 12px; font-weight: 600;">
                ← Retour à l'accueil
            </a>
            <a href="/contact"
                style="display: inline-block; padding: 14px 28px; background: transparent; color: #22c55e; text-decoration: none; border-radius: 12px; font-weight: 600; border: 2px solid #22c55e;">
                Nous contacter
            </a>
        </div>
    </div>
@endsection
