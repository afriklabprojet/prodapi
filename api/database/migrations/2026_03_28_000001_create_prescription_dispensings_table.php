<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Ajout colonnes anti-réutilisation sur prescriptions
        Schema::table('prescriptions', function (Blueprint $table) {
            $table->string('fulfillment_status', 20)->default('none')->after('status')
                ->comment('none, partial, full');
            $table->unsignedInteger('dispensing_count')->default(0)->after('fulfillment_status');
            $table->timestamp('first_dispensed_at')->nullable()->after('dispensing_count');
            $table->string('image_hash', 64)->nullable()->after('first_dispensed_at')
                ->comment('SHA-256 hash de la première image pour détection doublons');
            $table->index('image_hash');
            $table->index('fulfillment_status');
        });

        // Table de dispensation par médicament
        Schema::create('prescription_dispensings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('prescription_id')->constrained()->cascadeOnDelete();
            $table->foreignId('pharmacy_id')->constrained()->cascadeOnDelete();
            $table->foreignId('order_id')->nullable()->constrained()->nullOnDelete();
            $table->string('medication_name');
            $table->foreignId('product_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedInteger('quantity_prescribed')->default(1);
            $table->unsignedInteger('quantity_dispensed')->default(1);
            $table->timestamp('dispensed_at');
            $table->foreignId('dispensed_by')->constrained('users')->cascadeOnDelete();
            $table->timestamps();

            $table->index(['prescription_id', 'medication_name']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('prescription_dispensings');

        Schema::table('prescriptions', function (Blueprint $table) {
            $table->dropIndex(['image_hash']);
            $table->dropIndex(['fulfillment_status']);
            $table->dropColumn([
                'fulfillment_status',
                'dispensing_count',
                'first_dispensed_at',
                'image_hash',
            ]);
        });
    }
};
