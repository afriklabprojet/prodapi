<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('withdrawal_requests')) { return; }

        Schema::create('withdrawal_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('pharmacy_id')->nullable()->constrained()->nullOnDelete();
            $table->decimal('amount', 14, 2);
            $table->string('payment_method')->nullable();
            $table->json('account_details')->nullable();
            $table->string('reference')->unique();
            $table->string('status')->default('pending');
            $table->timestamp('processed_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->text('admin_notes')->nullable();
            $table->text('error_message')->nullable();
            $table->string('jeko_reference')->nullable();
            $table->string('jeko_payment_id')->nullable();
            $table->string('phone')->nullable();
            $table->json('bank_details')->nullable();
            $table->timestamps();

            $table->index(['wallet_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('withdrawal_requests');
    }
};
