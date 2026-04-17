import 'package:equatable/equatable.dart';

/// Entité Utilisateur (couche Domain)
class UserEntity extends Equatable {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String? profilePicture;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final DateTime createdAt;
  final int _totalOrders;
  final int _completedOrders;
  final double _totalSpent;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.profilePicture,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    required this.createdAt,
    int totalOrders = 0,
    int completedOrders = 0,
    double totalSpent = 0.0,
  })  : _totalOrders = totalOrders,
        _completedOrders = completedOrders,
        _totalSpent = totalSpent;

  bool get isPhoneVerified => phoneVerifiedAt != null;
  bool get isEmailVerified => emailVerifiedAt != null;
  bool get hasAvatar => profilePicture != null && profilePicture!.isNotEmpty;
  bool get hasAddress => address != null && address!.isNotEmpty;
  bool get hasPhone => phone.isNotEmpty;
  bool get hasDefaultAddress => address != null && address!.isNotEmpty;

  /// Alias for profilePicture used in profile pages
  String? get avatar => profilePicture;

  /// Default address display text
  String? get defaultAddress => address;

  /// Stats populated from API response
  int get totalOrders => _totalOrders;
  int get completedOrders => _completedOrders;
  double get totalSpent => _totalSpent;

  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  UserEntity copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    bool clearAddress = false,
    String? profilePicture,
    bool clearProfilePicture = false,
    DateTime? emailVerifiedAt,
    DateTime? phoneVerifiedAt,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: clearAddress ? null : (address ?? this.address),
      profilePicture: clearProfilePicture ? null : (profilePicture ?? this.profilePicture),
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, name, email, phone, address, profilePicture,
        emailVerifiedAt, phoneVerifiedAt, createdAt,
        _totalOrders, _completedOrders, _totalSpent,
      ];
}
