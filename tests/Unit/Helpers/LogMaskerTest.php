<?php

namespace Tests\Unit\Helpers;

use App\Helpers\LogMasker;
use Tests\TestCase;

class LogMaskerTest extends TestCase
{
    /** @test */
    public function it_masks_email_addresses()
    {
        $data = ['email' => 'john.doe@example.com'];
        $masked = LogMasker::mask($data);

        $this->assertNotEquals('john.doe@example.com', $masked['email']);
        $this->assertStringContainsString('***', $masked['email']);
        $this->assertStringContainsString('@', $masked['email']);
    }

    /** @test */
    public function it_masks_phone_numbers()
    {
        $data = ['phone' => '+22507123456789'];
        $masked = LogMasker::mask($data);

        $this->assertNotEquals('+22507123456789', $masked['phone']);
        $this->assertStringContainsString('***', $masked['phone']);
    }

    /** @test */
    public function it_masks_passwords()
    {
        $data = ['password' => 'supersecret123'];
        $masked = LogMasker::mask($data);

        $this->assertNotEquals('supersecret123', $masked['password']);
        $this->assertStringContainsString('***', $masked['password']);
    }

    /** @test */
    public function it_masks_tokens()
    {
        $data = ['token' => 'abc123xyz789verylongtoken'];
        $masked = LogMasker::mask($data);

        $this->assertNotEquals('abc123xyz789verylongtoken', $masked['token']);
        $this->assertStringContainsString('***', $masked['token']);
    }

    /** @test */
    public function it_masks_api_keys()
    {
        $data = ['api_key' => 'sk_live_abc123xyz'];
        $masked = LogMasker::mask($data);

        $this->assertNotEquals('sk_live_abc123xyz', $masked['api_key']);
    }

    /** @test */
    public function it_masks_otp_codes()
    {
        $data = ['otp' => '123456'];
        $masked = LogMasker::mask($data);

        $this->assertNotEquals('123456', $masked['otp']);
    }

    /** @test */
    public function it_masks_verification_codes()
    {
        $data = ['verification_code' => '7890'];
        $masked = LogMasker::mask($data);

        $this->assertNotEquals('7890', $masked['verification_code']);
    }

    /** @test */
    public function it_preserves_non_sensitive_fields()
    {
        $data = [
            'name' => 'John Doe',
            'status' => 'active',
            'amount' => 5000,
        ];
        $masked = LogMasker::mask($data);

        $this->assertEquals('John Doe', $masked['name']);
        $this->assertEquals('active', $masked['status']);
        $this->assertEquals(5000, $masked['amount']);
    }

    /** @test */
    public function it_handles_nested_arrays()
    {
        $data = [
            'user' => [
                'email' => 'test@example.com',
                'phone' => '+1234567890',
                'name' => 'Test User',
            ],
        ];
        $masked = LogMasker::mask($data);

        $this->assertNotEquals('test@example.com', $masked['user']['email']);
        $this->assertNotEquals('+1234567890', $masked['user']['phone']);
        $this->assertEquals('Test User', $masked['user']['name']);
    }

    /** @test */
    public function it_handles_null_values()
    {
        $data = ['email' => null];
        $masked = LogMasker::mask($data);

        $this->assertEquals('[null]', $masked['email']);
    }

    /** @test */
    public function it_handles_empty_values()
    {
        $data = ['phone' => ''];
        $masked = LogMasker::mask($data);

        $this->assertEquals('[empty]', $masked['phone']);
    }

    /** @test */
    public function mask_email_hides_local_and_domain()
    {
        $masked = LogMasker::maskEmail('john@example.com');

        $this->assertStringStartsWith('joh', $masked);
        $this->assertStringContainsString('@', $masked);
        $this->assertStringEndsWith('.com', $masked);
    }

    /** @test */
    public function mask_email_handles_short_local_part()
    {
        $masked = LogMasker::maskEmail('jo@example.com');

        $this->assertStringContainsString('@', $masked);
    }

    /** @test */
    public function mask_email_handles_non_email_string()
    {
        $masked = LogMasker::maskEmail('not-an-email');

        $this->assertStringContainsString('***', $masked);
    }

    /** @test */
    public function mask_phone_preserves_prefix_and_suffix()
    {
        $masked = LogMasker::maskPhone('+22507123456');

        $this->assertStringStartsWith('+2250', $masked);
        $this->assertStringEndsWith('3456', $masked);
        $this->assertStringContainsString('***', $masked);
    }

    /** @test */
    public function mask_phone_handles_short_numbers()
    {
        $masked = LogMasker::maskPhone('1234');

        $this->assertEquals('****', $masked);
    }

    /** @test */
    public function it_is_case_insensitive_for_field_names()
    {
        $data = [
            'EMAIL' => 'test@test.com',
            'Phone' => '+1234567890',
            'PASSWORD' => 'secret',
        ];
        $masked = LogMasker::mask($data);

        $this->assertStringContainsString('***', $masked['EMAIL']);
        $this->assertStringContainsString('***', $masked['Phone']);
        $this->assertStringContainsString('***', $masked['PASSWORD']);
    }

    /** @test */
    public function it_masks_fields_containing_sensitive_keywords()
    {
        $data = [
            'user_email' => 'user@test.com',
            'phone_number' => '+1234567890',
            'api_token' => 'token123',
        ];
        $masked = LogMasker::mask($data);

        $this->assertStringContainsString('***', $masked['user_email']);
        $this->assertStringContainsString('***', $masked['phone_number']);
        $this->assertStringContainsString('***', $masked['api_token']);
    }

    /** @test */
    public function it_handles_deeply_nested_arrays()
    {
        $data = [
            'level1' => [
                'level2' => [
                    'level3' => [
                        'email' => 'deep@nested.com',
                    ],
                ],
            ],
        ];
        $masked = LogMasker::mask($data);

        $this->assertStringContainsString('***', $masked['level1']['level2']['level3']['email']);
    }
}
