<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class SecureDocumentController extends Controller
{
    private const ALLOWED_TYPES = [
        'kyc',
        'prescriptions',
        'delivery-proofs',
        'support-attachments',
    ];

    public function serve(Request $request, string $type, string $filename): StreamedResponse|JsonResponse
    {
        if (!in_array($type, self::ALLOWED_TYPES, true)) {
            return response()->json(['success' => false, 'message' => 'Type de document invalide'], 404);
        }

        // Sécurité : empêcher la traversée de répertoire (path traversal)
        $filename = str_replace(['..', '\\'], '', $filename);
        $filename = ltrim($filename, '/');
        
        // Valider que le chemin ne contient que des caractères sûrs
        if (!preg_match('/^[a-zA-Z0-9\/_\-\.]+$/', $filename)) {
            return response()->json(['success' => false, 'message' => 'Chemin invalide'], 400);
        }

        $path = "{$type}/{$filename}";

        if (!Storage::disk('private')->exists($path)) {
            return response()->json(['success' => false, 'message' => 'Document introuvable'], 404);
        }

        $mimeType = Storage::disk('private')->mimeType($path);

        return Storage::disk('private')->response($path, null, [
            'Content-Type' => $mimeType,
            'Cache-Control' => 'private, max-age=3600',
        ]);
    }

    public function getTemporaryUrl(Request $request, string $type, string $filename): JsonResponse
    {
        if (!in_array($type, self::ALLOWED_TYPES, true)) {
            return response()->json(['success' => false, 'message' => 'Type de document invalide'], 404);
        }

        // Sécurité : empêcher la traversée de répertoire (path traversal)
        $filename = str_replace(['..', '\\'], '', $filename);
        $filename = ltrim($filename, '/');
        
        if (!preg_match('/^[a-zA-Z0-9\/_\-\.]+$/', $filename)) {
            return response()->json(['success' => false, 'message' => 'Chemin invalide'], 400);
        }

        $path = "{$type}/{$filename}";

        if (!Storage::disk('private')->exists($path)) {
            return response()->json(['success' => false, 'message' => 'Document introuvable'], 404);
        }

        $url = route('secure.document', ['type' => $type, 'filename' => $filename]);

        return response()->json([
            'success' => true,
            'data' => ['url' => $url],
        ]);
    }
}
