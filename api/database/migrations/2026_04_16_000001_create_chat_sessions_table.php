<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Sessions de chat persistantes pharmacie ↔ client.
 *
 * Différentes des messages liés aux livraisons (delivery_messages) :
 * ici la session survit à la livraison et permet un suivi client long terme.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_sessions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('pharmacy_id');
            $table->string('client_type', 50)->default('customer'); // 'customer'|'pharmacy_user'
            $table->unsignedBigInteger('client_id');
            $table->enum('status', ['active', 'closed', 'archived'])->default('active');
            $table->timestamp('last_message_at')->nullable();
            $table->timestamps();

            $table->foreign('pharmacy_id')->references('id')->on('pharmacies')->cascadeOnDelete();

            // Unicité : une seule session active par paire pharmacie+client
            $table->unique(['pharmacy_id', 'client_type', 'client_id']);

            // Index pour listage rapide par pharmacie
            $table->index(['pharmacy_id', 'status', 'last_message_at']);
        });

        Schema::create('chat_session_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('session_id')->constrained('chat_sessions')->cascadeOnDelete();
            $table->string('sender_type', 50);   // 'pharmacy_user' | 'customer'
            $table->unsignedBigInteger('sender_id');
            $table->text('message');
            $table->string('type', 20)->default('text');        // text|image|file
            $table->json('metadata')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->softDeletes();
            $table->timestamps();

            // Index pour pagination curseur (le plus fréquent)
            $table->index(['session_id', 'id']);
            // Index pour les messages non lus
            $table->index(['session_id', 'read_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_session_messages');
        Schema::dropIfExists('chat_sessions');
    }
};
