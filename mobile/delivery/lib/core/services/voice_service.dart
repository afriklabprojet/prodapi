import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Type d'annonce vocale
enum VoiceAnnouncementType {
  newDelivery,
  deliveryAccepted,
  navigationStart,
  navigationTurn,
  navigationArrival,
  deliveryCompleted,
  earnings,
  warning,
  reminder,
  custom,
}

/// Commande vocale reconnue
enum VoiceCommand {
  acceptDelivery,
  declineDelivery,
  startNavigation,
  callCustomer,
  callPharmacy,
  markDelivered,
  goOnline,
  goOffline,
  readStats,
  unknown,
}

/// Configuration vocale
class VoiceSettings {
  final bool ttsEnabled;
  final bool sttEnabled;
  final double speechRate;
  final double pitch;
  final double volume;
  final String language;
  final bool announceNewDeliveries;
  final bool announceNavigation;
  final bool announceEarnings;
  final bool voiceCommands;

  const VoiceSettings({
    this.ttsEnabled = true,
    this.sttEnabled = true,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.language = 'fr-FR',
    this.announceNewDeliveries = true,
    this.announceNavigation = true,
    this.announceEarnings = true,
    this.voiceCommands = true,
  });

  VoiceSettings copyWith({
    bool? ttsEnabled,
    bool? sttEnabled,
    double? speechRate,
    double? pitch,
    double? volume,
    String? language,
    bool? announceNewDeliveries,
    bool? announceNavigation,
    bool? announceEarnings,
    bool? voiceCommands,
  }) {
    return VoiceSettings(
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      sttEnabled: sttEnabled ?? this.sttEnabled,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      language: language ?? this.language,
      announceNewDeliveries:
          announceNewDeliveries ?? this.announceNewDeliveries,
      announceNavigation: announceNavigation ?? this.announceNavigation,
      announceEarnings: announceEarnings ?? this.announceEarnings,
      voiceCommands: voiceCommands ?? this.voiceCommands,
    );
  }
}

/// Messages d'annonce prédéfinis
class VoiceMessages {
  // Livraisons
  static String newDelivery(String pharmacyName, String amount) =>
      'Nouvelle livraison disponible. $pharmacyName. Commission: $amount francs.';

  static String deliveryAccepted(String pharmacyName) =>
      'Livraison acceptée. Dirigez-vous vers $pharmacyName.';

  static String deliveryCompleted(String amount) =>
      'Livraison terminée. Vous avez gagné $amount francs.';

  // Navigation
  static String navigationStart(String destination, String duration) =>
      'Démarrage de la navigation vers $destination. Durée estimée: $duration.';

  static String turnLeft(String street) =>
      'Dans 100 mètres, tournez à gauche sur $street.';

  static String turnRight(String street) =>
      'Dans 100 mètres, tournez à droite sur $street.';

  static String goStraight(String distance) =>
      'Continuez tout droit sur $distance.';

  static String arrival() => 'Vous êtes arrivé à destination.';

  static String rerouting() => 'Recalcul de l\'itinéraire.';

  // Gains
  static String dailyEarnings(String amount) =>
      'Gains du jour: $amount francs.';

  static String weeklyEarnings(String amount) =>
      'Gains de la semaine: $amount francs.';

  // Alertes
  static String batteryLow(int percent) =>
      'Attention, batterie faible. $percent pour cent restants.';

  static String connectionLost() =>
      'Attention, connexion internet perdue. Mode hors-ligne activé.';

  static String connectionRestored() => 'Connexion internet restaurée.';
}

/// État du service vocal
class VoiceServiceState {
  final VoiceSettings settings;
  final bool isSpeaking;
  final bool isListening;
  final String? lastSpokenText;
  final String? lastRecognizedText;
  final VoiceCommand? lastCommand;
  final bool ttsAvailable;
  final bool sttAvailable;
  final List<String> availableLanguages;

  const VoiceServiceState({
    this.settings = const VoiceSettings(),
    this.isSpeaking = false,
    this.isListening = false,
    this.lastSpokenText,
    this.lastRecognizedText,
    this.lastCommand,
    this.ttsAvailable = false,
    this.sttAvailable = false,
    this.availableLanguages = const [],
  });

  VoiceServiceState copyWith({
    VoiceSettings? settings,
    bool? isSpeaking,
    bool? isListening,
    String? lastSpokenText,
    String? lastRecognizedText,
    VoiceCommand? lastCommand,
    bool? ttsAvailable,
    bool? sttAvailable,
    List<String>? availableLanguages,
  }) {
    return VoiceServiceState(
      settings: settings ?? this.settings,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isListening: isListening ?? this.isListening,
      lastSpokenText: lastSpokenText ?? this.lastSpokenText,
      lastRecognizedText: lastRecognizedText ?? this.lastRecognizedText,
      lastCommand: lastCommand ?? this.lastCommand,
      ttsAvailable: ttsAvailable ?? this.ttsAvailable,
      sttAvailable: sttAvailable ?? this.sttAvailable,
      availableLanguages: availableLanguages ?? this.availableLanguages,
    );
  }
}

/// Service vocal (TTS + STT)
class VoiceService extends StateNotifier<VoiceServiceState> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  Function(VoiceCommand)? onCommandRecognized;

  VoiceService() : super(const VoiceServiceState()) {
    _init();
  }

  Future<void> _init() async {
    await _initTts();
    await _initStt();
  }

  Future<void> _initTts() async {
    try {
      // Configurer TTS
      await _tts.setLanguage(state.settings.language);
      await _tts.setSpeechRate(state.settings.speechRate);
      await _tts.setPitch(state.settings.pitch);
      await _tts.setVolume(state.settings.volume);

      // Callbacks
      _tts.setStartHandler(() {
        state = state.copyWith(isSpeaking: true);
      });

      _tts.setCompletionHandler(() {
        state = state.copyWith(isSpeaking: false);
      });

      _tts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        state = state.copyWith(isSpeaking: false);
      });

      // Obtenir les langues disponibles
      final languages = await _tts.getLanguages;
      final languageList = (languages as List)
          .map((l) => l.toString())
          .toList();

      state = state.copyWith(
        ttsAvailable: true,
        availableLanguages: languageList,
      );
    } catch (e) {
      debugPrint('TTS init error: $e');
      state = state.copyWith(ttsAvailable: false);
    }
  }

  Future<void> _initStt() async {
    try {
      final available = await _stt.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          state = state.copyWith(isListening: status == 'listening');
        },
        onError: (error) {
          debugPrint('STT Error: $error');
          state = state.copyWith(isListening: false);
        },
      );

      state = state.copyWith(sttAvailable: available);
    } catch (e) {
      debugPrint('STT init error: $e');
      state = state.copyWith(sttAvailable: false);
    }
  }

  /// Mettre à jour les paramètres
  Future<void> updateSettings(VoiceSettings settings) async {
    await _tts.setLanguage(settings.language);
    await _tts.setSpeechRate(settings.speechRate);
    await _tts.setPitch(settings.pitch);
    await _tts.setVolume(settings.volume);

    state = state.copyWith(settings: settings);
  }

  /// Parler (TTS)
  Future<void> speak(String text, {VoiceAnnouncementType? type}) async {
    if (!state.settings.ttsEnabled || !state.ttsAvailable) return;

    // Vérifier les préférences par type
    if (type != null) {
      switch (type) {
        case VoiceAnnouncementType.newDelivery:
          if (!state.settings.announceNewDeliveries) return;
          break;
        case VoiceAnnouncementType.navigationStart:
        case VoiceAnnouncementType.navigationTurn:
        case VoiceAnnouncementType.navigationArrival:
          if (!state.settings.announceNavigation) return;
          break;
        case VoiceAnnouncementType.earnings:
          if (!state.settings.announceEarnings) return;
          break;
        default:
          break;
      }
    }

    // Arrêter si déjà en train de parler
    if (state.isSpeaking) {
      await _tts.stop();
    }

    state = state.copyWith(lastSpokenText: text);
    await _tts.speak(text);
  }

  /// Arrêter de parler
  Future<void> stop() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  /// Annoncer une nouvelle livraison
  Future<void> announceNewDelivery({
    required String pharmacyName,
    required String amount,
  }) async {
    await speak(
      VoiceMessages.newDelivery(pharmacyName, amount),
      type: VoiceAnnouncementType.newDelivery,
    );
  }

  /// Annoncer le démarrage de navigation
  Future<void> announceNavigationStart({
    required String destination,
    required String duration,
  }) async {
    await speak(
      VoiceMessages.navigationStart(destination, duration),
      type: VoiceAnnouncementType.navigationStart,
    );
  }

  /// Annoncer un virage
  Future<void> announceTurn({
    required bool isLeft,
    required String streetName,
  }) async {
    final message = isLeft
        ? VoiceMessages.turnLeft(streetName)
        : VoiceMessages.turnRight(streetName);

    await speak(message, type: VoiceAnnouncementType.navigationTurn);
  }

  /// Annoncer l'arrivée
  Future<void> announceArrival() async {
    await speak(
      VoiceMessages.arrival(),
      type: VoiceAnnouncementType.navigationArrival,
    );
  }

  /// Annoncer livraison terminée
  Future<void> announceDeliveryCompleted(String amount) async {
    await speak(
      VoiceMessages.deliveryCompleted(amount),
      type: VoiceAnnouncementType.deliveryCompleted,
    );
  }

  /// Annoncer les gains
  Future<void> announceEarnings({
    required String amount,
    bool weekly = false,
  }) async {
    final message = weekly
        ? VoiceMessages.weeklyEarnings(amount)
        : VoiceMessages.dailyEarnings(amount);

    await speak(message, type: VoiceAnnouncementType.earnings);
  }

  /// Annoncer batterie faible
  Future<void> announceLowBattery(int percent) async {
    await speak(
      VoiceMessages.batteryLow(percent),
      type: VoiceAnnouncementType.warning,
    );
  }

  /// Démarrer l'écoute (STT)
  Future<void> startListening() async {
    if (!state.settings.sttEnabled ||
        !state.settings.voiceCommands ||
        !state.sttAvailable) {
      return;
    }

    if (state.isListening) return;

    // Arrêter TTS si en cours
    if (state.isSpeaking) {
      await stop();
    }

    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          _processRecognizedText(result.recognizedWords);
        }
      },
      localeId: state.settings.language,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
      ),
    );

    state = state.copyWith(isListening: true);
  }

  /// Arrêter l'écoute
  Future<void> stopListening() async {
    await _stt.stop();
    state = state.copyWith(isListening: false);
  }

  /// Traiter le texte reconnu
  void _processRecognizedText(String text) {
    state = state.copyWith(lastRecognizedText: text);

    final command = _parseCommand(text.toLowerCase());
    state = state.copyWith(lastCommand: command);

    if (command != VoiceCommand.unknown) {
      onCommandRecognized?.call(command);
      _confirmCommand(command);
    }
  }

  /// Parser la commande
  VoiceCommand _parseCommand(String text) {
    // Accepter
    if (_matches(text, ['accepter', 'accepte', 'oui', 'ok', 'prendre'])) {
      return VoiceCommand.acceptDelivery;
    }

    // Refuser
    if (_matches(text, ['refuser', 'non', 'refuse', 'annuler', 'passer'])) {
      return VoiceCommand.declineDelivery;
    }

    // Navigation
    if (_matches(text, [
      'navigation',
      'naviguer',
      'aller',
      'itinéraire',
      'route',
    ])) {
      return VoiceCommand.startNavigation;
    }

    // Appeler client
    if (_matches(text, [
      'appeler client',
      'appelle client',
      'téléphone client',
    ])) {
      return VoiceCommand.callCustomer;
    }

    // Appeler pharmacie
    if (_matches(text, [
      'appeler pharmacie',
      'appelle pharmacie',
      'téléphone pharmacie',
    ])) {
      return VoiceCommand.callPharmacy;
    }

    // Marquer livré
    if (_matches(text, ['livré', 'terminé', 'fini', 'déposé', 'remis'])) {
      return VoiceCommand.markDelivered;
    }

    // Hors ligne
    // Important: vérifier AVANT "en ligne" car "déconnecter" contient
    // le mot "connecter" et "désactiver" contient "activer".
    if (_matches(text, ['hors ligne', 'déconnecter', 'pause', 'désactiver'])) {
      return VoiceCommand.goOffline;
    }

    // En ligne
    if (_matches(text, ['en ligne', 'connecter', 'disponible', 'activer'])) {
      return VoiceCommand.goOnline;
    }

    // Statistiques
    if (_matches(text, [
      'statistiques',
      'gains',
      'combien',
      'résumé',
      'bilan',
    ])) {
      return VoiceCommand.readStats;
    }

    return VoiceCommand.unknown;
  }

  bool _matches(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }

  /// Confirmer la commande
  Future<void> _confirmCommand(VoiceCommand command) async {
    String confirmation;

    switch (command) {
      case VoiceCommand.acceptDelivery:
        confirmation = 'Livraison acceptée.';
        break;
      case VoiceCommand.declineDelivery:
        confirmation = 'Livraison refusée.';
        break;
      case VoiceCommand.startNavigation:
        confirmation = 'Démarrage de la navigation.';
        break;
      case VoiceCommand.callCustomer:
        confirmation = 'Appel du client.';
        break;
      case VoiceCommand.callPharmacy:
        confirmation = 'Appel de la pharmacie.';
        break;
      case VoiceCommand.markDelivered:
        confirmation = 'Livraison marquée comme terminée.';
        break;
      case VoiceCommand.goOnline:
        confirmation = 'Vous êtes maintenant en ligne.';
        break;
      case VoiceCommand.goOffline:
        confirmation = 'Vous êtes maintenant hors ligne.';
        break;
      case VoiceCommand.readStats:
        // Sera géré par l'appelant
        return;
      default:
        return;
    }

    await speak(confirmation);
  }

  /// Lire les statistiques à voix haute
  Future<void> readStats({
    required int deliveriesToday,
    required String earningsToday,
    required double rating,
  }) async {
    final message =
        'Aujourd\'hui: $deliveriesToday livraisons, '
        '$earningsToday francs gagnés. '
        'Note moyenne: ${rating.toStringAsFixed(1)} étoiles.';

    await speak(message);
  }

  /// Navigation guidée par la voix
  Future<void> handleNavigationInstruction({
    required String instruction,
    required String distance,
  }) async {
    if (!state.settings.announceNavigation) return;

    // Simplifier l'instruction pour TTS sans corrompre "km" en "k mètres".
    final simplified = instruction
        .replaceAllMapped(
          RegExp(r'(\d+(?:[.,]\d+)?)\s*km\b', caseSensitive: false),
          (match) => '${match.group(1)} kilomètres',
        )
        .replaceAllMapped(
          RegExp(r'(\d+(?:[.,]\d+)?)\s*m\b', caseSensitive: false),
          (match) => '${match.group(1)} mètres',
        );

    await speak(simplified, type: VoiceAnnouncementType.navigationTurn);
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    super.dispose();
  }
}

/// Provider pour le service
final voiceServiceProvider =
    StateNotifierProvider<VoiceService, VoiceServiceState>((ref) {
      return VoiceService();
    });

/// Provider pour les paramètres vocaux
final voiceSettingsProvider = Provider<VoiceSettings>((ref) {
  return ref.watch(voiceServiceProvider).settings;
});

/// Provider: est-ce que TTS est disponible
final ttsAvailableProvider = Provider<bool>((ref) {
  return ref.watch(voiceServiceProvider).ttsAvailable;
});

/// Provider: est-ce que STT est disponible
final sttAvailableProvider = Provider<bool>((ref) {
  return ref.watch(voiceServiceProvider).sttAvailable;
});

/// Provider: est en train de parler
final isSpeakingProvider = Provider<bool>((ref) {
  return ref.watch(voiceServiceProvider).isSpeaking;
});

/// Provider: est en train d'écouter
final isListeningProvider = Provider<bool>((ref) {
  return ref.watch(voiceServiceProvider).isListening;
});
