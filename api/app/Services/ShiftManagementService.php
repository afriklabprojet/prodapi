<?php

namespace App\Services;

use App\Models\Courier;
use App\Models\CourierShift;
use App\Models\CourierShiftSlot;
use App\Services\GeoZoneService;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ShiftManagementService
{
    protected GeoZoneService $geoZoneService;

    public function __construct(GeoZoneService $geoZoneService)
    {
        $this->geoZoneService = $geoZoneService;
    }

    /**
     * Types de shifts disponibles
     */
    const SHIFT_TYPES = [
        'morning' => ['label' => 'Matin', 'start' => '06:00', 'end' => '12:00', 'bonus' => 0],
        'lunch' => ['label' => 'Déjeuner', 'start' => '11:00', 'end' => '15:00', 'bonus' => 100],
        'afternoon' => ['label' => 'Après-midi', 'start' => '14:00', 'end' => '19:00', 'bonus' => 0],
        'dinner' => ['label' => 'Dîner', 'start' => '18:00', 'end' => '23:00', 'bonus' => 150],
        'night' => ['label' => 'Nuit', 'start' => '22:00', 'end' => '02:00', 'bonus' => 200],
    ];

    /**
     * Créer les créneaux pour une semaine
     */
    public function generateWeeklySlots(string $zoneId, Carbon $weekStart, int $capacityPerSlot = 10): void
    {
        $days = collect(range(0, 6))->map(fn($day) => $weekStart->copy()->addDays($day));

        DB::transaction(function () use ($days, $zoneId, $capacityPerSlot) {
            foreach ($days as $date) {
                foreach (self::SHIFT_TYPES as $type => $config) {
                    // Vérifier si le slot existe déjà
                    $exists = CourierShiftSlot::where('zone_id', $zoneId)
                        ->whereDate('date', $date)
                        ->where('shift_type', $type)
                        ->exists();

                    if (!$exists) {
                        CourierShiftSlot::create([
                            'zone_id' => $zoneId,
                            'date' => $date,
                            'shift_type' => $type,
                            'start_time' => $config['start'],
                            'end_time' => $config['end'],
                            'capacity' => $capacityPerSlot,
                            'booked_count' => 0,
                            'bonus_amount' => $config['bonus'],
                            'status' => CourierShiftSlot::STATUS_OPEN,
                        ]);
                    }
                }
            }
        });

        Log::info("ShiftManagement: Generated weekly slots for zone {$zoneId}");
    }

    /**
     * Obtenir les créneaux disponibles pour un livreur
     */
    public function getAvailableSlots(string $zoneId, ?Carbon $fromDate = null): Collection
    {
        $fromDate = $fromDate ?? today();

        return CourierShiftSlot::inZone($zoneId)
            ->available()
            ->where('date', '>=', $fromDate)
            ->orderBy('date')
            ->orderBy('start_time')
            ->get()
            ->groupBy(fn($slot) => $slot->date->format('Y-m-d'));
    }

    /**
     * Réserver un shift
     */
    public function bookShift(Courier $courier, CourierShiftSlot $slot): array
    {
        // Vérifications
        if ($slot->status !== CourierShiftSlot::STATUS_OPEN) {
            return ['success' => false, 'message' => 'Ce créneau n\'est plus disponible'];
        }

        if ($slot->booked_count >= $slot->capacity) {
            return ['success' => false, 'message' => 'Ce créneau est complet'];
        }

        // Vérifier les conflits
        $conflict = $this->checkShiftConflict($courier, $slot);
        if ($conflict) {
            return ['success' => false, 'message' => 'Vous avez déjà un shift à cette heure'];
        }

        // Vérifier la limite journalière (max 2 shifts par jour)
        $dailyCount = CourierShift::forCourier($courier->id)
            ->whereDate('date', $slot->date)
            ->whereNotIn('status', [CourierShift::STATUS_CANCELLED])
            ->count();

        if ($dailyCount >= 2) {
            return ['success' => false, 'message' => 'Maximum 2 shifts par jour'];
        }

        return DB::transaction(function () use ($courier, $slot) {
            // Créer le shift
            $shift = CourierShift::create([
                'courier_id' => $courier->id,
                'slot_id' => $slot->id,
                'zone_id' => $slot->zone_id,
                'date' => $slot->date,
                'start_time' => $slot->start_time,
                'end_time' => $slot->end_time,
                'guaranteed_bonus' => $slot->bonus_amount,
                'status' => CourierShift::STATUS_CONFIRMED,
                'deliveries_completed' => 0,
                'violations_count' => 0,
                'violations' => [],
            ]);

            // Mettre à jour le slot
            $slot->book();

            Log::info("ShiftManagement: Courier {$courier->id} booked shift {$shift->id}");

            return [
                'success' => true,
                'shift' => $shift,
                'message' => 'Shift réservé avec succès',
            ];
        });
    }

    /**
     * Vérifier les conflits de shift
     */
    protected function checkShiftConflict(Courier $courier, CourierShiftSlot $newSlot): bool
    {
        return CourierShift::forCourier($courier->id)
            ->whereDate('date', $newSlot->date)
            ->whereNotIn('status', [CourierShift::STATUS_CANCELLED])
            ->where(function ($q) use ($newSlot) {
                $q->whereBetween('start_time', [$newSlot->start_time, $newSlot->end_time])
                    ->orWhereBetween('end_time', [$newSlot->start_time, $newSlot->end_time]);
            })
            ->exists();
    }

    /**
     * Annuler un shift
     */
    public function cancelShift(CourierShift $shift, ?string $reason = null): array
    {
        // Vérifier si l'annulation est possible (pas trop proche)
        $hoursUntilShift = now()->diffInHours($shift->date->setTimeFromTimeString($shift->start_time->format('H:i')), false);

        if ($hoursUntilShift < 2 && $hoursUntilShift >= 0) {
            return [
                'success' => false,
                'message' => 'Annulation impossible moins de 2h avant le début du shift',
            ];
        }

        $shift->cancel();

        Log::info("ShiftManagement: Shift {$shift->id} cancelled", ['reason' => $reason]);

        return [
            'success' => true,
            'message' => 'Shift annulé avec succès',
        ];
    }

    /**
     * Démarrer un shift
     */
    public function startShift(CourierShift $shift): array
    {
        if ($shift->status !== CourierShift::STATUS_CONFIRMED) {
            return ['success' => false, 'message' => 'Ce shift ne peut pas être démarré'];
        }

        // Vérifier qu'on est dans la fenêtre de démarrage (15 min avant à 30 min après)
        $shiftStart = $shift->date->setTimeFromTimeString($shift->start_time->format('H:i'));
        $minutesDiff = now()->diffInMinutes($shiftStart, false);

        if ($minutesDiff > 15) {
            return ['success' => false, 'message' => 'Le shift ne peut démarrer que 15 minutes avant l\'heure prévue'];
        }

        if ($minutesDiff < -30) {
            // Trop tard - marquer comme no-show
            $shift->markNoShow();
            return ['success' => false, 'message' => 'Vous êtes en retard de plus de 30 minutes'];
        }

        $shift->start();

        // Mettre le livreur en disponible
        $shift->courier->update(['status' => 'available']);

        return [
            'success' => true,
            'shift' => $shift,
            'message' => 'Shift démarré',
        ];
    }

    /**
     * Terminer un shift
     */
    public function endShift(CourierShift $shift): array
    {
        if ($shift->status !== CourierShift::STATUS_IN_PROGRESS) {
            return ['success' => false, 'message' => 'Ce shift n\'est pas actif'];
        }

        $shift->complete();

        // Créditer le bonus si applicable
        $earnedBonus = $shift->calculated_bonus;
        if ($earnedBonus > 0 && $shift->courier->wallet) {
            $shift->courier->wallet->credit(
                $earnedBonus,
                'shift_bonus',
                "Bonus shift du {$shift->date->format('d/m/Y')}"
            );
        }

        // Mettre le livreur en indisponible
        $shift->courier->update(['status' => 'offline']);

        Log::info("ShiftManagement: Shift {$shift->id} completed", [
            'deliveries' => $shift->deliveries_completed,
            'earned_bonus' => $earnedBonus,
        ]);

        return [
            'success' => true,
            'shift' => $shift->fresh(),
            'earned_bonus' => $earnedBonus,
            'message' => 'Shift terminé',
        ];
    }

    /**
     * Enregistrer une violation
     */
    public function recordViolation(CourierShift $shift, string $type, ?string $details = null): void
    {
        $shift->addViolation($type, $details);

        Log::warning("ShiftManagement: Violation recorded for shift {$shift->id}", [
            'type' => $type,
            'details' => $details,
        ]);
    }

    /**
     * Vérifier les shifts en cours et détecter les violations
     */
    public function checkActiveShiftsForViolations(): void
    {
        $activeShifts = CourierShift::active()->with('courier')->get();

        foreach ($activeShifts as $shift) {
            $courier = $shift->courier;

            // Vérifier si le livreur est actif
            if ($courier->status === 'offline') {
                $this->recordViolation($shift, CourierShift::VIOLATION_NOT_ACTIVE, 'Livreur marqué hors ligne pendant le shift');
            }

            // Vérifier la fraîcheur du GPS
            if ($courier->last_location_update && $courier->last_location_update->diffInMinutes(now()) > 15) {
                $this->recordViolation($shift, CourierShift::VIOLATION_GPS_STALE, 'Position GPS non mise à jour depuis 15 minutes');
            }

            // Vérifier si le livreur est dans sa zone assignée
            if ($courier->latitude && $courier->longitude && $shift->zone_id) {
                $isInZone = $this->geoZoneService->isCourierInAssignedZone($courier, $shift->zone_id);
                
                if (!$isInZone) {
                    $currentZone = $this->geoZoneService->getZoneIdFromCoordinates(
                        $courier->latitude, 
                        $courier->longitude
                    );
                    $expectedZone = $this->geoZoneService->getZoneInfo($shift->zone_id);
                    $expectedZoneName = $expectedZone ? $expectedZone['name'] : $shift->zone_id;
                    
                    $this->recordViolation(
                        $shift, 
                        CourierShift::VIOLATION_OUT_OF_ZONE, 
                        "Livreur hors de sa zone assignée ({$expectedZoneName}). Zone actuelle: {$currentZone}"
                    );
                }
            }
        }
    }

    /**
     * Obtenir les shifts d'un livreur
     */
    public function getCourierShifts(Courier $courier, ?Carbon $fromDate = null): Collection
    {
        $fromDate = $fromDate ?? today();

        return CourierShift::forCourier($courier->id)
            ->where('date', '>=', $fromDate)
            ->orderBy('date')
            ->orderBy('start_time')
            ->get();
    }

    /**
     * Obtenir le shift actif d'un livreur
     */
    public function getActiveShift(Courier $courier): ?CourierShift
    {
        return CourierShift::forCourier($courier->id)
            ->active()
            ->today()
            ->first();
    }

    /**
     * Statistiques des shifts pour une zone
     */
    public function getZoneShiftStats(string $zoneId, Carbon $date): array
    {
        $slots = CourierShiftSlot::inZone($zoneId)
            ->whereDate('date', $date)
            ->get();

        $totalCapacity = $slots->sum('capacity');
        $totalBooked = $slots->sum('booked_count');
        $fillRate = $totalCapacity > 0 ? ($totalBooked / $totalCapacity) * 100 : 0;

        return [
            'date' => $date->format('Y-m-d'),
            'zone_id' => $zoneId,
            'total_slots' => $slots->count(),
            'total_capacity' => $totalCapacity,
            'total_booked' => $totalBooked,
            'fill_rate' => round($fillRate, 1),
            'slots_by_type' => $slots->groupBy('shift_type')->map(function ($typeSlots) {
                return [
                    'capacity' => $typeSlots->sum('capacity'),
                    'booked' => $typeSlots->sum('booked_count'),
                ];
            }),
        ];
    }
}
