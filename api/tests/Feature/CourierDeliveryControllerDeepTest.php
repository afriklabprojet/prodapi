<?php

namespace Tests\Feature;

use App\Actions\CalculateCommissionAction;
use App\Models\Challenge;
use App\Models\Courier;
use App\Models\Customer;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Services\FirestoreService;
use App\Services\GoogleMapsService;
use App\Services\WaitingFeeService;
use App\Services\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class CourierDeliveryControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    private User $courierUser;
    private Courier $courier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->courierUser = User::factory()->create([
            'role' => 'courier',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);

        $this->courier = Courier::factory()->create([
            'user_id' => $this->courierUser->id,
            'status' => 'available',
        ]);

        // Mock Firestore to prevent real API calls
        $this->mock(FirestoreService::class, function ($mock) {
            $mock->shouldReceive('updateDeliveryStatus')->andReturn(null);
        });
    }

    private function actingAsCourier()
    {
        return $this->actingAs($this->courierUser, 'sanctum');
    }

    private function createDeliveryWithOrder(array $deliveryOverrides = [], array $orderOverrides = []): Delivery
    {
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $customer = User::factory()->create(['role' => 'customer']);

        $order = Order::factory()->create(array_merge([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customer->id,
            'status' => 'confirmed',
            'delivery_fee' => 1000,
            'total_amount' => 5000,
        ], $orderOverrides));

        return Delivery::factory()->create(array_merge([
            'order_id' => $order->id,
            'courier_id' => null,
            'status' => 'pending',
        ], $deliveryOverrides));
    }

    // ─── INDEX ───────────────────────────────────────────────────────────────

    public function test_index_returns_marketplace_deliveries(): void
    {
        $delivery = $this->createDeliveryWithOrder();

        $response = $this->actingAsCourier()->getJson('/api/courier/deliveries');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_index_returns_personal_deliveries(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAsCourier()->getJson('/api/courier/deliveries?type=personal');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_index_requires_auth(): void
    {
        $this->getJson('/api/courier/deliveries')->assertUnauthorized();
    }

    // ─── SHOW ────────────────────────────────────────────────────────────────

    public function test_show_own_delivery(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAsCourier()->getJson("/api/courier/deliveries/{$delivery->id}");

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_show_returns_403_without_courier_profile(): void
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);
        $delivery = $this->createDeliveryWithOrder();

        $response = $this->actingAs($userWithoutCourier, 'sanctum')
            ->getJson("/api/courier/deliveries/{$delivery->id}");

        $response->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    // ─── ACCEPT ──────────────────────────────────────────────────────────────

    public function test_accept_pending_delivery(): void
    {
        $delivery = $this->createDeliveryWithOrder();

        $this->mock(WalletService::class, function ($mock) {
            $mock->shouldReceive('getCommissionAmount')->andReturn(200);
            $mock->shouldReceive('getDeliveryFeeBase')->andReturn(200);
        });

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/accept");

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('deliveries', [
            'id' => $delivery->id,
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);
    }

    public function test_accept_already_assigned_delivery_returns_conflict(): void
    {
        $otherCourier = Courier::factory()->create();
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $otherCourier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/accept");

        $response->assertStatus(404);
    }

    // ─── BATCH ACCEPT ────────────────────────────────────────────────────────

    public function test_batch_accept_multiple_deliveries(): void
    {
        $d1 = $this->createDeliveryWithOrder();
        $d2 = $this->createDeliveryWithOrder();

        $this->mock(WalletService::class, function ($mock) {
            $mock->shouldReceive('getCommissionAmount')->andReturn(200);
            $mock->shouldReceive('getDeliveryFeeBase')->andReturn(200);
        });

        $response = $this->actingAsCourier()->postJson('/api/courier/deliveries/batch-accept', [
            'delivery_ids' => [$d1->id, $d2->id],
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.accepted_count', 2);
    }

    public function test_batch_accept_exceeds_max_active_returns_error(): void
    {
        // Create 5 already active deliveries for this courier
        for ($i = 0; $i < 5; $i++) {
            $this->createDeliveryWithOrder([
                'courier_id' => $this->courier->id,
                'status' => 'assigned',
            ]);
        }

        $newDelivery = $this->createDeliveryWithOrder();

        $response = $this->actingAsCourier()->postJson('/api/courier/deliveries/batch-accept', [
            'delivery_ids' => [$newDelivery->id],
        ]);

        $response->assertStatus(400);
    }

    public function test_batch_accept_validation_requires_array(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/deliveries/batch-accept', []);

        $response->assertUnprocessable();
    }

    public function test_batch_accept_unavailable_delivery_returns_conflict(): void
    {
        $d1 = $this->createDeliveryWithOrder();
        // Assign d1 first
        $d1->update(['courier_id' => Courier::factory()->create()->id, 'status' => 'assigned']);

        $d2 = $this->createDeliveryWithOrder();

        $this->mock(WalletService::class, function ($mock) {
            $mock->shouldReceive('getCommissionAmount')->andReturn(200);
            $mock->shouldReceive('getDeliveryFeeBase')->andReturn(200);
        });

        $response = $this->actingAsCourier()->postJson('/api/courier/deliveries/batch-accept', [
            'delivery_ids' => [$d1->id, $d2->id],
        ]);

        $response->assertStatus(409);
    }

    // ─── PICKUP ──────────────────────────────────────────────────────────────

    public function test_pickup_assigned_delivery(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/pickup");

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('deliveries', [
            'id' => $delivery->id,
            'status' => 'picked_up',
        ]);
    }

    public function test_pickup_wrong_status_returns_error(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'delivered',
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/pickup");

        $response->assertStatus(400);
    }

    public function test_pickup_accepted_delivery(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'accepted',
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/pickup");

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('deliveries', [
            'id' => $delivery->id,
            'status' => 'picked_up',
        ]);
    }

    // ─── DELIVER ─────────────────────────────────────────────────────────────

    public function test_deliver_with_correct_code(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
        ]);
        $delivery->order->update(['delivery_code' => '1234', 'delivery_fee' => 1000]);

        $wallet = Wallet::create([
            'walletable_id' => $this->courier->id,
            'walletable_type' => Courier::class,
            'balance' => 5000,
            'currency' => 'XOF',
        ]);

        $earnTx = new WalletTransaction(['type' => 'credit', 'amount' => 1000, 'reference' => 'REF-EARN', 'balance_after' => 5800]);
        $earnTx->id = 1;
        $commTx = new WalletTransaction(['type' => 'debit', 'amount' => 200, 'reference' => 'REF-COMM', 'balance_after' => 5600]);
        $commTx->id = 2;

        $this->mock(WalletService::class, function ($mock) use ($earnTx, $commTx) {
            $mock->shouldReceive('canCompleteDelivery')->andReturn(true);
            $mock->shouldReceive('creditDeliveryEarning')->andReturn($earnTx);
            $mock->shouldReceive('deductCommission')->andReturn($commTx);
            $mock->shouldReceive('getCommissionAmount')->andReturn(200);
            $mock->shouldReceive('getBalance')->andReturn(['balance' => 4800, 'currency' => 'XOF']);
        });

        $this->mock(CalculateCommissionAction::class, function ($mock) {
            $mock->shouldReceive('execute')->once();
        });

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/deliver", [
            'confirmation_code' => '1234',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('deliveries', [
            'id' => $delivery->id,
            'status' => 'delivered',
        ]);
    }

    public function test_deliver_wrong_code_returns_error(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
        ]);
        $delivery->order->update(['delivery_code' => '1234']);

        $this->mock(WalletService::class, function ($mock) {
            $mock->shouldReceive('canCompleteDelivery')->andReturn(true);
        });

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/deliver", [
            'confirmation_code' => '0000',
        ]);

        $response->assertStatus(400);
    }

    public function test_deliver_already_delivered_returns_conflict(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'delivered',
        ]);
        $delivery->order->update(['delivery_code' => '1234']);

        $this->mock(WalletService::class, function ($mock) {
            $mock->shouldReceive('canCompleteDelivery')->andReturn(true);
        });

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/deliver", [
            'confirmation_code' => '1234',
        ]);

        $response->assertStatus(409);
    }

    public function test_deliver_insufficient_balance_returns_error(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
        ]);
        $delivery->order->update(['delivery_code' => '1234']);

        $this->mock(WalletService::class, function ($mock) {
            $mock->shouldReceive('canCompleteDelivery')->andReturn(false);
        });

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/deliver", [
            'confirmation_code' => '1234',
        ]);

        $response->assertStatus(402);
    }

    public function test_deliver_requires_confirmation_code(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/deliver", []);

        $response->assertUnprocessable();
    }

    public function test_deliver_wrong_status_returns_bad_request(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);
        $delivery->order->update(['delivery_code' => '1234']);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/deliver", [
            'confirmation_code' => '1234',
        ]);

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    // ─── UPDATE LOCATION ─────────────────────────────────────────────────────

    public function test_update_location_success(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/location/update', [
            'latitude' => 5.3456,
            'longitude' => -3.9876,
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_update_location_saves_history_for_active_delivery(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
        ]);

        $response = $this->actingAsCourier()->postJson('/api/courier/location/update', [
            'latitude' => 5.3456,
            'longitude' => -3.9876,
        ]);

        $response->assertOk();

        $delivery->refresh();
        $this->assertNotEmpty($delivery->location_history);
    }

    public function test_update_location_validation(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/location/update', []);

        $response->assertUnprocessable();
    }

    public function test_update_location_returns_403_without_courier_profile(): void
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);

        $response = $this->actingAs($userWithoutCourier, 'sanctum')->postJson('/api/courier/location/update', [
            'latitude' => 5.3456,
            'longitude' => -3.9876,
        ]);

        $response->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    // ─── TOGGLE AVAILABILITY ─────────────────────────────────────────────────

    public function test_toggle_availability_explicit_status(): void
    {
        $this->courier->update(['status' => 'available']);

        $response = $this->actingAsCourier()->postJson('/api/courier/availability/toggle', [
            'status' => 'offline',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.status', 'offline')
            ->assertJsonPath('data.is_online', false);
    }

    public function test_toggle_availability_auto_toggle(): void
    {
        $this->courier->update(['status' => 'available']);

        $response = $this->actingAsCourier()->postJson('/api/courier/availability/toggle');

        $response->assertOk()
            ->assertJsonPath('data.status', 'offline');
    }

    // ─── PROFILE ─────────────────────────────────────────────────────────────

    public function test_profile_returns_courier_data(): void
    {
        $response = $this->actingAsCourier()->getJson('/api/courier/profile');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['id', 'name', 'status', 'rating', 'badges', 'active_challenges']]);
    }

    public function test_profile_includes_completed_challenges_as_badges(): void
    {
        // Créer un challenge complété
        $completedChallenge = Challenge::factory()->create([
            'title' => 'Première livraison',
            'description' => 'Effectuer votre première livraison',
            'icon' => 'star',
            'color' => '#FFD700',
            'reward_amount' => 500,
        ]);

        // Attacher le challenge complété au coursier
        $this->courier->challenges()->attach($completedChallenge->id, [
            'status' => 'completed',
            'current_progress' => 1,
            'started_at' => now()->subDays(2),
            'completed_at' => now()->subDay(),
        ]);

        $response = $this->actingAsCourier()->getJson('/api/courier/profile');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.badges.0.title', 'Première livraison')
            ->assertJsonPath('data.badges.0.icon', 'star')
            ->assertJsonPath('data.badges.0.color', '#FFD700')
            ->assertJsonPath('data.badges.0.reward_amount', 500);
    }

    public function test_profile_includes_active_challenges(): void
    {
        // Créer un challenge actif en cours
        $activeChallenge = Challenge::factory()->create([
            'title' => '10 livraisons cette semaine',
            'target_value' => 10,
            'reward_amount' => 2000,
            'icon' => 'trophy',
            'color' => '#4CAF50',
            'is_active' => true,
            'ends_at' => now()->addDays(5),
        ]);

        // Attacher le challenge en cours au coursier
        $this->courier->challenges()->attach($activeChallenge->id, [
            'status' => 'in_progress',
            'current_progress' => 3,
            'started_at' => now()->subDays(2),
        ]);

        $response = $this->actingAsCourier()->getJson('/api/courier/profile');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.active_challenges.0.title', '10 livraisons cette semaine')
            ->assertJsonPath('data.active_challenges.0.target_value', 10)
            ->assertJsonPath('data.active_challenges.0.current_progress', 3)
            ->assertJsonPath('data.active_challenges.0.progress_percentage', 30);
    }

    // ─── RATE CUSTOMER ───────────────────────────────────────────────────────

    public function test_rate_customer_after_delivery(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'delivered',
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/rate-customer", [
            'rating' => 5,
            'comment' => 'Excellent client',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('deliveries', [
            'id' => $delivery->id,
            'customer_rating' => 5,
        ]);
    }

    public function test_rate_customer_already_rated_returns_error(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'delivered',
            'customer_rating' => 4,
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/rate-customer", [
            'rating' => 5,
        ]);

        $response->assertStatus(422);
    }

    // ─── ARRIVED ─────────────────────────────────────────────────────────────

    public function test_arrived_starts_waiting_timer(): void
    {
        \Illuminate\Support\Facades\Notification::fake();

        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
        ]);

        $this->mock(WaitingFeeService::class, function ($mock) {
            $mock->shouldReceive('getWaitingInfo')->andReturn([
                'timeout_minutes' => 10,
                'free_minutes' => 3,
                'fee_per_minute' => 100,
                'elapsed_minutes' => 0,
                'is_free_period' => true,
                'current_fee' => 0,
            ]);
        });

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/arrived");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['waiting_info']]);
    }

    public function test_arrived_wrong_status_returns_error(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/arrived");

        $response->assertStatus(400);
    }

    public function test_arrived_already_waiting_returns_error(): void
    {
        \Illuminate\Support\Facades\Notification::fake();

        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
            'waiting_started_at' => now(),
        ]);

        $this->mock(WaitingFeeService::class, function ($mock) {
            $mock->shouldReceive('getWaitingInfo')->andReturn([
                'timeout_minutes' => 10,
                'free_minutes' => 3,
                'fee_per_minute' => 100,
                'elapsed_minutes' => 2,
                'is_free_period' => true,
                'current_fee' => 0,
            ]);
        });

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/arrived");

        $response->assertStatus(400);
    }

    public function test_arrived_returns_403_without_courier_profile(): void
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);
        $delivery = $this->createDeliveryWithOrder();

        $response = $this->actingAs($userWithoutCourier, 'sanctum')
            ->postJson("/api/courier/deliveries/{$delivery->id}/arrived");

        $response->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    // ─── WAITING STATUS ──────────────────────────────────────────────────────

    public function test_waiting_status_returns_info(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
            'waiting_started_at' => now(),
        ]);

        $this->mock(WaitingFeeService::class, function ($mock) {
            $mock->shouldReceive('getWaitingInfo')->andReturn([
                'elapsed_minutes' => 5,
                'fee_per_minute' => 100,
            ]);
        });

        $response = $this->actingAsCourier()->getJson("/api/courier/deliveries/{$delivery->id}/waiting-status");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['waiting_info']]);
    }

    public function test_waiting_status_returns_403_without_courier_profile(): void
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);
        $delivery = $this->createDeliveryWithOrder();

        $response = $this->actingAs($userWithoutCourier, 'sanctum')
            ->getJson("/api/courier/deliveries/{$delivery->id}/waiting-status");

        $response->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    // ─── WAITING SETTINGS ────────────────────────────────────────────────────

    public function test_get_waiting_settings(): void
    {
        $this->mock(WaitingFeeService::class, function ($mock) {
            $mock->shouldReceive('getSettings')->andReturn([
                'timeout_minutes' => 10,
                'fee_per_minute' => 100,
                'free_minutes' => 3,
            ]);
        });

        $response = $this->actingAsCourier()->getJson('/api/courier/waiting-settings');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.timeout_minutes', 10);
    }

    // ─── REJECT ──────────────────────────────────────────────────────────────

    public function test_reject_pending_delivery(): void
    {
        $delivery = $this->createDeliveryWithOrder();

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/reject");

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_reject_assigned_delivery_returns_error(): void
    {
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/reject");

        $response->assertStatus(400);
    }

    // ─── UPLOAD PROOF ────────────────────────────────────────────────────────

    public function test_upload_delivery_proof(): void
    {
        Storage::fake('private');

        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'delivered',
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/proof", [
            'delivery_photo' => UploadedFile::fake()->image('proof.jpg'),
            'notes' => 'Livré devant la porte',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.has_photo', true);
    }

    public function test_upload_delivery_proof_with_signature_and_coordinates(): void
    {
        Storage::fake('private');

        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'delivered',
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/proof", [
            'delivery_photo' => UploadedFile::fake()->image('proof-2.jpg'),
            'signature' => UploadedFile::fake()->image('signature.png'),
            'notes' => 'Remis au client en main propre',
            'latitude' => 5.3488,
            'longitude' => -3.9872,
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.has_photo', true)
            ->assertJsonPath('data.has_signature', true);

        $delivery->refresh();
        $this->assertEquals('Remis au client en main propre', data_get($delivery->metadata, 'delivery_proof.notes'));
    }

    public function test_upload_delivery_proof_returns_403_without_courier_profile(): void
    {
        Storage::fake('private');

        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);
        $delivery = $this->createDeliveryWithOrder();

        $response = $this->actingAs($userWithoutCourier, 'sanctum')->postJson("/api/courier/deliveries/{$delivery->id}/proof", [
            'delivery_photo' => UploadedFile::fake()->image('proof.jpg'),
        ]);

        $response->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    // ─── OPTIMIZED ROUTE ─────────────────────────────────────────────────────
    public function test_optimized_route_empty_deliveries(): void
    {
        $response = $this->actingAsCourier()->getJson('/api/courier/deliveries/route');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.stops', []);
    }

    public function test_optimized_route_returns_403_without_courier_profile(): void
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);

        $response = $this->actingAs($userWithoutCourier, 'sanctum')
            ->getJson('/api/courier/deliveries/route');

        $response->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    public function test_optimized_route_with_active_deliveries(): void
    {
        $d1 = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
            'pickup_latitude' => 5.34,
            'pickup_longitude' => -3.98,
        ]);

        $this->mock(WalletService::class, function ($mock) {
            $mock->shouldReceive('getCommissionAmount')->andReturn(200);
            $mock->shouldReceive('getDeliveryFeeBase')->andReturn(200);
        });

        $response = $this->actingAsCourier()->getJson('/api/courier/deliveries/route');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['stops', 'pickup_count']]);
    }

    public function test_optimized_route_uses_google_directions_when_multiple_stops_exist(): void
    {
        $pickupDelivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
            'pickup_latitude' => 5.3400,
            'pickup_longitude' => -3.9800,
        ]);

        $dropoffDelivery = $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
            'dropoff_latitude' => 5.3600,
            'dropoff_longitude' => -3.9500,
        ], [
            'delivery_fee' => 1200,
            'total_amount' => 8000,
            'delivery_address' => 'Cocody Riviera',
        ]);

        $this->mock(GoogleMapsService::class, function ($mock) {
            $mock->shouldReceive('getDirections')->once()->andReturn([
                'polyline' => 'encoded-polyline',
                'total_distance_km' => 8.4,
                'total_duration_minutes' => 21,
                'waypoint_order' => [],
                'legs' => [
                    ['distance_text' => '4.1 km', 'duration_text' => '10 mins'],
                    ['distance_text' => '4.3 km', 'duration_text' => '11 mins'],
                ],
            ]);
        });

        $response = $this->actingAsCourier()
            ->getJson('/api/courier/deliveries/route?lat=5.3200&lng=-3.9700');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.route_source', 'google_directions')
            ->assertJsonPath('data.pickup_count', 1)
            ->assertJsonPath('data.delivery_count', 1)
            ->assertJsonPath('data.polyline', 'encoded-polyline');
    }

    public function test_optimized_route_falls_back_to_estimated_distances_when_maps_fails(): void
    {
        $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
            'estimated_distance' => 3.2,
            'pickup_latitude' => 5.3400,
            'pickup_longitude' => -3.9800,
        ]);

        $this->createDeliveryWithOrder([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
            'estimated_distance' => 4.5,
            'dropoff_latitude' => 5.3600,
            'dropoff_longitude' => -3.9500,
        ]);

        $this->mock(GoogleMapsService::class, function ($mock) {
            $mock->shouldReceive('getDirections')->once()->andThrow(new \Exception('Maps unavailable'));
        });

        $response = $this->actingAsCourier()->getJson('/api/courier/deliveries/route');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.route_source', 'estimated')
            ->assertJsonPath('data.total_distance_km', 7.7);
    }

    // ─── UPDATE COURIER PROFILE ──────────────────────────────────────────────

    public function test_update_courier_profile_name(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/profile/update', [
            'name' => 'Jean-Marc Livreur',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Jean-Marc Livreur');

        $this->courierUser->refresh();
        $this->assertEquals('Jean-Marc Livreur', $this->courierUser->name);
    }

    public function test_update_courier_profile_vehicle_info(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/profile/update', [
            'vehicle_type' => 'motorcycle',
            'vehicle_number' => 'AB-123-CI',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.vehicle_type', 'motorcycle');

        $this->courier->refresh();
        $this->assertEquals('motorcycle', $this->courier->vehicle_type);
        $this->assertEquals('AB-123-CI', $this->courier->vehicle_number);
    }

    public function test_update_courier_profile_phone(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/profile/update', [
            'phone' => '+22507999999',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->courierUser->refresh();
        $this->assertEquals('+22507999999', $this->courierUser->phone);
    }

    public function test_update_courier_profile_invalid_vehicle_type(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/profile/update', [
            'vehicle_type' => 'helicopter', // Invalid
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['vehicle_type']);
    }

    public function test_update_courier_profile_duplicate_phone(): void
    {
        $otherUser = User::factory()->create(['phone' => '+22507888888']);

        $response = $this->actingAsCourier()->postJson('/api/courier/profile/update', [
            'phone' => '+22507888888', // Already taken
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['phone']);
    }

    public function test_update_courier_profile_multiple_fields(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/profile/update', [
            'name' => 'Nouveau Nom',
            'vehicle_type' => 'car',
            'vehicle_number' => 'DF-456-CI',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.name', 'Nouveau Nom')
            ->assertJsonPath('data.vehicle_type', 'car');

        $this->courierUser->refresh();
        $this->courier->refresh();
        $this->assertEquals('Nouveau Nom', $this->courierUser->name);
        $this->assertEquals('car', $this->courier->vehicle_type);
    }

    public function test_update_courier_profile_empty_request(): void
    {
        $originalName = $this->courierUser->name;

        $response = $this->actingAsCourier()->postJson('/api/courier/profile/update', []);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->courierUser->refresh();
        $this->assertEquals($originalName, $this->courierUser->name);
    }

    public function test_profile_returns_403_without_courier_profile(): void
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);

        $response = $this->actingAs($userWithoutCourier, 'sanctum')
            ->getJson('/api/courier/profile');

        $response->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    public function test_update_courier_profile_returns_403_without_courier_profile(): void
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);

        $response = $this->actingAs($userWithoutCourier, 'sanctum')
            ->postJson('/api/courier/profile/update', [
                'name' => 'No profile courier',
            ]);

        $response->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    // ─── ADDITIONAL EDGE CASES ───────────────────────────────────────────────

    public function test_accept_nonexistent_delivery_returns_404(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/deliveries/99999/accept');

        $response->assertStatus(404);
    }

    public function test_pickup_nonexistent_delivery_returns_404(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/deliveries/99999/pickup');

        $response->assertStatus(404);
    }

    public function test_deliver_nonexistent_delivery_returns_404(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/deliveries/99999/deliver', [
            'confirmation_code' => '1234',
        ]);

        $response->assertStatus(404);
    }

    public function test_reject_nonexistent_delivery_returns_404(): void
    {
        $response = $this->actingAsCourier()->postJson('/api/courier/deliveries/99999/reject');

        $response->assertStatus(404);
    }

    public function test_show_other_courier_delivery_returns_404(): void
    {
        $otherCourier = Courier::factory()->create();
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $otherCourier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAsCourier()->getJson("/api/courier/deliveries/{$delivery->id}");

        // Controller's query scopes to courier's own deliveries, so other couriers get 404
        $response->assertStatus(404);
    }

    public function test_pickup_other_courier_delivery_returns_404(): void
    {
        $otherCourier = Courier::factory()->create();
        $delivery = $this->createDeliveryWithOrder([
            'courier_id' => $otherCourier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAsCourier()->postJson("/api/courier/deliveries/{$delivery->id}/pickup");

        // Controller's query scopes to courier's own deliveries, so other couriers get 404
        $response->assertStatus(404);
    }
}
