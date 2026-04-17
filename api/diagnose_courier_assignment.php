<?php

/**
 * Script de diagnostic pour l'assignation des livreurs
 * 
 * Usage: php diagnose_courier_assignment.php
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\Courier;
use App\Models\Order;
use App\Models\Delivery;
use App\Models\Pharmacy;
use App\Services\CourierAssignmentService;

echo "\n";
echo "╔════════════════════════════════════════════════════════════════╗\n";
echo "║   DIAGNOSTIC - ASSIGNATION DES LIVREURS                        ║\n";
echo "╚════════════════════════════════════════════════════════════════╝\n";

// ═══════════════════════════════════════
// 1. ÉTAT DES LIVREURS
// ═══════════════════════════════════════
echo "\n📊 1. ÉTAT DES LIVREURS\n";
echo str_repeat("─", 60) . "\n";

$totalCouriers = Courier::count();
$availableCouriers = Courier::where('status', 'available')->count();
$busyCouriers = Courier::where('status', 'busy')->count();
$offlineCouriers = Courier::where('status', 'offline')->count();

echo "   Total: {$totalCouriers}\n";
echo "   ✅ Disponibles: {$availableCouriers}\n";
echo "   🔴 Occupés: {$busyCouriers}\n";
echo "   ⚫ Hors ligne: {$offlineCouriers}\n";

// Livreurs avec coordonnées GPS
$withGps = Courier::where('status', 'available')
    ->whereNotNull('latitude')
    ->whereNotNull('longitude')
    ->count();

echo "\n   📍 Livreurs disponibles avec GPS: {$withGps}\n";

if ($withGps === 0) {
    echo "\n   ⚠️  PROBLÈME: Aucun livreur disponible n'a de coordonnées GPS!\n";
    echo "   Les livreurs doivent ouvrir l'app delivery pour partager leur position.\n";
}

// ═══════════════════════════════════════
// 2. DÉTAIL DES LIVREURS DISPONIBLES
// ═══════════════════════════════════════
echo "\n📋 2. LIVREURS DISPONIBLES\n";
echo str_repeat("─", 60) . "\n";

$couriers = Courier::with('user:id,name,phone,fcm_token')
    ->where('status', 'available')
    ->get();

if ($couriers->isEmpty()) {
    echo "   ❌ Aucun livreur disponible.\n";
} else {
    foreach ($couriers as $c) {
        echo "\n   [{$c->id}] {$c->name}\n";
        echo "       Phone: {$c->user?->phone}\n";
        echo "       KYC: {$c->kyc_status}\n";
        
        if ($c->latitude && $c->longitude) {
            echo "       📍 Position: {$c->latitude}, {$c->longitude}\n";
            echo "       🕐 Dernière mise à jour: " . ($c->last_location_update ?? 'jamais') . "\n";
        } else {
            echo "       ❌ Position GPS: NON DÉFINIE\n";
        }
        
        if ($c->user?->fcm_token) {
            echo "       📱 FCM Token: ✅ Présent\n";
        } else {
            echo "       📱 FCM Token: ❌ MANQUANT (pas de notifications push)\n";
        }
    }
}

// ═══════════════════════════════════════
// 3. COMMANDES EN ATTENTE D'ASSIGNATION
// ═══════════════════════════════════════
echo "\n\n📦 3. COMMANDES PRÊTES (EN ATTENTE D'ASSIGNATION)\n";
echo str_repeat("─", 60) . "\n";

$readyOrders = Order::where('status', 'ready')
    ->whereDoesntHave('delivery')
    ->with('pharmacy:id,name,latitude,longitude')
    ->get();

if ($readyOrders->isEmpty()) {
    echo "   ✅ Aucune commande en attente.\n";
} else {
    echo "   Total: {$readyOrders->count()} commande(s)\n\n";
    
    foreach ($readyOrders->take(5) as $order) {
        echo "   [{$order->id}] {$order->reference}\n";
        echo "       Pharmacie: {$order->pharmacy?->name}\n";
        
        if ($order->pharmacy?->latitude && $order->pharmacy?->longitude) {
            echo "       📍 Position pharmacie: {$order->pharmacy->latitude}, {$order->pharmacy->longitude}\n";
        } else {
            echo "       ❌ Position pharmacie: NON DÉFINIE\n";
        }
        
        echo "       Adresse livraison: {$order->delivery_address}\n";
        echo "\n";
    }
}

// ═══════════════════════════════════════
// 4. TEST D'ASSIGNATION
// ═══════════════════════════════════════
echo "\n🧪 4. TEST D'ASSIGNATION\n";
echo str_repeat("─", 60) . "\n";

try {
    $assignmentService = app(CourierAssignmentService::class);
    
    // Trouver une pharmacie avec des coordonnées
    $pharmacy = Pharmacy::whereNotNull('latitude')
        ->whereNotNull('longitude')
        ->first();
    
    if (!$pharmacy) {
        echo "   ❌ Aucune pharmacie avec coordonnées GPS trouvée.\n";
    } else {
        echo "   Test avec la pharmacie: {$pharmacy->name}\n";
        echo "   Position: {$pharmacy->latitude}, {$pharmacy->longitude}\n\n";
        
        // Test getAvailableCouriersInRadius
        echo "   🔍 Recherche de livreurs dans un rayon de 20 km...\n";
        
        $nearbyCouriers = $assignmentService->getAvailableCouriersInRadius(
            $pharmacy->latitude,
            $pharmacy->longitude,
            20
        );
        
        if ($nearbyCouriers->isEmpty()) {
            echo "   ❌ Aucun livreur trouvé à proximité.\n";
            echo "\n   Causes possibles:\n";
            echo "   - Aucun livreur n'a le status 'available'\n";
            echo "   - Les livreurs disponibles n'ont pas de position GPS\n";
            echo "   - Les livreurs sont trop loin (> 20 km)\n";
        } else {
            echo "   ✅ {$nearbyCouriers->count()} livreur(s) trouvé(s):\n\n";
            
            foreach ($nearbyCouriers as $courier) {
                $distance = isset($courier->distance) 
                    ? number_format($courier->distance, 2) . ' km' 
                    : 'N/A';
                echo "       • {$courier->name} - Distance: {$distance}\n";
            }
        }
    }
} catch (\Exception $e) {
    echo "   ❌ Erreur lors du test: {$e->getMessage()}\n";
    echo "\n   Trace:\n";
    echo "   " . $e->getTraceAsString() . "\n";
}

// ═══════════════════════════════════════
// 5. VÉRIFICATION DES DERNIÈRES LIVRAISONS
// ═══════════════════════════════════════
echo "\n\n📜 5. DERNIÈRES LIVRAISONS CRÉÉES\n";
echo str_repeat("─", 60) . "\n";

$recentDeliveries = Delivery::with(['courier:id,name', 'order:id,reference'])
    ->orderBy('created_at', 'desc')
    ->limit(5)
    ->get();

if ($recentDeliveries->isEmpty()) {
    echo "   Aucune livraison dans le système.\n";
} else {
    foreach ($recentDeliveries as $delivery) {
        echo "   [{$delivery->id}] Commande: {$delivery->order?->reference}\n";
        echo "       Livreur: {$delivery->courier?->name}\n";
        echo "       Status: {$delivery->status}\n";
        echo "       Créée: {$delivery->created_at}\n\n";
    }
}

// ═══════════════════════════════════════
// 6. RECOMMANDATIONS
// ═══════════════════════════════════════
echo "\n💡 6. RECOMMANDATIONS\n";
echo str_repeat("─", 60) . "\n";

$problems = [];

if ($availableCouriers === 0) {
    $problems[] = "❌ Aucun livreur disponible. Les livreurs doivent se mettre en ligne.";
}

if ($withGps === 0 && $availableCouriers > 0) {
    $problems[] = "❌ Les livreurs disponibles n'ont pas de position GPS. Ils doivent ouvrir l'app delivery.";
}

$couriersWithoutFcm = Courier::where('status', 'available')
    ->whereHas('user', fn($q) => $q->whereNull('fcm_token'))
    ->count();

if ($couriersWithoutFcm > 0) {
    $problems[] = "⚠️  {$couriersWithoutFcm} livreur(s) disponible(s) sans token FCM - pas de notifications push.";
}

$pharmaciesWithoutGps = Pharmacy::whereNull('latitude')
    ->orWhereNull('longitude')
    ->count();

if ($pharmaciesWithoutGps > 0) {
    $problems[] = "⚠️  {$pharmaciesWithoutGps} pharmacie(s) sans coordonnées GPS.";
}

if (empty($problems)) {
    echo "   ✅ Aucun problème détecté. L'assignation devrait fonctionner.\n";
} else {
    foreach ($problems as $problem) {
        echo "   {$problem}\n";
    }
}

echo "\n" . str_repeat("═", 60) . "\n";
echo "Diagnostic terminé.\n\n";
