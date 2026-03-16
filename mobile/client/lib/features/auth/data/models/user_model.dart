import 'package:json_annotation/json_annotation.dart';
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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      phone: phone,
      address: address, // Mapping correct: address → address
      profilePicture: avatar,
      emailVerifiedAt: emailVerifiedAt != null
          ? DateTime.tryParse(emailVerifiedAt!)
          : null,
      phoneVerifiedAt: phoneVerifiedAt != null
          ? DateTime.tryParse(phoneVerifiedAt!)
          : null,
      createdAt: createdAt != null
          ? (DateTime.tryParse(createdAt!) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
