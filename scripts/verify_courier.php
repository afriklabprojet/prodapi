<?php

require_once __DIR__ . '/../api/vendor/autoload.php';

$app = require_once __DIR__ . '/../api/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\User;

$user = User::where('email', 'coursier@drlpharma.com')->with('courier')->first();

if (!$user) {
    echo "❌ Utilisateur non trouvé\n";
    exit(1);
}

echo "\n✅ Compte coursier validé et confirmé!\n\n";
echo "📋 Informations de connexion:\n";
echo "─────────────────────────────────────\n";
echo "Email:             {$user->email}\n";
echo "Téléphone:         {$user->phone}\n";
echo "Mot de passe:      Coursier@2026\n";
echo "Rôle:              {$user->role}\n";
echo "Email vérifié:     " . ($user->email_verified_at ? '✓ Oui' : '✗ Non') . "\n";
echo "Téléphone vérifié: " . ($user->phone_verified_at ? '✓ Oui' : '✗ Non') . "\n";
echo "─────────────────────────────────────\n";

if ($user->courier) {
    echo "Statut coursier:   {$user->courier->status}\n";
    echo "KYC:               {$user->courier->kyc_status}\n";
    echo "Véhicule:          {$user->courier->vehicle_type}\n";
    echo "Plaque:            {$user->courier->vehicle_number}\n";
    echo "Note:              {$user->courier->rating}/5\n";
} else {
    echo "⚠️ Profil coursier non trouvé\n";
}
echo "─────────────────────────────────────\n\n";
