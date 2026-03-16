import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provider pour le service de navigation
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService();
});

/// Application GPS disponible
enum NavigationApp {
  googleMaps,
  waze,
  appleMaps,
  yandex,
  citymapper,
  osmAnd,
}

/// Extension pour les métadonnées des apps
extension NavigationAppExtension on NavigationApp {
  String get displayName {
    switch (this) {
      case NavigationApp.googleMaps:
        return 'Google Maps';
      case NavigationApp.waze:
        return 'Waze';
      case NavigationApp.appleMaps:
        return 'Apple Maps';
      case NavigationApp.yandex:
        return 'Yandex Maps';
      case NavigationApp.citymapper:
        return 'Citymapper';
      case NavigationApp.osmAnd:
        return 'OsmAnd';
    }
  }

  IconData get icon {
    switch (this) {
      case NavigationApp.googleMaps:
        return Icons.map;
      case NavigationApp.waze:
        return Icons.navigation;
      case NavigationApp.appleMaps:
        return Icons.apple;
      case NavigationApp.yandex:
        return Icons.explore;
      case NavigationApp.citymapper:
        return Icons.directions_transit;
      case NavigationApp.osmAnd:
        return Icons.terrain;
    }
  }

  Color get color {
    switch (this) {
      case NavigationApp.googleMaps:
        return const Color(0xFF4285F4);
      case NavigationApp.waze:
        return const Color(0xFF00CCFF);
      case NavigationApp.appleMaps:
        return Colors.grey.shade800;
      case NavigationApp.yandex:
        return const Color(0xFFFF0000);
      case NavigationApp.citymapper:
        return const Color(0xFF2DBE60);
      case NavigationApp.osmAnd:
        return const Color(0xFF2D9B27);
    }
  }

  MapType? get mapType {
    switch (this) {
      case NavigationApp.googleMaps:
        return MapType.google;
      case NavigationApp.waze:
        return MapType.waze;
      case NavigationApp.appleMaps:
        return MapType.apple;
      case NavigationApp.yandex:
        return MapType.yandexMaps;
      case NavigationApp.citymapper:
        return MapType.citymapper;
      case NavigationApp.osmAnd:
        return MapType.osmand;
    }
  }
}

/// Instruction de navigation turn-by-turn
class NavigationInstruction {
  final String instruction;
  final String maneuver;
  final double distanceMeters;
  final double durationSeconds;
  final double startLat;
  final double startLng;

  NavigationInstruction({
    required this.instruction,
    required this.maneuver,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startLat,
    required this.startLng,
  });

  String get distanceText {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationText {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 1) return 'maintenant';
    if (minutes == 1) return '1 min';
    return '$minutes min';
  }

  IconData get maneuverIcon {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
      case 'turn-slight-left':
      case 'turn-sharp-left':
        return Icons.turn_left;
      case 'turn-right':
      case 'turn-slight-right':
      case 'turn-sharp-right':
        return Icons.turn_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_right;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      case 'merge':
        return Icons.merge;
      case 'fork-left':
      case 'fork-right':
        return Icons.fork_right;
      case 'ramp-left':
      case 'ramp-right':
        return Icons.ramp_right;
      case 'ferry':
        return Icons.directions_boat;
      default:
        return Icons.straight;
    }
  }
}

/// Service de navigation avancée avec guidage vocal
class NavigationService {
  static const String _preferredAppKey = 'preferred_nav_app';
  static const String _voiceEnabledKey = 'nav_voice_enabled';
  static const String _voiceLanguageKey = 'nav_voice_language';

  FlutterTts? _tts;
  bool _isVoiceEnabled = true;
  String _voiceLanguage = 'fr-FR';
  NavigationApp? _preferredApp;
  
  // État de navigation active
  bool _isNavigating = false;
  // ignore: unused_field
  double? _destinationLat;
  // ignore: unused_field
  double? _destinationLng;
  String? _destinationName;
  final List<NavigationInstruction> _instructions = [];
  int _currentInstructionIndex = 0;
  StreamSubscription<Position>? _positionSubscription;

  /// Callbacks
  Function(NavigationInstruction)? onInstructionUpdate;
  Function(double distanceRemaining, double timeRemaining)? onProgressUpdate;
  Function()? onArrival;

  NavigationService() {
    _initTTS();
    _loadPreferences();
  }

  /// Initialiser le moteur TTS
  Future<void> _initTTS() async {
    _tts = FlutterTts();
    
    await _tts!.setLanguage(_voiceLanguage);
    await _tts!.setSpeechRate(0.5); // Vitesse normale
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);
    
    // Sur iOS, utiliser la catégorie audio appropriée
    if (Platform.isIOS) {
      await _tts!.setSharedInstance(true);
      await _tts!.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }
  }

  /// Charger les préférences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isVoiceEnabled = prefs.getBool(_voiceEnabledKey) ?? true;
    _voiceLanguage = prefs.getString(_voiceLanguageKey) ?? 'fr-FR';
    
    final appName = prefs.getString(_preferredAppKey);
    if (appName != null) {
      try {
        _preferredApp = NavigationApp.values.firstWhere(
          (a) => a.name == appName,
        );
      } catch (_) {
        _preferredApp = null;
      }
    }
  }

  /// Sauvegarder l'app préférée
  Future<void> setPreferredApp(NavigationApp app) async {
    _preferredApp = app;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredAppKey, app.name);
  }

  /// Activer/désactiver le guidage vocal
  Future<void> setVoiceEnabled(bool enabled) async {
    _isVoiceEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceEnabledKey, enabled);
  }

  bool get isVoiceEnabled => _isVoiceEnabled;
  NavigationApp? get preferredApp => _preferredApp;
  bool get isNavigating => _isNavigating;
  List<NavigationInstruction> get instructions => _instructions;
  int get currentInstructionIndex => _currentInstructionIndex;

  /// Obtenir les apps de navigation installées
  Future<List<NavigationApp>> getInstalledApps() async {
    final availableMaps = await MapLauncher.installedMaps;
    final installed = <NavigationApp>[];
    
    for (final app in NavigationApp.values) {
      final mapType = app.mapType;
      if (mapType != null) {
        if (availableMaps.any((m) => m.mapType == mapType)) {
          installed.add(app);
        }
      }
    }
    
    // Google Maps web fallback toujours disponible
    if (!installed.contains(NavigationApp.googleMaps)) {
      installed.insert(0, NavigationApp.googleMaps);
    }
    
    return installed;
  }

  /// Lancer la navigation vers une destination
  Future<bool> launchNavigation({
    required double destinationLat,
    required double destinationLng,
    required String destinationName,
    NavigationApp? app,
    double? originLat,
    double? originLng,
  }) async {
    final targetApp = app ?? _preferredApp ?? NavigationApp.googleMaps;
    
    _destinationLat = destinationLat;
    _destinationLng = destinationLng;
    _destinationName = destinationName;

    try {
      final availableMaps = await MapLauncher.installedMaps;
      final mapType = targetApp.mapType;
      
      if (mapType != null) {
        final selectedMap = availableMaps.firstWhere(
          (m) => m.mapType == mapType,
          orElse: () => availableMaps.first,
        );

        if (originLat != null && originLng != null) {
          await selectedMap.showDirections(
            destination: Coords(destinationLat, destinationLng),
            destinationTitle: destinationName,
            origin: Coords(originLat, originLng),
            originTitle: 'Ma position',
            directionsMode: DirectionsMode.driving,
          );
        } else {
          await selectedMap.showDirections(
            destination: Coords(destinationLat, destinationLng),
            destinationTitle: destinationName,
            directionsMode: DirectionsMode.driving,
          );
        }
        
        // Annoncer le démarrage
        if (_isVoiceEnabled) {
          await _speak('Navigation vers $destinationName démarrée');
        }
        
        return true;
      }
    } catch (e) {
      // Fallback vers Google Maps web
      debugPrint('MapLauncher error: $e - falling back to web');
    }

    // Fallback: ouvrir Google Maps dans le navigateur
    return _launchGoogleMapsWeb(
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      originLat: originLat,
      originLng: originLng,
    );
  }

  /// Fallback Google Maps web
  Future<bool> _launchGoogleMapsWeb({
    required double destinationLat,
    required double destinationLng,
    double? originLat,
    double? originLng,
  }) async {
    String url;
    if (originLat != null && originLng != null) {
      url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=$originLat,$originLng'
          '&destination=$destinationLat,$destinationLng'
          '&travelmode=driving';
    } else {
      url = 'https://www.google.com/maps/dir/?api=1'
          '&destination=$destinationLat,$destinationLng'
          '&travelmode=driving';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Lancer la navigation avec sélection d'app
  Future<NavigationApp?> showAppSelector(
    BuildContext context, {
    required double destinationLat,
    required double destinationLng,
    required String destinationName,
  }) async {
    final installedApps = await getInstalledApps();
    
    if (installedApps.length == 1) {
      // Une seule app, lancer directement
      await launchNavigation(
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        destinationName: destinationName,
        app: installedApps.first,
      );
      return installedApps.first;
    }

    // Afficher le sélecteur
    if (!context.mounted) return null;
    final selectedApp = await showModalBottomSheet<NavigationApp>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NavigationAppSelector(
        installedApps: installedApps,
        preferredApp: _preferredApp,
        destinationName: destinationName,
        isVoiceEnabled: _isVoiceEnabled,
        onVoiceToggle: (enabled) => setVoiceEnabled(enabled),
        onSetPreferred: (app) => setPreferredApp(app),
      ),
    );

    if (selectedApp != null) {
      await launchNavigation(
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        destinationName: destinationName,
        app: selectedApp,
      );
    }

    return selectedApp;
  }

  /// Parler une instruction
  Future<void> _speak(String text) async {
    if (!_isVoiceEnabled || _tts == null) return;
    
    await _tts!.stop();
    await _tts!.speak(text);
  }

  /// Annoncer la prochaine instruction basée sur la distance
  Future<void> announceNextInstruction(double distanceToNext) async {
    if (_currentInstructionIndex >= _instructions.length) return;
    
    final instruction = _instructions[_currentInstructionIndex];
    
    // Annoncer à différentes distances
    if (distanceToNext <= 50) {
      // Très proche
      await _speak(instruction.instruction);
    } else if (distanceToNext <= 200) {
      // Proche
      await _speak('Dans ${instruction.distanceText}, ${instruction.instruction}');
    } else if (distanceToNext <= 500) {
      // Préparation
      await _speak('Préparez-vous: dans ${instruction.distanceText}, ${instruction.instruction}');
    }
  }

  /// Annoncer l'arrivée
  Future<void> announceArrival() async {
    await _speak('Vous êtes arrivé à destination: $_destinationName');
    _isNavigating = false;
    onArrival?.call();
  }

  /// Arrêter la navigation
  Future<void> stopNavigation() async {
    _isNavigating = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _instructions.clear();
    _currentInstructionIndex = 0;
    await _tts?.stop();
  }

  /// Nettoyer les ressources
  void dispose() {
    stopNavigation();
    _tts?.stop();
  }
}

/// Widget de sélection d'app de navigation
class _NavigationAppSelector extends StatefulWidget {
  final List<NavigationApp> installedApps;
  final NavigationApp? preferredApp;
  final String destinationName;
  final bool isVoiceEnabled;
  final Function(bool) onVoiceToggle;
  final Function(NavigationApp)? onSetPreferred;

  const _NavigationAppSelector({
    required this.installedApps,
    this.preferredApp,
    required this.destinationName,
    required this.isVoiceEnabled,
    required this.onVoiceToggle,
    this.onSetPreferred,
  });

  @override
  State<_NavigationAppSelector> createState() => _NavigationAppSelectorState();
}

class _NavigationAppSelectorState extends State<_NavigationAppSelector> {
  late bool _voiceEnabled;

  @override
  void initState() {
    super.initState();
    _voiceEnabled = widget.isVoiceEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.navigation, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Naviguer vers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        widget.destinationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Voice toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _voiceEnabled ? Icons.volume_up : Icons.volume_off,
                    color: _voiceEnabled ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guidage vocal',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _voiceEnabled ? 'Instructions vocales activées' : 'Désactivé',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _voiceEnabled,
                    onChanged: (value) {
                      setState(() => _voiceEnabled = value);
                      widget.onVoiceToggle(value);
                    },
                    activeThumbColor: Colors.blue,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Choisir une application',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Apps grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              physics: const NeverScrollableScrollPhysics(),
              children: widget.installedApps.map((app) {
                final isPreferred = app == widget.preferredApp;
                return _AppTile(
                  app: app,
                  isPreferred: isPreferred,
                  onTap: () => Navigator.pop(context, app),
                  onSetPreferred: widget.onSetPreferred != null
                      ? () => widget.onSetPreferred!(app)
                      : null,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Hint
            Center(
              child: Text(
                'Appui long pour définir comme app par défaut',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final NavigationApp app;
  final bool isPreferred;
  final VoidCallback onTap;
  final VoidCallback? onSetPreferred;

  const _AppTile({
    required this.app,
    required this.isPreferred,
    required this.onTap,
    this.onSetPreferred,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        onSetPreferred?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${app.displayName} défini comme app par défaut'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPreferred ? app.color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Icon(
                  app.icon,
                  size: 32,
                  color: app.color,
                ),
                if (isPreferred)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              app.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isPreferred ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
