<?php

namespace App\Services;

use App\Models\BonusMultiplier;
use App\Models\Challenge;
use App\Models\Courier;

class ChallengeService
{
    public function __construct(
        protected WalletService $walletService,
    ) {}

    /**
     * Return all currently available challenges for a courier.
     */
    public function getAvailableChallenges(Courier $courier): array
    {
        return Challenge::where('is_active', true)
            ->where(function ($query) {
                $query->whereNull('starts_at')->orWhere('starts_at', '<=', now());
            })
            ->where(function ($query) {
                $query->whereNull('ends_at')->orWhere('ends_at', '>=', now());
            })
            ->get()
            ->map(function (Challenge $challenge) use ($courier) {
                $pivotChallenge = $courier->challenges()
                    ->where('challenge_id', $challenge->id)
                    ->first();

                $pivot = $pivotChallenge?->pivot;
                $status = $pivot?->status ?? 'not_started';

                return [
                    'id' => $challenge->id,
                    'title' => $challenge->title,
                    'name' => $challenge->title,
                    'description' => $challenge->description,
                    'type' => $challenge->type,
                    'metric' => $challenge->metric,
                    'target_value' => $challenge->target_value,
                    'target' => $challenge->target_value,
                    'reward_amount' => $challenge->reward_amount,
                    'reward' => $challenge->reward_amount,
                    'icon' => $challenge->icon,
                    'color' => $challenge->color,
                    'current_progress' => (int) ($pivot?->current_progress ?? 0),
                    'progress' => (int) ($pivot?->current_progress ?? 0),
                    'status' => $status,
                    'can_claim' => $status === 'completed',
                    'starts_at' => $challenge->starts_at,
                    'ends_at' => $challenge->ends_at,
                ];
            })
            ->values()
            ->toArray();
    }

    /**
     * Return active bonus multipliers.
     */
    public function getActiveBonuses(): array
    {
        return BonusMultiplier::where('is_active', true)
            ->where(function ($query) {
                $query->whereNull('starts_at')->orWhere('starts_at', '<=', now());
            })
            ->where(function ($query) {
                $query->whereNull('ends_at')->orWhere('ends_at', '>=', now());
            })
            ->get()
            ->toArray();
    }

    /**
     * Claim a completed challenge reward for a courier.
     *
     * @throws \Exception
     */
    public function claimReward(Courier $courier, int $challengeId): array
    {
        $challenge = Challenge::find($challengeId);

        if (!$challenge) {
            throw new \Exception('Challenge introuvable');
        }

        $pivotChallenge = $courier->challenges()
            ->where('challenge_id', $challengeId)
            ->first();

        if (!$pivotChallenge) {
            throw new \Exception('Challenge pas encore complété');
        }

        $status = $pivotChallenge->pivot?->status;

        if ($status === 'rewarded') {
            throw new \Exception('Récompense déjà réclamée');
        }

        if ($status !== 'completed') {
            throw new \Exception('Challenge pas encore complété');
        }

        $transaction = $this->walletService->creditBonus(
            $courier,
            $challenge->reward_amount,
            "Récompense challenge : {$challenge->title}",
            $challenge->id,
        );

        $courier->challenges()->updateExistingPivot($challengeId, [
            'status' => 'rewarded',
            'rewarded_at' => now(),
        ]);

        return [
            'message' => 'Récompense réclamée avec succès',
            'reward_amount' => $challenge->reward_amount,
            'transaction_id' => $transaction->id,
        ];
    }
}
