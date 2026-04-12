<?php

namespace App\Console\Commands;

use App\Models\Courier;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Services\CourierAssignmentService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class TestAssignDelivery extends Command
{
    protected $signature = 'test:assign-delivery 
                            {courier_name? : Nom du livreur (ex: baba)}
                            {--create-order : Créer une commande test si aucune disponible}';

    protected $description = 'Test d\'assignation d\'une livraison à un livreur pour vérifier les notifications';

    public function handle(CourierAssignmentService $assignmentService): int
    {
        $courierName = $this->argument('courier_name') ?? 'baba';

        $this->info("\n🔍 Recherche du livreur '{$courierName}'...");

        // Trouver le livreur
        $courier = Courier::where('name', 'like', "%{$courierName}%")
            ->orWhereHas('user', fn ($q) => $q->where('name', 'like', "%{$courierName}%"))
            ->with('user:id,name,phone,fcm_token')
            ->first();

        if (!$courier) {
            $this->error("❌ Livreur '{$courierName}' non trouvé.");
            $this->line("\n📋 Livreurs disponibles:");
            
            Courier::with('user:id,name,phone,fcm_token')
                ->where('status', 'available')
                ->limit(10)
                ->get()
                ->each(function ($c) {
                    $fcm = $c->user?->fcm_token ? '✅' : '❌';
                    $this->line("   {$c->id} | {$c->name} | {$c->user?->phone} | FCM: {$fcm}");
                });

            return self::FAILURE;
        }

        $this->info("✅ Livreur trouvé:");
        $this->line("   ID: {$courier->id}");
        $this->line("   Nom: {$courier->name}");
        $this->line("   Status: {$courier->status}");
        $this->line("   Phone: {$courier->user?->phone}");
        
        $hasFcm = $courier->user?->fcm_token ? true : false;
        $this->line("   FCM Token: " . ($hasFcm ? '✅ Configuré' : '❌ NON DÉFINI'));

        if (!$hasFcm) {
            $this->warn("\n⚠️  Le livreur n'a pas de FCM token!");
            $this->line("   La notification push ne sera pas reçue.");
            $this->line("   Assurez-vous que l'app est connectée sur le téléphone.");
        }

        // Chercher une commande prête
        $this->info("\n🔍 Recherche d'une commande 'ready'...");

        $order = Order::where('status', 'ready')
            ->whereDoesntHave('deliveries')
            ->with('pharmacy')
            ->first();

        if (!$order && $this->option('create-order')) {
            $this->line("   Aucune commande disponible. Création d'une commande test...");
            
            $pharmacy = Pharmacy::first();
            if (!$pharmacy) {
                $this->error("❌ Aucune pharmacie trouvée.");
                return self::FAILURE;
            }

            $order = Order::create([
                'reference' => 'TEST-' . strtoupper(uniqid()),
                'pharmacy_id' => $pharmacy->id,
                'customer_name' => 'Client Test Notification',
                'customer_phone' => '+22507000000',
                'delivery_address' => 'Abidjan, Cocody - Test notification livreur',
                'delivery_latitude' => $pharmacy->latitude + 0.01,
                'delivery_longitude' => $pharmacy->longitude + 0.01,
                'status' => 'ready',
                'payment_status' => 'paid',
                'total_amount' => 5000,
                'delivery_fee' => 1500,
            ]);

            $this->info("✅ Commande test créée: {$order->reference}");
        }

        if (!$order) {
            $this->error("❌ Aucune commande 'ready' disponible.");
            $this->line("   Utilisez --create-order pour créer une commande test.");
            return self::FAILURE;
        }

        $this->info("\n📋 Commande sélectionnée:");
        $this->line("   ID: {$order->id}");
        $this->line("   Référence: {$order->reference}");
        $this->line("   Pharmacie: {$order->pharmacy?->name}");
        $this->line("   Adresse: {$order->delivery_address}");

        // Confirmer
        if (!$this->confirm("\n🚀 Assigner cette commande au livreur {$courier->name}?", true)) {
            $this->line("Annulé.");
            return self::SUCCESS;
        }

        // Assigner
        try {
            DB::beginTransaction();
            
            $delivery = $assignmentService->assignSpecificCourier($order, $courier);

            if ($delivery) {
                DB::commit();

                $this->newLine();
                $this->info("✅ SUCCÈS! Livraison créée:");
                $this->line("   ID Livraison: {$delivery->id}");
                $this->line("   Status: {$delivery->status}");
                $this->line("   Frais: {$delivery->delivery_fee} FCFA");

                $this->newLine();
                $this->warn("📱 NOTIFICATION ENVOYÉE!");
                $this->line("   Une notification push avec sonnerie a été envoyée.");
                $this->line("   Vérifiez l'app delivery du livreur '{$courier->name}'.");

                $this->newLine();
                $this->info("🔔 La notification devrait:");
                $this->line("   • Afficher: 🚨 NOUVELLE LIVRAISON ! 📦");
                $this->line("   • Jouer une sonnerie d'alerte");
                $this->line("   • Vibrer le téléphone");

                return self::SUCCESS;
            } else {
                DB::rollBack();
                $this->error("❌ Échec de l'assignation.");
                return self::FAILURE;
            }

        } catch (\Exception $e) {
            DB::rollBack();
            $this->error("❌ Erreur: {$e->getMessage()}");
            return self::FAILURE;
        }
    }
}
