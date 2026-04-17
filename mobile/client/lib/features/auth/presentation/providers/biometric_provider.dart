import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/app_logger.dart';

/// État de la biométrie
class BiometricState {
  final bool isAvailable;
  final bool isEnabled;
  final bool hasCredentials;
  final String biometricTypeName;
  final bool isLoading;
  final String? error;

  const BiometricState({
    this.isAvailable = false,
    this.isEnabled = false,
    this.hasCredentials = false,
    this.biometricTypeName = 'Biométrie',
    this.isLoading = false,
    this.error,
  });

  /// Peut utiliser la connexion biométrique
  bool get canUseBiometricLogin => isAvailable && isEnabled && hasCredentials;

  BiometricState copyWith({
    bool? isAvailable,
    bool? isEnabled,
    bool? hasCredentials,
    String? biometricTypeName,
    bool? isLoading,
    String? error,
  }) {
    return BiometricState(
      isAvailable: isAvailable ?? this.isAvailable,
      isEnabled: isEnabled ?? this.isEnabled,
      hasCredentials: hasCredentials ?? this.hasCredentials,
      biometricTypeName: biometricTypeName ?? this.biometricTypeName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour gérer l'état biométrique
class BiometricNotifier extends StateNotifier<BiometricState> {
  BiometricNotifier() : super(const BiometricState()) {
    _init();
  }

  /// Initialiser l'état biométrique
  Future<void> _init() async {
    await refresh();
  }

  /// Rafraîchir l'état biométrique
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isAvailable = await BiometricService.isAvailable();
      final isEnabled = await BiometricService.isBiometricLoginEnabled();
      final hasCredentials = await BiometricService.hasStoredCredentials();
      final typeName = await BiometricService.getBiometricTypeName();

      state = state.copyWith(
        isAvailable: isAvailable,
        isEnabled: isEnabled,
        hasCredentials: hasCredentials,
        biometricTypeName: typeName,
        isLoading: false,
      );

      AppLogger.debug(
        '🔐 Biometric state: available=$isAvailable, enabled=$isEnabled, hasCredentials=$hasCredentials',
      );
    } catch (e) {
      AppLogger.error('Biometric refresh failed', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la vérification biométrique',
      );
    }
  }

  /// Activer la biométrie et sauvegarder les credentials
  Future<bool> enableBiometricLogin({
    required String identifier,
    required String password,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Vérifier que la biométrie est disponible
      final isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        state = state.copyWith(
          isLoading: false,
          error: 'La biométrie n\'est pas disponible sur cet appareil',
        );
        return false;
      }

      // Vérifier que des empreintes/faces sont enregistrées
      final hasEnrolled = await BiometricService.hasEnrolledBiometrics();
      if (!hasEnrolled) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Aucune empreinte ou face enregistrée. Configurez-la dans les paramètres de votre appareil.',
        );
        return false;
      }

      // Demander une authentification pour confirmer
      final authenticated = await BiometricService.authenticate(
        reason:
            'Confirmez votre identité pour activer la connexion biométrique',
      );

      if (!authenticated) {
        state = state.copyWith(
          isLoading: false,
          error: 'Authentification annulée',
        );
        return false;
      }

      // Sauvegarder les credentials
      final saved = await BiometricService.saveCredentials(
        identifier: identifier,
        password: password,
        userId: userId,
      );

      if (!saved) {
        state = state.copyWith(
          isLoading: false,
          error: 'Erreur lors de la sauvegarde des credentials',
        );
        return false;
      }

      await refresh();
      return true;
    } catch (e) {
      AppLogger.error('Enable biometric login failed', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'activation de la biométrie',
      );
      return false;
    }
  }

  /// Désactiver la biométrie
  Future<bool> disableBiometricLogin() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await BiometricService.clearCredentials();
      await refresh();
      return true;
    } catch (e) {
      AppLogger.error('Disable biometric login failed', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la désactivation de la biométrie',
      );
      return false;
    }
  }

  /// Effectuer une connexion biométrique
  Future<({String identifier, String password})?>
  performBiometricLogin() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await BiometricService.performBiometricLogin();
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      AppLogger.error('Biometric login failed', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Échec de l\'authentification biométrique',
      );
      return null;
    }
  }

  /// Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider pour l'état biométrique
final biometricProvider =
    StateNotifierProvider<BiometricNotifier, BiometricState>((ref) {
      return BiometricNotifier();
    });

/// Provider pour vérifier si la biométrie peut être utilisée pour la connexion
final canUseBiometricLoginProvider = Provider<bool>((ref) {
  final state = ref.watch(biometricProvider);
  return state.canUseBiometricLogin;
});

/// Provider pour le nom du type de biométrie
final biometricTypeNameProvider = Provider<String>((ref) {
  final state = ref.watch(biometricProvider);
  return state.biometricTypeName;
});
