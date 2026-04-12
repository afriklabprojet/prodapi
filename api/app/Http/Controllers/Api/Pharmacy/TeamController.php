<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Enums\PharmacyRole;
use App\Http\Controllers\Controller;
use App\Models\TeamInvitation;
use App\Models\User;
use App\Notifications\TeamInvitationNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class TeamController extends Controller
{
    /**
     * Liste les membres de l'équipe de la pharmacie
     */
    public function index(Request $request): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();
        
        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Pharmacie non trouvée',
            ], 404);
        }

        $members = $pharmacy->users()
            ->withPivot('role', 'created_at')
            ->get()
            ->map(fn ($user) => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'avatar' => $user->avatar,
                'role' => $user->pivot->role,
                'role_label' => PharmacyRole::tryFrom($user->pivot->role)?->label() ?? $user->pivot->role,
                'joined_at' => $user->pivot->created_at,
                'is_current_user' => $user->id === $request->user()->id,
            ]);

        return response()->json([
            'success' => true,
            'data' => [
                'members' => $members,
                'total' => $members->count(),
            ],
        ]);
    }

    /**
     * Inviter un nouveau membre
     */
    public function invite(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'nullable|email|required_without:phone',
            'phone' => 'nullable|string|required_without:email',
            'role' => ['required', Rule::enum(PharmacyRole::class)],
        ]);

        $pharmacy = $request->user()->pharmacies()->first();
        
        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Pharmacie non trouvée',
            ], 404);
        }

        // Vérifier que l'utilisateur actuel peut inviter
        $currentUserRole = $pharmacy->users()
            ->where('user_id', $request->user()->id)
            ->first()
            ?->pivot->role;
        
        $currentRole = PharmacyRole::tryFrom($currentUserRole);
        if (!$currentRole?->canInvite()) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'avez pas la permission d\'inviter des membres',
            ], 403);
        }

        // Vérifier si l'utilisateur est déjà membre
        $existingUser = User::where('email', $request->email)
            ->orWhere('phone', $request->phone)
            ->first();

        if ($existingUser && $pharmacy->users()->where('user_id', $existingUser->id)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Cet utilisateur fait déjà partie de l\'équipe',
            ], 422);
        }

        // Vérifier s'il n'y a pas déjà une invitation en attente
        $existingInvitation = TeamInvitation::where('pharmacy_id', $pharmacy->id)
            ->where('status', 'pending')
            ->where(function ($q) use ($request) {
                $q->where('email', $request->email)
                  ->orWhere('phone', $request->phone);
            })
            ->where('expires_at', '>', now())
            ->first();

        if ($existingInvitation) {
            return response()->json([
                'success' => false,
                'message' => 'Une invitation est déjà en attente pour cette personne',
            ], 422);
        }

        // Créer l'invitation
        $invitation = TeamInvitation::create([
            'pharmacy_id' => $pharmacy->id,
            'invited_by' => $request->user()->id,
            'email' => $request->email,
            'phone' => $request->phone,
            'role' => $request->role,
            'token' => TeamInvitation::generateToken(),
            'expires_at' => now()->addDays(7),
        ]);

        // Envoyer la notification à l'utilisateur existant
        if ($existingUser) {
            $existingUser->notify(new TeamInvitationNotification($invitation));
        }

        return response()->json([
            'success' => true,
            'message' => 'Invitation envoyée avec succès',
            'data' => [
                'invitation_id' => $invitation->id,
                'token' => $invitation->token,
                'expires_at' => $invitation->expires_at,
            ],
        ]);
    }

    /**
     * Liste les invitations en attente
     */
    public function pendingInvitations(Request $request): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();
        
        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Pharmacie non trouvée',
            ], 404);
        }

        $invitations = TeamInvitation::where('pharmacy_id', $pharmacy->id)
            ->where('status', 'pending')
            ->where('expires_at', '>', now())
            ->with('invitedBy:id,name')
            ->get()
            ->map(fn ($inv) => [
                'id' => $inv->id,
                'email' => $inv->email,
                'phone' => $inv->phone,
                'role' => $inv->role->value,
                'role_label' => $inv->role->label(),
                'invited_by' => $inv->invitedBy->name,
                'created_at' => $inv->created_at,
                'expires_at' => $inv->expires_at,
            ]);

        return response()->json([
            'success' => true,
            'data' => ['invitations' => $invitations],
        ]);
    }

    /**
     * Annuler une invitation
     */
    public function cancelInvitation(Request $request, int $invitationId): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();
        
        $invitation = TeamInvitation::where('id', $invitationId)
            ->where('pharmacy_id', $pharmacy?->id)
            ->where('status', 'pending')
            ->first();

        if (!$invitation) {
            return response()->json([
                'success' => false,
                'message' => 'Invitation non trouvée',
            ], 404);
        }

        $invitation->update(['status' => 'expired']);

        return response()->json([
            'success' => true,
            'message' => 'Invitation annulée',
        ]);
    }

    /**
     * Accepter une invitation (appelé par l'utilisateur invité)
     */
    public function acceptInvitation(Request $request): JsonResponse
    {
        $request->validate([
            'token' => 'required|string',
        ]);

        $invitation = TeamInvitation::where('token', $request->token)
            ->where('status', 'pending')
            ->where('expires_at', '>', now())
            ->first();

        if (!$invitation) {
            return response()->json([
                'success' => false,
                'message' => 'Invitation invalide ou expirée',
            ], 404);
        }

        $user = $request->user();

        // Vérifier que l'invitation correspond à l'utilisateur
        if ($invitation->email && $invitation->email !== $user->email) {
            if ($invitation->phone && $invitation->phone !== $user->phone) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette invitation ne vous est pas destinée',
                ], 403);
            }
        }

        $invitation->accept($user);

        return response()->json([
            'success' => true,
            'message' => 'Vous avez rejoint l\'équipe !',
            'data' => [
                'pharmacy_name' => $invitation->pharmacy->name,
                'role' => $invitation->role->label(),
            ],
        ]);
    }

    /**
     * Modifier le rôle d'un membre
     */
    public function updateRole(Request $request, int $memberId): JsonResponse
    {
        $request->validate([
            'role' => ['required', Rule::enum(PharmacyRole::class)],
        ]);

        $pharmacy = $request->user()->pharmacies()->first();
        
        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Pharmacie non trouvée',
            ], 404);
        }

        // Vérifier permissions
        $currentUserRole = $pharmacy->users()
            ->where('user_id', $request->user()->id)
            ->first()
            ?->pivot->role;
        
        $currentRole = PharmacyRole::tryFrom($currentUserRole);
        if (!$currentRole?->canManageTeam()) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'avez pas la permission de modifier les rôles',
            ], 403);
        }

        // Ne pas permettre de modifier son propre rôle
        if ($memberId === $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez pas modifier votre propre rôle',
            ], 422);
        }

        // Mettre à jour le rôle
        $pharmacy->users()->updateExistingPivot($memberId, [
            'role' => $request->role,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Rôle mis à jour',
        ]);
    }

    /**
     * Retirer un membre de l'équipe
     */
    public function removeMember(Request $request, int $memberId): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();
        
        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Pharmacie non trouvée',
            ], 404);
        }

        // Vérifier permissions
        $currentUserRole = $pharmacy->users()
            ->where('user_id', $request->user()->id)
            ->first()
            ?->pivot->role;
        
        $currentRole = PharmacyRole::tryFrom($currentUserRole);
        if (!$currentRole?->canManageTeam()) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'avez pas la permission de retirer des membres',
            ], 403);
        }

        // Ne pas permettre de se retirer soi-même
        if ($memberId === $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez pas vous retirer de l\'équipe',
            ], 422);
        }

        // Vérifier qu'il reste au moins un titulaire
        $remainingTitulaires = $pharmacy->users()
            ->wherePivot('role', PharmacyRole::TITULAIRE->value)
            ->where('user_id', '!=', $memberId)
            ->count();

        $memberRole = $pharmacy->users()
            ->where('user_id', $memberId)
            ->first()
            ?->pivot->role;

        if ($memberRole === PharmacyRole::TITULAIRE->value && $remainingTitulaires === 0) {
            return response()->json([
                'success' => false,
                'message' => 'La pharmacie doit avoir au moins un titulaire',
            ], 422);
        }

        $pharmacy->users()->detach($memberId);

        return response()->json([
            'success' => true,
            'message' => 'Membre retiré de l\'équipe',
        ]);
    }

    /**
     * Rôles disponibles
     */
    public function availableRoles(): JsonResponse
    {
        $roles = collect(PharmacyRole::cases())->map(fn ($role) => [
            'value' => $role->value,
            'label' => $role->label(),
            'permissions' => $role->permissions(),
        ]);

        return response()->json([
            'success' => true,
            'data' => ['roles' => $roles],
        ]);
    }
}
