<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Makes withdrawal_requests polymorphic to support both pharmacies and customers
     */
    public function up(): void
    {
        Schema::table('withdrawal_requests', function (Blueprint $table) {
            // Add polymorphic columns
            $table->string('requestable_type')->nullable()->after('wallet_id');
            $table->unsignedBigInteger('requestable_id')->nullable()->after('requestable_type');
            
            // Add index for polymorphic relation
            $table->index(['requestable_type', 'requestable_id']);
        });

        // Migrate existing pharmacy_id data to polymorphic columns
        DB::table('withdrawal_requests')
            ->whereNotNull('pharmacy_id')
            ->whereNull('requestable_type')
            ->update([
                'requestable_type' => 'App\\Models\\Pharmacy',
                'requestable_id' => DB::raw('pharmacy_id'),
            ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('withdrawal_requests', function (Blueprint $table) {
            $table->dropIndex(['requestable_type', 'requestable_id']);
            $table->dropColumn(['requestable_type', 'requestable_id']);
        });
    }
};
