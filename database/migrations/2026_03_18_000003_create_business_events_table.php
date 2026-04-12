<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('business_events')) {
            Schema::create('business_events', function (Blueprint $table) {
                $table->id();
                $table->string('event', 100)->index();
                $table->unsignedBigInteger('user_id')->nullable()->index();
                $table->json('properties')->nullable();
                $table->string('ip_address', 45)->nullable();
                $table->string('user_agent', 500)->nullable();
                $table->timestamp('created_at')->useCurrent()->index();

                // Index composite pour les requêtes analytics
                $table->index(['event', 'created_at'], 'idx_event_date');
                $table->index(['user_id', 'event'], 'idx_user_event');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('business_events');
    }
};
