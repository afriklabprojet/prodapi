<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fraud_events', function (Blueprint $table) {
            $table->id();
            $table->string('type', 64)->index(); // prescription_reuse, payment_replay, prescription_rejected_repeat, ...
            $table->string('severity', 16)->default('low'); // low, medium, high, critical
            $table->unsignedTinyInteger('score')->default(10); // 0-100
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete()->index();
            $table->nullableMorphs('subject'); // ex: Prescription, Order, PaymentIntent
            $table->ipAddress('ip')->nullable();
            $table->string('user_agent', 255)->nullable();
            $table->json('payload')->nullable();
            $table->boolean('reviewed')->default(false)->index();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->index(['type', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fraud_events');
    }
};
