<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'DejaVu Sans', Arial, sans-serif;
            font-size: 12px;
            line-height: 1.4;
            color: #333;
            padding: 20px;
        }
        .header {
            background: #1E3A5F;
            color: white;
            padding: 20px;
            margin: -20px -20px 20px;
            text-align: center;
        }
        .header h1 {
            font-size: 20px;
            margin-bottom: 5px;
        }
        .header p {
            font-size: 14px;
            opacity: 0.9;
        }
        .info-box {
            background: #f5f5f5;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        .info-row {
            display: flex;
            margin-bottom: 8px;
        }
        .info-label {
            font-weight: bold;
            width: 150px;
            color: #666;
        }
        .info-value {
            color: #333;
        }
        .summary-table {
            width: 100%;
            margin-bottom: 20px;
        }
        .summary-table td {
            padding: 10px 15px;
            border: 1px solid #ddd;
        }
        .summary-table .label {
            background: #f9f9f9;
            font-weight: bold;
            width: 50%;
        }
        .summary-table .value {
            text-align: right;
            font-weight: bold;
        }
        .summary-table .value.credit {
            color: #28a745;
        }
        .summary-table .value.debit {
            color: #dc3545;
        }
        .summary-table .value.balance {
            color: #1E3A5F;
            font-size: 14px;
        }
        h2 {
            color: #1E3A5F;
            font-size: 14px;
            margin: 20px 0 10px;
            padding-bottom: 5px;
            border-bottom: 2px solid #1E3A5F;
        }
        .transactions-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 10px;
        }
        .transactions-table th {
            background: #1E3A5F;
            color: white;
            padding: 8px 5px;
            text-align: left;
            font-weight: bold;
        }
        .transactions-table td {
            padding: 6px 5px;
            border-bottom: 1px solid #eee;
        }
        .transactions-table tr:nth-child(even) {
            background: #f9f9f9;
        }
        .transactions-table .amount {
            text-align: right;
            font-weight: bold;
        }
        .transactions-table .amount.credit {
            color: #28a745;
        }
        .transactions-table .amount.debit {
            color: #dc3545;
        }
        .footer {
            margin-top: 30px;
            padding-top: 15px;
            border-top: 1px solid #ddd;
            text-align: center;
            font-size: 10px;
            color: #999;
        }
        .no-transactions {
            text-align: center;
            padding: 30px;
            color: #666;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>RELEVÉ DE COMPTE</h1>
        <p>{{ $pharmacy->name }}</p>
    </div>

    <div class="info-box">
        <div class="info-row">
            <span class="info-label">Pharmacie:</span>
            <span class="info-value">{{ $pharmacy->name }}</span>
        </div>
        <div class="info-row">
            <span class="info-label">Adresse:</span>
            <span class="info-value">{{ $pharmacy->address ?? 'Non renseignée' }}</span>
        </div>
        <div class="info-row">
            <span class="info-label">Période:</span>
            <span class="info-value">Du {{ $period_start->format('d/m/Y') }} au {{ $period_end->format('d/m/Y') }}</span>
        </div>
        <div class="info-row">
            <span class="info-label">Type de relevé:</span>
            <span class="info-value">{{ $frequency_label }}</span>
        </div>
        <div class="info-row">
            <span class="info-label">Date d'émission:</span>
            <span class="info-value">{{ now()->format('d/m/Y H:i') }}</span>
        </div>
    </div>

    <h2>RÉSUMÉ FINANCIER</h2>
    <table class="summary-table">
        <tr>
            <td class="label">Solde actuel</td>
            <td class="value balance">{{ number_format($balance, 0, ',', ' ') }} FCFA</td>
        </tr>
        <tr>
            <td class="label">Total des crédits (période)</td>
            <td class="value credit">+{{ number_format($total_credits, 0, ',', ' ') }} FCFA</td>
        </tr>
        <tr>
            <td class="label">Total des débits (période)</td>
            <td class="value debit">-{{ number_format($total_debits, 0, ',', ' ') }} FCFA</td>
        </tr>
        <tr>
            <td class="label">Nombre de transactions</td>
            <td class="value">{{ $transactions->count() }}</td>
        </tr>
    </table>

    <h2>DÉTAIL DES TRANSACTIONS</h2>
    @if($transactions->count() > 0)
        <table class="transactions-table">
            <thead>
                <tr>
                    <th style="width: 15%;">Date</th>
                    <th style="width: 12%;">Type</th>
                    <th style="width: 48%;">Description</th>
                    <th style="width: 25%;">Montant</th>
                </tr>
            </thead>
            <tbody>
                @foreach($transactions as $transaction)
                    <tr>
                        <td>{{ $transaction->created_at->format('d/m/Y H:i') }}</td>
                        <td>{{ $transaction->type === 'credit' ? 'Crédit' : 'Débit' }}</td>
                        <td>{{ $transaction->description ?? '-' }}</td>
                        <td class="amount {{ $transaction->type }}">
                            {{ $transaction->type === 'credit' ? '+' : '-' }}{{ number_format($transaction->amount, 0, ',', ' ') }} FCFA
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @else
        <div class="no-transactions">
            Aucune transaction pour cette période.
        </div>
    @endif

    <div class="footer">
        <p>Ce document est généré automatiquement par DR Pharma.</p>
        <p>Pour toute question, contactez support@drlpharma.com</p>
        <p>© {{ date('Y') }} DR Pharma - Tous droits réservés</p>
    </div>
</body>
</html>
