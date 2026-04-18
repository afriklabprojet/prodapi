<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Contrôleur pour servir les documents privés dans l'admin Filament
 */
class PrivateDocumentController extends Controller
{
    /**
     * Servir un document privé de manière sécurisée
     * Accessible uniquement aux administrateurs authentifiés
     */
    public function show(Request $request): StreamedResponse
    {
        // Vérifier que l'utilisateur est authentifié et admin
        if (!Auth::check() || !in_array(Auth::user()->role, ['admin', 'super_admin'])) {
            abort(403, 'Accès non autorisé');
        }

        // Chemin passé en query string pour éviter l'encodage %2F des slashes dans les URL
        $path = $request->query('path', '');

        // Nettoyer le chemin pour éviter les attaques de traversée de répertoire
        $path = urldecode($path);
        $path = str_replace(['..', '\\'], '', $path);
        $path = ltrim($path, '/');
        
        // Valider que le chemin ne contient que des caractères sûrs
        if (empty($path) || !preg_match('/^[a-zA-Z0-9\/_\-\.]+$/', $path)) {
            abort(400, 'Chemin invalide');
        }

        /** @var FilesystemAdapter $disk */
        $disk = Storage::disk('private');
        
        // Vérifier que le fichier existe
        if (!$disk->exists($path)) {
            abort(404, 'Document non trouvé');
        }

        // Déterminer le type MIME
        $mimeType = $disk->mimeType($path);
        
        // Retourner le fichier en streaming
        return $disk->response($path, null, [
            'Content-Type' => $mimeType,
            'Cache-Control' => 'private, max-age=3600',
        ]);
    }

    /**
     * Télécharger un document privé
     */
    public function download(Request $request): StreamedResponse
    {
        // Vérifier que l'utilisateur est authentifié et admin
        if (!Auth::check() || !in_array(Auth::user()->role, ['admin', 'super_admin'])) {
            abort(403, 'Accès non autorisé');
        }

        // Chemin passé en query string
        $path = $request->query('path', '');

        // Nettoyer le chemin
        $path = urldecode($path);
        $path = str_replace(['..', '\\'], '', $path);
        $path = ltrim($path, '/');
        
        // Valider que le chemin ne contient que des caractères sûrs
        if (empty($path) || !preg_match('/^[a-zA-Z0-9\/_\-\.]+$/', $path)) {
            abort(400, 'Chemin invalide');
        }

        /** @var FilesystemAdapter $disk */
        $disk = Storage::disk('private');
        
        // Vérifier que le fichier existe
        if (!$disk->exists($path)) {
            abort(404, 'Document non trouvé');
        }

        // Télécharger le fichier
        return $disk->download($path);
    }
}
