<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('webhook_logs')) { return; }

        Schema::create('webhook_logs', function (Blueprint $table) {
            $table->id();
            $table->string('provider');
            $table->string('webhook_id')->nullable();
            $table->string('event_type')->nullable();
            $table->string('reference')->nullable();
            $table->string('status')->default('received');
            $table->json('payload')->nullable();
            $table->string('ip_address')->nullable();
            $table->boolean('processed')->default(false);
            $table->text('error_message')->nullable();
            $table->integer('attempts')->default(0);
            $table->timestamps();

            $table->index(['provider', 'processed']);
            $table->index('reference');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('webhook_logs');
    }
};
