<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('pharmacy_statement_preferences')) { return; }

        Schema::create('pharmacy_statement_preferences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pharmacy_id')->constrained()->cascadeOnDelete();
            $table->string('frequency')->default('weekly');
            $table->string('format')->default('pdf');
            $table->boolean('auto_send')->default(true);
            $table->string('email')->nullable();
            $table->timestamp('next_send_at')->nullable();
            $table->timestamp('last_sent_at')->nullable();
            $table->timestamps();

            $table->unique('pharmacy_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pharmacy_statement_preferences');
    }
};
