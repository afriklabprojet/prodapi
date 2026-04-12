<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Gère la vérification de version des apps mobiles.
 * 
 * Permet de forcer une mise à jour quand une version critique est déployée.
 * Les versions minimales sont stockées en config (modifiable via .env).
 */
class AppVersionController extends Controller
{
    /**
     * Vérifie si la version courante de l'app est supportée.
     *
     * GET /api/app/version-check?app=delivery&version=1.2.3&platform=android
     */
    public function check(Request $request): JsonResponse
    {
        $request->validate([
            'app' => 'required|in:client,pharmacy,delivery',
            'version' => 'required|string',
            'platform' => 'required|in:android,ios',
        ]);

        $app = $request->input('app');
        $currentVersion = $request->input('version');
        $platform = $request->input('platform');

        $minVersion = config("app.min_versions.{$app}.{$platform}", '1.0.0');
        $latestVersion = config("app.latest_versions.{$app}.{$platform}", $currentVersion);
        $forceUpdate = version_compare($currentVersion, $minVersion, '<');
        $updateAvailable = version_compare($currentVersion, $latestVersion, '<');

        $storeUrl = $platform === 'android'
            ? config("app.store_urls.{$app}.android", '')
            : config("app.store_urls.{$app}.ios", '');

        return response()->json([
            'success' => true,
            'data' => [
                'force_update' => $forceUpdate,
                'update_available' => $updateAvailable,
                'min_version' => $minVersion,
                'latest_version' => $latestVersion,
                'current_version' => $currentVersion,
                'store_url' => $storeUrl,
                'changelog' => $forceUpdate
                    ? 'Une mise à jour critique est disponible. Veuillez mettre à jour votre application.'
                    : ($updateAvailable ? 'Une nouvelle version est disponible avec des améliorations.' : null),
            ],
        ]);
    }

    /**
     * Retourne les feature flags actifs pour l'app.
     *
     * GET /api/app/features?app=delivery
     */
    public function features(Request $request): JsonResponse
    {
        $request->validate([
            'app' => 'required|in:client,pharmacy,delivery',
        ]);

        $app = $request->input('app');
        $flags = config("features.{$app}", []);

        return response()->json([
            'success' => true,
            'data' => $flags,
        ]);
    }
}
