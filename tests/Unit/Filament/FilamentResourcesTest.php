<?php

namespace Tests\Unit\Filament;

use App\Filament\Resources\BonusMultiplierResource;
use App\Filament\Resources\CategoryResource;
use App\Filament\Resources\CommissionResource;
use App\Filament\Resources\CourierResource;
use App\Filament\Resources\CustomerAddressResource;
use App\Filament\Resources\CustomerResource;
use App\Filament\Resources\DeliveryZoneResource;
use App\Filament\Resources\DutyZoneResource;
use App\Filament\Resources\JekoPaymentResource;
use App\Filament\Resources\OrderResource;
use App\Filament\Resources\PharmacyResource;
use App\Filament\Resources\PrescriptionResource as FilamentPrescriptionResource;
use App\Filament\Resources\ProductResource;
use App\Filament\Resources\RatingResource;
use App\Filament\Resources\SettingResource;
use App\Filament\Resources\SupportTicketResource;
use App\Filament\Resources\UserResource;
use App\Filament\Resources\WithdrawalRequestResource;
use App\Models\Courier;
use Filament\Forms\Form;
use Filament\Tables\Table;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use ReflectionClass;
use Tests\TestCase;

class FilamentResourcesTest extends TestCase
{
    use RefreshDatabase;

    public static function resourceClasses(): array
    {
        return array_map(fn (string $class) => [$class], [
            BonusMultiplierResource::class,
            CategoryResource::class,
            CommissionResource::class,
            CourierResource::class,
            CustomerAddressResource::class,
            CustomerResource::class,
            DeliveryZoneResource::class,
            DutyZoneResource::class,
            JekoPaymentResource::class,
            OrderResource::class,
            PharmacyResource::class,
            FilamentPrescriptionResource::class,
            ProductResource::class,
            RatingResource::class,
            SettingResource::class,
            SupportTicketResource::class,
            UserResource::class,
            WithdrawalRequestResource::class,
        ]);
    }

    #[DataProvider('resourceClasses')]
    public function test_resource_builders_return_expected_types(string $resourceClass): void
    {
        $reflection = new ReflectionClass($resourceClass);

        if ($reflection->hasMethod('form') && $reflection->getMethod('form')->getDeclaringClass()->getName() === $resourceClass) {
            /** @var TestForm $form */
            $form = (new ReflectionClass(TestForm::class))->newInstanceWithoutConstructor();
            $result = $resourceClass::form($form);

            $this->assertSame($form, $result);
            $this->assertNotEmpty($form->schemaDefinition);
        }

        if ($reflection->hasMethod('table') && $reflection->getMethod('table')->getDeclaringClass()->getName() === $resourceClass) {
            /** @var TestTable $table */
            $table = (new ReflectionClass(TestTable::class))->newInstanceWithoutConstructor();
            $result = $resourceClass::table($table);

            $this->assertSame($table, $result);
            $this->assertNotEmpty($table->columnsDefinition);
        }

        if ($reflection->hasMethod('getPages') && $reflection->getMethod('getPages')->getDeclaringClass()->getName() === $resourceClass) {
            $pages = $resourceClass::getPages();
            $this->assertIsArray($pages);
            $this->assertNotEmpty($pages);
        }

        if ($reflection->hasMethod('getRelations') && $reflection->getMethod('getRelations')->getDeclaringClass()->getName() === $resourceClass) {
            $relations = $resourceClass::getRelations();
            $this->assertIsArray($relations);
        }
    }

    public function test_courier_resource_navigation_badge_and_color(): void
    {
        $this->assertNull(CourierResource::getNavigationBadge());

        Courier::factory()->create([
            'kyc_status' => 'pending_review',
        ]);

        $this->assertSame('1', CourierResource::getNavigationBadge());
        $this->assertSame('warning', CourierResource::getNavigationBadgeColor());
    }

    public function test_courier_resource_document_preview_fallbacks(): void
    {
        $reflection = new ReflectionClass(CourierResource::class);
        $method = $reflection->getMethod('renderDocumentPreview');
        $method->setAccessible(true);

        $this->assertSame('Aucun document', $method->invoke(null, null));
        $this->assertSame('Pas de fichier', $method->invoke(null, '', 'Pas de fichier'));

        $result = $method->invoke(null, 'documents/example.jpg');
        $this->assertTrue(is_string($result) || $result instanceof \Illuminate\Support\HtmlString);
    }
}

class TestForm extends Form
{
    public mixed $schemaDefinition = null;

    public function schema($components): static
    {
        $this->schemaDefinition = $components;

        return $this;
    }

    public function columns($columns = 2): static
    {
        return $this;
    }

    public function columnSpan($span = null): static
    {
        return $this;
    }

    public function __call(string $method, array $parameters): mixed
    {
        return $this;
    }
}

class TestTable extends Table
{
    public mixed $columnsDefinition = null;

    public function columns($columns = []): static
    {
        $this->columnsDefinition = $columns;

        return $this;
    }

    public function filters($filters = [], $layout = null): static
    {
        return $this;
    }

    public function actions($actions = [], $position = null): static
    {
        return $this;
    }

    public function bulkActions($actions = []): static
    {
        return $this;
    }

    public function headerActions($actions = [], $position = null): static
    {
        return $this;
    }

    public function defaultSort($column = null, $direction = 'asc'): static
    {
        return $this;
    }

    public function reorderable($column = null, $condition = null): static
    {
        return $this;
    }

    public function poll($interval = '10s'): static
    {
        return $this;
    }

    public function striped($condition = true): static
    {
        return $this;
    }

    public function groups($groups = []): static
    {
        return $this;
    }

    public function recordUrl($url = null, $shouldOpenInNewTab = false): static
    {
        return $this;
    }

    public function modifyQueryUsing($callback = null): static
    {
        return $this;
    }

    public function defaultPaginationPageOption($option = null): static
    {
        return $this;
    }

    public function paginated($options = null): static
    {
        return $this;
    }

    public function __call(string $method, array $parameters): mixed
    {
        return $this;
    }
}
