<?php

namespace Tests\Feature\Api\Customer;

use App\Models\User;
use App\Models\CustomerAddress;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AddressControllerTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private string $token;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->user = User::factory()->create([
            'role' => 'customer',
            'phone' => '+22507000000',
        ]);
        
        $this->token = $this->user->createToken('test-token')->plainTextToken;
    }

    /** @test */
    public function user_can_list_their_addresses()
    {
        CustomerAddress::factory()->count(3)->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->getJson('/api/customer/addresses');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'data' => [
                    '*' => ['id', 'label', 'address', 'city', 'is_default'],
                ],
            ]);
    }

    /** @test */
    public function user_can_create_address()
    {
        $addressData = [
            'label' => 'Maison',
            'address' => '123 Rue Test',
            'city' => 'Abidjan',
            'district' => 'Cocody',
            'latitude' => 5.3600,
            'longitude' => -4.0083,
        ];

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson('/api/customer/addresses', $addressData);

        $response->assertStatus(201)
            ->assertJson([
                'status' => 'success',
                'message' => 'Adresse créée avec succès',
            ]);

        $this->assertDatabaseHas('customer_addresses', [
            'user_id' => $this->user->id,
            'label' => 'Maison',
            'address' => '123 Rue Test',
        ]);
    }

    /** @test */
    public function first_address_is_set_as_default()
    {
        $addressData = [
            'label' => 'Maison',
            'address' => '123 Rue Test',
            'city' => 'Abidjan',
        ];

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson('/api/customer/addresses', $addressData);

        $response->assertStatus(201);

        $this->assertDatabaseHas('customer_addresses', [
            'user_id' => $this->user->id,
            'is_default' => true,
        ]);
    }

    /** @test */
    public function user_can_show_specific_address()
    {
        $address = CustomerAddress::factory()->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->getJson("/api/customer/addresses/{$address->id}");

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'success',
            ]);
    }

    /** @test */
    public function user_cannot_see_other_users_address()
    {
        $otherUser = User::factory()->create();
        $address = CustomerAddress::factory()->create([
            'user_id' => $otherUser->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->getJson("/api/customer/addresses/{$address->id}");

        $response->assertStatus(404);
    }

    /** @test */
    public function user_can_update_address()
    {
        $address = CustomerAddress::factory()->create([
            'user_id' => $this->user->id,
            'address' => 'Old Address',
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->putJson("/api/customer/addresses/{$address->id}", [
                'address' => 'New Address',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('customer_addresses', [
            'id' => $address->id,
            'address' => 'New Address',
        ]);
    }

    /** @test */
    public function user_can_delete_address()
    {
        $address = CustomerAddress::factory()->create([
            'user_id' => $this->user->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->deleteJson("/api/customer/addresses/{$address->id}");

        $response->assertStatus(200);

        $this->assertDatabaseMissing('customer_addresses', [
            'id' => $address->id,
        ]);
    }

    /** @test */
    public function user_can_set_default_address()
    {
        $address1 = CustomerAddress::factory()->create([
            'user_id' => $this->user->id,
            'is_default' => true,
        ]);
        
        $address2 = CustomerAddress::factory()->create([
            'user_id' => $this->user->id,
            'is_default' => false,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson("/api/customer/addresses/{$address2->id}/default");

        $response->assertStatus(200);

        $this->assertDatabaseHas('customer_addresses', [
            'id' => $address2->id,
            'is_default' => true,
        ]);
    }

    /** @test */
    public function address_requires_valid_label()
    {
        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson('/api/customer/addresses', [
                'label' => 'InvalidLabel',
                'address' => '123 Rue Test',
            ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function address_requires_address_field()
    {
        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson('/api/customer/addresses', [
                'label' => 'Maison',
            ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function label_is_normalized_to_proper_case()
    {
        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson('/api/customer/addresses', [
                'label' => 'maison',
                'address' => '123 Rue Test',
            ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('customer_addresses', [
            'user_id' => $this->user->id,
            'label' => 'Maison',
        ]);
    }
}
