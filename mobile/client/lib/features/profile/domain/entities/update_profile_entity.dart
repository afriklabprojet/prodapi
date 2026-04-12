import 'package:equatable/equatable.dart';

/// Entité pour la mise à jour du profil
class UpdateProfileEntity extends Equatable {
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? currentPassword;
  final String? newPassword;
  final String? newPasswordConfirmation;

  const UpdateProfileEntity({
    this.name,
    this.email,
    this.phone,
    this.address,
    this.currentPassword,
    this.newPassword,
    this.newPasswordConfirmation,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (email != null) map['email'] = email;
    if (phone != null) map['phone'] = phone;
    if (address != null) map['address'] = address;
    if (currentPassword != null) map['current_password'] = currentPassword;
    if (newPassword != null) map['new_password'] = newPassword;
    if (newPasswordConfirmation != null) {
      map['new_password_confirmation'] = newPasswordConfirmation;
    }
    return map;
  }

  bool get hasPasswordChange =>
      currentPassword != null &&
      currentPassword!.isNotEmpty &&
      newPassword != null &&
      newPassword!.isNotEmpty;

  @override
  List<Object?> get props => [
    name,
    email,
    phone,
    address,
    currentPassword,
    newPassword,
  ];
}
