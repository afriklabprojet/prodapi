import 'package:json_annotation/json_annotation.dart';
import '../../../../core/config/env_config.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final int id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(defaultValue: '')
  final String email;
  @JsonKey(defaultValue: '')
  final String phone;
  final String? role;
  final String? address; // Champ address ajouté
  final String? avatar;
  @JsonKey(name: 'email_verified_at')
  final String? emailVerifiedAt;
  @JsonKey(name: 'phone_verified_at')
  final String? phoneVerifiedAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'total_orders', defaultValue: 0)
  final int totalOrders;
  @JsonKey(name: 'completed_orders', defaultValue: 0)
  final int completedOrders;
  @JsonKey(name: 'total_spent', defaultValue: 0.0)
  final dynamic totalSpent;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role,
    this.address,
    this.avatar,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.createdAt,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.totalSpent = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  String? _buildAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${EnvConfig.apiBaseUrl}$path';
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      phone: phone,
      address: address,
      profilePicture: _buildAvatarUrl(avatar),
      emailVerifiedAt: emailVerifiedAt != null
          ? DateTime.tryParse(emailVerifiedAt!)
          : null,
      phoneVerifiedAt: phoneVerifiedAt != null
          ? DateTime.tryParse(phoneVerifiedAt!)
          : null,
      createdAt: createdAt != null
          ? (DateTime.tryParse(createdAt!) ?? DateTime.now())
          : DateTime.now(),
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      totalSpent: _parseDouble(totalSpent),
    );
  }
}
