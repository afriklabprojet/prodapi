<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Gère les codes promotionnels et leur application sur les commandes.
 */
class PromoCodeController extends Controller
{
    /**
     * Valide un code promo et retourne la remise applicable.
     *
     * POST /api/promo-codes/validate
     */
    public function validate(Request $request): JsonResponse
    {
        $request->validate([
            'code' => 'required|string|max:50',
            'order_amount' => 'required|numeric|min:0',
        ]);

        $code = strtoupper(trim($request->input('code')));
        $orderAmount = $request->input('order_amount');
        $user = $request->user();

        $promo = DB::table('promo_codes')
            ->where('code', $code)
            ->where('is_active', true)
            ->first();

        if (!$promo) {
            return response()->json([
                'success' => false,
                'message' => 'Code promo invalide ou expiré.',
            ], 422);
        }

        // Vérifier la date de validité
        if ($promo->starts_at && now()->lt($promo->starts_at)) {
            return response()->json([
                'success' => false,
                'message' => 'Ce code promo n\'est pas encore actif.',
            ], 422);
        }

        if ($promo->expires_at && now()->gt($promo->expires_at)) {
            return response()->json([
                'success' => false,
                'message' => 'Ce code promo a expiré.',
            ], 422);
        }

        // Vérifier le nombre max d'utilisations global
        if ($promo->max_uses && $promo->current_uses >= $promo->max_uses) {
            return response()->json([
                'success' => false,
                'message' => 'Ce code promo a atteint son nombre maximum d\'utilisations.',
            ], 422);
        }

        // Vérifier le nombre max d'utilisations par utilisateur
        if ($promo->max_uses_per_user) {
            $userUsageCount = DB::table('promo_code_usages')
                ->where('promo_code_id', $promo->id)
                ->where('user_id', $user->id)
                ->count();

            if ($userUsageCount >= $promo->max_uses_per_user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vous avez déjà utilisé ce code promo le nombre maximum de fois.',
                ], 422);
            }
        }

        // Vérifier le montant minimum de commande
        if ($promo->min_order_amount && $orderAmount < $promo->min_order_amount) {
            return response()->json([
                'success' => false,
                'message' => "Ce code promo nécessite un montant minimum de {$promo->min_order_amount} FCFA.",
            ], 422);
        }

        // Calculer la remise
        $discount = $this->calculateDiscount($promo, $orderAmount);

        return response()->json([
            'success' => true,
            'data' => [
                'code' => $promo->code,
                'type' => $promo->type,
                'value' => $promo->value,
                'discount' => $discount,
                'description' => $promo->description,
                'min_order_amount' => $promo->min_order_amount,
            ],
        ]);
    }

    /**
     * Applique un code promo à une commande (appelé en interne lors de la création de commande).
     */
    public static function applyPromoCode(string $code, int $userId, float $orderAmount): ?array
    {
        $promo = DB::table('promo_codes')
            ->where('code', strtoupper(trim($code)))
            ->where('is_active', true)
            ->first();

        if (!$promo) {
            return null;
        }

        // Atomique: incrémente et enregistre l'usage
        DB::table('promo_codes')
            ->where('id', $promo->id)
            ->increment('current_uses');

        DB::table('promo_code_usages')->insert([
            'promo_code_id' => $promo->id,
            'user_id' => $userId,
            'used_at' => now(),
        ]);

        $discount = self::calculateDiscountStatic($promo, $orderAmount);

        return [
            'promo_code_id' => $promo->id,
            'code' => $promo->code,
            'discount' => $discount,
        ];
    }

    private function calculateDiscount(object $promo, float $orderAmount): float
    {
        return self::calculateDiscountStatic($promo, $orderAmount);
    }

    private static function calculateDiscountStatic(object $promo, float $orderAmount): float
    {
        if ($promo->type === 'percentage') {
            $discount = $orderAmount * ($promo->value / 100);
            // Plafond de remise
            if ($promo->max_discount && $discount > $promo->max_discount) {
                $discount = $promo->max_discount;
            }
        } else {
            // Remise fixe
            $discount = min($promo->value, $orderAmount);
        }

        return round($discount, 0);
    }
}
