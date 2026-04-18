<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_batches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->foreignId('pharmacy_id')->constrained()->cascadeOnDelete();
            $table->string('batch_number');
            $table->string('lot_number')->nullable();
            $table->date('expiry_date');
            $table->integer('quantity')->default(0);
            $table->date('received_at')->nullable();
            $table->string('supplier')->nullable();
            $table->timestamps();

            $table->unique(['pharmacy_id', 'product_id', 'batch_number']);
            $table->index(['pharmacy_id', 'expiry_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_batches');
    }
};
