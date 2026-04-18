<?php

namespace App\Console\Commands;

use App\Models\Prescription;
use App\Services\PerceptualHashService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class BackfillPrescriptionHashesCommand extends Command
{
    protected $signature = 'prescriptions:backfill-hashes
        {--limit=500 : Nombre max de prescriptions à traiter}
        {--force : Recalculer même si image_phash déjà présent}';

    protected $description = 'Calcule SHA-256 + dHash pour les prescriptions existantes (détection doublons).';

    public function handle(PerceptualHashService $phashSvc): int
    {
        $query = Prescription::query()
            ->whereNotNull('images')
            ->orderByDesc('id')
            ->limit((int) $this->option('limit'));

        if (!$this->option('force')) {
            $query->whereNull('image_phash');
        }

        $disk = Storage::disk('private');
        $total = (clone $query)->count();
        $this->info("Prescriptions à traiter : {$total}");

        $bar = $this->output->createProgressBar($total);
        $ok = $skip = $err = 0;

        $query->each(function (Prescription $p) use ($disk, $phashSvc, $bar, &$ok, &$skip, &$err) {
            $bar->advance();
            $images = $p->getRawImages();
            $first = $images[0] ?? null;
            if (!$first || !$disk->exists($first)) {
                $skip++;
                return;
            }
            try {
                $binary = $disk->get($first);
                $sha = hash('sha256', $binary);
                $phash = $phashSvc->dhash($binary);
                $p->forceFill([
                    'image_hash' => $sha,
                    'image_phash' => $phash,
                ])->saveQuietly();
                $ok++;
            } catch (\Throwable $e) {
                $err++;
                $this->newLine();
                $this->warn("Prescription #{$p->id} : {$e->getMessage()}");
            }
        });

        $bar->finish();
        $this->newLine(2);
        $this->info("OK={$ok}  ignorées={$skip}  erreurs={$err}");

        return self::SUCCESS;
    }
}
