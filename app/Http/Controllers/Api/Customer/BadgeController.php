<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Services\CustomerBadgeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BadgeController extends Controller
{
    public function __construct(private readonly CustomerBadgeService $badges)
    {
    }

    /**
     * GET /api/customer/badges
     * Liste les badges débloqués + le catalogue complet (pour afficher les badges grisés).
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => [
                'unlocked' => $this->badges->listFor($user),
                'catalog' => collect(CustomerBadgeService::CATALOG)
                    ->map(fn ($v, $k) => array_merge(['id' => $k], $v))
                    ->values()
                    ->all(),
            ],
        ]);
    }
}
