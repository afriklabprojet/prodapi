import 'user_entity.dart';

/// Entité représentant la réponse d'authentification.
class AuthResponseEntity {
  final UserEntity user;
  final String token;

  const AuthResponseEntity({
    required this.user,
    required this.token,
  });
}
