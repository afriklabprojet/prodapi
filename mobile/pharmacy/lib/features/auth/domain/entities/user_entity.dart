import 'pharmacy_entity.dart';

/// Entité utilisateur de la couche domaine.
class UserEntity {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? role;
  final String? avatar;
  final List<PharmacyEntity> pharmacies;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role,
    this.avatar,
    this.pharmacies = const [],
  });

  /// Raccourci pour obtenir la première pharmacie (ou null).
  PharmacyEntity? get pharmacy => pharmacies.isNotEmpty ? pharmacies.first : null;

  UserEntity copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? avatar,
    List<PharmacyEntity>? pharmacies,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      pharmacies: pharmacies ?? this.pharmacies,
    );
  }
}
