<?php

namespace App\Services;

use App\Models\CustomerBadge;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CustomerBadgeService
{
    /**
     * Catalogue des badges client.
     * Source de vérité unique côté backend.
     */
    public const CATALOG = [
        'first_order' => [
            'title' => 'Première commande',
            'description' => 'Votre toute première commande sur DR-PHARMA',
            'icon' => 'celebration',
        ],
        'fifth_order' => [
            'title' => 'Client fidèle',
            'description' => '5 commandes complétées',
            'icon' => 'star',
        ],
        'vip' => [
            'title' => 'Client VIP',
            'description' => '10 commandes complétées',
            'icon' => 'workspace_premium',
        ],
        'first_renewal' => [
            'title' => 'Traitement suivi',
            'description' => 'Premier renouvellement de traitement',
            'icon' => 'medication',
        ],
        'first_wallet' => [
            'title' => 'Wallet activé',
            'description' => 'Premier rechargement du portefeuille',
            'icon' => 'account_balance_wallet',
        ],
        'first_scan' => [
            'title' => 'Ordonnance scannée',
            'description' => 'Première ordonnance scannée',
            'icon' => 'document_scanner',
        ],
    ];

    /**
     * Vérifie si un identifiant est connu dans le catalogue.
     */
    public static function isValid(string $badgeId): bool
    {
        return array_key_exists($badgeId, self::CATALOG);
    }

    /**
     * Débloque un badge (idempotent).
     * Retourne le record si nouvellement créé, null si déjà débloqué.
     */
    public function unlock(User $user, string $badgeId, array $meta = []): ?CustomerBadge
    {
        if (!self::isValid($badgeId)) {
            Log::warning('Tentative de déblocage badge inconnu', [
                'badge_id' => $badgeId,
                'user_id' => $user->id,
            ]);
            return null;
        }

        return DB::transaction(function () use ($user, $badgeId, $meta) {
            $existing = CustomerBadge::where('user_id', $user->id)
                ->where('badge_id', $badgeId)
                ->first();

            if ($existing) {
                return null;
            }

            $badge = CustomerBadge::create([
                'user_id' => $user->id,
                'badge_id' => $badgeId,
                'unlocked_at' => now(),
                'meta' => $meta ?: null,
            ]);

            Log::info('Badge client débloqué', [
                'user_id' => $user->id,
                'badge_id' => $badgeId,
            ]);

            return $badge;
        });
    }

    /**
     * Vérifie les badges liés au volume de commandes livrées.
     * Idempotent : ne déclenche que si seuil atteint et badge non encore débloqué.
     */
    public function checkOrderMilestones(User $user): array
    {
        if ($user->role !== 'customer') {
            return [];
        }

        $deliveredCount = Order::where('customer_id', $user->id)
            ->where('status', 'delivered')
            ->count();

        $unlocked = [];

        if ($deliveredCount >= 1 && $badge = $this->unlock($user, 'first_order', ['count' => $deliveredCount])) {
            $unlocked[] = $badge;
        }
        if ($deliveredCount >= 5 && $badge = $this->unlock($user, 'fifth_order', ['count' => $deliveredCount])) {
            $unlocked[] = $badge;
        }
        if ($deliveredCount >= 10 && $badge = $this->unlock($user, 'vip', ['count' => $deliveredCount])) {
            $unlocked[] = $badge;
        }

        return $unlocked;
    }

    /**
     * Liste tous les badges débloqués par un utilisateur.
     */
    public function listFor(User $user): array
    {
        return CustomerBadge::where('user_id', $user->id)
            ->orderByDesc('unlocked_at')
            ->get()
            ->map(fn (CustomerBadge $b) => [
                'id' => $b->badge_id,
                'unlocked_at' => $b->unlocked_at?->toIso8601String(),
                'meta' => $b->meta,
                'title' => self::CATALOG[$b->badge_id]['title'] ?? $b->badge_id,
                'description' => self::CATALOG[$b->badge_id]['description'] ?? null,
                'icon' => self::CATALOG[$b->badge_id]['icon'] ?? null,
            ])
            ->all();
    }

    /**
     * Compte les badges d'un utilisateur (rapide, sans charger les rows).
     */
    public function countFor(User $user): int
    {
        return CustomerBadge::where('user_id', $user->id)->count();
    }
}
