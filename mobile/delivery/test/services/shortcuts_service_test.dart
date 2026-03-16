import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/shortcuts_service.dart';

void main() {
  group('ShortcutType', () {
    test('should have all expected values', () {
      expect(ShortcutType.values.length, 8);
      expect(ShortcutType.goOnline.index, 0);
      expect(ShortcutType.goOffline.index, 1);
      expect(ShortcutType.viewEarnings.index, 2);
      expect(ShortcutType.viewStats.index, 3);
      expect(ShortcutType.startDelivery.index, 4);
      expect(ShortcutType.callSupport.index, 5);
      expect(ShortcutType.viewHistory.index, 6);
      expect(ShortcutType.shareLocation.index, 7);
    });
  });

  group('AppShortcut', () {
    test('should create with required properties', () {
      const shortcut = AppShortcut(
        id: 'test_shortcut',
        type: ShortcutType.goOnline,
        title: 'Go Online',
        subtitle: 'Start receiving deliveries',
      );

      expect(shortcut.id, 'test_shortcut');
      expect(shortcut.type, ShortcutType.goOnline);
      expect(shortcut.title, 'Go Online');
      expect(shortcut.subtitle, 'Start receiving deliveries');
      expect(shortcut.iconName, isNull);
      expect(shortcut.isEnabled, true);
      expect(shortcut.siriPhrase, isNull);
    });

    test('should create with all optional properties', () {
      const shortcut = AppShortcut(
        id: 'full_shortcut',
        type: ShortcutType.viewEarnings,
        title: 'Voir mes gains',
        subtitle: 'Afficher les gains du jour',
        iconName: 'attach_money',
        isEnabled: true,
        siriPhrase: 'Afficher mes gains DR Pharma',
      );

      expect(shortcut.iconName, 'attach_money');
      expect(shortcut.siriPhrase, 'Afficher mes gains DR Pharma');
    });

    test('copyWith should update specified fields', () {
      const shortcut = AppShortcut(
        id: 'test',
        type: ShortcutType.goOnline,
        title: 'Test',
        subtitle: 'Test subtitle',
      );

      final updated = shortcut.copyWith(
        isEnabled: false,
        siriPhrase: 'New phrase',
      );

      expect(updated.isEnabled, false);
      expect(updated.siriPhrase, 'New phrase');
      // Others should remain unchanged
      expect(updated.id, 'test');
      expect(updated.type, ShortcutType.goOnline);
      expect(updated.title, 'Test');
    });
  });

  group('predefinedShortcuts', () {
    test('should have multiple shortcuts', () {
      expect(predefinedShortcuts.length, greaterThanOrEqualTo(6));
    });

    test('each shortcut should have unique id', () {
      final ids = predefinedShortcuts.map((s) => s.id).toSet();
      expect(ids.length, predefinedShortcuts.length);
    });

    test('should have go_online shortcut', () {
      final goOnline = predefinedShortcuts.firstWhere(
        (s) => s.id == 'go_online',
        orElse: () => throw Exception('go_online shortcut not found'),
      );
      expect(goOnline.type, ShortcutType.goOnline);
      expect(goOnline.title, 'Passer en ligne');
      expect(goOnline.siriPhrase, isNotNull);
    });

    test('should have go_offline shortcut', () {
      final goOffline = predefinedShortcuts.firstWhere(
        (s) => s.id == 'go_offline',
        orElse: () => throw Exception('go_offline shortcut not found'),
      );
      expect(goOffline.type, ShortcutType.goOffline);
      expect(goOffline.title, 'Passer hors-ligne');
    });

    test('should have view_earnings shortcut', () {
      final viewEarnings = predefinedShortcuts.firstWhere(
        (s) => s.id == 'view_earnings',
        orElse: () => throw Exception('view_earnings shortcut not found'),
      );
      expect(viewEarnings.type, ShortcutType.viewEarnings);
      expect(viewEarnings.title, 'Voir mes gains');
    });

    test('should have view_stats shortcut', () {
      final viewStats = predefinedShortcuts.firstWhere(
        (s) => s.id == 'view_stats',
        orElse: () => throw Exception('view_stats shortcut not found'),
      );
      expect(viewStats.type, ShortcutType.viewStats);
      expect(viewStats.title, 'Mes statistiques');
    });

    test('should have view_history shortcut', () {
      final viewHistory = predefinedShortcuts.firstWhere(
        (s) => s.id == 'view_history',
        orElse: () => throw Exception('view_history shortcut not found'),
      );
      expect(viewHistory.type, ShortcutType.viewHistory);
      expect(viewHistory.title, 'Historique');
    });

    test('should have call_support shortcut', () {
      final callSupport = predefinedShortcuts.firstWhere(
        (s) => s.id == 'call_support',
        orElse: () => throw Exception('call_support shortcut not found'),
      );
      expect(callSupport.type, ShortcutType.callSupport);
      expect(callSupport.title, 'Appeler le support');
    });

    test('all shortcuts should have Siri phrases', () {
      for (final shortcut in predefinedShortcuts) {
        expect(
          shortcut.siriPhrase, 
          isNotNull, 
          reason: '${shortcut.id} should have a Siri phrase',
        );
      }
    });
  });

  group('ShortcutsState', () {
    test('should create with default values', () {
      const state = ShortcutsState();

      expect(state.shortcuts, isEmpty);
      expect(state.siriEnabled, false);
      expect(state.quickActionsEnabled, true);
      expect(state.lastTriggeredShortcut, isNull);
    });

    test('should create with shortcuts', () {
      final state = ShortcutsState(
        shortcuts: predefinedShortcuts,
      );

      expect(state.shortcuts.length, predefinedShortcuts.length);
    });

    test('copyWith should update specified fields', () {
      const state = ShortcutsState();

      final updated = state.copyWith(
        siriEnabled: true,
        lastTriggeredShortcut: 'go_online',
      );

      expect(updated.siriEnabled, true);
      expect(updated.lastTriggeredShortcut, 'go_online');
      // Others should remain unchanged
      expect(updated.quickActionsEnabled, true);
    });

    test('should track shortcuts list', () {
      final shortcuts = [
        const AppShortcut(
          id: 'test1',
          type: ShortcutType.goOnline,
          title: 'Test 1',
          subtitle: 'Subtitle 1',
        ),
        const AppShortcut(
          id: 'test2',
          type: ShortcutType.goOffline,
          title: 'Test 2',
          subtitle: 'Subtitle 2',
        ),
      ];

      final state = ShortcutsState(shortcuts: shortcuts);

      expect(state.shortcuts.length, 2);
      expect(state.shortcuts[0].id, 'test1');
      expect(state.shortcuts[1].id, 'test2');
    });
  });
}
