<?php

namespace Tests\Unit\Enums;

use App\Enums\JekoPaymentMethod;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class JekoPaymentMethodTest extends TestCase
{
    #[Test]
    public function it_has_wave_method()
    {
        $this->assertEquals('wave', JekoPaymentMethod::WAVE->value);
    }

    #[Test]
    public function it_has_orange_method()
    {
        $this->assertEquals('orange', JekoPaymentMethod::ORANGE->value);
    }

    #[Test]
    public function it_has_mtn_method()
    {
        $this->assertEquals('mtn', JekoPaymentMethod::MTN->value);
    }

    #[Test]
    public function it_has_moov_method()
    {
        $this->assertEquals('moov', JekoPaymentMethod::MOOV->value);
    }

    #[Test]
    public function it_has_djamo_method()
    {
        $this->assertEquals('djamo', JekoPaymentMethod::DJAMO->value);
    }

    #[Test]
    public function it_has_bank_transfer_method()
    {
        $this->assertEquals('bank_transfer', JekoPaymentMethod::BANK_TRANSFER->value);
    }

    #[Test]
    public function wave_has_correct_label()
    {
        $this->assertEquals('Wave', JekoPaymentMethod::WAVE->label());
    }

    #[Test]
    public function orange_has_correct_label()
    {
        $this->assertEquals('Orange Money', JekoPaymentMethod::ORANGE->label());
    }

    #[Test]
    public function mtn_has_correct_label()
    {
        $this->assertEquals('MTN Mobile Money', JekoPaymentMethod::MTN->label());
    }

    #[Test]
    public function bank_transfer_has_correct_label()
    {
        $this->assertEquals('Virement Bancaire', JekoPaymentMethod::BANK_TRANSFER->label());
    }

    #[Test]
    public function methods_have_icons()
    {
        $this->assertEquals('wave', JekoPaymentMethod::WAVE->icon());
        $this->assertEquals('orange-money', JekoPaymentMethod::ORANGE->icon());
        $this->assertEquals('mtn-momo', JekoPaymentMethod::MTN->icon());
        $this->assertEquals('moov-money', JekoPaymentMethod::MOOV->icon());
        $this->assertEquals('djamo', JekoPaymentMethod::DJAMO->icon());
        $this->assertEquals('bank', JekoPaymentMethod::BANK_TRANSFER->icon());
    }

    #[Test]
    public function values_returns_all_values()
    {
        $values = JekoPaymentMethod::values();

        $this->assertContains('wave', $values);
        $this->assertContains('orange', $values);
        $this->assertContains('mtn', $values);
        $this->assertContains('moov', $values);
        $this->assertContains('djamo', $values);
        $this->assertContains('bank_transfer', $values);
    }

    #[Test]
    public function payout_methods_returns_correct_methods()
    {
        $payoutMethods = JekoPaymentMethod::payoutMethods();

        $this->assertContains(JekoPaymentMethod::ORANGE, $payoutMethods);
        $this->assertContains(JekoPaymentMethod::MTN, $payoutMethods);
        $this->assertContains(JekoPaymentMethod::MOOV, $payoutMethods);
        $this->assertContains(JekoPaymentMethod::WAVE, $payoutMethods);
        $this->assertContains(JekoPaymentMethod::DJAMO, $payoutMethods);
        $this->assertContains(JekoPaymentMethod::BANK_TRANSFER, $payoutMethods);
    }

    #[Test]
    public function payout_methods_includes_all_payment_methods_plus_bank()
    {
        $payoutMethods = JekoPaymentMethod::payoutMethods();
        $paymentMethods = JekoPaymentMethod::paymentMethods();

        foreach ($paymentMethods as $method) {
            $this->assertContains($method, $payoutMethods);
        }
        $this->assertContains(JekoPaymentMethod::BANK_TRANSFER, $payoutMethods);
    }

    #[Test]
    public function can_be_created_from_string()
    {
        $method = JekoPaymentMethod::from('wave');
        $this->assertEquals(JekoPaymentMethod::WAVE, $method);
    }

    #[Test]
    public function try_from_returns_null_for_invalid_value()
    {
        $method = JekoPaymentMethod::tryFrom('invalid_method');
        $this->assertNull($method);
    }
}
