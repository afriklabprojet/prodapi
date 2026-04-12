<?php

namespace Tests\Unit\Filament;

use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use ReflectionClass;
use Tests\TestCase;

/**
 * Tests for all Filament Resource Pages and RelationManagers at 0% coverage.
 */
class FilamentResourcePagesTest extends TestCase
{
    use RefreshDatabase;

    // ═══════════════════════════════════════════════════════════════
    //  Resource Pages — property & method checks
    // ═══════════════════════════════════════════════════════════════

    public static function resourcePageClasses(): array
    {
        return array_map(fn (string $class) => [$class], [
            \App\Filament\Resources\BonusMultiplierResource\Pages\CreateBonusMultiplier::class,
            \App\Filament\Resources\BonusMultiplierResource\Pages\EditBonusMultiplier::class,
            \App\Filament\Resources\BonusMultiplierResource\Pages\ListBonusMultipliers::class,
            \App\Filament\Resources\CategoryResource\Pages\CreateCategory::class,
            \App\Filament\Resources\CategoryResource\Pages\EditCategory::class,
            \App\Filament\Resources\CategoryResource\Pages\ListCategories::class,
            \App\Filament\Resources\CommissionResource\Pages\ListCommissions::class,
            \App\Filament\Resources\CourierResource\Pages\CreateCourier::class,
            \App\Filament\Resources\CourierResource\Pages\EditCourier::class,
            \App\Filament\Resources\CourierResource\Pages\ListCouriers::class,
            \App\Filament\Resources\CourierResource\Pages\ViewCourier::class,
            \App\Filament\Resources\CustomerAddressResource\Pages\CreateCustomerAddress::class,
            \App\Filament\Resources\CustomerAddressResource\Pages\EditCustomerAddress::class,
            \App\Filament\Resources\CustomerAddressResource\Pages\ListCustomerAddresses::class,
            \App\Filament\Resources\CustomerResource\Pages\CreateCustomer::class,
            \App\Filament\Resources\CustomerResource\Pages\EditCustomer::class,
            \App\Filament\Resources\CustomerResource\Pages\ListCustomers::class,
            \App\Filament\Resources\DeliveryZoneResource\Pages\EditDeliveryZone::class,
            \App\Filament\Resources\DeliveryZoneResource\Pages\ListDeliveryZones::class,
            \App\Filament\Resources\DeliveryZoneResource\Pages\ViewDeliveryZone::class,
            \App\Filament\Resources\DutyZoneResource\Pages\CreateDutyZone::class,
            \App\Filament\Resources\DutyZoneResource\Pages\EditDutyZone::class,
            \App\Filament\Resources\DutyZoneResource\Pages\ListDutyZones::class,
            \App\Filament\Resources\JekoPaymentResource\Pages\ListJekoPayments::class,
            \App\Filament\Resources\JekoPaymentResource\Pages\ViewJekoPayment::class,
            \App\Filament\Resources\OrderResource\Pages\CreateOrder::class,
            \App\Filament\Resources\OrderResource\Pages\EditOrder::class,
            \App\Filament\Resources\OrderResource\Pages\ListOrders::class,
            \App\Filament\Resources\PharmacyResource\Pages\CreatePharmacy::class,
            \App\Filament\Resources\PharmacyResource\Pages\EditPharmacy::class,
            \App\Filament\Resources\PharmacyResource\Pages\ListPharmacies::class,
            \App\Filament\Resources\PrescriptionResource\Pages\CreatePrescription::class,
            \App\Filament\Resources\PrescriptionResource\Pages\EditPrescription::class,
            \App\Filament\Resources\PrescriptionResource\Pages\ListPrescriptions::class,
            \App\Filament\Resources\ProductResource\Pages\CreateProduct::class,
            \App\Filament\Resources\ProductResource\Pages\EditProduct::class,
            \App\Filament\Resources\ProductResource\Pages\ListProducts::class,
            \App\Filament\Resources\RatingResource\Pages\CreateRating::class,
            \App\Filament\Resources\RatingResource\Pages\EditRating::class,
            \App\Filament\Resources\RatingResource\Pages\ListRatings::class,
            \App\Filament\Resources\SettingResource\Pages\CreateSetting::class,
            \App\Filament\Resources\SettingResource\Pages\EditSetting::class,
            \App\Filament\Resources\SettingResource\Pages\ListSettings::class,
            \App\Filament\Resources\SupportTicketResource\Pages\CreateSupportTicket::class,
            \App\Filament\Resources\SupportTicketResource\Pages\EditSupportTicket::class,
            \App\Filament\Resources\SupportTicketResource\Pages\ListSupportTickets::class,
            \App\Filament\Resources\UserResource\Pages\CreateUser::class,
            \App\Filament\Resources\UserResource\Pages\EditUser::class,
            \App\Filament\Resources\UserResource\Pages\ListUsers::class,
            \App\Filament\Resources\WithdrawalRequestResource\Pages\ListWithdrawalRequests::class,
        ]);
    }

    #[DataProvider('resourcePageClasses')]
    public function test_resource_page_has_resource_property(string $pageClass): void
    {
        $reflection = new ReflectionClass($pageClass);
        $this->assertTrue(
            $reflection->hasProperty('resource'),
            "{$pageClass} should declare a \$resource property."
        );

        $prop = $reflection->getProperty('resource');
        $prop->setAccessible(true);
        $resourceClass = $prop->getValue();

        $this->assertNotNull($resourceClass, "{$pageClass}::\$resource should not be null.");
        $this->assertTrue(class_exists($resourceClass), "Resource class {$resourceClass} should exist.");
    }

    #[DataProvider('resourcePageClasses')]
    public function test_resource_page_extends_correct_base_class(string $pageClass): void
    {
        $validBases = [
            \Filament\Resources\Pages\ListRecords::class,
            \Filament\Resources\Pages\CreateRecord::class,
            \Filament\Resources\Pages\EditRecord::class,
            \Filament\Resources\Pages\ViewRecord::class,
        ];

        $extends = false;
        foreach ($validBases as $base) {
            if (is_subclass_of($pageClass, $base)) {
                $extends = true;
                break;
            }
        }

        $this->assertTrue($extends, "{$pageClass} should extend a Filament page base class.");
    }

    // ═══════════════════════════════════════════════════════════════
    //  WithdrawalRequest ListRecords — tabs
    // ═══════════════════════════════════════════════════════════════

    public function test_list_withdrawal_requests_has_tabs(): void
    {
        $page = new \App\Filament\Resources\WithdrawalRequestResource\Pages\ListWithdrawalRequests();
        $tabs = $page->getTabs();

        $this->assertIsArray($tabs);
        $this->assertArrayHasKey('all', $tabs);
        $this->assertArrayHasKey('pending', $tabs);
        $this->assertArrayHasKey('processing', $tabs);
        $this->assertArrayHasKey('completed', $tabs);
        $this->assertArrayHasKey('failed', $tabs);
    }

    // ═══════════════════════════════════════════════════════════════
    //  ViewCourier — header actions & infolist
    // ═══════════════════════════════════════════════════════════════

    public function test_view_courier_page_declares_custom_methods(): void
    {
        $reflection = new ReflectionClass(\App\Filament\Resources\CourierResource\Pages\ViewCourier::class);

        $this->assertTrue($reflection->hasMethod('getHeaderActions'));
        $this->assertTrue($reflection->hasMethod('infolist'));
        $this->assertSame(
            \App\Filament\Resources\CourierResource::class,
            $reflection->getProperty('resource')->getValue()
        );
    }

    // ═══════════════════════════════════════════════════════════════
    //  RelationManagers — form & table definitions
    // ═══════════════════════════════════════════════════════════════

    public static function relationManagerClasses(): array
    {
        return [
            'DeliveryRelationManager' => [\App\Filament\Resources\OrderResource\RelationManagers\DeliveryRelationManager::class],
            'ItemsRelationManager' => [\App\Filament\Resources\OrderResource\RelationManagers\ItemsRelationManager::class],
            'SupportMessagesRelationManager' => [\App\Filament\Resources\SupportTicketResource\RelationManagers\SupportMessagesRelationManager::class],
        ];
    }

    #[DataProvider('relationManagerClasses')]
    public function test_relation_manager_has_relationship_property(string $rmClass): void
    {
        $reflection = new ReflectionClass($rmClass);
        $this->assertTrue(
            $reflection->hasProperty('relationship'),
            "{$rmClass} should declare a \$relationship property."
        );

        $prop = $reflection->getProperty('relationship');
        $prop->setAccessible(true);
        $this->assertNotEmpty($prop->getValue(), "{$rmClass}::\$relationship should not be empty.");
    }

    #[DataProvider('relationManagerClasses')]
    public function test_relation_manager_has_form_method(string $rmClass): void
    {
        $reflection = new ReflectionClass($rmClass);
        $this->assertTrue($reflection->hasMethod('form'));
        $formMethod = $reflection->getMethod('form');
        $this->assertSame($rmClass, $formMethod->getDeclaringClass()->getName());
    }

    #[DataProvider('relationManagerClasses')]
    public function test_relation_manager_has_table_method(string $rmClass): void
    {
        $reflection = new ReflectionClass($rmClass);
        $this->assertTrue($reflection->hasMethod('table'));
        $tableMethod = $reflection->getMethod('table');
        $this->assertSame($rmClass, $tableMethod->getDeclaringClass()->getName());
    }

    public function test_delivery_relation_manager_relationship_value(): void
    {
        $reflection = new ReflectionClass(\App\Filament\Resources\OrderResource\RelationManagers\DeliveryRelationManager::class);
        $prop = $reflection->getProperty('relationship');
        $prop->setAccessible(true);
        $this->assertSame('delivery', $prop->getValue());
    }

    public function test_items_relation_manager_relationship_value(): void
    {
        $reflection = new ReflectionClass(\App\Filament\Resources\OrderResource\RelationManagers\ItemsRelationManager::class);
        $prop = $reflection->getProperty('relationship');
        $prop->setAccessible(true);
        $this->assertSame('items', $prop->getValue());
    }

    public function test_support_messages_relation_manager_relationship_value(): void
    {
        $reflection = new ReflectionClass(\App\Filament\Resources\SupportTicketResource\RelationManagers\SupportMessagesRelationManager::class);
        $prop = $reflection->getProperty('relationship');
        $prop->setAccessible(true);
        $this->assertSame('messages', $prop->getValue());
    }
}
