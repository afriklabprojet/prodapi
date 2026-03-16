<!DOCTYPE html>
<html lang="fr">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenue sur DR-PHARMA</title>
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
            font-size: 32px;
            font-weight: bold;
            color: #1E88E5;
        }

        .logo span {
            color: #43A047;
        }

        .welcome-banner {
            background: linear-gradient(135deg, #1E88E5, #42A5F5);
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            color: white;
            margin: 20px 0;
        }

        .welcome-banner h1 {
            margin: 0;
            font-size: 28px;
        }

        .welcome-banner p {
            margin: 10px 0 0;
            opacity: 0.9;
        }

        .features {
            margin: 30px 0;
        }

        .feature {
            display: flex;
            align-items: center;
            margin: 15px 0;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 10px;
        }

        .feature-icon {
            font-size: 30px;
            margin-right: 15px;
        }

        .feature-text h3 {
            margin: 0;
            color: #1E88E5;
            font-size: 16px;
        }

        .feature-text p {
            margin: 5px 0 0;
            color: #666;
            font-size: 14px;
        }

        .cta-button {
            display: inline-block;
            background: linear-gradient(135deg, #43A047, #66BB6A);
            color: white;
            padding: 15px 40px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: bold;
            margin: 20px 0;
        }

        .user-type-info {
            background-color: #E8F5E9;
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
            text-align: center;
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

        .social-links {
            margin: 20px 0;
        }

        .social-links a {
            display: inline-block;
            margin: 0 10px;
            color: #666;
            text-decoration: none;
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="header">
            <img src="{{ asset('images/logo.png') }}" alt="DR-PHARMA" width="64" height="64"
                style="border-radius: 14px; margin-bottom: 8px;">
            <div class="logo">DR-<span>PHARMA</span></div>
        </div>

        <div class="welcome-banner">
            <h1>Bienvenue {{ $userName }} ! 🎉</h1>
            <p>Votre compte {{ $userTypeLabel }} a été créé avec succès</p>
        </div>

        <p style="text-align: center; font-size: 18px;">
            Merci de rejoindre la communauté DR-PHARMA !
        </p>

        @if ($userType === 'customer')
            <div class="features">
                <div class="feature">
                    <span class="feature-icon">💊</span>
                    <div class="feature-text">
                        <h3>Commandez vos médicaments</h3>
                        <p>Accédez à un large catalogue de produits pharmaceutiques</p>
                    </div>
                </div>
                <div class="feature">
                    <span class="feature-icon">📱</span>
                    <div class="feature-text">
                        <h3>Envoyez vos ordonnances</h3>
                        <p>Uploadez vos prescriptions et recevez un devis rapidement</p>
                    </div>
                </div>
                <div class="feature">
                    <span class="feature-icon">🚚</span>
                    <div class="feature-text">
                        <h3>Livraison rapide</h3>
                        <p>Faites-vous livrer en moins d'une heure</p>
                    </div>
                </div>
            </div>
        @elseif($userType === 'pharmacy')
            <div class="features">
                <div class="feature">
                    <span class="feature-icon">📦</span>
                    <div class="feature-text">
                        <h3>Gérez votre inventaire</h3>
                        <p>Ajoutez et mettez à jour vos produits facilement</p>
                    </div>
                </div>
                <div class="feature">
                    <span class="feature-icon">📋</span>
                    <div class="feature-text">
                        <h3>Recevez des commandes</h3>
                        <p>Traitez les commandes et ordonnances de vos clients</p>
                    </div>
                </div>
                <div class="feature">
                    <span class="feature-icon">📊</span>
                    <div class="feature-text">
                        <h3>Suivez vos performances</h3>
                        <p>Accédez à des statistiques détaillées sur vos ventes</p>
                    </div>
                </div>
            </div>
        @elseif($userType === 'courier')
            <div class="features">
                <div class="feature">
                    <span class="feature-icon">🛵</span>
                    <div class="feature-text">
                        <h3>Effectuez des livraisons</h3>
                        <p>Acceptez les courses et gagnez de l'argent</p>
                    </div>
                </div>
                <div class="feature">
                    <span class="feature-icon">💰</span>
                    <div class="feature-text">
                        <h3>Suivez vos gains</h3>
                        <p>Consultez vos revenus et retirez facilement</p>
                    </div>
                </div>
                <div class="feature">
                    <span class="feature-icon">🏆</span>
                    <div class="feature-text">
                        <h3>Relevez des défis</h3>
                        <p>Gagnez des bonus en complétant des challenges</p>
                    </div>
                </div>
            </div>

            <div class="user-type-info">
                <p><strong>⏳ Prochaine étape :</strong></p>
                <p>Complétez votre profil et téléchargez vos documents KYC pour commencer à livrer.</p>
            </div>
        @endif

        <div style="text-align: center;">
            <a href="{{ url('/') }}" class="cta-button">Commencer maintenant</a>
        </div>

        <div class="footer">
            <p>Besoin d'aide ? Contactez-nous à <a href="mailto:support@drlpharma.com">support@drlpharma.com</a></p>

            <div class="social-links">
                <a href="https://web.facebook.com/profile.php?id=61588488598146">Facebook</a>
                <a href="#">Twitter</a>
                <a href="#">Instagram</a>
            </div>

            <p>© {{ date('Y') }} DR-PHARMA. Tous droits réservés.</p>
            <p>
                <a href="{{ url('/confidentialite') }}">Politique de confidentialité</a> |
                <a href="{{ url('/cgu') }}">Conditions d'utilisation</a>
            </p>
        </div>
    </div>
</body>

</html>
