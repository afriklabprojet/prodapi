<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Régénère les delivery_code existants qui ne sont pas au format 4 chiffres.
     */
    public function up(): void
    {
        // Sélectionner les commandes avec un delivery_code non conforme (pas exactement 4 chiffres)
        $driver = DB::connection()->getDriverName();
        $nonDigitCondition = $driver === 'sqlite'
            ? "delivery_code GLOB '*[^0-9]*'"
            : "delivery_code REGEXP '[^0-9]'";

        $orders = DB::table('orders')
            ->whereNotNull('delivery_code')
            ->where(function ($query) use ($nonDigitCondition) {
                $query->whereRaw("LENGTH(delivery_code) != 4")
                      ->orWhereRaw($nonDigitCondition);
            })
            ->get(['id']);

        foreach ($orders as $order) {
            do {
                $code = str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);
            } while (DB::table('orders')->where('delivery_code', $code)->exists());

            DB::table('orders')->where('id', $order->id)->update([
                'delivery_code' => $code,
            ]);
        }
    }

    /**
     * Reverse the migration (no-op, old codes are lost).
     */
    public function down(): void
    {
        // Cannot restore old codes
    }
};
