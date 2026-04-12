<?php

namespace Tests\Unit\Models;

use App\Models\Rating;
use App\Models\User;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Courier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RatingTest extends TestCase
{
    use RefreshDatabase;

    public function test_fillable_attributes(): void
    {
        $rating = new Rating();
        $fillable = $rating->getFillable();
        $this->assertContains('user_id', $fillable);
        $this->assertContains('order_id', $fillable);
        $this->assertContains('rateable_type', $fillable);
        $this->assertContains('rateable_id', $fillable);
        $this->assertContains('rating', $fillable);
        $this->assertContains('comment', $fillable);
        $this->assertContains('tags', $fillable);
    }

    public function test_casts_rating_as_integer(): void
    {
        $rating = new Rating();
        $casts = $rating->getCasts();
        $this->assertSame('integer', $casts['rating']);
    }

    public function test_casts_tags_as_array(): void
    {
        $rating = new Rating();
        $casts = $rating->getCasts();
        $this->assertSame('array', $casts['tags']);
    }

    public function test_user_relationship(): void
    {
        $rating = new Rating();
        $relation = $rating->user();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $relation);
    }

    public function test_order_relationship(): void
    {
        $rating = new Rating();
        $relation = $rating->order();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $relation);
    }

    public function test_rateable_relationship(): void
    {
        $rating = new Rating();
        $relation = $rating->rateable();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\MorphTo::class, $relation);
    }

    public function test_scope_for_type_filters_by_rateable_type(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        $courier = Courier::factory()->create();
        
        $order1 = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);
        $order2 = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);

        // Rating for pharmacy
        $pharmacyRating = Rating::create([
            'user_id' => $user->id,
            'order_id' => $order1->id,
            'rateable_type' => Pharmacy::class,
            'rateable_id' => $pharmacy->id,
            'rating' => 5,
        ]);

        // Rating for courier
        $courierRating = Rating::create([
            'user_id' => $user->id,
            'order_id' => $order2->id,
            'rateable_type' => Courier::class,
            'rateable_id' => $courier->id,
            'rating' => 4,
        ]);

        $pharmacyRatings = Rating::forType(Pharmacy::class)->get();
        $courierRatings = Rating::forType(Courier::class)->get();

        $this->assertCount(1, $pharmacyRatings);
        $this->assertCount(1, $courierRatings);
        $this->assertEquals($pharmacyRating->id, $pharmacyRatings->first()->id);
        $this->assertEquals($courierRating->id, $courierRatings->first()->id);
    }

    public function test_scope_for_rateable_filters_by_type_and_id(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $pharmacy1 = Pharmacy::factory()->create();
        $pharmacy2 = Pharmacy::factory()->create();
        
        $order1 = Order::factory()->create(['pharmacy_id' => $pharmacy1->id]);
        $order2 = Order::factory()->create(['pharmacy_id' => $pharmacy2->id]);

        // Rating for pharmacy 1
        $rating1 = Rating::create([
            'user_id' => $user->id,
            'order_id' => $order1->id,
            'rateable_type' => Pharmacy::class,
            'rateable_id' => $pharmacy1->id,
            'rating' => 5,
        ]);

        // Rating for pharmacy 2
        $rating2 = Rating::create([
            'user_id' => $user->id,
            'order_id' => $order2->id,
            'rateable_type' => Pharmacy::class,
            'rateable_id' => $pharmacy2->id,
            'rating' => 4,
        ]);

        $pharmacy1Ratings = Rating::forRateable(Pharmacy::class, $pharmacy1->id)->get();

        $this->assertCount(1, $pharmacy1Ratings);
        $this->assertEquals($rating1->id, $pharmacy1Ratings->first()->id);
    }
}
