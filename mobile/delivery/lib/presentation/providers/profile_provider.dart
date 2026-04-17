import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

final profileProvider = FutureProvider.autoDispose<User>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getProfile();
});
