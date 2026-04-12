<?php

namespace Tests\Unit\Policies;

use App\Models\Courier;
use App\Models\User;
use App\Policies\CourierPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class CourierPolicyTest extends TestCase
{
    use RefreshDatabase;

    private CourierPolicy $policy;

    protected function setUp(): void
    {
        parent::setUp();
        $this->policy = new CourierPolicy();
    }

    #[Test]
    public function admin_can_view_any_couriers(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->assertTrue($this->policy->viewAny($admin));
    }

    #[Test]
    public function pharmacy_can_view_any_couriers(): void
    {
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);

        $this->assertTrue($this->policy->viewAny($pharmacy));
    }

    #[Test]
    public function customer_cannot_view_any_couriers(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);

        $this->assertFalse($this->policy->viewAny($customer));
    }

    #[Test]
    public function admin_can_view_any_courier(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->assertTrue($this->policy->view($admin, $courier));
    }

    #[Test]
    public function courier_can_view_own_profile(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->assertTrue($this->policy->view($courierUser, $courier));
    }

    #[Test]
    public function courier_cannot_view_other_courier_profile(): void
    {
        $courierUser1 = User::factory()->create(['role' => 'courier']);
        $courier1 = Courier::factory()->create(['user_id' => $courierUser1->id]);

        $courierUser2 = User::factory()->create(['role' => 'courier']);
        $courier2 = Courier::factory()->create(['user_id' => $courierUser2->id]);

        $this->assertFalse($this->policy->view($courierUser1, $courier2));
    }

    #[Test]
    public function pharmacy_can_view_available_courier(): void
    {
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create([
            'user_id' => $courierUser->id,
            'status' => 'available',
        ]);

        $this->assertTrue($this->policy->view($pharmacy, $courier));
    }

    #[Test]
    public function pharmacy_can_view_busy_courier(): void
    {
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create([
            'user_id' => $courierUser->id,
            'status' => 'busy',
        ]);

        $this->assertTrue($this->policy->view($pharmacy, $courier));
    }

    #[Test]
    public function admin_can_update_any_courier(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->assertTrue($this->policy->update($admin, $courier));
    }

    #[Test]
    public function courier_can_update_own_profile(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->assertTrue($this->policy->update($courierUser, $courier));
    }

    #[Test]
    public function courier_cannot_update_other_courier(): void
    {
        $courierUser1 = User::factory()->create(['role' => 'courier']);
        $courier1 = Courier::factory()->create(['user_id' => $courierUser1->id]);

        $courierUser2 = User::factory()->create(['role' => 'courier']);
        $courier2 = Courier::factory()->create(['user_id' => $courierUser2->id]);

        $this->assertFalse($this->policy->update($courierUser1, $courier2));
    }

    #[Test]
    public function admin_can_delete_courier(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->assertTrue($this->policy->delete($admin, $courier));
    }

    #[Test]
    public function non_admin_cannot_delete_courier(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->assertFalse($this->policy->delete($courierUser, $courier));
    }

    #[Test]
    public function admin_can_approve_pending_courier(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create([
            'user_id' => $courierUser->id,
            'status' => 'pending_approval',
        ]);

        $this->assertTrue($this->policy->approve($admin, $courier));
    }

    #[Test]
    public function admin_cannot_approve_already_approved_courier(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create([
            'user_id' => $courierUser->id,
            'status' => 'available',
        ]);

        $this->assertFalse($this->policy->approve($admin, $courier));
    }

    #[Test]
    public function admin_can_suspend_active_courier(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create([
            'user_id' => $courierUser->id,
            'status' => 'available',
        ]);

        $this->assertTrue($this->policy->suspend($admin, $courier));
    }

    #[Test]
    public function admin_cannot_suspend_already_suspended_courier(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create([
            'user_id' => $courierUser->id,
            'status' => 'suspended',
        ]);

        $this->assertFalse($this->policy->suspend($admin, $courier));
    }

    #[Test]
    public function admin_can_reject_pending_courier(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create([
            'user_id' => $courierUser->id,
            'status' => 'pending_approval',
        ]);

        $this->assertTrue($this->policy->reject($admin, $courier));
    }

    #[Test]
    public function admin_can_view_courier_documents(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->assertTrue($this->policy->viewDocuments($admin, $courier));
    }

    #[Test]
    public function courier_can_view_own_documents(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->assertTrue($this->policy->viewDocuments($courierUser, $courier));
    }

    #[Test]
    public function courier_can_update_own_location(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->assertTrue($this->policy->updateLocation($courierUser, $courier));
    }

    #[Test]
    public function courier_cannot_update_other_courier_location(): void
    {
        $courierUser1 = User::factory()->create(['role' => 'courier']);
        $courier1 = Courier::factory()->create(['user_id' => $courierUser1->id]);

        $courierUser2 = User::factory()->create(['role' => 'courier']);
        $courier2 = Courier::factory()->create(['user_id' => $courierUser2->id]);

        $this->assertFalse($this->policy->updateLocation($courierUser1, $courier2));
    }

    #[Test]
    public function courier_can_toggle_own_availability(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->assertTrue($this->policy->toggleAvailability($courierUser, $courier));
    }

    #[Test]
    public function courier_cannot_toggle_other_courier_availability(): void
    {
        $courierUser1 = User::factory()->create(['role' => 'courier']);
        $courier1 = Courier::factory()->create(['user_id' => $courierUser1->id]);

        $courierUser2 = User::factory()->create(['role' => 'courier']);
        $courier2 = Courier::factory()->create(['user_id' => $courierUser2->id]);

        $this->assertFalse($this->policy->toggleAvailability($courierUser1, $courier2));
    }
}
