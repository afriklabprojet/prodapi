<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\PharmacyStatementPreference;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StatementPreferenceController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();
        $preference = PharmacyStatementPreference::where('pharmacy_id', $pharmacy->id)->first();

        return response()->json([
            'success' => true,
            'data' => $preference,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();

        $validated = $request->validate([
            'frequency' => 'required|in:weekly,monthly,quarterly',
            'format' => 'required|in:pdf,excel,csv',
            'auto_send' => 'boolean',
            'email' => 'nullable|email|max:255',
        ]);

        $preference = PharmacyStatementPreference::updateOrCreate(
            ['pharmacy_id' => $pharmacy->id],
            array_merge($validated, [
                'next_send_at' => $this->calculateNextSendAt($validated['frequency']),
            ]),
        );

        return response()->json([
            'success' => true,
            'message' => 'Préférences de relevé enregistrées',
            'data' => $preference,
        ]);
    }

    public function disable(Request $request): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();

        PharmacyStatementPreference::where('pharmacy_id', $pharmacy->id)
            ->update(['auto_send' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Envoi automatique désactivé',
        ]);
    }

    private function calculateNextSendAt(string $frequency): \Carbon\Carbon
    {
        return match ($frequency) {
            'weekly' => now()->next('Monday'),
            'quarterly' => now()->addQuarter()->startOfQuarter(),
            default => now()->addMonth()->startOfMonth(),
        };
    }
}
