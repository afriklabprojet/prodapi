import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/profile_entity.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class ProfileModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  @JsonKey(name: 'default_address')
  final String? defaultAddress;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'total_orders')
  final int? totalOrders;
  @JsonKey(name: 'completed_orders')
  final int? completedOrders;
  @JsonKey(name: 'total_spent')
  final dynamic totalSpent;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.defaultAddress,
    required this.createdAt,
    this.totalOrders,
    this.completedOrders,
    this.totalSpent,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      name: name,
      email: email,
      phone: phone,
      avatar: avatar,
      defaultAddress: defaultAddress,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      totalOrders: totalOrders ?? 0,
      completedOrders: completedOrders ?? 0,
      totalSpent: _parseDouble(totalSpent),
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory ProfileModel.fromEntity(ProfileEntity entity) {
    return ProfileModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      avatar: entity.avatar,
      defaultAddress: entity.defaultAddress,
      createdAt: entity.createdAt.toIso8601String(),
      totalOrders: entity.totalOrders,
      completedOrders: entity.completedOrders,
      totalSpent: entity.totalSpent,
    );
  }
}
