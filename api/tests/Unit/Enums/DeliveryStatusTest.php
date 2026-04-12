<?php

namespace Tests\Unit\Enums;

use App\Enums\DeliveryStatus;
use PHPUnit\Framework\TestCase;

class DeliveryStatusTest extends TestCase
{
    public function test_all_cases_have_correct_values(): void
    {
        $this->assertSame('pending', DeliveryStatus::Pending->value);
        $this->assertSame('accepted', DeliveryStatus::Accepted->value);
        $this->assertSame('assigned', DeliveryStatus::Assigned->value);
        $this->assertSame('picked_up', DeliveryStatus::PickedUp->value);
        $this->assertSame('in_transit', DeliveryStatus::InTransit->value);
        $this->assertSame('delivered', DeliveryStatus::Delivered->value);
        $this->assertSame('cancelled', DeliveryStatus::Cancelled->value);
        $this->assertSame('failed', DeliveryStatus::Failed->value);
    }

    public function test_label_returns_french_translations(): void
    {
        $this->assertSame('En attente', DeliveryStatus::Pending->label());
        $this->assertSame('Acceptée', DeliveryStatus::Accepted->label());
        $this->assertSame('Assignée', DeliveryStatus::Assigned->label());
        $this->assertSame('Récupérée', DeliveryStatus::PickedUp->label());
        $this->assertSame('En transit', DeliveryStatus::InTransit->label());
        $this->assertSame('Livrée', DeliveryStatus::Delivered->label());
        $this->assertSame('Annulée', DeliveryStatus::Cancelled->label());
        $this->assertSame('Échouée', DeliveryStatus::Failed->label());
    }

    public function test_color_returns_correct_values(): void
    {
        $this->assertSame('warning', DeliveryStatus::Pending->color());
        $this->assertSame('info', DeliveryStatus::Accepted->color());
        $this->assertSame('primary', DeliveryStatus::Assigned->color());
        $this->assertSame('primary', DeliveryStatus::PickedUp->color());
        $this->assertSame('primary', DeliveryStatus::InTransit->color());
        $this->assertSame('success', DeliveryStatus::Delivered->color());
        $this->assertSame('danger', DeliveryStatus::Cancelled->color());
        $this->assertSame('danger', DeliveryStatus::Failed->color());
    }

    public function test_is_active_returns_true_for_active_statuses(): void
    {
        $this->assertTrue(DeliveryStatus::Accepted->isActive());
        $this->assertTrue(DeliveryStatus::Assigned->isActive());
        $this->assertTrue(DeliveryStatus::PickedUp->isActive());
        $this->assertTrue(DeliveryStatus::InTransit->isActive());
    }

    public function test_is_active_returns_false_for_non_active_statuses(): void
    {
        $this->assertFalse(DeliveryStatus::Pending->isActive());
        $this->assertFalse(DeliveryStatus::Delivered->isActive());
        $this->assertFalse(DeliveryStatus::Cancelled->isActive());
        $this->assertFalse(DeliveryStatus::Failed->isActive());
    }

    public function test_is_terminal_returns_true_for_terminal_statuses(): void
    {
        $this->assertTrue(DeliveryStatus::Delivered->isTerminal());
        $this->assertTrue(DeliveryStatus::Cancelled->isTerminal());
        $this->assertTrue(DeliveryStatus::Failed->isTerminal());
    }

    public function test_is_terminal_returns_false_for_non_terminal_statuses(): void
    {
        $this->assertFalse(DeliveryStatus::Pending->isTerminal());
        $this->assertFalse(DeliveryStatus::Accepted->isTerminal());
        $this->assertFalse(DeliveryStatus::Assigned->isTerminal());
        $this->assertFalse(DeliveryStatus::PickedUp->isTerminal());
        $this->assertFalse(DeliveryStatus::InTransit->isTerminal());
    }

    public function test_cases_count(): void
    {
        $this->assertCount(8, DeliveryStatus::cases());
    }
}
