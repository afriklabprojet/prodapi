<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('prescriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('pharmacy_id')->nullable()->constrained()->nullOnDelete();
            $table->json('images');
            $table->text('notes')->nullable();
            $table->string('status')->default('pending')->index();
            $table->text('admin_notes')->nullable();
            $table->timestamp('validated_at')->nullable();
            $table->foreignId('validated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->decimal('quote_amount', 12, 2)->nullable();
            $table->text('pharmacy_notes')->nullable();
            $table->foreignId('order_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('source', ['upload', 'checkout'])->default('upload');
            $table->timestamps();

            $table->index('customer_id');
            $table->index(['customer_id', 'order_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('prescriptions');
    }
};
