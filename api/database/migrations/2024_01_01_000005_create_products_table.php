<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('products')) { return; }

        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pharmacy_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name');
            $table->string('slug')->nullable();
            $table->text('description')->nullable();
            $table->string('category')->nullable();
            $table->string('brand')->nullable();
            $table->decimal('price', 12, 2);
            $table->decimal('discount_price', 12, 2)->nullable();
            $table->integer('stock_quantity')->default(0);
            $table->integer('low_stock_threshold')->default(5);
            $table->string('sku')->nullable();
            $table->string('barcode')->nullable();
            $table->string('image')->nullable();
            $table->json('images')->nullable();
            $table->boolean('requires_prescription')->default(false);
            $table->boolean('is_available')->default(true);
            $table->string('delivery_option')->nullable();
            $table->boolean('is_featured')->default(false);
            $table->string('unit')->nullable();
            $table->integer('units_per_pack')->nullable();
            $table->date('expiry_date')->nullable();
            $table->string('manufacturer')->nullable();
            $table->string('active_ingredient')->nullable();
            $table->text('usage_instructions')->nullable();
            $table->text('side_effects')->nullable();
            $table->json('tags')->nullable();
            $table->unsignedInteger('views_count')->default(0);
            $table->unsignedInteger('sales_count')->default(0);
            $table->decimal('average_rating', 3, 2)->default(0);
            $table->unsignedInteger('reviews_count')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['pharmacy_id', 'is_available']);
            $table->index('slug');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
