<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('jeko_payments')) { return; }

        Schema::create('jeko_payments', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('reference')->unique();
            $table->string('jeko_payment_request_id')->nullable();
            $table->string('payable_type');
            $table->unsignedBigInteger('payable_id');
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->integer('amount_cents');
            $table->string('currency')->default('XOF');
            $table->string('payment_method')->nullable();
            $table->string('status')->default('pending');
            $table->string('redirect_url')->nullable();
            $table->string('success_url')->nullable();
            $table->string('error_url')->nullable();
            $table->json('transaction_data')->nullable();
            $table->text('error_message')->nullable();
            $table->timestamp('initiated_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('webhook_received_at')->nullable();
            $table->boolean('webhook_processed')->default(false);
            $table->boolean('is_payout')->default(false);
            $table->string('recipient_phone')->nullable();
            $table->json('bank_details')->nullable();
            $table->text('description')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['payable_type', 'payable_id']);
            $table->index(['status', 'is_payout']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jeko_payments');
    }
};
