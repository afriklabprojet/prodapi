<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class MapController extends Controller
{
    public function directions(Request $request) 
    {
        $request->validate([
            'origin' => 'required|string',
            'destination' => 'required|string',
        ]);

        $apiKey = config('services.google_maps.key');
        $baseUrl = config('services.google_maps.base_url', 'https://maps.googleapis.com/maps/api');

        $response = Http::get("{$baseUrl}/directions/json", [
            'origin' => $request->origin,
            'destination' => $request->destination,
            'mode' => 'driving',
            'key' => $apiKey,
            'language' => 'fr',
        ]);

        return $response->json();
    }
}
