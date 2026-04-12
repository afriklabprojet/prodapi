<?php

namespace Tests\Unit\Filament\Pharmacy;

use App\Filament\Pharmacy\Resources\OrderResource;
use App\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use ReflectionClass;
use Tests\TestCase;
use Tests\Unit\Filament\TestForm;
use Tests\Unit\Filament\TestTable;

class PharmacyOrderResourceTest extends TestCase
{
    use RefreshDatabase;

    public function test_resource_model_is_order(): void
    {
        $this->assertSame(Order::class, OrderResource::getModel());
    }

    public function test_resource_navigation_icon(): void
    {
        $reflection = new ReflectionClass(OrderResource::class);
        $prop = $reflection->getProperty('navigationIcon');
        $prop->setAccessible(true);
        $this->assertSame('heroicon-o-shopping-cart', $prop->getValue());
    }

    public function test_resource_navigation_label(): void
    {
        $reflection = new ReflectionClass(OrderResource::class);
        $prop = $reflection->getProperty('navigationLabel');
        $prop->setAccessible(true);
        $this->assertSame('Commandes', $prop->getValue());
    }

    public function test_resource_has_form_method(): void
    {
        $reflection = new ReflectionClass(OrderResource::class);
        $this->assertTrue($reflection->hasMethod('form'));
        $this->assertSame(
            OrderResource::class,
            $reflection->getMethod('form')->getDeclaringClass()->getName()
        );
    }

    public function test_resource_has_table_method(): void
    {
        $reflection = new ReflectionClass(OrderResource::class);
        $this->assertTrue($reflection->hasMethod('table'));
        $this->assertSame(
            OrderResource::class,
            $reflection->getMethod('table')->getDeclaringClass()->getName()
        );
    }

    public function test_resource_declares_pages_method(): void
    {
        $reflection = new ReflectionClass(OrderResource::class);
        $method = $reflection->getMethod('getPages');
        $this->assertSame(
            OrderResource::class,
            $method->getDeclaringClass()->getName()
        );
    }

    public function test_resource_relations(): void
    {
        $relations = OrderResource::getRelations();
        $this->assertIsArray($relations);
    }

    public function test_resource_has_eloquent_query_override(): void
    {
        $reflection = new ReflectionClass(OrderResource::class);
        $method = $reflection->getMethod('getEloquentQuery');
        $this->assertSame(
            OrderResource::class,
            $method->getDeclaringClass()->getName()
        );
    }

    public function test_form_returns_schema(): void
    {
        /** @var TestForm $form */
        $form = (new ReflectionClass(TestForm::class))->newInstanceWithoutConstructor();
        $result = OrderResource::form($form);

        $this->assertSame($form, $result);
        $this->assertNotEmpty($form->schemaDefinition);
    }

    public function test_table_returns_columns(): void
    {
        /** @var TestTable $table */
        $table = (new ReflectionClass(TestTable::class))->newInstanceWithoutConstructor();
        $result = OrderResource::table($table);

        $this->assertSame($table, $result);
        $this->assertNotEmpty($table->columnsDefinition);
    }
}
