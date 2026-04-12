<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('couriers')) { return; }

        Schema::create('couriers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('phone')->nullable();
            $table->string('vehicle_type')->nullable();
            $table->string('vehicle_number')->nullable();
            $table->string('license_number')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->string('status')->default('offline');
            $table->decimal('rating', 3, 1)->default(0);
            $table->integer('completed_deliveries')->default(0);
            $table->timestamp('last_location_update')->nullable();
            $table->string('driving_license_front_document')->nullable();
            $table->string('driving_license_back_document')->nullable();
            $table->string('vehicle_registration_document')->nullable();
            $table->string('id_card_front_document')->nullable();
            $table->string('id_card_back_document')->nullable();
            $table->string('selfie_document')->nullable();
            $table->string('kyc_status')->default('pending');
            $table->text('kyc_rejection_reason')->nullable();
            $table->timestamp('kyc_verified_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['status', 'latitude', 'longitude']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('couriers');
    }
};
