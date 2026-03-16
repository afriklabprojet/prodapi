import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/voice_service.dart';

void main() {
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
      expect(VoiceMessages.connectionLost(), contains('connexion internet perdue'));
    });

    test('connectionRestored should have correct message', () {
      expect(VoiceMessages.connectionRestored(), contains('Connexion internet restaurée'));
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
      const newSettings = VoiceSettings(
        speechRate: 0.7,
        language: 'en-US',
      );

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
  });
}
