<?php

namespace Tests\Unit\Enums;

use App\Enums\JekoPaymentStatus;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class JekoPaymentStatusTest extends TestCase
{
    #[Test]
    public function it_has_pending_status()
    {
        $this->assertEquals('pending', JekoPaymentStatus::PENDING->value);
    }

    #[Test]
    public function it_has_processing_status()
    {
        $this->assertEquals('processing', JekoPaymentStatus::PROCESSING->value);
    }

    #[Test]
    public function it_has_success_status()
    {
        $this->assertEquals('success', JekoPaymentStatus::SUCCESS->value);
    }

    #[Test]
    public function it_has_failed_status()
    {
        $this->assertEquals('failed', JekoPaymentStatus::FAILED->value);
    }

    #[Test]
    public function it_has_expired_status()
    {
        $this->assertEquals('expired', JekoPaymentStatus::EXPIRED->value);
    }

    #[Test]
    public function pending_has_correct_label()
    {
        $this->assertEquals('En attente', JekoPaymentStatus::PENDING->label());
    }

    #[Test]
    public function processing_has_correct_label()
    {
        $this->assertEquals('En cours', JekoPaymentStatus::PROCESSING->label());
    }

    #[Test]
    public function success_has_correct_label()
    {
        $this->assertEquals('Réussi', JekoPaymentStatus::SUCCESS->label());
    }

    #[Test]
    public function failed_has_correct_label()
    {
        $this->assertEquals('Échoué', JekoPaymentStatus::FAILED->label());
    }

    #[Test]
    public function expired_has_correct_label()
    {
        $this->assertEquals('Expiré', JekoPaymentStatus::EXPIRED->label());
    }

    #[Test]
    public function pending_has_warning_color()
    {
        $this->assertEquals('warning', JekoPaymentStatus::PENDING->color());
    }

    #[Test]
    public function processing_has_info_color()
    {
        $this->assertEquals('info', JekoPaymentStatus::PROCESSING->color());
    }

    #[Test]
    public function success_has_success_color()
    {
        $this->assertEquals('success', JekoPaymentStatus::SUCCESS->color());
    }

    #[Test]
    public function failed_has_danger_color()
    {
        $this->assertEquals('danger', JekoPaymentStatus::FAILED->color());
    }

    #[Test]
    public function expired_has_gray_color()
    {
        $this->assertEquals('gray', JekoPaymentStatus::EXPIRED->color());
    }

    #[Test]
    public function success_is_final()
    {
        $this->assertTrue(JekoPaymentStatus::SUCCESS->isFinal());
    }

    #[Test]
    public function failed_is_final()
    {
        $this->assertTrue(JekoPaymentStatus::FAILED->isFinal());
    }

    #[Test]
    public function expired_is_final()
    {
        $this->assertTrue(JekoPaymentStatus::EXPIRED->isFinal());
    }

    #[Test]
    public function pending_is_not_final()
    {
        $this->assertFalse(JekoPaymentStatus::PENDING->isFinal());
    }

    #[Test]
    public function processing_is_not_final()
    {
        $this->assertFalse(JekoPaymentStatus::PROCESSING->isFinal());
    }

    #[Test]
    public function can_be_created_from_string()
    {
        $status = JekoPaymentStatus::from('pending');
        $this->assertEquals(JekoPaymentStatus::PENDING, $status);
    }

    #[Test]
    public function try_from_returns_null_for_invalid_value()
    {
        $status = JekoPaymentStatus::tryFrom('invalid_status');
        $this->assertNull($status);
    }

    #[Test]
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
