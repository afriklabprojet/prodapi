import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';
import '../../domain/entities/auth_response_entity.dart';

part 'auth_response_model.g.dart';

@JsonSerializable()
class AuthResponseModel {
  final UserModel user;
  final String token;
  @JsonKey(name: 'firebase_token')
  final String? firebaseToken;

  AuthResponseModel({
    required this.user,
    required this.token,
    this.firebaseToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);

  AuthResponseEntity toEntity() {
    return AuthResponseEntity(
      user: user.toEntity(),
      token: token,
      firebaseToken: firebaseToken,
    );
  }
}
