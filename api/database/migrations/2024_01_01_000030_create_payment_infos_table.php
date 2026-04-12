<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('payment_infos')) { return; }

        Schema::create('payment_infos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pharmacy_id')->constrained()->cascadeOnDelete();
            $table->string('type'); // bank, mobile_money
            $table->string('bank_name')->nullable();
            $table->string('holder_name')->nullable();
            $table->string('account_number')->nullable();
            $table->string('iban')->nullable();
            $table->string('operator')->nullable();
            $table->string('phone_number')->nullable();
            $table->boolean('is_primary')->default(false);
            $table->boolean('is_verified')->default(false);
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();

            $table->index(['pharmacy_id', 'is_primary']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_infos');
    }
};
