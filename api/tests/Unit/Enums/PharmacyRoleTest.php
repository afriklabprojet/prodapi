<?php

namespace Tests\Unit\Enums;

use App\Enums\PharmacyRole;
use PHPUnit\Framework\TestCase;

class PharmacyRoleTest extends TestCase
{
    public function test_all_cases_have_correct_values(): void
    {
        $this->assertSame('titulaire', PharmacyRole::TITULAIRE->value);
        $this->assertSame('adjoint', PharmacyRole::ADJOINT->value);
        $this->assertSame('preparateur', PharmacyRole::PREPARATEUR->value);
        $this->assertSame('stagiaire', PharmacyRole::STAGIAIRE->value);
    }

    public function test_label_returns_french_labels(): void
    {
        $this->assertSame('Pharmacien Titulaire', PharmacyRole::TITULAIRE->label());
        $this->assertSame('Pharmacien Adjoint', PharmacyRole::ADJOINT->label());
        $this->assertSame('Préparateur', PharmacyRole::PREPARATEUR->label());
        $this->assertSame('Stagiaire', PharmacyRole::STAGIAIRE->label());
    }

    public function test_titulaire_has_all_permissions(): void
    {
        $permissions = PharmacyRole::TITULAIRE->permissions();
        $this->assertContains('team.manage', $permissions);
        $this->assertContains('team.invite', $permissions);
        $this->assertContains('pharmacy.edit', $permissions);
        $this->assertContains('orders.manage', $permissions);
        $this->assertContains('inventory.manage', $permissions);
        $this->assertContains('reports.view', $permissions);
        $this->assertContains('finances.view', $permissions);
        $this->assertContains('prescriptions.manage', $permissions);
    }

    public function test_adjoint_has_most_permissions_except_team_manage(): void
    {
        $permissions = PharmacyRole::ADJOINT->permissions();
        $this->assertContains('team.invite', $permissions);
        $this->assertNotContains('team.manage', $permissions);
        $this->assertNotContains('pharmacy.edit', $permissions);
        $this->assertContains('orders.manage', $permissions);
    }

    public function test_preparateur_has_limited_permissions(): void
    {
        $permissions = PharmacyRole::PREPARATEUR->permissions();
        $this->assertContains('orders.manage', $permissions);
        $this->assertContains('inventory.manage', $permissions);
        $this->assertContains('prescriptions.view', $permissions);
        $this->assertNotContains('team.manage', $permissions);
        $this->assertNotContains('finances.view', $permissions);
    }

    public function test_stagiaire_has_view_only_permissions(): void
    {
        $permissions = PharmacyRole::STAGIAIRE->permissions();
        $this->assertContains('orders.view', $permissions);
        $this->assertContains('inventory.view', $permissions);
        $this->assertContains('prescriptions.view', $permissions);
        $this->assertNotContains('orders.manage', $permissions);
        $this->assertNotContains('team.manage', $permissions);
    }

    public function test_can_manage_team(): void
    {
        $this->assertTrue(PharmacyRole::TITULAIRE->canManageTeam());
        $this->assertFalse(PharmacyRole::ADJOINT->canManageTeam());
        $this->assertFalse(PharmacyRole::PREPARATEUR->canManageTeam());
        $this->assertFalse(PharmacyRole::STAGIAIRE->canManageTeam());
    }

    public function test_can_invite(): void
    {
        $this->assertTrue(PharmacyRole::TITULAIRE->canInvite());
        $this->assertTrue(PharmacyRole::ADJOINT->canInvite());
        $this->assertFalse(PharmacyRole::PREPARATEUR->canInvite());
        $this->assertFalse(PharmacyRole::STAGIAIRE->canInvite());
    }

    public function test_can_edit_pharmacy(): void
    {
        $this->assertTrue(PharmacyRole::TITULAIRE->canEditPharmacy());
        $this->assertFalse(PharmacyRole::ADJOINT->canEditPharmacy());
        $this->assertFalse(PharmacyRole::PREPARATEUR->canEditPharmacy());
        $this->assertFalse(PharmacyRole::STAGIAIRE->canEditPharmacy());
    }

    public function test_cases_count(): void
    {
        $this->assertCount(4, PharmacyRole::cases());
    }
}
