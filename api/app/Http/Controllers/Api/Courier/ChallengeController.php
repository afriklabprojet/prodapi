<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Services\ChallengeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChallengeController extends Controller
{
    public function __construct(
        protected ChallengeService $challengeService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $courier = $request->user()->courier;

        $emptyResponse = [
            'challenges' => [
                'in_progress' => [],
                'completed' => [],
                'rewarded' => [],
                'all' => [],
            ],
            'active_bonuses' => [],
            'stats' => [
                'total_challenges' => 0,
                'in_progress_count' => 0,
                'completed_count' => 0,
                'rewarded_count' => 0,
                'can_claim_count' => 0,
            ],
        ];

        if (!$courier) {
            return response()->json([
                'success' => true,
                'status' => 'success',
                'data' => $emptyResponse,
                'message' => 'Profil coursier non configuré',
            ]);
        }

        try {
            $challenges = collect($this->challengeService->getAvailableChallenges($courier));
            $activeBonuses = $this->challengeService->getActiveBonuses();

            $grouped = [
                'in_progress' => $challenges->whereIn('status', ['in_progress', 'not_started'])->values()->toArray(),
                'completed' => $challenges->where('status', 'completed')->values()->toArray(),
                'rewarded' => $challenges->where('status', 'rewarded')->values()->toArray(),
                'all' => $challenges->values()->toArray(),
            ];

            return response()->json([
                'success' => true,
                'status' => 'success',
                'data' => [
                    'challenges' => $grouped,
                    'active_bonuses' => $activeBonuses,
                    'stats' => [
                        'total_challenges' => $challenges->count(),
                        'in_progress_count' => count($grouped['in_progress']),
                        'completed_count' => count($grouped['completed']),
                        'rewarded_count' => count($grouped['rewarded']),
                        'can_claim_count' => $challenges->where('can_claim', true)->count(),
                    ],
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => true,
                'status' => 'success',
                'data' => $emptyResponse,
            ]);
        }
    }

    public function claimReward(Request $request, int $id): JsonResponse
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Profil coursier non trouvé',
            ], 403);
        }

        try {
            $result = $this->challengeService->claimReward($courier, $id);

            return response()->json([
                'success' => true,
                'status' => 'success',
                'message' => $result['message'] ?? 'Récompense réclamée !',
                'data' => $result,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 400);
        }
    }

    public function bonuses(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'status' => 'success',
            'data' => $this->challengeService->getActiveBonuses(),
        ]);
    }

    public function calculateBonus(Request $request): JsonResponse
    {
        $request->validate([
            'base_amount' => 'required|numeric|min:0',
        ]);

        $activeBonuses = BonusMultiplier::where('is_active', true)
            ->where(function ($q) {
                $q->whereNull('starts_at')->orWhere('starts_at', '<=', now());
            })
            ->where(function ($q) {
                $q->whereNull('ends_at')->orWhere('ends_at', '>=', now());
            })
            ->get();

        $baseAmount = $request->base_amount;
        $totalMultiplier = 1.0;
        $totalFlatBonus = 0;

        foreach ($activeBonuses as $bonus) {
            $totalMultiplier *= $bonus->multiplier;
            $totalFlatBonus += $bonus->flat_bonus;
        }

        $finalAmount = ($baseAmount * $totalMultiplier) + $totalFlatBonus;

        return response()->json([
            'success' => true,
            'data' => [
                'base_amount' => $baseAmount,
                'multiplier' => round($totalMultiplier, 2),
                'flat_bonus' => $totalFlatBonus,
                'final_amount' => round($finalAmount),
                'active_bonuses' => $activeBonuses->count(),
            ],
        ]);
    }
}
