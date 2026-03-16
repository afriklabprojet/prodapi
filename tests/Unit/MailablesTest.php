<?php

namespace Tests\Unit;

use App\Mail\OtpMail;
use App\Mail\WelcomeMail;
use App\Mail\AdminAlertMail;
use PHPUnit\Framework\TestCase;

class MailablesTest extends TestCase
{
    /**
     * Test OtpMail can be constructed for verification
     */
    public function test_otp_mail_for_verification(): void
    {
        $mail = new OtpMail('123456', 'verification');
        
        $this->assertInstanceOf(OtpMail::class, $mail);
    }

    /**
     * Test OtpMail can be constructed for password reset
     */
    public function test_otp_mail_for_password_reset(): void
    {
        $mail = new OtpMail('654321', 'password_reset');
        
        $this->assertInstanceOf(OtpMail::class, $mail);
    }

    /**
     * Test OtpMail can be constructed for login
     */
    public function test_otp_mail_for_login(): void
    {
        $mail = new OtpMail('111222', 'login');
        
        $this->assertInstanceOf(OtpMail::class, $mail);
    }

    /**
     * Test WelcomeMail can be constructed for customer
     */
    public function test_welcome_mail_for_customer(): void
    {
        $mail = new WelcomeMail('John Doe', 'customer');
        
        $this->assertInstanceOf(WelcomeMail::class, $mail);
    }

    /**
     * Test WelcomeMail can be constructed for pharmacy
     */
    public function test_welcome_mail_for_pharmacy(): void
    {
        $mail = new WelcomeMail('Pharma Plus', 'pharmacy');
        
        $this->assertInstanceOf(WelcomeMail::class, $mail);
    }

    /**
     * Test WelcomeMail can be constructed for courier
     */
    public function test_welcome_mail_for_courier(): void
    {
        $mail = new WelcomeMail('Jean Dupont', 'courier');
        
        $this->assertInstanceOf(WelcomeMail::class, $mail);
    }

    /**
     * Test AdminAlertMail can be constructed
     */
    public function test_admin_alert_mail(): void
    {
        $mail = new AdminAlertMail('no_courier_available', [
            'order_number' => 'ORD-2024-002',
            'pharmacy_name' => 'Pharma Test',
        ]);
        
        $this->assertInstanceOf(AdminAlertMail::class, $mail);
    }

    /**
     * Test AdminAlertMail with different alert types
     */
    public function test_admin_alert_mail_various_types(): void
    {
        $alertTypes = [
            'no_courier_available',
            'kyc_pending',
            'withdrawal_request',
            'payment_failed',
            'high_value_order',
        ];

        foreach ($alertTypes as $type) {
            $mail = new AdminAlertMail($type, ['test' => 'data']);
            $this->assertInstanceOf(AdminAlertMail::class, $mail);
        }
    }
}
