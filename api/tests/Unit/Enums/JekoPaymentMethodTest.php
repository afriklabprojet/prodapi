<?php

namespace Tests\Unit\Enums;

use App\Enums\JekoPaymentMethod;
use Tests\TestCase;

class JekoPaymentMethodTest extends TestCase
{
    /** @test */
    public function it_has_wave_method()
    {
        $this->assertEquals('wave', JekoPaymentMethod::WAVE->value);
    }

    /** @test */
    public function it_has_orange_method()
    {
        $this->assertEquals('orange', JekoPaymentMethod::ORANGE->value);
    }

    /** @test */
    public function it_has_mtn_method()
    {
        $this->assertEquals('mtn', JekoPaymentMethod::MTN->value);
    }

    /** @test */
    public function it_has_moov_method()
    {
        $this->assertEquals('moov', JekoPaymentMethod::MOOV->value);
    }

    /** @test */
    public function it_has_djamo_method()
    {
        $this->assertEquals('djamo', JekoPaymentMethod::DJAMO->value);
    }

    /** @test */
    public function it_has_bank_transfer_method()
    {
        $this->assertEquals('bank_transfer', JekoPaymentMethod::BANK_TRANSFER->value);
    }

    /** @test */
    public function wave_has_correct_label()
    {
        $this->assertEquals('Wave', JekoPaymentMethod::WAVE->label());
    }

    /** @test */
    public function orange_has_correct_label()
    {
        $this->assertEquals('Orange Money', JekoPaymentMethod::ORANGE->label());
    }

    /** @test */
    public function mtn_has_correct_label()
    {
        $this->assertEquals('MTN Mobile Money', JekoPaymentMethod::MTN->label());
    }

    /** @test */
    public function bank_transfer_has_correct_label()
    {
        $this->assertEquals('Virement Bancaire', JekoPaymentMethod::BANK_TRANSFER->label());
    }

    /** @test */
    public function methods_have_icons()
    {
        $this->assertEquals('wave', JekoPaymentMethod::WAVE->icon());
        $this->assertEquals('orange-money', JekoPaymentMethod::ORANGE->icon());
        $this->assertEquals('mtn-momo', JekoPaymentMethod::MTN->icon());
        $this->assertEquals('moov-money', JekoPaymentMethod::MOOV->icon());
        $this->assertEquals('djamo', JekoPaymentMethod::DJAMO->icon());
        $this->assertEquals('bank', JekoPaymentMethod::BANK_TRANSFER->icon());
    }

    /** @test */
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

    /** @test */
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

    /** @test */
    public function payout_methods_includes_all_payment_methods_plus_bank()
    {
        $payoutMethods = JekoPaymentMethod::payoutMethods();
        $paymentMethods = JekoPaymentMethod::paymentMethods();

        foreach ($paymentMethods as $method) {
            $this->assertContains($method, $payoutMethods);
        }
        $this->assertContains(JekoPaymentMethod::BANK_TRANSFER, $payoutMethods);
    }

    /** @test */
    public function can_be_created_from_string()
    {
        $method = JekoPaymentMethod::from('wave');
        $this->assertEquals(JekoPaymentMethod::WAVE, $method);
    }

    /** @test */
    public function try_from_returns_null_for_invalid_value()
    {
        $method = JekoPaymentMethod::tryFrom('invalid_method');
        $this->assertNull($method);
    }
}
