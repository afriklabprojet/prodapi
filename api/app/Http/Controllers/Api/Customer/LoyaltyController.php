<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Services\LoyaltyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LoyaltyController extends Controller
{
    public function __construct(
        private readonly LoyaltyService $loyaltyService,
    ) {}

    /**
     * Get loyalty summary, rewards, and history.
     *
     * GET /api/customer/loyalty
     */
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $summary = $this->loyaltyService->getSummary($userId);
        $rewards = $this->loyaltyService->getAvailableRewards($userId);
        $tiers = $this->loyaltyService->getTiersInfo();
        $history = $this->loyaltyService->getHistory($userId, 10);

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => $summary,
                'rewards' => $rewards,
                'tiers' => $tiers,
                'history' => $history,
            ],
        ]);
    }

    /**
     * Redeem a loyalty reward.
     *
     * POST /api/customer/loyalty/redeem
     */
    public function redeem(Request $request): JsonResponse
    {
        $request->validate([
            'reward_id' => 'required|integer|exists:loyalty_rewards,id',
        ]);

        try {
            $redemption = $this->loyaltyService->redeemReward(
                $request->user()->id,
                $request->reward_id,
            );

            return response()->json([
                'success' => true,
                'message' => 'Récompense échangée avec succès !',
                'data' => [
                    'redemption' => $redemption,
                    'summary' => $this->loyaltyService->getSummary($request->user()->id),
                ],
            ]);
        } catch (\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Get full points history.
     *
     * GET /api/customer/loyalty/history
     */
    public function history(Request $request): JsonResponse
    {
        $history = $this->loyaltyService->getHistory(
            $request->user()->id,
            $request->get('per_page', 20),
        );

        return response()->json([
            'success' => true,
            'data' => $history,
        ]);
    }
}
