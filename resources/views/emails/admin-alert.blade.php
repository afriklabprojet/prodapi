<!DOCTYPE html>
<html lang="fr">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Alerte Admin - DR-PHARMA</title>
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
            margin-bottom: 20px;
        }

        .logo {
            font-size: 24px;
            font-weight: bold;
            color: #1E88E5;
        }

        .logo span {
            color: #43A047;
        }

        .alert-banner {
            border-radius: 12px;
            padding: 25px;
            text-align: center;
            margin: 20px 0;
        }

        .alert-banner.no_courier_available {
            background-color: #FFF3E0;
            border: 2px solid #FF9800;
        }

        .alert-banner.payment_failed {
            background-color: #FFEBEE;
            border: 2px solid #F44336;
        }

        .alert-banner.kyc_pending {
            background-color: #E3F2FD;
            border: 2px solid #2196F3;
        }

        .alert-banner.withdrawal_request {
            background-color: #E8F5E9;
            border: 2px solid #4CAF50;
        }

        .alert-banner.high_volume {
            background-color: #F3E5F5;
            border: 2px solid #9C27B0;
        }

        .alert-title {
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 10px;
        }

        .data-box {
            background-color: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
        }

        .data-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }

        .data-row:last-child {
            border-bottom: none;
        }

        .data-label {
            color: #666;
        }

        .data-value {
            font-weight: 600;
        }

        .action-required {
            background-color: #FFEBEE;
            border-left: 4px solid #F44336;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
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

        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #999;
            font-size: 12px;
        }

        .timestamp {
            text-align: center;
            color: #999;
            font-size: 12px;
            margin-top: 20px;
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="header">
            <img src="{{ asset('images/logo.png') }}" alt="DR-PHARMA" width="48" height="48"
                style="border-radius: 10px; margin-bottom: 6px;">
            <div class="logo">DR-<span>PHARMA</span></div>
            <p style="color: #999; font-size: 12px;">Panel Administrateur</p>
        </div>

        <div class="alert-banner {{ $alertType }}">
            <div class="alert-title">
                @if ($alertType === 'no_courier_available')
                    ⚠️ Aucun coursier disponible
                @elseif($alertType === 'payment_failed')
                    ❌ Échec de paiement
                @elseif($alertType === 'kyc_pending')
                    📋 Nouveau KYC en attente
                @elseif($alertType === 'withdrawal_request')
                    💰 Demande de retrait
                @elseif($alertType === 'high_volume')
                    📈 Volume élevé
                @else
                    🔔 {{ $alertTitle }}
                @endif
            </div>
        </div>

        @if ($alertType === 'no_courier_available')
            <p style="text-align: center;">
                Une commande n'a pas pu être assignée automatiquement car aucun coursier n'est disponible dans la zone.
            </p>

            <div class="data-box">
                @if (isset($data['order_id']))
                    <div class="data-row">
                        <span class="data-label">Commande</span>
                        <span class="data-value">#{{ $data['order_id'] }}</span>
                    </div>
                @endif
                @if (isset($data['pharmacy_name']))
                    <div class="data-row">
                        <span class="data-label">Pharmacie</span>
                        <span class="data-value">{{ $data['pharmacy_name'] }}</span>
                    </div>
                @endif
                @if (isset($data['delivery_address']))
                    <div class="data-row">
                        <span class="data-label">Adresse de livraison</span>
                        <span class="data-value">{{ $data['delivery_address'] }}</span>
                    </div>
                @endif
                @if (isset($data['total_amount']))
                    <div class="data-row">
                        <span class="data-label">Montant</span>
                        <span class="data-value">{{ number_format($data['total_amount'], 0, ',', ' ') }} FCFA</span>
                    </div>
                @endif
            </div>

            <div class="action-required">
                <strong>🚨 Action requise :</strong><br>
                Assignez manuellement un coursier ou contactez les coursiers de la zone.
            </div>
        @elseif($alertType === 'kyc_pending')
            <p style="text-align: center;">
                Un nouveau document KYC a été soumis et attend votre validation.
            </p>

            <div class="data-box">
                @if (isset($data['user_name']))
                    <div class="data-row">
                        <span class="data-label">Nom</span>
                        <span class="data-value">{{ $data['user_name'] }}</span>
                    </div>
                @endif
                @if (isset($data['user_type']))
                    <div class="data-row">
                        <span class="data-label">Type</span>
                        <span class="data-value">{{ ucfirst($data['user_type']) }}</span>
                    </div>
                @endif
                @if (isset($data['document_type']))
                    <div class="data-row">
                        <span class="data-label">Document</span>
                        <span class="data-value">{{ $data['document_type'] }}</span>
                    </div>
                @endif
            </div>
        @elseif($alertType === 'withdrawal_request')
            <p style="text-align: center;">
                Une nouvelle demande de retrait a été effectuée.
            </p>

            <div class="data-box">
                @if (isset($data['user_name']))
                    <div class="data-row">
                        <span class="data-label">Demandeur</span>
                        <span class="data-value">{{ $data['user_name'] }}</span>
                    </div>
                @endif
                @if (isset($data['amount']))
                    <div class="data-row">
                        <span class="data-label">Montant</span>
                        <span class="data-value" style="color: #4CAF50; font-size: 18px;">
                            {{ number_format($data['amount'], 0, ',', ' ') }} FCFA
                        </span>
                    </div>
                @endif
                @if (isset($data['payment_method']))
                    <div class="data-row">
                        <span class="data-label">Méthode</span>
                        <span class="data-value">{{ $data['payment_method'] }}</span>
                    </div>
                @endif
            </div>
        @elseif($alertType === 'payment_failed')
            <p style="text-align: center;">
                Un paiement a échoué et nécessite peut-être une intervention.
            </p>

            <div class="data-box">
                @foreach ($data as $key => $value)
                    <div class="data-row">
                        <span class="data-label">{{ ucfirst(str_replace('_', ' ', $key)) }}</span>
                        <span class="data-value">{{ is_array($value) ? json_encode($value) : $value }}</span>
                    </div>
                @endforeach
            </div>
        @else
            <div class="data-box">
                @foreach ($data as $key => $value)
                    <div class="data-row">
                        <span class="data-label">{{ ucfirst(str_replace('_', ' ', $key)) }}</span>
                        <span class="data-value">{{ is_array($value) ? json_encode($value) : $value }}</span>
                    </div>
                @endforeach
            </div>
        @endif

        <div style="text-align: center;">
            <a href="{{ url('/admin') }}" class="cta-button">Accéder au Panel Admin</a>
        </div>

        <div class="timestamp">
            Alerte générée le {{ now()->format('d/m/Y à H:i:s') }}
        </div>

        <div class="footer">
            <p>© {{ date('Y') }} DR-PHARMA - Panel Administrateur</p>
        </div>
    </div>
</body>

</html>
