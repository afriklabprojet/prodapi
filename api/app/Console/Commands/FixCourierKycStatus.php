<?php

namespace App\Console\Commands;

use App\Models\Courier;
use Illuminate\Console\Command;

class FixCourierKycStatus extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'courier:fix-kyc-status 
        {--dry-run : Afficher ce qui serait corrigé sans modifier}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Corrige les livreurs dont le kyc_status est approved mais le status est encore pending_approval';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $dryRun = $this->option('dry-run');

        // Trouver les livreurs désalignés
        $couriers = Courier::where('kyc_status', 'approved')
            ->where('status', 'pending_approval')
            ->get();

        if ($couriers->isEmpty()) {
            $this->info('✅ Aucun livreur à corriger. Tout est synchronisé.');
            return Command::SUCCESS;
        }

        $this->info("📋 {$couriers->count()} livreur(s) avec kyc_status=approved mais status=pending_approval :");
        $this->newLine();

        $table = [];
        foreach ($couriers as $courier) {
            $table[] = [
                $courier->id,
                $courier->user?->name ?? 'N/A',
                $courier->user?->phone ?? 'N/A',
                $courier->kyc_status,
                $courier->status,
            ];
        }

        $this->table(
            ['ID', 'Nom', 'Téléphone', 'KYC Status', 'Status'],
            $table
        );

        if ($dryRun) {
            $this->warn('⚠️  Mode dry-run : aucune modification effectuée.');
            $this->info("Pour appliquer les corrections, relancez sans --dry-run :");
            $this->line("   php artisan courier:fix-kyc-status");
            return Command::SUCCESS;
        }

        if (!$this->confirm('Voulez-vous corriger ces livreurs en passant leur status à "available" ?')) {
            $this->warn('Opération annulée.');
            return Command::SUCCESS;
        }

        $fixedCount = 0;
        foreach ($couriers as $courier) {
            $courier->update([
                'status' => 'available',
                'kyc_verified_at' => $courier->kyc_verified_at ?? now(),
            ]);
            $fixedCount++;
            $this->line("  ✓ Livreur #{$courier->id} ({$courier->user?->name}) → status = available");
        }

        $this->newLine();
        $this->info("✅ {$fixedCount} livreur(s) corrigé(s) avec succès.");

        return Command::SUCCESS;
    }
}
