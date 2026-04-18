<?php

namespace App\Services;

use App\Models\FraudEvent;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class FraudDetectionService
{
    /**
     * Enregistre un événement et retourne le score cumulé du user (30 derniers jours).
     */
    public function record(
        string $type,
        ?int $userId = null,
        ?Model $subject = null,
        string $severity = FraudEvent::SEVERITY_LOW,
        int $score = 10,
        array $payload = [],
        ?Request $request = null,
    ): FraudEvent {
        $request = $request ?? request();

        $event = FraudEvent::create([
            'type' => $type,
            'severity' => $severity,
            'score' => $score,
            'user_id' => $userId,
            'subject_type' => $subject?->getMorphClass(),
            'subject_id' => $subject?->getKey(),
            'ip' => $request?->ip(),
            'user_agent' => substr((string) $request?->userAgent(), 0, 255),
            'payload' => $payload,
        ]);

        Log::channel('stack')->warning('Fraud event recorded', [
            'type' => $type,
            'severity' => $severity,
            'score' => $score,
            'user_id' => $userId,
            'subject' => $subject ? get_class($subject) . ':' . $subject->getKey() : null,
        ]);

        return $event;
    }

    /**
     * Score de risque cumulé d'un user (somme score / 30j) — borné à 100.
     */
    public function userRiskScore(int $userId): int
    {
        $sum = (int) FraudEvent::where('user_id', $userId)
            ->where('created_at', '>=', now()->subDays(30))
            ->sum('score');

        return min($sum, 100);
    }

    /**
     * Vrai si le user a dépassé un seuil de risque (par défaut 70).
     */
    public function isHighRisk(int $userId, int $threshold = 70): bool
    {
        return $this->userRiskScore($userId) >= $threshold;
    }

    /**
     * Détecte un burst de commandes (anti-velocity).
     * Retourne true et enregistre un event si > $max commandes en $minutes minutes.
     */
    public function detectOrderBurst(int $userId, int $max = 5, int $minutes = 10): bool
    {
        $count = \App\Models\Order::where('customer_id', $userId)
            ->where('created_at', '>=', now()->subMinutes($minutes))
            ->count();

        if ($count > $max) {
            $this->record(
                type: FraudEvent::TYPE_RAPID_ORDER_BURST,
                userId: $userId,
                severity: FraudEvent::SEVERITY_MEDIUM,
                score: 25,
                payload: ['count' => $count, 'window_minutes' => $minutes, 'threshold' => $max],
            );
            return true;
        }

        return false;
    }
}
