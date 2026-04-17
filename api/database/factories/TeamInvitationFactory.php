<?php

namespace Database\Factories;

use App\Enums\PharmacyRole;
use App\Models\Pharmacy;
use App\Models\TeamInvitation;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class TeamInvitationFactory extends Factory
{
    protected $model = TeamInvitation::class;

    public function definition(): array
    {
        return [
            'pharmacy_id' => Pharmacy::factory(),
            'invited_by' => User::factory(),
            'email' => $this->faker->unique()->safeEmail(),
            'phone' => '+213' . $this->faker->numerify('#########'),
            'role' => PharmacyRole::ADJOINT,
            'token' => Str::random(32),
            'status' => 'pending',
            'expires_at' => now()->addDays(7),
        ];
    }
}
