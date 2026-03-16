import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class AuthResponseEntity extends Equatable {
  final UserEntity user;
  final String token;
  final String? firebaseToken;

  const AuthResponseEntity({
    required this.user,
    required this.token,
    this.firebaseToken,
  });

  @override
  List<Object?> get props => [user, token, firebaseToken];
}
