/// Rôles disponibles au sein d'une pharmacie
enum PharmacyRole {
  titulaire,
  adjoint,
  preparateur,
  stagiaire;

  String get label {
    switch (this) {
      case PharmacyRole.titulaire:
        return 'Pharmacien Titulaire';
      case PharmacyRole.adjoint:
        return 'Pharmacien Adjoint';
      case PharmacyRole.preparateur:
        return 'Préparateur';
      case PharmacyRole.stagiaire:
        return 'Stagiaire';
    }
  }

  String get description {
    switch (this) {
      case PharmacyRole.titulaire:
        return 'Tous les droits : équipe, pharmacie, finances';
      case PharmacyRole.adjoint:
        return 'Peut inviter, gérer commandes et stock';
      case PharmacyRole.preparateur:
        return 'Gère les commandes et le stock';
      case PharmacyRole.stagiaire:
        return 'Consultation uniquement';
    }
  }

  static PharmacyRole fromString(String value) {
    return PharmacyRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => PharmacyRole.stagiaire,
    );
  }
}

/// Membre d'une équipe de pharmacie
class TeamMember {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final PharmacyRole role;
  final DateTime joinedAt;
  final bool isCurrentUser;

  const TeamMember({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    required this.role,
    required this.joinedAt,
    this.isCurrentUser = false,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      role: PharmacyRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );
  }
}

/// Invitation en attente
class TeamInvitation {
  final int id;
  final String? email;
  final String? phone;
  final PharmacyRole role;
  final String invitedBy;
  final DateTime createdAt;
  final DateTime expiresAt;

  const TeamInvitation({
    required this.id,
    this.email,
    this.phone,
    required this.role,
    required this.invitedBy,
    required this.createdAt,
    required this.expiresAt,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) {
    return TeamInvitation(
      id: json['id'] as int,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: PharmacyRole.fromString(json['role'] as String),
      invitedBy: json['invited_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  String get contact => email ?? phone ?? '?';
  
  bool get isExpired => expiresAt.isBefore(DateTime.now());
}
