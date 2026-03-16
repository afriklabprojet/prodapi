<?php

namespace Tests\Feature\Api\Customer;

use App\Models\User;
use App\Models\Prescription;
use App\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class PrescriptionControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $prescription;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('private');
        Notification::fake();

        $this->user = User::factory()->create([
            'role' => 'customer',
            'phone_verified_at' => now(),
        ]);

        $this->prescription = Prescription::factory()->create([
            'customer_id' => $this->user->id,
            'status' => 'pending',
            'images' => json_encode(['prescriptions/test/image1.jpg']),
        ]);
    }

    /** @test */
    public function customer_can_list_prescriptions()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/prescriptions');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'status',
                        'source',
                        'notes',
                        'images',
                        'created_at',
                    ],
                ],
            ]);
    }

    /** @test */
    public function prescriptions_include_associated_order()
    {
        $order = Order::factory()->create([
            'customer_id' => $this->user->id,
        ]);

        $this->prescription->update(['order_id' => $order->id]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/prescriptions');

        $response->assertOk();
        $data = $response->json('data');
        $found = collect($data)->firstWhere('id', $this->prescription->id);
        $this->assertNotNull($found);
        $this->assertEquals($order->id, $found['order']['id']);
    }

    /** @test */
    public function customer_can_upload_prescription()
    {
        $images = [
            UploadedFile::fake()->image('prescription1.jpg', 800, 600),
            UploadedFile::fake()->image('prescription2.jpg', 800, 600),
        ];

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/customer/prescriptions/upload', [
                'images' => $images,
                'notes' => 'Ordonnance pour mal de tête',
            ]);

        $response->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Prescription uploaded successfully')
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'id',
                    'status',
                    'source',
                    'images',
                    'notes',
                    'created_at',
                ],
            ]);

        $this->assertDatabaseHas('prescriptions', [
            'customer_id' => $this->user->id,
            'status' => 'pending',
            'notes' => 'Ordonnance pour mal de tête',
        ]);
    }

    /** @test */
    public function upload_requires_at_least_one_image()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/customer/prescriptions/upload', [
                'images' => [],
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['images']);
    }

    /** @test */
    public function upload_rejects_non_image_files()
    {
        $file = UploadedFile::fake()->create('document.pdf', 100, 'application/pdf');

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/customer/prescriptions/upload', [
                'images' => [$file],
            ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function upload_rejects_large_images()
    {
        $file = UploadedFile::fake()->image('large.jpg')->size(15000); // 15MB

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/customer/prescriptions/upload', [
                'images' => [$file],
            ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function customer_can_specify_upload_source()
    {
        $image = UploadedFile::fake()->image('prescription.jpg');

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/customer/prescriptions/upload', [
                'images' => [$image],
                'source' => 'checkout',
            ]);

        $response->assertCreated()
            ->assertJsonPath('data.source', 'checkout');
    }

    /** @test */
    public function customer_can_view_prescription_details()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/customer/prescriptions/{$this->prescription->id}");

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    'id',
                    'status',
                    'notes',
                    'images',
                    'quote_amount',
                    'created_at',
                    'validated_at',
                ],
            ]);
    }

    /** @test */
    public function customer_cannot_view_other_customer_prescriptions()
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        $otherPrescription = Prescription::factory()->create([
            'customer_id' => $otherUser->id,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/customer/prescriptions/{$otherPrescription->id}");

        $response->assertNotFound();
    }

    /** @test */
    public function returns_404_for_non_existent_prescription()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/prescriptions/999999');

        $response->assertNotFound();
    }

    /** @test */
    public function customer_can_view_quoted_prescription()
    {
        $this->prescription->update([
            'status' => 'quoted',
            'quote_amount' => 15000,
            'pharmacy_notes' => 'Tous les médicaments disponibles',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/customer/prescriptions/{$this->prescription->id}");

        $response->assertOk()
            ->assertJsonPath('data.status', 'quoted')
            ->assertJsonPath('data.quote_amount', 15000);
    }

    /** @test */
    public function prescriptions_are_ordered_by_latest()
    {
        // Create older prescriptions
        Prescription::factory()->count(3)->create([
            'customer_id' => $this->user->id,
            'created_at' => now()->subDays(5),
        ]);

        // Create recent prescription
        $recent = Prescription::factory()->create([
            'customer_id' => $this->user->id,
            'created_at' => now()->addMinute(),
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/prescriptions');

        $response->assertOk();
        $data = $response->json('data');
        
        // Most recent should be first
        $this->assertEquals($recent->id, $data[0]['id']);
    }

    /** @test */
    public function upload_accepts_webp_format()
    {
        $image = UploadedFile::fake()->image('prescription.webp');

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/customer/prescriptions/upload', [
                'images' => [$image],
            ]);

        $response->assertCreated();
    }

    /** @test */
    public function notes_have_maximum_length()
    {
        $image = UploadedFile::fake()->image('prescription.jpg');
        $longNotes = str_repeat('a', 600); // Exceeds 500 char limit

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/customer/prescriptions/upload', [
                'images' => [$image],
                'notes' => $longNotes,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['notes']);
    }

    /** @test */
    public function unauthenticated_user_cannot_access_prescriptions()
    {
        $response = $this->getJson('/api/customer/prescriptions');

        $response->assertUnauthorized();
    }

    /** @test */
    public function unauthenticated_user_cannot_upload_prescriptions()
    {
        $image = UploadedFile::fake()->image('prescription.jpg');

        $response = $this->postJson('/api/customer/prescriptions/upload', [
            'images' => [$image],
        ]);

        $response->assertUnauthorized();
    }
}
