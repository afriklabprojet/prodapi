import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/secure_token_service.dart';
import 'profile_provider.dart';

/// Provider qui vérifie si l'utilisateur a un token d'authentification valide.
/// Utilise FutureProvider car hasToken() est asynchrone.
final authStateProvider = FutureProvider<bool>((ref) async {
  return SecureTokenService.instance.hasToken();
});

/// État global de l'application.
///
/// Ce provider combine les différents états globaux pour faciliter
/// l'accès et la réactivité dans les widgets.
///
/// Usage:
/// ```dart
/// final appState = ref.watch(appStateProvider);
/// if (appState.isReady) {
///   // App is fully initialized
/// }
/// ```
@immutable
class AppState {
  final bool isAuthenticated;
  final bool isOnline;
  final bool isLoading;
  final String? error;

  const AppState({
    this.isAuthenticated = false,
    this.isOnline = true,
    this.isLoading = false,
    this.error,
  });

  /// L'app est prête (authentifiée et connectée)
  bool get isReady => isAuthenticated && isOnline && !isLoading;

  /// L'app peut effectuer des opérations réseau
  bool get canMakeRequests => isAuthenticated && isOnline;

  AppState copyWith({
    bool? isAuthenticated,
    bool? isOnline,
    bool? isLoading,
    String? error,
  }) {
    return AppState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          isAuthenticated == other.isAuthenticated &&
          isOnline == other.isOnline &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode =>
      isAuthenticated.hashCode ^
      isOnline.hashCode ^
      isLoading.hashCode ^
      error.hashCode;

  @override
  String toString() =>
      'AppState(auth: $isAuthenticated, online: $isOnline, loading: $isLoading, error: $error)';
}

/// Provider d'état global de l'application.
///
/// Combine automatiquement l'état d'authentification et de connectivité.
final appStateProvider = Provider<AppState>((ref) {
  // Observer l'état d'authentification
  final authState = ref.watch(authStateProvider);
  final isAuthenticated = authState.maybeWhen(
    data: (hasToken) => hasToken,
    orElse: () => false,
  );

  // Observer l'état de connectivité
  final connectivity = ref.watch(connectivityProvider);
  final isOnline = connectivity.isOnline;

  // Observer le profil pour détecter les erreurs
  final profile = ref.watch(profileProvider);
  final isLoading = profile.isLoading;
  final error = profile.whenOrNull(error: (e, _) => e.toString());

  return AppState(
    isAuthenticated: isAuthenticated,
    isOnline: isOnline,
    isLoading: isLoading,
    error: error,
  );
});

/// Provider simplifié pour vérifier si l'utilisateur est authentifié
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isAuthenticated;
});

/// Provider simplifié pour vérifier si l'app est en ligne
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isOnline;
});

/// Provider simplifié pour vérifier si l'app est prête
final isAppReadyProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isReady;
});
