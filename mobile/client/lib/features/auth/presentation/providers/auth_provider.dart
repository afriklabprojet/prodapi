import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return AuthNotifier(
    loginUseCase: LoginUseCase(authRepository),
    registerUseCase: RegisterUseCase(authRepository),
    logoutUseCase: LogoutUseCase(authRepository),
    getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
    authRepository: authRepository,
  );
});
