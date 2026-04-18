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
        
        $response = Http::get('https://maps.googleapis.com/maps/api/directions/json', [
            'origin' => $request->origin,
            'destination' => $request->destination,
            'mode' => 'driving',
            'key' => $apiKey,
            'language' => 'fr',
        ]);

        return $response->json();
    }
}
