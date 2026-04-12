<?php

namespace Tests\Unit\Services;

use App\Services\AutoAssignmentService;
use Tests\TestCase;

class AutoAssignmentServiceTest extends TestCase
{
    public function test_it_can_be_instantiated(): void
    {
        $service = new AutoAssignmentService();
        $this->assertInstanceOf(AutoAssignmentService::class, $service);
    }
}
