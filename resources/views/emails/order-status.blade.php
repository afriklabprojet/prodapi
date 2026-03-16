<!DOCTYPE html>
<html lang="fr">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mise à jour de votre commande - DR-PHARMA</title>
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

        .status-badge {
            display: inline-block;
            padding: 10px 25px;
            border-radius: 25px;
            font-weight: bold;
            font-size: 16px;
            margin: 20px 0;
        }

        .status-confirmed {
            background-color: #E3F2FD;
            color: #1565C0;
        }

        .status-ready {
            background-color: #FFF3E0;
            color: #EF6C00;
        }

        .status-picked_up {
            background-color: #E8F5E9;
            color: #2E7D32;
        }

        .status-delivered {
            background-color: #E8F5E9;
            color: #1B5E20;
        }

        .status-cancelled {
            background-color: #FFEBEE;
            color: #C62828;
        }

        .order-box {
            background-color: #f8f9fa;
            border-radius: 12px;
            padding: 25px;
            margin: 25px 0;
        }

        .order-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 15px;
            border-bottom: 1px solid #eee;
        }

        .order-number {
            font-size: 18px;
            font-weight: bold;
            color: #1E88E5;
        }

        .order-detail {
            margin: 10px 0;
            display: flex;
            justify-content: space-between;
        }

        .order-detail-label {
            color: #666;
        }

        .order-detail-value {
            font-weight: 600;
        }

        .delivery-code {
            background: linear-gradient(135deg, #43A047, #66BB6A);
            border-radius: 12px;
            padding: 20px;
            text-align: center;
            margin: 20px 0;
            color: white;
        }

        .delivery-code-label {
            font-size: 14px;
            opacity: 0.9;
        }

        .delivery-code-value {
            font-size: 32px;
            font-weight: bold;
            letter-spacing: 8px;
            margin-top: 10px;
        }

        .message-box {
            background-color: #E3F2FD;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
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

        .cta-button {
            display: inline-block;
            background: linear-gradient(135deg, #1E88E5, #42A5F5);
            color: white;
            padding: 15px 30px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: bold;
            margin: 20px 0;
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

        <div style="text-align: center;">
            <span class="status-badge status-{{ $status }}">
                @if ($status === 'confirmed')
                    ✅ Commande Confirmée
                @elseif($status === 'ready')
                    📦 Commande Prête
                @elseif($status === 'picked_up')
                    🚚 En cours de livraison
                @elseif($status === 'delivered')
                    🎉 Commande Livrée
                @elseif($status === 'cancelled')
                    ❌ Commande Annulée
                @else
                    {{ $statusLabel }}
                @endif
            </span>
        </div>

        <div class="order-box">
            <div class="order-header">
                <span class="order-number">Commande #{{ $order->id }}</span>
                <span style="color: #666;">{{ $order->created_at->format('d/m/Y H:i') }}</span>
            </div>

            @if ($order->pharmacy)
                <div class="order-detail">
                    <span class="order-detail-label">Pharmacie</span>
                    <span class="order-detail-value">{{ $order->pharmacy->name }}</span>
                </div>
            @endif

            <div class="order-detail">
                <span class="order-detail-label">Adresse de livraison</span>
                <span class="order-detail-value">{{ $order->delivery_address ?? 'Non spécifiée' }}</span>
            </div>

            <div class="order-detail">
                <span class="order-detail-label">Total</span>
                <span class="order-detail-value" style="color: #1E88E5; font-size: 18px;">
                    {{ number_format($order->total_amount, 0, ',', ' ') }} FCFA
                </span>
            </div>
        </div>

        @if ($status === 'picked_up' && $order->delivery_code)
            <div class="delivery-code">
                <div class="delivery-code-label">Code de livraison à communiquer au livreur</div>
                <div class="delivery-code-value">{{ $order->delivery_code }}</div>
            </div>
        @endif

        @if ($message)
            <div class="message-box">
                <strong>Message :</strong><br>
                {{ $message }}
            </div>
        @endif

        @if ($status === 'confirmed')
            <p style="text-align: center; color: #666;">
                Votre commande a été confirmée par la pharmacie et sera bientôt préparée.
            </p>
        @elseif($status === 'ready')
            <p style="text-align: center; color: #666;">
                Votre commande est prête ! Un livreur sera assigné très bientôt.
            </p>
        @elseif($status === 'picked_up')
            <p style="text-align: center; color: #666;">
                Votre commande est en route ! Le livreur arrivera bientôt à votre adresse.
            </p>
        @elseif($status === 'delivered')
            <p style="text-align: center; color: #666;">
                Merci pour votre confiance ! Nous espérons vous revoir bientôt. 💚
            </p>
        @endif

        <div style="text-align: center;">
            <a href="#" class="cta-button">Suivre ma commande</a>
        </div>

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
