<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('ratings')) { return; }

        Schema::create('ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->morphs('rateable'); // rateable_type + rateable_id
            $table->unsignedTinyInteger('rating'); // 1-5
            $table->text('comment')->nullable();
            $table->json('tags')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'order_id', 'rateable_type', 'rateable_id'], 'ratings_unique');
            $table->index(['rateable_type', 'rateable_id', 'rating']);
        });

        // Add customer_rating columns to deliveries for the existing rateCustomer flow
        Schema::table('deliveries', function (Blueprint $table) {
            $table->unsignedTinyInteger('customer_rating')->nullable()->after('cancellation_reason');
            $table->text('customer_rating_comment')->nullable()->after('customer_rating');
            $table->json('customer_rating_tags')->nullable()->after('customer_rating_comment');
            $table->timestamp('customer_rated_at')->nullable()->after('customer_rating_tags');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ratings');

        Schema::table('deliveries', function (Blueprint $table) {
            $table->dropColumn([
                'customer_rating',
                'customer_rating_comment',
                'customer_rating_tags',
                'customer_rated_at',
            ]);
        });
    }
};
