import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Service de recherche vocale pour l'application
/// Note: Sur le Web, la reconnaissance vocale nécessite une implémentation spécifique
class VoiceSearchService {
  static final VoiceSearchService _instance = VoiceSearchService._internal();
  factory VoiceSearchService() => _instance;
  VoiceSearchService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  String _currentLocale = 'fr_FR';
  
  // Callbacks
  Function(String)? onResult;
  Function(String)? onPartialResult;
  Function()? onListeningStarted;
  Function()? onListeningStopped;
  Function(String)? onError;

  /// Vérifie si le service est disponible
  bool get isAvailable => _isInitialized;
  
  /// Vérifie si le service écoute actuellement
  bool get isListening => _isListening;
  
  /// Derniers mots reconnus
  String get lastWords => _lastWords;
  
  /// Vérifie si on est sur le web
  bool get _isWeb => kIsWeb;

  /// Initialise le service de reconnaissance vocale
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    // Sur le Web, speech_to_text ne fonctionne pas directement
    if (_isWeb) {
      if (kDebugMode) debugPrint('🎤 [VoiceSearch] Mode Web - reconnaissance vocale limitée');
      // On retourne false pour le web car le plugin ne supporte pas bien le web
      // L'utilisateur peut utiliser la saisie manuelle à la place
      _isInitialized = false;
      return false;
    }
    
    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: _onStatus,
        onError: _onSpeechError,
        debugLogging: kDebugMode,
      );
      
      if (_isInitialized) {
        // Chercher la locale française
        final locales = await _speechToText.locales();
        LocaleName? selectedLocale;
        
        // Essayer de trouver une locale française
        for (final locale in locales) {
          if (locale.localeId.startsWith('fr')) {
            selectedLocale = locale;
            break;
          }
        }
        
        // Sinon prendre la première disponible ou défaut
        selectedLocale ??= locales.isNotEmpty ? locales.first : null;
        _currentLocale = selectedLocale?.localeId ?? 'fr_FR';
        
        if (kDebugMode) debugPrint('🎤 [VoiceSearch] Initialisé avec locale: $_currentLocale');
      }
      
      return _isInitialized;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [VoiceSearch] Erreur d\'initialisation: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Démarre l'écoute vocale
  Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onPartialResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Service vocal non disponible');
        return;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    this.onResult = onResult;
    this.onPartialResult = onPartialResult;
    _lastWords = '';

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: _currentLocale,
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.search,
        ),
      );
      _isListening = true;
      onListeningStarted?.call();
      if (kDebugMode) debugPrint('🎤 [VoiceSearch] Écoute démarrée');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [VoiceSearch] Erreur démarrage: $e');
      onError?.call('Impossible de démarrer l\'écoute');
    }
  }

  /// Arrête l'écoute vocale
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _speechToText.stop();
      _isListening = false;
      onListeningStopped?.call();
      if (kDebugMode) debugPrint('🎤 [VoiceSearch] Écoute arrêtée');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [VoiceSearch] Erreur arrêt: $e');
    }
  }

  /// Annule l'écoute en cours
  Future<void> cancelListening() async {
    try {
      await _speechToText.cancel();
      _isListening = false;
      _lastWords = '';
      onListeningStopped?.call();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [VoiceSearch] Erreur annulation: $e');
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    
    if (result.finalResult) {
      if (kDebugMode) debugPrint('🎤 [VoiceSearch] Résultat final: $_lastWords');
      onResult?.call(_lastWords);
    } else {
      if (kDebugMode) debugPrint('🎤 [VoiceSearch] Partiel: $_lastWords');
      onPartialResult?.call(_lastWords);
    }
  }

  void _onStatus(String status) {
    if (kDebugMode) debugPrint('🎤 [VoiceSearch] Status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      onListeningStopped?.call();
    }
  }

  void _onSpeechError(dynamic error) {
    if (kDebugMode) debugPrint('❌ [VoiceSearch] Erreur: $error');
    _isListening = false;
    onListeningStopped?.call();
    
    String errorMessage = 'Erreur de reconnaissance vocale';
    if (error.toString().contains('error_no_match')) {
      errorMessage = 'Aucune correspondance trouvée';
    } else if (error.toString().contains('error_speech_timeout')) {
      errorMessage = 'Temps d\'écoute dépassé';
    } else if (error.toString().contains('error_audio')) {
      errorMessage = 'Erreur audio - vérifiez le microphone';
    } else if (error.toString().contains('error_permission')) {
      errorMessage = 'Permission microphone refusée';
    }
    
    onError?.call(errorMessage);
  }

  /// Libère les ressources
  void dispose() {
    stopListening();
  }
}
