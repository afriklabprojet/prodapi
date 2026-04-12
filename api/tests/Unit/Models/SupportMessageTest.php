<?php

namespace Tests\Unit\Models;

use App\Models\SupportMessage;
use Tests\TestCase;

class SupportMessageTest extends TestCase
{
    public function test_fillable_fields(): void
    {
        $model = new SupportMessage();
        $fillable = $model->getFillable();
        $this->assertContains('support_ticket_id', $fillable);
        $this->assertContains('user_id', $fillable);
        $this->assertContains('message', $fillable);
        $this->assertContains('is_from_support', $fillable);
    }

    public function test_casts(): void
    {
        $model = new SupportMessage();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('is_from_support', $casts);
        $this->assertArrayHasKey('read_at', $casts);
    }

    public function test_has_support_ticket_relationship(): void
    {
        $model = new SupportMessage();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->supportTicket());
    }

    public function test_has_user_relationship(): void
    {
        $model = new SupportMessage();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->user());
    }
}
