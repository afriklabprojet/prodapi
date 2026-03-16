<!DOCTYPE html>
<html lang="fr">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code de vérification - DR-PHARMA</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f7fa;
        }

        .container {
            background-color: #ffffff;
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .header {
            text-align: center;
            margin-bottom: 30px;
        }

        .logo {
            font-size: 28px;
            font-weight: bold;
            color: #1E88E5;
        }

        .logo span {
            color: #43A047;
        }

        .otp-box {
            background: linear-gradient(135deg, #1E88E5, #42A5F5);
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            margin: 30px 0;
        }

        .otp-code {
            font-size: 42px;
            font-weight: bold;
            letter-spacing: 12px;
            color: #ffffff;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
        }

        .message {
            text-align: center;
            color: #666;
            margin-bottom: 20px;
        }

        .warning {
            background-color: #FFF3E0;
            border-left: 4px solid #FF9800;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
            font-size: 14px;
        }

        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #999;
            font-size: 12px;
        }

        .footer a {
            color: #1E88E5;
            text-decoration: none;
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="header">
            <img src="{{ asset('images/logo.png') }}" alt="DR-PHARMA" width="60" height="60"
                style="border-radius: 12px; margin-bottom: 8px;">
            <div class="logo">DR-<span>PHARMA</span></div>
            <p style="color: #666; margin-top: 5px;">Votre santé, notre priorité</p>
        </div>

        <p class="message">
            @if ($purpose === 'verification')
                Bienvenue ! Voici votre code de vérification pour activer votre compte :
            @elseif($purpose === 'password_reset')
                Vous avez demandé à réinitialiser votre mot de passe. Voici votre code :
            @elseif($purpose === 'login')
                Voici votre code de connexion sécurisée :
            @else
                Voici votre code de vérification :
            @endif
        </p>

        <div class="otp-box">
            <div class="otp-code">{{ $otp }}</div>
        </div>

        <p class="message">
            Ce code est valide pendant <strong>{{ $validityMinutes }} minutes</strong>.
        </p>

        <div class="warning">
            ⚠️ <strong>Sécurité :</strong> Ne partagez jamais ce code avec qui que ce soit.
            L'équipe DR-PHARMA ne vous demandera jamais ce code par téléphone ou email.
        </div>

        <p class="message">
            Si vous n'avez pas demandé ce code, vous pouvez ignorer cet email en toute sécurité.
        </p>

        <div class="footer">
            <p>© {{ date('Y') }} DR-PHARMA. Tous droits réservés.</p>
            <p>
                <a href="{{ url('/confidentialite') }}">Politique de confidentialité</a> |
                <a href="{{ url('/cgu') }}">Conditions d'utilisation</a> |
                <a href="{{ url('/aide') }}">Aide</a>
            </p>
        </div>
    </div>
</body>

</html>
