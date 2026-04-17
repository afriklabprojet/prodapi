import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/core/services/voice_service.dart';

const MethodChannel _ttsChannel = MethodChannel('flutter_tts');
const MethodChannel _sttChannel = MethodChannel(
  'plugin.csdcorp.com/speech_to_text',
);

void _mockVoicePlatformChannels() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(_ttsChannel, (call) async {
    switch (call.method) {
      case 'getLanguages':
        return ['fr-FR', 'en-US', 'ar-MA'];
      default:
        return 1;
    }
  });

  messenger.setMockMethodCallHandler(_sttChannel, (call) async {
    switch (call.method) {
      case 'initialize':
      case 'listen':
      case 'stop':
      case 'cancel':
        return true;
      default:
        return true;
    }
  });
}

Future<void> _sendPlatformCallback(
  MethodChannel channel,
  String method,
  dynamic arguments,
) async {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  await messenger.handlePlatformMessage(
    channel.name,
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
    (_) {},
  );
  await pumpEventQueue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockVoicePlatformChannels();
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_ttsChannel, null);
    messenger.setMockMethodCallHandler(_sttChannel, null);
  });

  group('VoiceAnnouncementType', () {
    test('should have all expected values', () {
      expect(VoiceAnnouncementType.values.length, 10);
      expect(VoiceAnnouncementType.newDelivery.index, 0);
      expect(VoiceAnnouncementType.deliveryAccepted.index, 1);
      expect(VoiceAnnouncementType.navigationStart.index, 2);
      expect(VoiceAnnouncementType.navigationTurn.index, 3);
      expect(VoiceAnnouncementType.navigationArrival.index, 4);
      expect(VoiceAnnouncementType.deliveryCompleted.index, 5);
      expect(VoiceAnnouncementType.earnings.index, 6);
      expect(VoiceAnnouncementType.warning.index, 7);
      expect(VoiceAnnouncementType.reminder.index, 8);
      expect(VoiceAnnouncementType.custom.index, 9);
    });
  });

  group('VoiceCommand', () {
    test('should have all expected values', () {
      expect(VoiceCommand.values.length, 10);
      expect(VoiceCommand.acceptDelivery.index, 0);
      expect(VoiceCommand.declineDelivery.index, 1);
      expect(VoiceCommand.startNavigation.index, 2);
      expect(VoiceCommand.callCustomer.index, 3);
      expect(VoiceCommand.callPharmacy.index, 4);
      expect(VoiceCommand.markDelivered.index, 5);
      expect(VoiceCommand.goOnline.index, 6);
      expect(VoiceCommand.goOffline.index, 7);
      expect(VoiceCommand.readStats.index, 8);
      expect(VoiceCommand.unknown.index, 9);
    });
  });

  group('VoiceSettings', () {
    test('should create with default values', () {
      const settings = VoiceSettings();

      expect(settings.ttsEnabled, true);
      expect(settings.sttEnabled, true);
      expect(settings.speechRate, 0.5);
      expect(settings.pitch, 1.0);
      expect(settings.volume, 1.0);
      expect(settings.language, 'fr-FR');
      expect(settings.announceNewDeliveries, true);
      expect(settings.announceNavigation, true);
      expect(settings.announceEarnings, true);
      expect(settings.voiceCommands, true);
    });

    test('copyWith should update specified fields', () {
      const settings = VoiceSettings();

      final updated = settings.copyWith(
        speechRate: 0.8,
        pitch: 1.2,
        announceNavigation: false,
      );

      expect(updated.speechRate, 0.8);
      expect(updated.pitch, 1.2);
      expect(updated.announceNavigation, false);
      // Others should remain unchanged
      expect(updated.ttsEnabled, true);
      expect(updated.language, 'fr-FR');
    });

    test('should allow disabling features', () {
      const settings = VoiceSettings(
        ttsEnabled: false,
        sttEnabled: false,
        voiceCommands: false,
      );

      expect(settings.ttsEnabled, false);
      expect(settings.sttEnabled, false);
      expect(settings.voiceCommands, false);
    });
  });

  group('VoiceMessages', () {
    test('newDelivery should format correctly', () {
      final message = VoiceMessages.newDelivery('Pharmacie du Centre', '1500');

      expect(message, contains('Nouvelle livraison disponible'));
      expect(message, contains('Pharmacie du Centre'));
      expect(message, contains('1500 francs'));
    });

    test('deliveryAccepted should format correctly', () {
      final message = VoiceMessages.deliveryAccepted('Pharmacie du Centre');

      expect(message, contains('Livraison acceptée'));
      expect(message, contains('Pharmacie du Centre'));
    });

    test('deliveryCompleted should format correctly', () {
      final message = VoiceMessages.deliveryCompleted('2000');

      expect(message, contains('Livraison terminée'));
      expect(message, contains('2000 francs'));
    });

    test('navigationStart should format correctly', () {
      final message = VoiceMessages.navigationStart('Cocody', '15 minutes');

      expect(message, contains('Démarrage de la navigation'));
      expect(message, contains('Cocody'));
      expect(message, contains('15 minutes'));
    });

    test('turnLeft should format correctly', () {
      final message = VoiceMessages.turnLeft('Rue du Commerce');

      expect(message, contains('tournez à gauche'));
      expect(message, contains('Rue du Commerce'));
    });

    test('turnRight should format correctly', () {
      final message = VoiceMessages.turnRight('Avenue Houphouët');

      expect(message, contains('tournez à droite'));
      expect(message, contains('Avenue Houphouët'));
    });

    test('goStraight should format correctly', () {
      final message = VoiceMessages.goStraight('500 mètres');

      expect(message, contains('Continuez tout droit'));
      expect(message, contains('500 mètres'));
    });

    test('arrival should have correct message', () {
      expect(VoiceMessages.arrival(), contains('arrivé à destination'));
    });

    test('rerouting should have correct message', () {
      expect(VoiceMessages.rerouting(), contains('Recalcul'));
    });

    test('dailyEarnings should format correctly', () {
      final message = VoiceMessages.dailyEarnings('8500');

      expect(message, contains('Gains du jour'));
      expect(message, contains('8500 francs'));
    });

    test('weeklyEarnings should format correctly', () {
      final message = VoiceMessages.weeklyEarnings('45000');

      expect(message, contains('Gains de la semaine'));
      expect(message, contains('45000 francs'));
    });

    test('batteryLow should format correctly', () {
      final message = VoiceMessages.batteryLow(15);

      expect(message, contains('batterie faible'));
      expect(message, contains('15 pour cent'));
    });

    test('connectionLost should have correct message', () {
      expect(
        VoiceMessages.connectionLost(),
        contains('connexion internet perdue'),
      );
    });

    test('connectionRestored should have correct message', () {
      expect(
        VoiceMessages.connectionRestored(),
        contains('Connexion internet restaurée'),
      );
    });
  });

  group('VoiceServiceState', () {
    test('should create with default values', () {
      const state = VoiceServiceState();

      expect(state.settings.ttsEnabled, true);
      expect(state.isSpeaking, false);
      expect(state.isListening, false);
      expect(state.lastSpokenText, isNull);
      expect(state.lastRecognizedText, isNull);
      expect(state.lastCommand, isNull);
      expect(state.ttsAvailable, false);
      expect(state.sttAvailable, false);
      expect(state.availableLanguages, isEmpty);
    });

    test('copyWith should update specified fields', () {
      const state = VoiceServiceState();

      final updated = state.copyWith(
        isSpeaking: true,
        lastSpokenText: 'Hello',
        ttsAvailable: true,
        availableLanguages: ['fr-FR', 'en-US'],
      );

      expect(updated.isSpeaking, true);
      expect(updated.lastSpokenText, 'Hello');
      expect(updated.ttsAvailable, true);
      expect(updated.availableLanguages.length, 2);
      // Others should remain unchanged
      expect(updated.isListening, false);
      expect(updated.sttAvailable, false);
    });

    test('should update settings', () {
      const state = VoiceServiceState();
      const newSettings = VoiceSettings(speechRate: 0.7, language: 'en-US');

      final updated = state.copyWith(settings: newSettings);

      expect(updated.settings.speechRate, 0.7);
      expect(updated.settings.language, 'en-US');
    });

    test('should track last command', () {
      const state = VoiceServiceState();

      final updated = state.copyWith(
        lastRecognizedText: 'accepter la livraison',
        lastCommand: VoiceCommand.acceptDelivery,
      );

      expect(updated.lastRecognizedText, 'accepter la livraison');
      expect(updated.lastCommand, VoiceCommand.acceptDelivery);
    });

    test('copyWith updates isListening independently', () {
      const state = VoiceServiceState();
      final updated = state.copyWith(isListening: true);
      expect(updated.isListening, true);
      expect(updated.isSpeaking, false);
    });

    test('copyWith updates sttAvailable independently', () {
      const state = VoiceServiceState();
      final updated = state.copyWith(sttAvailable: true);
      expect(updated.sttAvailable, true);
      expect(updated.ttsAvailable, false);
    });

    test('copyWith preserves all fields when nothing changed', () {
      final state = VoiceServiceState(
        settings: const VoiceSettings(speechRate: 0.8),
        isSpeaking: true,
        isListening: true,
        lastSpokenText: 'test',
        lastRecognizedText: 'rec',
        lastCommand: VoiceCommand.goOnline,
        ttsAvailable: true,
        sttAvailable: true,
        availableLanguages: ['fr-FR'],
      );
      final copy = state.copyWith();
      expect(copy.settings.speechRate, 0.8);
      expect(copy.isSpeaking, true);
      expect(copy.isListening, true);
      expect(copy.lastSpokenText, 'test');
      expect(copy.lastRecognizedText, 'rec');
      expect(copy.lastCommand, VoiceCommand.goOnline);
      expect(copy.ttsAvailable, true);
      expect(copy.sttAvailable, true);
      expect(copy.availableLanguages, ['fr-FR']);
    });
  });

  group('VoiceSettings - individual copyWith fields', () {
    test('copyWith updates ttsEnabled', () {
      const settings = VoiceSettings();
      final updated = settings.copyWith(ttsEnabled: false);
      expect(updated.ttsEnabled, false);
      expect(updated.sttEnabled, true);
    });

    test('copyWith updates sttEnabled', () {
      const settings = VoiceSettings();
      final updated = settings.copyWith(sttEnabled: false);
      expect(updated.sttEnabled, false);
      expect(updated.ttsEnabled, true);
    });

    test('copyWith updates volume', () {
      const settings = VoiceSettings();
      final updated = settings.copyWith(volume: 0.5);
      expect(updated.volume, 0.5);
      expect(updated.speechRate, 0.5);
    });

    test('copyWith updates language', () {
      const settings = VoiceSettings();
      final updated = settings.copyWith(language: 'en-US');
      expect(updated.language, 'en-US');
    });

    test('copyWith updates announceNewDeliveries', () {
      const settings = VoiceSettings();
      final updated = settings.copyWith(announceNewDeliveries: false);
      expect(updated.announceNewDeliveries, false);
      expect(updated.announceEarnings, true);
    });

    test('copyWith updates announceEarnings', () {
      const settings = VoiceSettings();
      final updated = settings.copyWith(announceEarnings: false);
      expect(updated.announceEarnings, false);
      expect(updated.announceNewDeliveries, true);
    });

    test('copyWith updates voiceCommands', () {
      const settings = VoiceSettings();
      final updated = settings.copyWith(voiceCommands: false);
      expect(updated.voiceCommands, false);
    });

    test('preserves all fields when nothing changed', () {
      const settings = VoiceSettings(
        ttsEnabled: false,
        sttEnabled: false,
        speechRate: 0.3,
        pitch: 0.5,
        volume: 0.7,
        language: 'en-US',
        announceNewDeliveries: false,
        announceNavigation: false,
        announceEarnings: false,
        voiceCommands: false,
      );
      final copy = settings.copyWith();
      expect(copy.ttsEnabled, false);
      expect(copy.sttEnabled, false);
      expect(copy.speechRate, 0.3);
      expect(copy.pitch, 0.5);
      expect(copy.volume, 0.7);
      expect(copy.language, 'en-US');
      expect(copy.announceNewDeliveries, false);
      expect(copy.announceNavigation, false);
      expect(copy.announceEarnings, false);
      expect(copy.voiceCommands, false);
    });

    test('copyWith updates announceNavigation', () {
      const settings = VoiceSettings();
      final updated = settings.copyWith(announceNavigation: false);
      expect(updated.announceNavigation, false);
      expect(updated.announceNewDeliveries, true);
    });

    test('copyWith updates pitch', () {
      const settings = VoiceSettings();
      final updated = settings.copyWith(pitch: 1.5);
      expect(updated.pitch, 1.5);
      expect(updated.volume, 1.0);
    });

    test('copyWith updates speechRate', () {
      const settings = VoiceSettings();
      final updated = settings.copyWith(speechRate: 0.9);
      expect(updated.speechRate, 0.9);
      expect(updated.pitch, 1.0);
    });
  });

  group('VoiceMessages - exact return values', () {
    test('newDelivery returns full formatted sentence', () {
      expect(
        VoiceMessages.newDelivery('Pharmacie Test', '2500'),
        'Nouvelle livraison disponible. Pharmacie Test. Commission: 2500 francs.',
      );
    });

    test('deliveryAccepted returns full formatted sentence', () {
      expect(
        VoiceMessages.deliveryAccepted('Pharmacie du Centre'),
        'Livraison acceptée. Dirigez-vous vers Pharmacie du Centre.',
      );
    });

    test('deliveryCompleted returns full formatted sentence', () {
      expect(
        VoiceMessages.deliveryCompleted('3000'),
        'Livraison terminée. Vous avez gagné 3000 francs.',
      );
    });

    test('navigationStart returns full formatted sentence', () {
      expect(
        VoiceMessages.navigationStart('Cocody', '15 minutes'),
        'Démarrage de la navigation vers Cocody. Durée estimée: 15 minutes.',
      );
    });

    test('turnLeft returns full formatted sentence', () {
      expect(
        VoiceMessages.turnLeft('Rue du Commerce'),
        'Dans 100 mètres, tournez à gauche sur Rue du Commerce.',
      );
    });

    test('turnRight returns full formatted sentence', () {
      expect(
        VoiceMessages.turnRight('Avenue Houphouët'),
        'Dans 100 mètres, tournez à droite sur Avenue Houphouët.',
      );
    });

    test('goStraight returns full formatted sentence', () {
      expect(
        VoiceMessages.goStraight('500 mètres'),
        'Continuez tout droit sur 500 mètres.',
      );
    });

    test('arrival returns exact string', () {
      expect(VoiceMessages.arrival(), 'Vous êtes arrivé à destination.');
    });

    test('rerouting returns exact string', () {
      expect(VoiceMessages.rerouting(), 'Recalcul de l\'itinéraire.');
    });

    test('dailyEarnings returns full formatted sentence', () {
      expect(
        VoiceMessages.dailyEarnings('8500'),
        'Gains du jour: 8500 francs.',
      );
    });

    test('weeklyEarnings returns full formatted sentence', () {
      expect(
        VoiceMessages.weeklyEarnings('45000'),
        'Gains de la semaine: 45000 francs.',
      );
    });

    test('batteryLow returns full formatted sentence', () {
      expect(
        VoiceMessages.batteryLow(15),
        'Attention, batterie faible. 15 pour cent restants.',
      );
    });

    test('connectionLost returns exact string', () {
      expect(
        VoiceMessages.connectionLost(),
        'Attention, connexion internet perdue. Mode hors-ligne activé.',
      );
    });

    test('connectionRestored returns exact string', () {
      expect(
        VoiceMessages.connectionRestored(),
        'Connexion internet restaurée.',
      );
    });

    test('batteryLow with 0 percent', () {
      expect(
        VoiceMessages.batteryLow(0),
        'Attention, batterie faible. 0 pour cent restants.',
      );
    });

    test('batteryLow with 100 percent', () {
      expect(
        VoiceMessages.batteryLow(100),
        'Attention, batterie faible. 100 pour cent restants.',
      );
    });

    test('newDelivery with empty pharmacy name', () {
      final msg = VoiceMessages.newDelivery('', '0');
      expect(msg, contains('Nouvelle livraison'));
      expect(msg, contains('0 francs'));
    });
  });

  group('VoiceServiceState - individual copyWith fields', () {
    test('copyWith updates isSpeaking only', () {
      const state = VoiceServiceState();
      final updated = state.copyWith(isSpeaking: true);
      expect(updated.isSpeaking, true);
      expect(updated.isListening, false);
      expect(updated.ttsAvailable, false);
      expect(updated.sttAvailable, false);
      expect(updated.lastSpokenText, isNull);
    });

    test('copyWith updates lastSpokenText only', () {
      const state = VoiceServiceState();
      final updated = state.copyWith(lastSpokenText: 'Bonjour');
      expect(updated.lastSpokenText, 'Bonjour');
      expect(updated.lastRecognizedText, isNull);
      expect(updated.lastCommand, isNull);
    });

    test('copyWith updates lastRecognizedText only', () {
      const state = VoiceServiceState();
      final updated = state.copyWith(lastRecognizedText: 'accepter');
      expect(updated.lastRecognizedText, 'accepter');
      expect(updated.lastSpokenText, isNull);
    });

    test('copyWith updates lastCommand only', () {
      const state = VoiceServiceState();
      final updated = state.copyWith(lastCommand: VoiceCommand.acceptDelivery);
      expect(updated.lastCommand, VoiceCommand.acceptDelivery);
      expect(updated.lastRecognizedText, isNull);
    });

    test('copyWith updates ttsAvailable only', () {
      const state = VoiceServiceState();
      final updated = state.copyWith(ttsAvailable: true);
      expect(updated.ttsAvailable, true);
      expect(updated.sttAvailable, false);
    });

    test('copyWith updates availableLanguages only', () {
      const state = VoiceServiceState();
      final updated = state.copyWith(
        availableLanguages: ['fr-FR', 'en-US', 'ar-SA'],
      );
      expect(updated.availableLanguages, ['fr-FR', 'en-US', 'ar-SA']);
      expect(updated.settings.language, 'fr-FR');
    });

    test('copyWith updates settings only', () {
      const state = VoiceServiceState();
      const newSettings = VoiceSettings(
        speechRate: 1.0,
        pitch: 0.5,
        volume: 0.8,
      );
      final updated = state.copyWith(settings: newSettings);
      expect(updated.settings.speechRate, 1.0);
      expect(updated.settings.pitch, 0.5);
      expect(updated.settings.volume, 0.8);
      expect(updated.isSpeaking, false);
    });
  });

  group('VoiceAnnouncementType', () {
    test('all values have correct indices', () {
      expect(VoiceAnnouncementType.newDelivery.index, 0);
      expect(VoiceAnnouncementType.deliveryAccepted.index, 1);
      expect(VoiceAnnouncementType.navigationStart.index, 2);
      expect(VoiceAnnouncementType.navigationTurn.index, 3);
      expect(VoiceAnnouncementType.navigationArrival.index, 4);
      expect(VoiceAnnouncementType.deliveryCompleted.index, 5);
      expect(VoiceAnnouncementType.earnings.index, 6);
      expect(VoiceAnnouncementType.warning.index, 7);
      expect(VoiceAnnouncementType.reminder.index, 8);
      expect(VoiceAnnouncementType.custom.index, 9);
    });

    test('values count is 10', () {
      expect(VoiceAnnouncementType.values.length, 10);
    });
  });

  group('VoiceCommand', () {
    test('all values have correct indices', () {
      expect(VoiceCommand.acceptDelivery.index, 0);
      expect(VoiceCommand.declineDelivery.index, 1);
      expect(VoiceCommand.startNavigation.index, 2);
      expect(VoiceCommand.callCustomer.index, 3);
      expect(VoiceCommand.callPharmacy.index, 4);
      expect(VoiceCommand.markDelivered.index, 5);
      expect(VoiceCommand.goOnline.index, 6);
      expect(VoiceCommand.goOffline.index, 7);
      expect(VoiceCommand.readStats.index, 8);
      expect(VoiceCommand.unknown.index, 9);
    });

    test('values count is 10', () {
      expect(VoiceCommand.values.length, 10);
    });
  });

  // ── VoiceAnnouncementType - name property ──────────
  group('VoiceAnnouncementType name', () {
    test('each type has non-empty name', () {
      for (final type in VoiceAnnouncementType.values) {
        expect(type.name, isNotEmpty);
      }
    });

    test('newDelivery name', () {
      expect(VoiceAnnouncementType.newDelivery.name, 'newDelivery');
    });

    test('custom name', () {
      expect(VoiceAnnouncementType.custom.name, 'custom');
    });
  });

  // ── VoiceCommand - name property ───────────────────
  group('VoiceCommand name', () {
    test('each command has non-empty name', () {
      for (final cmd in VoiceCommand.values) {
        expect(cmd.name, isNotEmpty);
      }
    });

    test('acceptDelivery name', () {
      expect(VoiceCommand.acceptDelivery.name, 'acceptDelivery');
    });

    test('unknown name', () {
      expect(VoiceCommand.unknown.name, 'unknown');
    });
  });

  // ── VoiceSettings - boundary values ────────────────
  group('VoiceSettings boundary values', () {
    test('speechRate 0.0 is valid', () {
      const s = VoiceSettings(speechRate: 0.0);
      expect(s.speechRate, 0.0);
    });

    test('speechRate 1.0 is valid', () {
      const s = VoiceSettings(speechRate: 1.0);
      expect(s.speechRate, 1.0);
    });

    test('pitch 0.0 is valid', () {
      const s = VoiceSettings(pitch: 0.0);
      expect(s.pitch, 0.0);
    });

    test('pitch 2.0 is valid', () {
      const s = VoiceSettings(pitch: 2.0);
      expect(s.pitch, 2.0);
    });

    test('volume 0.0 is valid', () {
      const s = VoiceSettings(volume: 0.0);
      expect(s.volume, 0.0);
    });

    test('all features disabled simultaneously', () {
      const s = VoiceSettings(
        ttsEnabled: false,
        sttEnabled: false,
        announceNewDeliveries: false,
        announceNavigation: false,
        announceEarnings: false,
        voiceCommands: false,
      );
      expect(s.ttsEnabled, false);
      expect(s.sttEnabled, false);
      expect(s.announceNewDeliveries, false);
      expect(s.announceNavigation, false);
      expect(s.announceEarnings, false);
      expect(s.voiceCommands, false);
    });

    test('all features enabled simultaneously', () {
      const s = VoiceSettings(
        ttsEnabled: true,
        sttEnabled: true,
        announceNewDeliveries: true,
        announceNavigation: true,
        announceEarnings: true,
        voiceCommands: true,
      );
      expect(s.ttsEnabled, true);
      expect(s.sttEnabled, true);
      expect(s.announceNewDeliveries, true);
      expect(s.announceNavigation, true);
      expect(s.announceEarnings, true);
      expect(s.voiceCommands, true);
    });

    test('custom language', () {
      const s = VoiceSettings(language: 'ar-MA');
      expect(s.language, 'ar-MA');
    });
  });

  // ── VoiceMessages - edge cases ─────────────────────
  group('VoiceMessages edge cases', () {
    test('newDelivery with unicode pharmacy', () {
      final msg = VoiceMessages.newDelivery('Pharmacie étoile ★', '3000');
      expect(msg, contains('Pharmacie étoile ★'));
    });

    test('navigationStart with long destination', () {
      final msg = VoiceMessages.navigationStart(
        'Avenue du Général de Gaulle, Plateau, Abidjan',
        '45 minutes',
      );
      expect(msg, contains('Avenue du Général de Gaulle'));
    });

    test('turnLeft with empty street', () {
      final msg = VoiceMessages.turnLeft('');
      expect(msg, contains('tournez à gauche'));
    });

    test('turnRight with empty street', () {
      final msg = VoiceMessages.turnRight('');
      expect(msg, contains('tournez à droite'));
    });

    test('goStraight with empty distance', () {
      final msg = VoiceMessages.goStraight('');
      expect(msg, contains('Continuez tout droit'));
    });

    test('dailyEarnings with zero', () {
      final msg = VoiceMessages.dailyEarnings('0');
      expect(msg, contains('0 francs'));
    });

    test('weeklyEarnings with large amount', () {
      final msg = VoiceMessages.weeklyEarnings('1000000');
      expect(msg, contains('1000000 francs'));
    });

    test('batteryLow with 1 percent', () {
      expect(VoiceMessages.batteryLow(1), contains('1 pour cent'));
    });

    test('deliveryCompleted with zero amount', () {
      final msg = VoiceMessages.deliveryCompleted('0');
      expect(msg, contains('0 francs'));
    });
  });

  // ── VoiceServiceState - full state construction ────
  group('VoiceServiceState full construction', () {
    test('constructor with all fields', () {
      final state = VoiceServiceState(
        settings: const VoiceSettings(language: 'en-US', speechRate: 0.3),
        isSpeaking: true,
        isListening: true,
        lastSpokenText: 'spoken',
        lastRecognizedText: 'recognized',
        lastCommand: VoiceCommand.markDelivered,
        ttsAvailable: true,
        sttAvailable: true,
        availableLanguages: ['fr-FR', 'en-US', 'ar-MA'],
      );
      expect(state.settings.language, 'en-US');
      expect(state.settings.speechRate, 0.3);
      expect(state.isSpeaking, true);
      expect(state.isListening, true);
      expect(state.lastSpokenText, 'spoken');
      expect(state.lastRecognizedText, 'recognized');
      expect(state.lastCommand, VoiceCommand.markDelivered);
      expect(state.ttsAvailable, true);
      expect(state.sttAvailable, true);
      expect(state.availableLanguages.length, 3);
    });

    test('copyWith clears lastSpokenText to empty', () {
      final state = VoiceServiceState(lastSpokenText: 'old');
      final copy = state.copyWith(lastSpokenText: '');
      expect(copy.lastSpokenText, '');
    });

    test('available languages can be empty list', () {
      const state = VoiceServiceState();
      expect(state.availableLanguages, isEmpty);
    });

    test('copyWith updates all fields at once', () {
      const state = VoiceServiceState();
      final updated = state.copyWith(
        isSpeaking: true,
        isListening: true,
        lastSpokenText: 'text',
        lastRecognizedText: 'rec',
        lastCommand: VoiceCommand.goOnline,
        ttsAvailable: true,
        sttAvailable: true,
        availableLanguages: ['fr-FR'],
        settings: const VoiceSettings(volume: 0.5),
      );
      expect(updated.isSpeaking, true);
      expect(updated.isListening, true);
      expect(updated.lastSpokenText, 'text');
      expect(updated.lastRecognizedText, 'rec');
      expect(updated.lastCommand, VoiceCommand.goOnline);
      expect(updated.ttsAvailable, true);
      expect(updated.sttAvailable, true);
      expect(updated.availableLanguages, ['fr-FR']);
      expect(updated.settings.volume, 0.5);
    });
  });

  group('VoiceService integration', () {
    late VoiceService service;

    setUp(() async {
      service = VoiceService();
      await pumpEventQueue(times: 20);
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes TTS and STT availability from plugins', () {
      expect(service.state.ttsAvailable, isTrue);
      expect(service.state.sttAvailable, isTrue);
      expect(service.state.availableLanguages, contains('fr-FR'));
    });

    test('updateSettings applies new configuration', () async {
      const updatedSettings = VoiceSettings(
        ttsEnabled: true,
        sttEnabled: true,
        speechRate: 0.8,
        pitch: 1.3,
        volume: 0.6,
        language: 'en-US',
      );

      await service.updateSettings(updatedSettings);

      expect(service.state.settings.language, 'en-US');
      expect(service.state.settings.speechRate, 0.8);
      expect(service.state.settings.pitch, 1.3);
      expect(service.state.settings.volume, 0.6);
    });

    test('announceEarnings uses weekly message when requested', () async {
      await service.announceEarnings(amount: '12000', weekly: true);

      expect(service.state.lastSpokenText, contains('Gains de la semaine'));
      expect(service.state.lastSpokenText, contains('12000 francs'));
    });

    test('startListening and stopListening toggle state', () async {
      await service.startListening();
      expect(service.state.isListening, isTrue);

      await service.stopListening();
      expect(service.state.isListening, isFalse);
    });

    test('recognized accept command updates lastCommand', () async {
      VoiceCommand? recognized;
      service.onCommandRecognized = (cmd) => recognized = cmd;

      await service.startListening();
      await _sendPlatformCallback(
        _sttChannel,
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'oui accepte', 'confidence': 0.95},
          ],
          'finalResult': true,
        }),
      );

      expect(service.state.lastRecognizedText, 'oui accepte');
      expect(service.state.lastCommand, VoiceCommand.acceptDelivery);
      expect(recognized, VoiceCommand.acceptDelivery);
      expect(service.state.lastSpokenText, 'Livraison acceptée.');
    });

    test('recognized déconnecter command maps to goOffline', () async {
      VoiceCommand? recognized;
      service.onCommandRecognized = (cmd) => recognized = cmd;

      await service.startListening();
      await _sendPlatformCallback(
        _sttChannel,
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'déconnecter maintenant', 'confidence': 0.91},
          ],
          'finalResult': true,
        }),
      );

      expect(service.state.lastCommand, VoiceCommand.goOffline);
      expect(recognized, VoiceCommand.goOffline);
      expect(service.state.lastSpokenText, 'Vous êtes maintenant hors ligne.');
    });

    test('handleNavigationInstruction expands km and m clearly', () async {
      await service.handleNavigationInstruction(
        instruction: 'Continuez sur 2 km puis 200 m',
        distance: '2 km',
      );

      expect(
        service.state.lastSpokenText,
        'Continuez sur 2 kilomètres puis 200 mètres',
      );
    });

    test('voice providers expose derived state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(voiceServiceProvider.notifier);
      await pumpEventQueue(times: 20);

      expect(container.read(voiceSettingsProvider), notifier.state.settings);
      expect(container.read(ttsAvailableProvider), notifier.state.ttsAvailable);
      expect(container.read(sttAvailableProvider), notifier.state.sttAvailable);
      expect(container.read(isSpeakingProvider), notifier.state.isSpeaking);
      expect(container.read(isListeningProvider), notifier.state.isListening);
    });

    test('speak does nothing when ttsEnabled is false', () async {
      await service.updateSettings(const VoiceSettings(ttsEnabled: false));

      await service.speak('test');

      // lastSpokenText should not change because tts is disabled
      expect(service.state.lastSpokenText, isNull);
    });

    test(
      'speak skips newDelivery when announceNewDeliveries is false',
      () async {
        await service.updateSettings(
          const VoiceSettings(announceNewDeliveries: false),
        );

        await service.speak(
          'test delivery',
          type: VoiceAnnouncementType.newDelivery,
        );

        expect(service.state.lastSpokenText, isNull);
      },
    );

    test('speak skips navigation when announceNavigation is false', () async {
      await service.updateSettings(
        const VoiceSettings(announceNavigation: false),
      );

      await service.speak(
        'turn left',
        type: VoiceAnnouncementType.navigationStart,
      );
      expect(service.state.lastSpokenText, isNull);

      await service.speak(
        'turn right',
        type: VoiceAnnouncementType.navigationTurn,
      );
      expect(service.state.lastSpokenText, isNull);

      await service.speak(
        'arrived',
        type: VoiceAnnouncementType.navigationArrival,
      );
      expect(service.state.lastSpokenText, isNull);
    });

    test('speak skips earnings when announceEarnings is false', () async {
      await service.updateSettings(
        const VoiceSettings(announceEarnings: false),
      );

      await service.speak(
        'earnings today',
        type: VoiceAnnouncementType.earnings,
      );

      expect(service.state.lastSpokenText, isNull);
    });

    test('speak allows warning type regardless of settings', () async {
      await service.speak('battery low', type: VoiceAnnouncementType.warning);

      expect(service.state.lastSpokenText, 'battery low');
    });

    test('speak allows custom type regardless of settings', () async {
      await service.speak('custom message', type: VoiceAnnouncementType.custom);

      expect(service.state.lastSpokenText, 'custom message');
    });

    test('speak allows deliveryAccepted type', () async {
      await service.speak(
        'delivery accepted',
        type: VoiceAnnouncementType.deliveryAccepted,
      );

      expect(service.state.lastSpokenText, 'delivery accepted');
    });

    test('speak allows reminder type', () async {
      await service.speak('reminder msg', type: VoiceAnnouncementType.reminder);

      expect(service.state.lastSpokenText, 'reminder msg');
    });

    test('speak without type always speaks', () async {
      await service.speak('plain text');

      expect(service.state.lastSpokenText, 'plain text');
    });

    test('stop sets isSpeaking to false', () async {
      await service.stop();
      expect(service.state.isSpeaking, false);
    });

    test('announceNewDelivery speaks correct message', () async {
      await service.announceNewDelivery(
        pharmacyName: 'Pharmacie Soleil',
        amount: '3000',
      );

      expect(service.state.lastSpokenText, contains('Pharmacie Soleil'));
      expect(service.state.lastSpokenText, contains('3000 francs'));
    });

    test('announceNavigationStart speaks correct message', () async {
      await service.announceNavigationStart(
        destination: 'Cocody',
        duration: '10 minutes',
      );

      expect(service.state.lastSpokenText, contains('Cocody'));
      expect(service.state.lastSpokenText, contains('10 minutes'));
    });

    test('announceTurn left speaks correct message', () async {
      await service.announceTurn(isLeft: true, streetName: 'Rue du Commerce');

      expect(service.state.lastSpokenText, contains('gauche'));
      expect(service.state.lastSpokenText, contains('Rue du Commerce'));
    });

    test('announceTurn right speaks correct message', () async {
      await service.announceTurn(isLeft: false, streetName: 'Avenue Houphouët');

      expect(service.state.lastSpokenText, contains('droite'));
      expect(service.state.lastSpokenText, contains('Avenue Houphouët'));
    });

    test('announceArrival speaks arrival message', () async {
      await service.announceArrival();

      expect(service.state.lastSpokenText, contains('arrivé à destination'));
    });

    test('announceDeliveryCompleted speaks correct message', () async {
      await service.announceDeliveryCompleted('5000');

      expect(service.state.lastSpokenText, contains('5000 francs'));
      expect(service.state.lastSpokenText, contains('Livraison terminée'));
    });

    test('announceEarnings daily speaks correct message', () async {
      await service.announceEarnings(amount: '8000');

      expect(service.state.lastSpokenText, contains('Gains du jour'));
      expect(service.state.lastSpokenText, contains('8000 francs'));
    });

    test('announceLowBattery speaks correct message', () async {
      await service.announceLowBattery(15);

      expect(service.state.lastSpokenText, contains('batterie faible'));
      expect(service.state.lastSpokenText, contains('15 pour cent'));
    });

    test('readStats speaks formatted statistics', () async {
      await service.readStats(
        deliveriesToday: 12,
        earningsToday: '15000',
        rating: 4.8,
      );

      expect(service.state.lastSpokenText, contains('12 livraisons'));
      expect(service.state.lastSpokenText, contains('15000 francs'));
      expect(service.state.lastSpokenText, contains('4.8'));
    });

    test('startListening does nothing when sttEnabled is false', () async {
      await service.updateSettings(const VoiceSettings(sttEnabled: false));

      await service.startListening();
      // Should not start listening
      expect(service.state.isListening, false);
    });

    test('startListening does nothing when voiceCommands is false', () async {
      await service.updateSettings(const VoiceSettings(voiceCommands: false));

      await service.startListening();
      expect(service.state.isListening, false);
    });

    test('recognized navigation command maps to startNavigation', () async {
      VoiceCommand? recognized;
      service.onCommandRecognized = (cmd) => recognized = cmd;

      await service.startListening();
      await _sendPlatformCallback(
        _sttChannel,
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'lance la navigation', 'confidence': 0.90},
          ],
          'finalResult': true,
        }),
      );

      expect(service.state.lastCommand, VoiceCommand.startNavigation);
      expect(recognized, VoiceCommand.startNavigation);
    });

    test('recognized call customer command', () async {
      VoiceCommand? recognized;
      service.onCommandRecognized = (cmd) => recognized = cmd;

      await service.startListening();
      await _sendPlatformCallback(
        _sttChannel,
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'appeler client', 'confidence': 0.92},
          ],
          'finalResult': true,
        }),
      );

      expect(service.state.lastCommand, VoiceCommand.callCustomer);
      expect(recognized, VoiceCommand.callCustomer);
    });

    test('recognized call pharmacy command', () async {
      VoiceCommand? recognized;
      service.onCommandRecognized = (cmd) => recognized = cmd;

      await service.startListening();
      await _sendPlatformCallback(
        _sttChannel,
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'appeler pharmacie', 'confidence': 0.88},
          ],
          'finalResult': true,
        }),
      );

      expect(service.state.lastCommand, VoiceCommand.callPharmacy);
      expect(recognized, VoiceCommand.callPharmacy);
    });

    test('recognized mark delivered command', () async {
      VoiceCommand? recognized;
      service.onCommandRecognized = (cmd) => recognized = cmd;

      await service.startListening();
      await _sendPlatformCallback(
        _sttChannel,
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'livré terminé', 'confidence': 0.85},
          ],
          'finalResult': true,
        }),
      );

      expect(service.state.lastCommand, VoiceCommand.markDelivered);
      expect(recognized, VoiceCommand.markDelivered);
    });

    test('recognized go online command', () async {
      VoiceCommand? recognized;
      service.onCommandRecognized = (cmd) => recognized = cmd;

      await service.startListening();
      await _sendPlatformCallback(
        _sttChannel,
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'je suis en ligne', 'confidence': 0.90},
          ],
          'finalResult': true,
        }),
      );

      expect(service.state.lastCommand, VoiceCommand.goOnline);
      expect(recognized, VoiceCommand.goOnline);
    });

    test('recognized refuse command maps to declineDelivery', () async {
      VoiceCommand? recognized;
      service.onCommandRecognized = (cmd) => recognized = cmd;

      await service.startListening();
      await _sendPlatformCallback(
        _sttChannel,
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'non je refuse', 'confidence': 0.87},
          ],
          'finalResult': true,
        }),
      );

      expect(service.state.lastCommand, VoiceCommand.declineDelivery);
      expect(recognized, VoiceCommand.declineDelivery);
    });

    test('recognized stats command maps to readStats', () async {
      VoiceCommand? recognized;
      service.onCommandRecognized = (cmd) => recognized = cmd;

      await service.startListening();
      await _sendPlatformCallback(
        _sttChannel,
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'combien de gains', 'confidence': 0.82},
          ],
          'finalResult': true,
        }),
      );

      expect(service.state.lastCommand, VoiceCommand.readStats);
      expect(recognized, VoiceCommand.readStats);
      // readStats does not produce a spoken confirmation
    });

    test('unrecognized command maps to unknown and does not speak', () async {
      VoiceCommand? recognized;
      service.onCommandRecognized = (cmd) => recognized = cmd;

      await service.startListening();
      final prevSpoken = service.state.lastSpokenText;
      await _sendPlatformCallback(
        _sttChannel,
        'textRecognition',
        jsonEncode({
          'alternates': [
            {'recognizedWords': 'blabla random words', 'confidence': 0.60},
          ],
          'finalResult': true,
        }),
      );

      expect(service.state.lastCommand, VoiceCommand.unknown);
      expect(recognized, isNull); // unknown doesn't trigger callback
      expect(service.state.lastSpokenText, prevSpoken);
    });

    test(
      'handleNavigationInstruction does nothing when announceNavigation disabled',
      () async {
        await service.updateSettings(
          const VoiceSettings(announceNavigation: false),
        );
        final prevSpoken = service.state.lastSpokenText;

        await service.handleNavigationInstruction(
          instruction: 'Turn left in 200m',
          distance: '200 m',
        );

        expect(service.state.lastSpokenText, prevSpoken);
      },
    );
  });
}
