<?php

namespace Tests\Unit\Notifications;

use App\Notifications\PrescriptionStatusNotification;
use App\Models\Prescription;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Customer;
use App\Channels\FcmChannel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class PrescriptionStatusNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected $prescription;
    protected $customerUser;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        
        $this->customerUser = User::factory()->create([
            'role' => 'customer',
            'fcm_token' => 'customer_fcm_token',
        ]);
        $customer = Customer::factory()->create(['user_id' => $this->customerUser->id]);

        $this->prescription = Prescription::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'pending',
        ]);
    }

    /** @test */
    public function it_can_be_constructed_with_prescription_and_status()
    {
        $notification = new PrescriptionStatusNotification($this->prescription, 'quoted');

        $this->assertInstanceOf(PrescriptionStatusNotification::class, $notification);
    }

    /** @test */
    public function via_includes_database_channel()
    {
        $notification = new PrescriptionStatusNotification($this->prescription, 'quoted');
        $channels = $notification->via($this->customerUser);

        $this->assertContains('database', $channels);
    }

    /** @test */
    public function via_includes_fcm_when_user_has_token()
    {
        $notification = new PrescriptionStatusNotification($this->prescription, 'quoted');
        $channels = $notification->via($this->customerUser);

        $this->assertContains(FcmChannel::class, $channels);
    }

    /** @test */
    public function via_excludes_fcm_when_user_has_no_token()
    {
        $userWithoutToken = User::factory()->create(['fcm_token' => null]);

        $notification = new PrescriptionStatusNotification($this->prescription, 'quoted');
        $channels = $notification->via($userWithoutToken);

        $this->assertNotContains(FcmChannel::class, $channels);
    }

    /** @test */
    public function to_array_returns_correct_structure()
    {
        $notification = new PrescriptionStatusNotification($this->prescription, 'quoted');
        $array = $notification->toArray($this->customerUser);

        $this->assertArrayHasKey('title', $array);
        $this->assertArrayHasKey('body', $array);
        $this->assertEquals($this->prescription->id, $array['prescription_id']);
        $this->assertEquals('quoted', $array['status']);
        $this->assertEquals('prescription_status', $array['type']);
    }

    /** @test */
    public function quoted_status_returns_correct_message()
    {
        $notification = new PrescriptionStatusNotification($this->prescription, 'quoted');
        $array = $notification->toArray($this->customerUser);

        $this->assertStringContainsString('devis', $array['body']);
    }

    /** @test */
    public function validated_status_returns_correct_message()
    {
        $notification = new PrescriptionStatusNotification($this->prescription, 'validated');
        $array = $notification->toArray($this->customerUser);

        $this->assertStringContainsString('validée', $array['body']);
    }

    /** @test */
    public function rejected_status_returns_correct_message()
    {
        $notification = new PrescriptionStatusNotification($this->prescription, 'rejected');
        $array = $notification->toArray($this->customerUser);

        $this->assertStringContainsString('refusée', $array['body']);
    }

    /** @test */
    public function unknown_status_returns_generic_message()
    {
        $notification = new PrescriptionStatusNotification($this->prescription, 'unknown_status');
        $array = $notification->toArray($this->customerUser);

        $this->assertStringContainsString('unknown_status', $array['body']);
    }

    /** @test */
    public function to_fcm_returns_correct_structure()
    {
        $notification = new PrescriptionStatusNotification($this->prescription, 'quoted');
        $fcm = $notification->toFcm($this->customerUser);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
        $this->assertEquals('Mise à jour Ordonnance', $fcm['title']);
    }

    /** @test */
    public function to_fcm_data_contains_prescription_info()
    {
        $notification = new PrescriptionStatusNotification($this->prescription, 'validated');
        $fcm = $notification->toFcm($this->customerUser);

        $this->assertEquals('prescription_status', $fcm['data']['type']);
        $this->assertEquals((string) $this->prescription->id, $fcm['data']['prescription_id']);
        $this->assertEquals('validated', $fcm['data']['status']);
    }

    /** @test */
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->customerUser->notify(new PrescriptionStatusNotification($this->prescription, 'quoted'));

        Notification::assertSentTo($this->customerUser, PrescriptionStatusNotification::class);
    }

    /** @test */
    public function notification_can_be_sent_for_different_statuses()
    {
        Notification::fake();

        $statuses = ['quoted', 'validated', 'rejected', 'processing'];

        foreach ($statuses as $status) {
            $this->customerUser->notify(new PrescriptionStatusNotification($this->prescription, $status));
        }

        Notification::assertSentTo($this->customerUser, PrescriptionStatusNotification::class, function ($notification, $channels) {
            return true;
        });
    }
}
