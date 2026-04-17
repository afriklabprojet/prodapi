<?php

namespace Tests\Unit\Notifications;

use App\Notifications\NewPrescriptionNotification;
use App\Models\Prescription;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Customer;
use App\Channels\FcmChannel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class NewPrescriptionNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected $prescription;
    protected $pharmacyUser;
    protected $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        
        $customerUser = User::factory()->create(['role' => 'customer']);
        $this->customer = Customer::factory()->create(['user_id' => $customerUser->id]);

        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
            'fcm_token' => 'pharmacy_fcm_token',
        ]);

        $this->prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'pending',
        ]);
    }

    #[Test]
    public function it_can_be_constructed_with_prescription()
    {
        $notification = new NewPrescriptionNotification($this->prescription);

        $this->assertInstanceOf(NewPrescriptionNotification::class, $notification);
    }

    #[Test]
    public function via_includes_database_channel()
    {
        $notification = new NewPrescriptionNotification($this->prescription);
        $channels = $notification->via($this->pharmacyUser);

        $this->assertContains('database', $channels);
    }

    #[Test]
    public function via_includes_fcm_when_user_has_token()
    {
        $notification = new NewPrescriptionNotification($this->prescription);
        $channels = $notification->via($this->pharmacyUser);

        $this->assertContains(FcmChannel::class, $channels);
    }

    #[Test]
    public function via_excludes_fcm_when_user_has_no_token()
    {
        $userWithoutToken = User::factory()->create(['fcm_token' => null]);

        $notification = new NewPrescriptionNotification($this->prescription);
        $channels = $notification->via($userWithoutToken);

        $this->assertNotContains(FcmChannel::class, $channels);
    }

    #[Test]
    public function to_array_returns_correct_structure()
    {
        $notification = new NewPrescriptionNotification($this->prescription);
        $array = $notification->toArray($this->pharmacyUser);

        $this->assertArrayHasKey('title', $array);
        $this->assertArrayHasKey('body', $array);
        $this->assertEquals($this->prescription->id, $array['prescription_id']);
        $this->assertEquals('new_prescription', $array['type']);
    }

    #[Test]
    public function to_array_contains_customer_reference()
    {
        $notification = new NewPrescriptionNotification($this->prescription);
        $array = $notification->toArray($this->pharmacyUser);

        $this->assertEquals('Nouvelle Ordonnance', $array['title']);
        $this->assertStringContainsString($this->prescription->customer_id, $array['body']);
    }

    #[Test]
    public function to_fcm_returns_correct_structure()
    {
        $notification = new NewPrescriptionNotification($this->prescription);
        $fcm = $notification->toFcm($this->pharmacyUser);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
        $this->assertEquals('Nouvelle Ordonnance', $fcm['title']);
    }

    #[Test]
    public function to_fcm_data_contains_prescription_info()
    {
        $notification = new NewPrescriptionNotification($this->prescription);
        $fcm = $notification->toFcm($this->pharmacyUser);

        $this->assertEquals('new_prescription', $fcm['data']['type']);
        $this->assertEquals((string) $this->prescription->id, $fcm['data']['prescription_id']);
    }

    #[Test]
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->pharmacyUser->notify(new NewPrescriptionNotification($this->prescription));

        Notification::assertSentTo($this->pharmacyUser, NewPrescriptionNotification::class);
    }

    #[Test]
    public function notification_implements_should_queue()
    {
        $notification = new NewPrescriptionNotification($this->prescription);

        $this->assertInstanceOf(\Illuminate\Contracts\Queue\ShouldQueue::class, $notification);
    }
}
