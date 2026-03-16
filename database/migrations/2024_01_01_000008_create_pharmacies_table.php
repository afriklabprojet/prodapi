<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pharmacies', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('phone')->unique();
            $table->string('email')->nullable()->unique();
            $table->text('address');
            $table->string('city');
            $table->string('region')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->string('status')->default('pending');
            $table->decimal('commission_rate_platform', 5, 2)->default(0.10);
            $table->decimal('commission_rate_pharmacy', 5, 2)->default(0.85);
            $table->decimal('commission_rate_courier', 5, 2)->default(0.05);
            $table->string('license_number')->nullable();
            $table->string('owner_name')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
            $table->foreignId('duty_zone_id')->nullable()->constrained()->nullOnDelete();
            $table->string('license_document')->nullable();
            $table->boolean('is_featured')->default(false);
            $table->string('id_card_document')->nullable();
            $table->decimal('withdrawal_threshold', 12, 2)->default(50000);
            $table->boolean('auto_withdraw_enabled')->default(false);
            $table->boolean('is_open')->default(true);
            $table->string('withdrawal_pin')->nullable();
            $table->timestamp('pin_set_at')->nullable();
            $table->integer('pin_attempts')->default(0);
            $table->timestamp('pin_locked_until')->nullable();

            $table->index(['latitude', 'longitude']);
            $table->index(['status', 'city']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pharmacies');
    }
};
