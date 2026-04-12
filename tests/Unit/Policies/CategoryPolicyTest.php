<?php

namespace Tests\Unit\Policies;

use App\Models\Category;
use App\Models\User;
use App\Policies\CategoryPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class CategoryPolicyTest extends TestCase
{
    use RefreshDatabase;

    private CategoryPolicy $policy;

    protected function setUp(): void
    {
        parent::setUp();
        $this->policy = new CategoryPolicy();
    }

    #[Test]
    public function anyone_can_view_any_categories(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);
        $customer = User::factory()->create(['role' => 'customer']);
        $courier = User::factory()->create(['role' => 'courier']);

        $this->assertTrue($this->policy->viewAny($admin));
        $this->assertTrue($this->policy->viewAny($pharmacy));
        $this->assertTrue($this->policy->viewAny($customer));
        $this->assertTrue($this->policy->viewAny($courier));
    }

    #[Test]
    public function anyone_can_view_a_category(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $category = Category::factory()->create();

        $this->assertTrue($this->policy->view($user, $category));
    }

    #[Test]
    public function admin_can_create_categories(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->assertTrue($this->policy->create($admin));
    }

    #[Test]
    public function pharmacy_can_create_categories(): void
    {
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);

        $this->assertTrue($this->policy->create($pharmacy));
    }

    #[Test]
    public function customer_cannot_create_categories(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);

        $this->assertFalse($this->policy->create($customer));
    }

    #[Test]
    public function courier_cannot_create_categories(): void
    {
        $courier = User::factory()->create(['role' => 'courier']);

        $this->assertFalse($this->policy->create($courier));
    }

    #[Test]
    public function admin_can_update_categories(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $category = Category::factory()->create();

        $this->assertTrue($this->policy->update($admin, $category));
    }

    #[Test]
    public function pharmacy_cannot_update_categories(): void
    {
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);
        $category = Category::factory()->create();

        $this->assertFalse($this->policy->update($pharmacy, $category));
    }

    #[Test]
    public function admin_can_delete_categories(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $category = Category::factory()->create();

        $this->assertTrue($this->policy->delete($admin, $category));
    }

    #[Test]
    public function non_admin_cannot_delete_categories(): void
    {
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);
        $customer = User::factory()->create(['role' => 'customer']);
        $category = Category::factory()->create();

        $this->assertFalse($this->policy->delete($pharmacy, $category));
        $this->assertFalse($this->policy->delete($customer, $category));
    }

    #[Test]
    public function admin_can_reorder_categories(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->assertTrue($this->policy->reorder($admin));
    }

    #[Test]
    public function non_admin_cannot_reorder_categories(): void
    {
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);

        $this->assertFalse($this->policy->reorder($pharmacy));
    }
}
