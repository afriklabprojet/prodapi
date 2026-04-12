<?php

/**
 * Script de test pour assigner une commande au livreur "baba"
 * et vérifier que la notification avec sonnerie est déclenchée.
 * 
 * Usage: php test_assign_delivery.php
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\Courier;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\Delivery;
use App\Services\CourierAssignmentService;

echo "\n🔍 Recherche du livreur 'baba'...\n";

// Trouver le livreur Baba
$courier = Courier::whereHas('user', function ($q) {
    $q->where('name', 'like', '%baba%')
      ->orWhere('email', 'like', '%baba%');
})->first();

if (!$courier) {
    // Essayer par le nom du courier directement
    $courier = Courier::where('name', 'like', '%baba%')->first();
}

if (!$courier) {
    echo "❌ Livreur 'baba' non trouvé.\n";
    echo "\n📋 Liste des livreurs disponibles:\n";
    $couriers = Courier::with('user:id,name,email,phone,fcm_token')
        ->where('status', 'available')
        ->limit(10)
        ->get();
    
    foreach ($couriers as $c) {
        $fcmStatus = $c->user?->fcm_token ? '✅ FCM' : '❌ Pas de FCM';
        echo "   - ID: {$c->id} | {$c->name} | {$c->user?->phone} | {$fcmStatus}\n";
    }
    
    echo "\n💡 Indiquez le nom exact du livreur si différent.\n";
    exit(1);
}

echo "✅ Livreur trouvé:\n";
echo "   ID: {$courier->id}\n";
echo "   Nom: {$courier->name}\n";
echo "   Status: {$courier->status}\n";
echo "   User ID: {$courier->user_id}\n";
echo "   Phone: {$courier->user?->phone}\n";
echo "   FCM Token: " . ($courier->user?->fcm_token ? substr($courier->user->fcm_token, 0, 30) . '...' : '❌ NON DÉFINI') . "\n";

if (!$courier->user?->fcm_token) {
    echo "\n⚠️  ATTENTION: Le livreur n'a pas de FCM token!\n";
    echo "   La notification push ne sera pas envoyée.\n";
    echo "   Assurez-vous que l'app delivery est connectée.\n";
}

// Vérifier s'il y a une commande prête à être assignée
echo "\n🔍 Recherche d'une commande 'ready' sans livraison...\n";

$order = Order::where('status', 'ready')
    ->whereDoesntHave('deliveries')
    ->with('pharmacy')
    ->first();

if (!$order) {
    echo "   Aucune commande 'ready' disponible.\n";
    echo "\n📦 Création d'une commande test...\n";
    
    // Trouver une pharmacie
    $pharmacy = Pharmacy::first();
    if (!$pharmacy) {
        echo "❌ Aucune pharmacie trouvée. Impossible de créer une commande test.\n";
        exit(1);
    }
    
    // Créer une commande test
    $order = Order::create([
        'reference' => 'TEST-' . strtoupper(uniqid()),
        'pharmacy_id' => $pharmacy->id,
        'customer_id' => 1, // Un client existant ou null
        'customer_name' => 'Client Test',
        'customer_phone' => '+22507000000',
        'delivery_address' => 'Abidjan, Cocody - Test de notification',
        'delivery_latitude' => $pharmacy->latitude + 0.01,
        'delivery_longitude' => $pharmacy->longitude + 0.01,
        'status' => 'ready',
        'payment_status' => 'paid',
        'total_amount' => 5000,
        'delivery_fee' => 1500,
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    
    echo "✅ Commande test créée: {$order->reference}\n";
}

echo "\n📋 Commande sélectionnée:\n";
echo "   ID: {$order->id}\n";
echo "   Référence: {$order->reference}\n";
echo "   Pharmacie: {$order->pharmacy?->name}\n";
echo "   Status: {$order->status}\n";
echo "   Adresse: {$order->delivery_address}\n";

// Assigner le livreur
echo "\n🚀 Assignation du livreur au commande...\n";

try {
    DB::beginTransaction();
    
    $assignmentService = app(CourierAssignmentService::class);
    $delivery = $assignmentService->assignSpecificCourier($order, $courier);
    
    if ($delivery) {
        DB::commit();
        
        echo "\n✅ SUCCÈS! Livraison créée:\n";
        echo "   ID Livraison: {$delivery->id}\n";
        echo "   Status: {$delivery->status}\n";
        echo "   Frais livraison: {$delivery->delivery_fee} FCFA\n";
        echo "   Distance estimée: {$delivery->estimated_distance} km\n";
        
        echo "\n📱 NOTIFICATION ENVOYÉE AU LIVREUR!\n";
        echo "   Une notification push avec sonnerie a été envoyée.\n";
        echo "   Vérifiez l'app delivery du livreur 'baba'.\n";
        
        echo "\n🔔 La notification devrait:\n";
        echo "   - Afficher: 🚨 NOUVELLE LIVRAISON ! 📦\n";
        echo "   - Jouer une sonnerie d'alerte\n";
        echo "   - Vibrer le téléphone\n";
        
    } else {
        DB::rollBack();
        echo "❌ Échec de l'assignation. Vérifiez les logs.\n";
    }
    
} catch (\Exception $e) {
    DB::rollBack();
    echo "❌ Erreur: {$e->getMessage()}\n";
    Log::error("Test assign delivery failed", [
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString(),
    ]);
}

echo "\n📝 Pour vérifier les notifications envoyées:\n";
echo "   php artisan tinker\n";
echo "   \$c = Courier::find({$courier->id});\n";
echo "   \$c->user->notifications()->latest()->first();\n";

echo "\n✨ Test terminé.\n";
