<?php

namespace Tests\Unit\Filament;

use App\Filament\Pages\BroadcastNotification;
use App\Filament\Pages\ForceChangePassword;
use App\Filament\Pages\HelpPagesSettings;
use App\Filament\Pages\LandingPageSettings;
use App\Filament\Pages\PayoutOverview;
use App\Filament\Pages\Settings as SettingsPage;
use App\Models\Setting;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\MessageTarget;
use Kreait\Firebase\Messaging\MulticastSendReport;
use Kreait\Firebase\Messaging\SendReport;
use Mockery;
use ReflectionClass;
use Tests\TestCase;

class FilamentPagesTest extends TestCase
{
    use RefreshDatabase;

    // ═══════════════════════════════════════════════════════════════
    //  BroadcastNotification
    // ═══════════════════════════════════════════════════════════════

    public function test_broadcast_notification_page_has_correct_properties(): void
    {
        $reflection = new ReflectionClass(BroadcastNotification::class);

        $this->assertSame('filament.pages.broadcast-notification', $reflection->getProperty('view')->getValue());
        $this->assertSame('heroicon-o-megaphone', $reflection->getProperty('navigationIcon')->getValue());
    }

    public function test_broadcast_notification_default_state(): void
    {
        $page = new BroadcastNotification();
        $this->assertSame('all', $page->target);
        $this->assertSame('', $page->notification_title);
        $this->assertSame('', $page->body);
        $this->assertSame([], $page->data);
    }

    public function test_broadcast_notification_send_with_no_tokens(): void
    {
        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);
        $this->actingAs($admin);

        $page = new BroadcastNotification();
        $page->target = 'all';
        $page->notification_title = 'Test Notification';
        $page->body = 'Test Body message';
        $page->data = [];

        // No users with FCM tokens exist, so no send should happen
        $page->send();

        // Should not throw — just a "no recipients" notification
        $this->assertTrue(true);
    }

    public function test_broadcast_notification_send_success(): void
    {
        User::factory()->create([
            'role'      => 'customer',
            'fcm_token' => 'fake-token-123',
        ]);

        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);
        $this->actingAs($admin);

        // Use real MulticastSendReport (final class, cannot be mocked)
        $target = MessageTarget::with(MessageTarget::TOKEN, 'fake-token-123');
        $successItem = SendReport::success($target, ['message_id' => 'test-msg-id']);
        $report = MulticastSendReport::withItems([$successItem]);

        $messaging = Mockery::mock(Messaging::class);
        $messaging->shouldReceive('sendMulticast')->once()->andReturn($report);
        $this->app->instance(Messaging::class, $messaging);

        $page = new BroadcastNotification();
        $page->target = 'all';
        $page->notification_title = 'Promo';
        $page->body = 'Test send';
        $page->data = [];

        $page->send();

        // After successful send, form fields should be reset
        $this->assertSame('', $page->notification_title);
        $this->assertSame('', $page->body);
    }

    public function test_broadcast_notification_send_exception_handled(): void
    {
        User::factory()->create([
            'role'      => 'customer',
            'fcm_token' => 'fake-token-456',
        ]);

        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);
        $this->actingAs($admin);

        $messaging = Mockery::mock(Messaging::class);
        $messaging->shouldReceive('sendMulticast')
            ->andThrow(new \Exception('FCM error'));
        $this->app->instance(Messaging::class, $messaging);

        $page = new BroadcastNotification();
        $page->target = 'all';
        $page->notification_title = 'Error Test';
        $page->body = 'Will fail';
        $page->data = [];

        // Should not throw, exception is caught internally
        $page->send();
        $this->assertTrue(true);
    }

    public function test_broadcast_notification_targets_specific_role(): void
    {
        User::factory()->create(['role' => 'customer', 'fcm_token' => 'token-customer']);
        User::factory()->create(['role' => 'pharmacy', 'fcm_token' => 'token-pharmacy']);

        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);
        $this->actingAs($admin);

        $target = MessageTarget::with(MessageTarget::TOKEN, 'token-customer');
        $successItem = SendReport::success($target, ['message_id' => 'msg-customer']);
        $report = MulticastSendReport::withItems([$successItem]);

        $messaging = Mockery::mock(Messaging::class);
        $messaging->shouldReceive('sendMulticast')->once()->andReturn($report);
        $this->app->instance(Messaging::class, $messaging);

        $page = new BroadcastNotification();
        $page->target = 'customer';
        $page->notification_title = 'Customer Only';
        $page->body = 'Only for customers';
        $page->data = [];

        $page->send();
        $this->assertSame('', $page->notification_title);
    }

    public function test_broadcast_notification_form_state_path(): void
    {
        $page = new BroadcastNotification();
        $reflection = new ReflectionClass($page);
        $method = $reflection->getMethod('getFormStatePath');
        $method->setAccessible(true);

        $this->assertNull($method->invoke($page));
    }

    // ═══════════════════════════════════════════════════════════════
    //  ForceChangePassword
    // ═══════════════════════════════════════════════════════════════

    public function test_force_change_password_not_in_navigation(): void
    {
        $reflection = new ReflectionClass(ForceChangePassword::class);
        $prop = $reflection->getProperty('shouldRegisterNavigation');
        $prop->setAccessible(true);
        $this->assertFalse($prop->getValue());
    }

    public function test_force_change_password_slug(): void
    {
        $reflection = new ReflectionClass(ForceChangePassword::class);
        $prop = $reflection->getProperty('slug');
        $prop->setAccessible(true);
        $this->assertSame('force-change-password', $prop->getValue());
    }

    public function test_force_change_password_view(): void
    {
        $reflection = new ReflectionClass(ForceChangePassword::class);
        $prop = $reflection->getProperty('view');
        $prop->setAccessible(true);
        $this->assertSame('filament.pages.force-change-password', $prop->getValue());
    }

    public function test_force_change_password_default_state(): void
    {
        $page = new ForceChangePassword();
        $this->assertSame('', $page->new_password);
        $this->assertSame('', $page->new_password_confirmation);
    }

    public function test_force_change_password_get_form_actions(): void
    {
        $page = new ForceChangePassword();
        $reflection = new ReflectionClass($page);
        $method = $reflection->getMethod('getFormActions');
        $method->setAccessible(true);

        $actions = $method->invoke($page);
        $this->assertIsArray($actions);
        $this->assertNotEmpty($actions);
    }

    // ═══════════════════════════════════════════════════════════════
    //  PayoutOverview
    // ═══════════════════════════════════════════════════════════════

    public function test_payout_overview_can_access_as_admin(): void
    {
        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);
        $this->actingAs($admin);

        $this->assertTrue(PayoutOverview::canAccess());
    }

    public function test_payout_overview_cannot_access_as_non_admin(): void
    {
        /** @var User $user */
        $user = User::factory()->create(['role' => 'customer']);
        $this->actingAs($user);

        $this->assertFalse(PayoutOverview::canAccess());
    }

    public function test_payout_overview_cannot_access_unauthenticated(): void
    {
        $this->assertFalse(PayoutOverview::canAccess());
    }

    public function test_payout_overview_default_tab(): void
    {
        $page = new PayoutOverview();
        $this->assertSame('pharmacies', $page->activeTab);
    }

    public function test_payout_overview_switch_tab(): void
    {
        $page = $this->getMockBuilder(PayoutOverview::class)
            ->onlyMethods(['resetTable'])
            ->getMock();

        $page->expects($this->once())->method('resetTable');
        $page->switchTab('couriers');
        $this->assertSame('couriers', $page->activeTab);
    }

    public function test_payout_overview_header_widgets(): void
    {
        $page = new PayoutOverview();
        $reflection = new ReflectionClass($page);
        $method = $reflection->getMethod('getHeaderWidgets');
        $method->setAccessible(true);

        $widgets = $method->invoke($page);
        $this->assertIsArray($widgets);
        $this->assertContains(\App\Filament\Pages\PayoutOverview\PayoutStatsWidget::class, $widgets);
    }

    public function test_payout_overview_header_widgets_columns(): void
    {
        $page = new PayoutOverview();
        $this->assertSame(4, $page->getHeaderWidgetsColumns());
    }

    public function test_payout_overview_navigation_properties(): void
    {
        $reflection = new ReflectionClass(PayoutOverview::class);

        $this->assertSame('heroicon-o-banknotes', $reflection->getProperty('navigationIcon')->getValue());
        $this->assertSame('payout-overview', $reflection->getProperty('slug')->getValue());
        $this->assertSame('Finance', $reflection->getProperty('navigationGroup')->getValue());
    }

    // ═══════════════════════════════════════════════════════════════
    //  Settings Page
    // ═══════════════════════════════════════════════════════════════

    public function test_settings_page_can_access_as_admin(): void
    {
        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);
        $this->actingAs($admin);

        $this->assertTrue(SettingsPage::canAccess());
    }

    public function test_settings_page_cannot_access_as_non_admin(): void
    {
        /** @var User $user */
        $user = User::factory()->create(['role' => 'customer']);
        $this->actingAs($user);

        $this->assertFalse(SettingsPage::canAccess());
    }

    public function test_settings_page_navigation_properties(): void
    {
        $reflection = new ReflectionClass(SettingsPage::class);

        $this->assertSame('heroicon-o-cog-6-tooth', $reflection->getProperty('navigationIcon')->getValue());
        $this->assertSame('system-settings', $reflection->getProperty('slug')->getValue());
        $this->assertSame('Configuration', $reflection->getProperty('navigationGroup')->getValue());
    }

    public function test_settings_page_get_available_sounds(): void
    {
        $page = new SettingsPage();
        $reflection = new ReflectionClass($page);
        $method = $reflection->getMethod('getAvailableSounds');
        $method->setAccessible(true);

        $sounds = $method->invoke($page);

        $this->assertIsArray($sounds);
        $this->assertCount(13, $sounds);
        $this->assertArrayHasKey('default', $sounds);
        $this->assertArrayHasKey('delivery_alert', $sounds);
        $this->assertArrayHasKey('none', $sounds);
    }

    public function test_settings_page_get_form_actions(): void
    {
        $page = new SettingsPage();
        $reflection = new ReflectionClass($page);
        $method = $reflection->getMethod('getFormActions');
        $method->setAccessible(true);

        $actions = $method->invoke($page);
        $this->assertIsArray($actions);
        $this->assertNotEmpty($actions);
    }

    // ═══════════════════════════════════════════════════════════════
    //  HelpPagesSettings
    // ═══════════════════════════════════════════════════════════════

    public function test_help_pages_settings_page_properties(): void
    {
        $reflection = new ReflectionClass(HelpPagesSettings::class);

        $this->assertTrue($reflection->hasProperty('navigationIcon'));
        $this->assertTrue($reflection->hasProperty('view'));
        $this->assertTrue($reflection->hasMethod('form'));
    }

    public function test_help_pages_settings_extends_page(): void
    {
        $this->assertTrue(is_subclass_of(HelpPagesSettings::class, \Filament\Pages\Page::class));
    }

    // ═══════════════════════════════════════════════════════════════
    //  LandingPageSettings
    // ═══════════════════════════════════════════════════════════════

    public function test_landing_page_settings_page_properties(): void
    {
        $reflection = new ReflectionClass(LandingPageSettings::class);

        $this->assertTrue($reflection->hasProperty('navigationIcon'));
        $this->assertTrue($reflection->hasProperty('view'));
        $this->assertTrue($reflection->hasMethod('form'));
    }

    public function test_landing_page_settings_extends_page(): void
    {
        $this->assertTrue(is_subclass_of(LandingPageSettings::class, \Filament\Pages\Page::class));
    }
}
