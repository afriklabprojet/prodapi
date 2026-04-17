<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('promo_codes')) {
            Schema::create('promo_codes', function (Blueprint $table) {
                $table->id();
                $table->string('code', 50)->unique();
                $table->string('description')->nullable();
                $table->enum('type', ['percentage', 'fixed'])->default('fixed');
                $table->decimal('value', 10, 2); // pourcentage ou montant fixe
                $table->decimal('max_discount', 10, 2)->nullable(); // plafond pour percentage
                $table->decimal('min_order_amount', 10, 2)->nullable();
                $table->unsignedInteger('max_uses')->nullable(); // null = illimité
                $table->unsignedInteger('max_uses_per_user')->default(1);
                $table->unsignedInteger('current_uses')->default(0);
                $table->boolean('is_active')->default(true);
                $table->timestamp('starts_at')->nullable();
                $table->timestamp('expires_at')->nullable();
                $table->timestamps();

                $table->index(['code', 'is_active']);
                $table->index('expires_at');
            });
        }

        if (!Schema::hasTable('promo_code_usages')) {
            Schema::create('promo_code_usages', function (Blueprint $table) {
                $table->id();
                $table->foreignId('promo_code_id')->constrained('promo_codes')->onDelete('cascade');
                $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
                $table->foreignId('order_id')->nullable()->constrained('orders')->onDelete('set null');
                $table->decimal('discount_applied', 10, 2)->nullable();
                $table->timestamp('used_at');

                $table->index(['promo_code_id', 'user_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('promo_code_usages');
        Schema::dropIfExists('promo_codes');
    }
};
