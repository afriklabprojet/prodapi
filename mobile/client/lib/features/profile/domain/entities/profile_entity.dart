import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String? defaultAddress;
  final DateTime createdAt;
  final int totalOrders;
  final int completedOrders;
  final double totalSpent;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.defaultAddress,
    required this.createdAt,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.totalSpent = 0.0,
  });

  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;
  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasDefaultAddress =>
      defaultAddress != null && defaultAddress!.isNotEmpty;

  // Helper pour obtenir les initiales pour l'avatar
  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  ProfileEntity copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    bool clearPhone = false,
    String? avatar,
    bool clearAvatar = false,
    String? defaultAddress,
    bool clearDefaultAddress = false,
    DateTime? createdAt,
    int? totalOrders,
    int? completedOrders,
    double? totalSpent,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: clearPhone ? null : (phone ?? this.phone),
      avatar: clearAvatar ? null : (avatar ?? this.avatar),
      defaultAddress: clearDefaultAddress ? null : (defaultAddress ?? this.defaultAddress),
      createdAt: createdAt ?? this.createdAt,
      totalOrders: totalOrders ?? this.totalOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        avatar,
        defaultAddress,
        createdAt,
        totalOrders,
        completedOrders,
        totalSpent,
      ];
}
