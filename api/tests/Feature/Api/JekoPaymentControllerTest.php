<?php

namespace Tests\Feature\Api;

use App\Models\Customer;
use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Services\JekoPaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;

class JekoPaymentControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Order $order;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->user = User::factory()->create(['role' => 'customer', 'phone_verified_at' => now()]);
        Customer::factory()->create(['user_id' => $this->user->id]);
        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $this->user->id,
            'status' => 'pending',
            'payment_status' => 'unpaid',
            'total_amount' => 5000,
        ]);
    }

    public function test_user_can_list_payments(): void
    {
        JekoPayment::factory()->create(['user_id' => $this->user->id]);

        $response = $this->actingAs($this->user)->getJson('/api/customer/payments');

        $response->assertOk()
            ->assertJsonStructure(['success', 'data']);
    }

    public function test_user_can_get_payment_methods(): void
    {
        $mock = Mockery::mock(JekoPaymentService::class);
        $mock->shouldReceive('getAvailableMethods')->andReturn([
            ['id' => 'wave', 'name' => 'Wave', 'available' => true],
        ]);
        $this->app->instance(JekoPaymentService::class, $mock);

        $response = $this->actingAs($this->user)->getJson('/api/customer/payments/methods');

        $response->assertOk()->assertJsonStructure(['success', 'data']);
    }

    public function test_user_can_check_payment_status(): void
    {
        $payment = JekoPayment::factory()->create([
            'user_id' => $this->user->id,
            'reference' => 'JEKO-TEST-REF-001',
            'status' => 'pending',
        ]);

        $mock = Mockery::mock(JekoPaymentService::class);
        $mock->shouldReceive('checkPaymentStatus')->andReturn($payment);
        $this->app->instance(JekoPaymentService::class, $mock);

        $response = $this->actingAs($this->user)->getJson('/api/customer/payments/JEKO-TEST-REF-001/status');

        $response->assertOk()
            ->assertJsonPath('data.reference', 'JEKO-TEST-REF-001');
    }

    public function test_user_cannot_check_other_users_payment(): void
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        JekoPayment::factory()->create([
            'user_id' => $otherUser->id,
            'reference' => 'JEKO-OTHER-REF',
        ]);

        $response = $this->actingAs($this->user)->getJson('/api/customer/payments/JEKO-OTHER-REF/status');

        $response->assertStatus(404);
    }

    public function test_unauthenticated_user_cannot_access_payments(): void
    {
        $response = $this->getJson('/api/customer/payments');
        $response->assertStatus(401);
    }
}
