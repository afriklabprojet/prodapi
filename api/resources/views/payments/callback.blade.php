<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $status === 'success' ? 'Paiement confirmé' : 'Paiement échoué' }} — DR-PHARMA</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: {{ $status === 'success' ? '#f0fdf4' : '#fef2f2' }};
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }
        .card {
            background: white;
            border-radius: 20px;
            padding: 40px 32px;
            max-width: 400px;
            width: 100%;
            text-align: center;
            box-shadow: 0 4px 24px rgba(0,0,0,0.08);
        }
        .icon {
            font-size: 72px;
            margin-bottom: 20px;
            display: block;
        }
        h1 {
            font-size: 22px;
            font-weight: 700;
            color: {{ $status === 'success' ? '#16a34a' : '#dc2626' }};
            margin-bottom: 12px;
        }
        p {
            color: #6b7280;
            font-size: 15px;
            line-height: 1.6;
            margin-bottom: 8px;
        }
        .btn {
            display: inline-block;
            margin-top: 28px;
            padding: 14px 32px;
            background: {{ $status === 'success' ? '#16a34a' : '#dc2626' }};
            color: white;
            text-decoration: none;
            border-radius: 12px;
            font-size: 16px;
            font-weight: 600;
            width: 100%;
            border: none;
            cursor: pointer;
        }
        .redirecting {
            margin-top: 16px;
            color: #9ca3af;
            font-size: 13px;
        }
    </style>
</head>
<body>
    <div class="card">
        @if($status === 'success')
            <span class="icon">✅</span>
            <h1>Paiement confirmé !</h1>
            <p>Votre rechargement a été effectué avec succès.</p>
            <p>Votre solde a été mis à jour dans l'application.</p>
        @else
            <span class="icon">❌</span>
            <h1>Paiement échoué</h1>
            <p>{{ $errorMessage ?? 'Le paiement n\'a pas pu être complété.' }}</p>
            <p>Vous pouvez réessayer depuis l'application.</p>
        @endif

        <a href="{{ $deepLink }}" class="btn">
            Retourner à l'application
        </a>
        <p class="redirecting">Redirection automatique en cours...</p>
    </div>

    <script>
        // Rediriger immédiatement vers l'app via deep link
        (function() {
            var deepLink = "{{ $deepLink }}";
            var timeout;

            function openApp() {
                window.location.href = deepLink;
                // Si l'app ne s'ouvre pas après 1.5s, rester sur la page
                timeout = setTimeout(function() {
                    document.querySelector('.redirecting').textContent =
                        "Appuyez sur « Retourner à l'application » si la redirection ne fonctionne pas.";
                }, 1500);
            }

            // Lancer la redirection immédiatement
            openApp();

            // Nettoyer le timeout si l'utilisateur quitte la page (app ouverte)
            window.addEventListener('blur', function() {
                clearTimeout(timeout);
            });
            document.addEventListener('visibilitychange', function() {
                if (document.hidden) clearTimeout(timeout);
            });
        })();
    </script>
</body>
</html>
