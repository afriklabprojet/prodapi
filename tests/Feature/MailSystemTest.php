<?php

namespace Tests\Feature;

use App\Mail\OrderStatusMail;
use App\Models\Order;
use App\Models\User;
use App\Models\Pharmacy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class MailSystemTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test OrderStatusMail can be sent for an order
     */
    public function test_order_status_mail_can_be_rendered(): void
    {
        // Créer les données de test
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacyOwner = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacy->users()->attach($pharmacyOwner->id, ['role' => 'owner']);
        
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'pending',
            'total_amount' => 15000,
        ]);

        $mail = new OrderStatusMail($order, 'confirmed');

        // Vérifier que le mail peut être rendu sans erreur
        $this->assertNotEmpty($mail->envelope()->subject);
    }

    /**
     * Test OrderStatusMail generates correct subjects for different statuses
     */
    public function test_order_status_mail_generates_correct_subjects(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacyOwner = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacy->users()->attach($pharmacyOwner->id, ['role' => 'owner']);
        
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $statuses = [
            'confirmed' => 'confirmée',
            'ready' => 'prête',
            'picked_up' => 'en cours',
            'delivered' => 'livrée',
            'cancelled' => 'annulée',
        ];

        foreach ($statuses as $status => $expectedContains) {
            $mail = new OrderStatusMail($order, $status);
            $subject = $mail->envelope()->subject;
            
            $this->assertStringContainsString($expectedContains, $subject);
        }
    }

    /**
     * Test mail is queued when sent
     */
    public function test_order_status_mail_can_be_queued(): void
    {
        Mail::fake();

        $customer = User::factory()->create(['role' => 'customer', 'email' => 'test@example.com']);
        $pharmacyOwner = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacy->users()->attach($pharmacyOwner->id, ['role' => 'owner']);
        
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        Mail::to($customer)->queue(new OrderStatusMail($order, 'confirmed'));

        Mail::assertQueued(OrderStatusMail::class, function ($mail) use ($customer) {
            return $mail->hasTo($customer->email);
        });
    }
}
