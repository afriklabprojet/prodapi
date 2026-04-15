<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('delivery_messages', function (Blueprint $table) {
            // Type de message (text, image, file, location, system)
            $table->string('type', 20)->default('text')->after('message');
            
            // Métadonnées JSON (URL fichier, dimensions image, coordonnées GPS, etc.)
            $table->json('metadata')->nullable()->after('type');
            
            // Soft delete pour garder l'historique
            $table->softDeletes();
            
            // Index composites pour requêtes optimisées
            $table->index(['delivery_id', 'created_at'], 'idx_delivery_messages_conversation');
            $table->index(['receiver_type', 'receiver_id', 'read_at'], 'idx_delivery_messages_unread');
            $table->index(['sender_type', 'sender_id'], 'idx_delivery_messages_sender');
        });
    }

    public function down(): void
    {
        Schema::table('delivery_messages', function (Blueprint $table) {
            $table->dropColumn(['type', 'metadata']);
            $table->dropSoftDeletes();
            $table->dropIndex('idx_delivery_messages_conversation');
            $table->dropIndex('idx_delivery_messages_unread');
            $table->dropIndex('idx_delivery_messages_sender');
        });
    }
};
