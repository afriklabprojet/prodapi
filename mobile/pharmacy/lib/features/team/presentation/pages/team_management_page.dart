import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/team_entities.dart';
import '../providers/team_provider.dart';

class TeamManagementPage extends ConsumerStatefulWidget {
  const TeamManagementPage({super.key});

  @override
  ConsumerState<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends ConsumerState<TeamManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Charger l'équipe au démarrage
    Future.microtask(() {
      ref.read(teamProvider.notifier).loadTeam();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamProvider);
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Mon Équipe'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(teamProvider.notifier).loadTeam(),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 18),
                  const SizedBox(width: 6),
                  Text('Membres (${state.members.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mail_outline, size: 18),
                  const SizedBox(width: 6),
                  Text('Invitations (${state.pendingInvitations.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: state.isLoading
          ? SkeletonListBuilder.teamMembers()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(state, isDark),
                _buildInvitationsTab(state, isDark),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteSheet(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Inviter'),
      ),
    );
  }

  Widget _buildMembersTab(TeamState state, bool isDark) {
    if (state.members.isEmpty) {
      return AppEmptyState.team(onAdd: () => _showInviteSheet(context));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider.notifier).loadTeam(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final member = state.members[index];
          return _MemberCard(
            member: member,
            isDark: isDark,
            onRoleChange: (newRole) async {
              final success = await ref
                  .read(teamProvider.notifier)
                  .updateMemberRole(member.id, newRole);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rôle mis à jour')),
                );
              }
            },
            onRemove: () => _confirmRemoveMember(context, member),
          );
        },
      ),
    );
  }

  Widget _buildInvitationsTab(TeamState state, bool isDark) {
    if (state.pendingInvitations.isEmpty) {
      return const AppEmptyState(
        icon: Icons.mail_outline,
        title: 'Aucune invitation en attente',
        subtitle: 'Les invitations envoyées apparaîtront ici.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider.notifier).loadTeam(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.pendingInvitations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final invitation = state.pendingInvitations[index];
          return _InvitationCard(
            invitation: invitation,
            isDark: isDark,
            onCancel: () async {
              final success = await ref
                  .read(teamProvider.notifier)
                  .cancelInvitation(invitation.id);
              if (success && mounted) {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invitation annulée')),
                );
              }
            },
          );
        },
      ),
    );
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _InviteSheet(
        onInvite: (email, phone, role) async {
          final success = await ref
              .read(teamProvider.notifier)
              .inviteMember(email: email, phone: phone, role: role);
          if (success && mounted) {
            Navigator.pop(ctx);
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invitation envoyée !')),
            );
          }
        },
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, TeamMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer le membre ?'),
        content: Text('${member.name} ne pourra plus accéder à la pharmacie.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(teamProvider.notifier)
                  .removeMember(member.id);
              if (success && mounted) {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Membre retiré')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }
}

/// Carte d'un membre
class _MemberCard extends StatelessWidget {
  final TeamMember member;
  final bool isDark;
  final Function(PharmacyRole) onRoleChange;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.member,
    required this.isDark,
    required this.onRoleChange,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final roleLabel = _roleLabel(member.role);

    return Semantics(
      label:
          '${member.name}, rôle $roleLabel${member.isCurrentUser ? ", c\'est vous" : ""}',
      hint: 'Membre de l\'équipe',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: member.isCurrentUser
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar avec cache
                CachedAvatar(
                  imageUrl: member.avatar,
                  radius: 24,
                  fallbackText: member.name.isNotEmpty
                      ? member.name[0].toUpperCase()
                      : '?',
                  backgroundColor: _roleColor(
                    member.role,
                  ).withValues(alpha: 0.15),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.name,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (member.isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Vous',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.email ?? member.phone ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Role badge
                _RoleBadge(role: member.role),
              ],
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                Text(
                  'Depuis ${DateFormat('MMM yyyy', 'fr_FR').format(member.joinedAt)}',
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                ),
                const Spacer(),
                if (!member.isCurrentUser) ...[
                  // Dropdown pour changer le rôle
                  PopupMenuButton<PharmacyRole>(
                    initialValue: member.role,
                    onSelected: onRoleChange,
                    itemBuilder: (ctx) => PharmacyRole.values
                        .map(
                          (r) => PopupMenuItem(
                            value: r,
                            child: Row(
                              children: [
                                Icon(
                                  _roleIcon(r),
                                  size: 18,
                                  color: _roleColor(r),
                                ),
                                const SizedBox(width: 8),
                                Text(r.label),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Rôle', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red.shade400,
                    tooltip: 'Retirer',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge de rôle
class _RoleBadge extends StatelessWidget {
  final PharmacyRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _roleColor(role).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_roleIcon(role), size: 14, color: _roleColor(role)),
          const SizedBox(width: 4),
          Text(
            role.label,
            style: TextStyle(
              color: _roleColor(role),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'invitation
class _InvitationCard extends StatelessWidget {
  final TeamInvitation invitation;
  final bool isDark;
  final VoidCallback onCancel;

  const _InvitationCard({
    required this.invitation,
    required this.isDark,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
      ),
      child: Row(
        children: [
          // Icon
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.amber.shade100,
            child: Icon(Icons.mail_outline, color: Colors.amber.shade700),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.contact,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _RoleBadge(role: invitation.role),
                    const SizedBox(width: 8),
                    Text(
                      '• Par ${invitation.invitedBy}',
                      style: AppTextStyles.caption.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Expire ${DateFormat('dd MMM', 'fr_FR').format(invitation.expiresAt)}',
                  style: AppTextStyles.caption.copyWith(
                    color: invitation.isExpired ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Cancel button
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            color: Colors.grey,
            tooltip: 'Annuler l\'invitation',
          ),
        ],
      ),
    );
  }
}

/// Sheet pour inviter un membre
class _InviteSheet extends StatefulWidget {
  final Future<void> Function(String? email, String? phone, PharmacyRole role)
  onInvite;

  const _InviteSheet({required this.onInvite});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  PharmacyRole _selectedRole = PharmacyRole.preparateur;
  bool _useEmail = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await widget.onInvite(
      _useEmail ? _emailController.text.trim() : null,
      !_useEmail ? _phoneController.text.trim() : null,
      _selectedRole,
    );

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Inviter un membre',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Toggle Email/Phone
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Email')),
                  ButtonSegment(value: false, label: Text('Téléphone')),
                ],
                selected: {_useEmail},
                onSelectionChanged: (v) => setState(() => _useEmail = v.first),
              ),
              const SizedBox(height: 16),

              // Email or Phone input
              if (_useEmail)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                )
              else
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+225 07 XX XX XX XX',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v.length < 8) return 'Numéro trop court';
                    return null;
                  },
                ),
              const SizedBox(height: 20),

              // Role selection
              Text('Rôle', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              // ignore: deprecated_member_use - RadioGroup migration pending Flutter stable
              ...PharmacyRole.values.map(
                (role) => RadioListTile<PharmacyRole>(
                  value: role,
                  // ignore: deprecated_member_use
                  groupValue: _selectedRole,
                  // ignore: deprecated_member_use
                  onChanged: (r) => setState(() => _selectedRole = r!),
                  title: Row(
                    children: [
                      Icon(_roleIcon(role), color: _roleColor(role), size: 20),
                      const SizedBox(width: 8),
                      Text(role.label),
                    ],
                  ),
                  subtitle: Text(
                    role.description,
                    style: const TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),

              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Envoyer l\'invitation',
                icon: Icons.send,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helpers
Color _roleColor(PharmacyRole role) {
  switch (role) {
    case PharmacyRole.titulaire:
      return Colors.purple;
    case PharmacyRole.adjoint:
      return Colors.blue;
    case PharmacyRole.preparateur:
      return Colors.teal;
    case PharmacyRole.stagiaire:
      return Colors.grey;
  }
}

String _roleLabel(PharmacyRole role) {
  switch (role) {
    case PharmacyRole.titulaire:
      return 'Titulaire';
    case PharmacyRole.adjoint:
      return 'Adjoint';
    case PharmacyRole.preparateur:
      return 'Préparateur';
    case PharmacyRole.stagiaire:
      return 'Stagiaire';
  }
}

IconData _roleIcon(PharmacyRole role) {
  switch (role) {
    case PharmacyRole.titulaire:
      return Icons.shield;
    case PharmacyRole.adjoint:
      return Icons.verified_user_outlined;
    case PharmacyRole.preparateur:
      return Icons.medical_services_outlined;
    case PharmacyRole.stagiaire:
      return Icons.school_outlined;
  }
}
