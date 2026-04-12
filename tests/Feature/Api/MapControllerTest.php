<?php

namespace Tests\Unit\Controllers;

use App\Http\Controllers\Api\MapController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class MapControllerTest extends TestCase
{
    public function test_it_can_be_instantiated(): void
    {
        $controller = new MapController();
        $this->assertInstanceOf(MapController::class, $controller);
    }

    public function test_directions_validates_origin(): void
    {
        $this->expectException(ValidationException::class);

        $controller = new MapController();
        $request = Request::create('/api/maps/directions', 'POST', [
            'destination' => '5.316,-4.012',
        ]);

        $controller->directions($request);
    }

    public function test_directions_validates_destination(): void
    {
        $this->expectException(ValidationException::class);

        $controller = new MapController();
        $request = Request::create('/api/maps/directions', 'POST', [
            'origin' => '5.360,-4.008',
        ]);

        $controller->directions($request);
    }

    public function test_directions_calls_google_api(): void
    {
        Http::fake([
            'maps.googleapis.com/maps/api/directions/*' => Http::response([
                'routes' => [['summary' => 'Route A']],
                'status' => 'OK',
            ], 200),
        ]);

        $controller = new MapController();
        $request = Request::create('/api/maps/directions', 'POST', [
            'origin' => '5.360,-4.008',
            'destination' => '5.316,-4.012',
        ]);

        $result = $controller->directions($request);

        $this->assertIsArray($result);
        $this->assertEquals('OK', $result['status']);
        $this->assertNotEmpty($result['routes']);

        Http::assertSent(function ($request) {
            return str_contains($request->url(), 'directions/json') &&
                $request['mode'] === 'driving' &&
                $request['language'] === 'fr';
        });
    }
}
