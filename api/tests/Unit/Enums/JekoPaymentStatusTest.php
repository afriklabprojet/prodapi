<?php

namespace Tests\Unit\Enums;

use App\Enums\JekoPaymentStatus;
use Tests\TestCase;

class JekoPaymentStatusTest extends TestCase
{
    /** @test */
    public function it_has_pending_status()
    {
        $this->assertEquals('pending', JekoPaymentStatus::PENDING->value);
    }

    /** @test */
    public function it_has_processing_status()
    {
        $this->assertEquals('processing', JekoPaymentStatus::PROCESSING->value);
    }

    /** @test */
    public function it_has_success_status()
    {
        $this->assertEquals('success', JekoPaymentStatus::SUCCESS->value);
    }

    /** @test */
    public function it_has_failed_status()
    {
        $this->assertEquals('failed', JekoPaymentStatus::FAILED->value);
    }

    /** @test */
    public function it_has_expired_status()
    {
        $this->assertEquals('expired', JekoPaymentStatus::EXPIRED->value);
    }

    /** @test */
    public function pending_has_correct_label()
    {
        $this->assertEquals('En attente', JekoPaymentStatus::PENDING->label());
    }

    /** @test */
    public function processing_has_correct_label()
    {
        $this->assertEquals('En cours', JekoPaymentStatus::PROCESSING->label());
    }

    /** @test */
    public function success_has_correct_label()
    {
        $this->assertEquals('Réussi', JekoPaymentStatus::SUCCESS->label());
    }

    /** @test */
    public function failed_has_correct_label()
    {
        $this->assertEquals('Échoué', JekoPaymentStatus::FAILED->label());
    }

    /** @test */
    public function expired_has_correct_label()
    {
        $this->assertEquals('Expiré', JekoPaymentStatus::EXPIRED->label());
    }

    /** @test */
    public function pending_has_warning_color()
    {
        $this->assertEquals('warning', JekoPaymentStatus::PENDING->color());
    }

    /** @test */
    public function processing_has_info_color()
    {
        $this->assertEquals('info', JekoPaymentStatus::PROCESSING->color());
    }

    /** @test */
    public function success_has_success_color()
    {
        $this->assertEquals('success', JekoPaymentStatus::SUCCESS->color());
    }

    /** @test */
    public function failed_has_danger_color()
    {
        $this->assertEquals('danger', JekoPaymentStatus::FAILED->color());
    }

    /** @test */
    public function expired_has_gray_color()
    {
        $this->assertEquals('gray', JekoPaymentStatus::EXPIRED->color());
    }

    /** @test */
    public function success_is_final()
    {
        $this->assertTrue(JekoPaymentStatus::SUCCESS->isFinal());
    }

    /** @test */
    public function failed_is_final()
    {
        $this->assertTrue(JekoPaymentStatus::FAILED->isFinal());
    }

    /** @test */
    public function expired_is_final()
    {
        $this->assertTrue(JekoPaymentStatus::EXPIRED->isFinal());
    }

    /** @test */
    public function pending_is_not_final()
    {
        $this->assertFalse(JekoPaymentStatus::PENDING->isFinal());
    }

    /** @test */
    public function processing_is_not_final()
    {
        $this->assertFalse(JekoPaymentStatus::PROCESSING->isFinal());
    }

    /** @test */
    public function can_be_created_from_string()
    {
        $status = JekoPaymentStatus::from('pending');
        $this->assertEquals(JekoPaymentStatus::PENDING, $status);
    }

    /** @test */
    public function try_from_returns_null_for_invalid_value()
    {
        $status = JekoPaymentStatus::tryFrom('invalid_status');
        $this->assertNull($status);
    }

    /** @test */
    public function cases_returns_all_statuses()
    {
        $cases = JekoPaymentStatus::cases();
        
        $this->assertCount(5, $cases);
        $this->assertContains(JekoPaymentStatus::PENDING, $cases);
        $this->assertContains(JekoPaymentStatus::PROCESSING, $cases);
        $this->assertContains(JekoPaymentStatus::SUCCESS, $cases);
        $this->assertContains(JekoPaymentStatus::FAILED, $cases);
        $this->assertContains(JekoPaymentStatus::EXPIRED, $cases);
    }
}
