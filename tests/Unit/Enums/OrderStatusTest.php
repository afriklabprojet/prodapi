<?php

namespace Tests\Unit\Enums;

use App\Enums\OrderStatus;
use PHPUnit\Framework\TestCase;

class OrderStatusTest extends TestCase
{
    public function test_all_cases_have_correct_values(): void
    {
        $this->assertSame('pending', OrderStatus::Pending->value);
        $this->assertSame('confirmed', OrderStatus::Confirmed->value);
        $this->assertSame('preparing', OrderStatus::Preparing->value);
        $this->assertSame('ready', OrderStatus::Ready->value);
        $this->assertSame('paid', OrderStatus::Paid->value);
        $this->assertSame('assigned', OrderStatus::Assigned->value);
        $this->assertSame('in_transit', OrderStatus::InTransit->value);
        $this->assertSame('in_delivery', OrderStatus::InDelivery->value);
        $this->assertSame('delivered', OrderStatus::Delivered->value);
        $this->assertSame('cancelled', OrderStatus::Cancelled->value);
    }

    public function test_label_returns_french_translations(): void
    {
        $this->assertSame('En attente', OrderStatus::Pending->label());
        $this->assertSame('Confirmée', OrderStatus::Confirmed->label());
        $this->assertSame('En préparation', OrderStatus::Preparing->label());
        $this->assertSame('Prête', OrderStatus::Ready->label());
        $this->assertSame('Payée', OrderStatus::Paid->label());
        $this->assertSame('Assignée', OrderStatus::Assigned->label());
        $this->assertSame('En transit', OrderStatus::InTransit->label());
        $this->assertSame('En livraison', OrderStatus::InDelivery->label());
        $this->assertSame('Livrée', OrderStatus::Delivered->label());
        $this->assertSame('Annulée', OrderStatus::Cancelled->label());
    }

    public function test_color_returns_correct_values(): void
    {
        $this->assertSame('warning', OrderStatus::Pending->color());
        $this->assertSame('info', OrderStatus::Confirmed->color());
        $this->assertSame('info', OrderStatus::Preparing->color());
        $this->assertSame('success', OrderStatus::Ready->color());
        $this->assertSame('success', OrderStatus::Paid->color());
        $this->assertSame('primary', OrderStatus::Assigned->color());
        $this->assertSame('primary', OrderStatus::InTransit->color());
        $this->assertSame('primary', OrderStatus::InDelivery->color());
        $this->assertSame('success', OrderStatus::Delivered->color());
        $this->assertSame('danger', OrderStatus::Cancelled->color());
    }

    public function test_is_cancellable_returns_true_for_cancellable_statuses(): void
    {
        $this->assertTrue(OrderStatus::Pending->isCancellable());
        $this->assertTrue(OrderStatus::Confirmed->isCancellable());
        $this->assertTrue(OrderStatus::Preparing->isCancellable());
    }

    public function test_is_cancellable_returns_false_for_non_cancellable_statuses(): void
    {
        $this->assertFalse(OrderStatus::Ready->isCancellable());
        $this->assertFalse(OrderStatus::Paid->isCancellable());
        $this->assertFalse(OrderStatus::Assigned->isCancellable());
        $this->assertFalse(OrderStatus::InTransit->isCancellable());
        $this->assertFalse(OrderStatus::InDelivery->isCancellable());
        $this->assertFalse(OrderStatus::Delivered->isCancellable());
        $this->assertFalse(OrderStatus::Cancelled->isCancellable());
    }

    public function test_is_active_returns_true_for_active_statuses(): void
    {
        $this->assertTrue(OrderStatus::Confirmed->isActive());
        $this->assertTrue(OrderStatus::Preparing->isActive());
        $this->assertTrue(OrderStatus::Ready->isActive());
        $this->assertTrue(OrderStatus::Paid->isActive());
        $this->assertTrue(OrderStatus::Assigned->isActive());
        $this->assertTrue(OrderStatus::InTransit->isActive());
        $this->assertTrue(OrderStatus::InDelivery->isActive());
    }

    public function test_is_active_returns_false_for_non_active_statuses(): void
    {
        $this->assertFalse(OrderStatus::Pending->isActive());
        $this->assertFalse(OrderStatus::Delivered->isActive());
        $this->assertFalse(OrderStatus::Cancelled->isActive());
    }

    public function test_cases_count(): void
    {
        $this->assertCount(10, OrderStatus::cases());
    }
}
