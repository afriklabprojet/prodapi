<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Ajouter colonne business_processed pour idempotency du traitement métier
        if (Schema::hasTable('jeko_payments') && !Schema::hasColumn('jeko_payments', 'business_processed')) {
            Schema::table('jeko_payments', function (Blueprint $table) {
                $table->boolean('business_processed')->default(false)->after('webhook_processed');
                $table->index(['status', 'created_at'], 'idx_jeko_status_created');
                $table->index(['payable_type', 'payable_id', 'status'], 'idx_jeko_payable_status');
            });
        }

        // Table de tracking de webhooks reçus (déduplication persistante)
        if (!Schema::hasTable('webhook_logs')) {
            Schema::create('webhook_logs', function (Blueprint $table) {
                $table->id();
                $table->string('provider', 50)->index();          // jeko, infobip, etc.
                $table->string('webhook_id', 191)->unique();      // ID unique du webhook
                $table->string('event_type', 100)->nullable();    // payment.success, etc.
                $table->string('reference', 191)->nullable()->index();
                $table->string('status', 50)->nullable();
                $table->json('payload')->nullable();
                $table->string('ip_address', 45)->nullable();
                $table->boolean('processed')->default(false);
                $table->text('error_message')->nullable();
                $table->unsignedTinyInteger('attempts')->default(0);
                $table->timestamps();
                
                $table->index(['provider', 'processed']);
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('jeko_payments') && Schema::hasColumn('jeko_payments', 'business_processed')) {
            Schema::table('jeko_payments', function (Blueprint $table) {
                $table->dropColumn('business_processed');
                $table->dropIndex('idx_jeko_status_created');
                $table->dropIndex('idx_jeko_payable_status');
            });
        }

        Schema::dropIfExists('webhook_logs');
    }
};
