<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customer_loyalty_points', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->integer('points')->default(0);
            $table->string('type'); // earned, redeemed, expired, bonus
            $table->string('source')->nullable(); // order, referral, bonus, promo
            $table->unsignedBigInteger('source_id')->nullable(); // order_id, etc.
            $table->string('description')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'type']);
            $table->index(['user_id', 'created_at']);
        });

        Schema::create('loyalty_rewards', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('description')->nullable();
            $table->string('type'); // discount, free_delivery, gift
            $table->integer('points_cost');
            $table->integer('value')->default(0); // discount amount in FCFA or percentage
            $table->string('value_type')->default('fixed'); // fixed, percentage
            $table->string('min_tier')->default('bronze'); // bronze, silver, gold, platinum
            $table->boolean('is_active')->default(true);
            $table->integer('max_redemptions')->nullable();
            $table->integer('redemptions_count')->default(0);
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->index(['is_active', 'min_tier']);
        });

        Schema::create('loyalty_redemptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('loyalty_reward_id')->constrained()->cascadeOnDelete();
            $table->integer('points_spent');
            $table->string('status')->default('pending'); // pending, applied, expired
            $table->string('code')->unique(); // redemption code
            $table->foreignId('order_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamp('applied_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loyalty_redemptions');
        Schema::dropIfExists('loyalty_rewards');
        Schema::dropIfExists('customer_loyalty_points');
    }
};
