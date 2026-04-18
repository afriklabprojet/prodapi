<?php

namespace App\Jobs;

use App\Models\CourierShift;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;

/**
 * Ferme automatiquement les shifts in_progress dont l'heure de fin est dépassée.
 *
 * Un shift non fermé manuellement au-delà de sa plage horaire bloque le livreur
 * dans un état indéfini. Ce job appelle $shift->complete() si :
 *   - status = in_progress
 *   - date = aujourd'hui
 *   - heure actuelle > end_time + GRACE_MINUTES
 *
 * Fréquence recommandée : toutes les 30 minutes
 */
class ShiftAutoCloseJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public array $backoff = [60, 180];
    public int $timeout = 120;

    /** Délai de grâce avant fermeture forcée (minutes) */
    private const GRACE_MINUTES = 30;

    public function middleware(): array
    {
        return [new WithoutOverlapping('shift-auto-close')];
    }

    public function handle(): void
    {
        $closedCount = 0;

        // Shifts en cours pour aujourd'hui (ou la veille si passé minuit)
        CourierShift::where('status', CourierShift::STATUS_IN_PROGRESS)
            ->whereIn('date', [now()->toDateString(), now()->subDay()->toDateString()])
            ->with('courier')
            ->chunk(50, function ($shifts) use (&$closedCount) {
                foreach ($shifts as $shift) {
                    try {
                        $endTime = $this->resolveEndTime($shift);

                        if (!$endTime) {
                            continue;
                        }

                        // Fermer si heure actuelle > fin + grâce
                        if (now()->gt($endTime->addMinutes(self::GRACE_MINUTES))) {
                            $shift->complete();
                            $closedCount++;

                            Log::info("ShiftAutoCloseJob: shift #{$shift->id} (courier #{$shift->courier_id}) fermé automatiquement à ".now()->format('H:i'));
                        }
                    } catch (\Throwable $e) {
                        Log::warning("ShiftAutoCloseJob: erreur fermeture shift #{$shift->id}: {$e->getMessage()}");
                    }
                }
            });

        if ($closedCount > 0) {
            Log::info("ShiftAutoCloseJob: {$closedCount} shift(s) fermé(s) automatiquement");
        }
    }

    /**
     * Construit un Carbon à partir du champ end_time (format H:i) + date du shift.
     */
    private function resolveEndTime(CourierShift $shift): ?Carbon
    {
        if (!$shift->end_time) {
            return null;
        }

        // end_time est casté datetime:H:i → peut être Carbon ou string
        $timeStr = $shift->end_time instanceof \DateTimeInterface
            ? $shift->end_time->format('H:i')
            : (string) $shift->end_time;

        try {
            $date = $shift->date instanceof \DateTimeInterface
                ? $shift->date->format('Y-m-d')
                : (string) $shift->date;

            return Carbon::createFromFormat('Y-m-d H:i', "{$date} {$timeStr}");
        } catch (\Throwable) {
            return null;
        }
    }
}
