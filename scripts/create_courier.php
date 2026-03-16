<?php

require_once __DIR__ . '/../api/vendor/autoload.php';

$app = require_once __DIR__ . '/../api/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\User;
use App\Models\Courier;
use Illuminate\Support\Facades\Hash;

echo "\n=== Création d'un compte Coursier Actif ===\n\n";

// Vérifier si le compte existe déjà
$existingUser = User::where('email', 'coursier@drlpharma.com')->first();
if ($existingUser) {
    echo "⚠️ Ce compte existe déjà!\n";
    if ($existingUser->courier) {
        $existingUser->courier->status = 'approved';
        $existingUser->courier->save();
    }
    echo "✅ Statut mis à jour: approved\n";
} else {
    // Créer l'utilisateur
    $user = new User();
    $user->name = 'Jean Coursier';
    $user->email = 'coursier@drlpharma.com';
    $user->phone = '+2250701010101';
    $user->password = Hash::make('Coursier@2026');
    $user->role = 'courier';
    $user->email_verified_at = now();
    $user->save();

    // Créer le profil coursier avec les bons noms de colonnes
    $courier = new Courier();
    $courier->user_id = $user->id;
    $courier->name = 'Jean Coursier';
    $courier->phone = '+2250701010101';
    $courier->vehicle_type = 'motorcycle';
    $courier->vehicle_number = 'AB-1234-CI';
    $courier->license_number = 'PERM-2026-001';
    $courier->status = 'approved';
    $courier->kyc_status = 'approved';
    $courier->latitude = 5.3600;
    $courier->longitude = -4.0083;
    $courier->rating = 4.8;
    $courier->completed_deliveries = 0;
    $courier->save();

    echo "✅ Compte coursier créé avec succès!\n";
}

echo "\n📋 Informations de connexion:\n";
echo "--------------------------------\n";
echo "Email:        coursier@drlpharma.com\n";
echo "Téléphone:    +2250701010101\n";
echo "Mot de passe: Coursier@2026\n";
echo "Statut:       Approuvé (actif)\n";
echo "Véhicule:     Moto (motorcycle)\n";
echo "--------------------------------\n\n";
