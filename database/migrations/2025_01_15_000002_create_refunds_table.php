<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('refunds')) {
            Schema::create('refunds', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
                $table->foreignId('order_id')->constrained('orders')->onDelete('cascade');
                $table->decimal('amount', 10, 2);
                $table->string('reason', 500);
                $table->enum('type', ['full', 'partial'])->default('full');
                $table->enum('status', ['pending', 'approved', 'rejected', 'processed'])->default('pending');
                $table->string('admin_note', 500)->nullable();
                $table->foreignId('processed_by')->nullable()->constrained('users')->onDelete('set null');
                $table->timestamp('processed_at')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'status']);
                $table->index(['order_id', 'status']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('refunds');
    }
};
