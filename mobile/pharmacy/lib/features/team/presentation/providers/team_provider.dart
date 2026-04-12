import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/entities/team_entities.dart';

/// État de la gestion d'équipe
class TeamState {
  final List<TeamMember> members;
  final List<TeamInvitation> pendingInvitations;
  final bool isLoading;
  final String? error;

  const TeamState({
    this.members = const [],
    this.pendingInvitations = const [],
    this.isLoading = false,
    this.error,
  });

  TeamState copyWith({
    List<TeamMember>? members,
    List<TeamInvitation>? pendingInvitations,
    bool? isLoading,
    String? error,
  }) {
    return TeamState(
      members: members ?? this.members,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider pour la gestion d'équipe
class TeamNotifier extends Notifier<TeamState> {

  @override
  TeamState build() => const TeamState();

  /// Charge les membres et invitations
  Future<void> loadTeam() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final api = ref.read(apiClientProvider);
      
      // Charger membres et invitations en parallèle
      final responses = await Future.wait([
        api.get('/pharmacy/team'),
        api.get('/pharmacy/team/invitations'),
      ]);

      final membersData = responses[0].data['data']['members'] as List;
      final invitationsData = responses[1].data['data']['invitations'] as List;

      state = state.copyWith(
        members: membersData.map((m) => TeamMember.fromJson(m)).toList(),
        pendingInvitations: invitationsData.map((i) => TeamInvitation.fromJson(i)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement de l\'équipe',
      );
    }
  }

  /// Inviter un nouveau membre
  Future<bool> inviteMember({
    String? email,
    String? phone,
    required PharmacyRole role,
  }) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/pharmacy/team/invite', data: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'role': role.name,
      });
      
      // Recharger les invitations
      await loadTeam();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'envoi de l\'invitation');
      return false;
    }
  }

  /// Annuler une invitation
  Future<bool> cancelInvitation(int invitationId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/pharmacy/team/invitations/$invitationId');
      
      state = state.copyWith(
        pendingInvitations: state.pendingInvitations
            .where((i) => i.id != invitationId)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'annulation');
      return false;
    }
  }

  /// Modifier le rôle d'un membre
  Future<bool> updateMemberRole(int memberId, PharmacyRole newRole) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/pharmacy/team/members/$memberId/role', data: {
        'role': newRole.name,
      });
      
      state = state.copyWith(
        members: state.members.map((m) {
          if (m.id == memberId) {
            return TeamMember(
              id: m.id,
              name: m.name,
              email: m.email,
              phone: m.phone,
              avatar: m.avatar,
              role: newRole,
              joinedAt: m.joinedAt,
              isCurrentUser: m.isCurrentUser,
            );
          }
          return m;
        }).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la modification du rôle');
      return false;
    }
  }

  /// Retirer un membre
  Future<bool> removeMember(int memberId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/pharmacy/team/members/$memberId');
      
      state = state.copyWith(
        members: state.members.where((m) => m.id != memberId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors du retrait du membre');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final teamProvider = NotifierProvider<TeamNotifier, TeamState>(
  TeamNotifier.new,
);
