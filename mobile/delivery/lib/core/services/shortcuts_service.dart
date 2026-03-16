import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:quick_actions/quick_actions.dart';

/// Type de raccourci
enum ShortcutType {
  goOnline,
  goOffline,
  viewEarnings,
  viewStats,
  startDelivery,
  callSupport,
  viewHistory,
  shareLocation,
}

/// Raccourci de l'application
class AppShortcut {
  final String id;
  final ShortcutType type;
  final String title;
  final String subtitle;
  final String? iconName;
  final bool isEnabled;
  final String? siriPhrase;

  const AppShortcut({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.iconName,
    this.isEnabled = true,
    this.siriPhrase,
  });

  AppShortcut copyWith({
    bool? isEnabled,
    String? siriPhrase,
  }) {
    return AppShortcut(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      iconName: iconName,
      isEnabled: isEnabled ?? this.isEnabled,
      siriPhrase: siriPhrase ?? this.siriPhrase,
    );
  }
}

/// Raccourcis prédéfinis
const List<AppShortcut> predefinedShortcuts = [
  AppShortcut(
    id: 'go_online',
    type: ShortcutType.goOnline,
    title: 'Passer en ligne',
    subtitle: 'Commencer à recevoir des livraisons',
    iconName: 'play_circle_filled',
    siriPhrase: 'Passer en ligne sur DR Pharma',
  ),
  AppShortcut(
    id: 'go_offline',
    type: ShortcutType.goOffline,
    title: 'Passer hors-ligne',
    subtitle: 'Arrêter de recevoir des livraisons',
    iconName: 'pause_circle_filled',
    siriPhrase: 'Passer hors-ligne sur DR Pharma',
  ),
  AppShortcut(
    id: 'view_earnings',
    type: ShortcutType.viewEarnings,
    title: 'Voir mes gains',
    subtitle: 'Afficher les gains du jour',
    iconName: 'attach_money',
    siriPhrase: 'Afficher mes gains DR Pharma',
  ),
  AppShortcut(
    id: 'view_stats',
    type: ShortcutType.viewStats,
    title: 'Mes statistiques',
    subtitle: 'Voir mes statistiques de livraison',
    iconName: 'bar_chart',
    siriPhrase: 'Statistiques DR Pharma',
  ),
  AppShortcut(
    id: 'view_history',
    type: ShortcutType.viewHistory,
    title: 'Historique',
    subtitle: 'Voir l\'historique des livraisons',
    iconName: 'history',
    siriPhrase: 'Historique des livraisons DR Pharma',
  ),
  AppShortcut(
    id: 'call_support',
    type: ShortcutType.callSupport,
    title: 'Appeler le support',
    subtitle: 'Contacter l\'assistance DR Pharma',
    iconName: 'support_agent',
    siriPhrase: 'Appeler support DR Pharma',
  ),
];

/// État du service de raccourcis
class ShortcutsState {
  final List<AppShortcut> shortcuts;
  final bool siriEnabled;
  final bool quickActionsEnabled;
  final String? lastTriggeredShortcut;

  const ShortcutsState({
    this.shortcuts = const [],
    this.siriEnabled = false,
    this.quickActionsEnabled = true,
    this.lastTriggeredShortcut,
  });

  ShortcutsState copyWith({
    List<AppShortcut>? shortcuts,
    bool? siriEnabled,
    bool? quickActionsEnabled,
    String? lastTriggeredShortcut,
  }) {
    return ShortcutsState(
      shortcuts: shortcuts ?? this.shortcuts,
      siriEnabled: siriEnabled ?? this.siriEnabled,
      quickActionsEnabled: quickActionsEnabled ?? this.quickActionsEnabled,
      lastTriggeredShortcut: lastTriggeredShortcut ?? this.lastTriggeredShortcut,
    );
  }
}

/// Canal pour les raccourcis natifs
class ShortcutsChannel {
  static const _channel = MethodChannel('com.drpharma.courier/shortcuts');

  /// Enregistrer un raccourci Siri
  static Future<bool> registerSiriShortcut({
    required String identifier,
    required String title,
    required String phrase,
  }) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod('registerSiriShortcut', {
        'identifier': identifier,
        'title': title,
        'suggestedPhrase': phrase,
      });
      return result == true;
    } catch (e) {
      debugPrint('Error registering Siri shortcut: $e');
      return false;
    }
  }

  /// Supprimer un raccourci Siri
  static Future<bool> removeSiriShortcut(String identifier) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod('removeSiriShortcut', {
        'identifier': identifier,
      });
      return result == true;
    } catch (e) {
      debugPrint('Error removing Siri shortcut: $e');
      return false;
    }
  }

  /// Vérifier si Siri est disponible
  static Future<bool> isSiriAvailable() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod('isSiriAvailable');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Enregistrer un raccourci App Shortcut (Android)
  static Future<bool> registerAppShortcut({
    required String id,
    required String shortLabel,
    required String longLabel,
    required String iconRes,
  }) async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod('registerAppShortcut', {
        'id': id,
        'shortLabel': shortLabel,
        'longLabel': longLabel,
        'iconRes': iconRes,
      });
      return result == true;
    } catch (e) {
      debugPrint('Error registering app shortcut: $e');
      return false;
    }
  }

  /// Supprimer tous les raccourcis dynamiques (Android)
  static Future<void> clearDynamicShortcuts() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('clearDynamicShortcuts');
    } catch (e) {
      debugPrint('Error clearing shortcuts: $e');
    }
  }
}

/// Service de raccourcis Siri/Android
class ShortcutsService extends StateNotifier<ShortcutsState> {
  final QuickActions _quickActions = const QuickActions();
  Function(ShortcutType)? onShortcutTriggered;

  ShortcutsService() : super(ShortcutsState(
    shortcuts: predefinedShortcuts,
  )) {
    _init();
  }

  Future<void> _init() async {
    // Vérifier disponibilité Siri sur iOS
    if (Platform.isIOS) {
      final siriAvailable = await ShortcutsChannel.isSiriAvailable();
      state = state.copyWith(siriEnabled: siriAvailable);
    }

    // Initialiser Quick Actions (3D Touch / App Shortcuts)
    await _setupQuickActions();

    // Écouter les callbacks
    _quickActions.initialize((type) {
      _handleQuickAction(type);
    });
  }

  Future<void> _setupQuickActions() async {
    if (!state.quickActionsEnabled) return;

    final enabledShortcuts = state.shortcuts.where((s) => s.isEnabled).take(4);

    final items = enabledShortcuts.map((s) {
      return ShortcutItem(
        type: s.id,
        localizedTitle: s.title,
        icon: Platform.isIOS ? s.iconName : null,
      );
    }).toList();

    await _quickActions.setShortcutItems(items);

    // Sur Android, enregistrer aussi les App Shortcuts dynamiques
    if (Platform.isAndroid) {
      for (final shortcut in enabledShortcuts) {
        await ShortcutsChannel.registerAppShortcut(
          id: shortcut.id,
          shortLabel: shortcut.title,
          longLabel: shortcut.subtitle,
          iconRes: 'ic_${shortcut.iconName}',
        );
      }
    }
  }

  void _handleQuickAction(String type) {
    state = state.copyWith(lastTriggeredShortcut: type);

    final shortcut = state.shortcuts.firstWhere(
      (s) => s.id == type,
      orElse: () => predefinedShortcuts.first,
    );

    onShortcutTriggered?.call(shortcut.type);
  }

  /// Enregistrer un raccourci Siri
  Future<bool> registerSiriShortcut(AppShortcut shortcut) async {
    if (!Platform.isIOS || shortcut.siriPhrase == null) return false;

    final success = await ShortcutsChannel.registerSiriShortcut(
      identifier: shortcut.id,
      title: shortcut.title,
      phrase: shortcut.siriPhrase!,
    );

    if (success) {
      // Mettre à jour l'état
      final updatedShortcuts = state.shortcuts.map((s) {
        if (s.id == shortcut.id) {
          return s.copyWith(isEnabled: true);
        }
        return s;
      }).toList();

      state = state.copyWith(shortcuts: updatedShortcuts);
    }

    return success;
  }

  /// Supprimer un raccourci Siri
  Future<bool> removeSiriShortcut(String shortcutId) async {
    if (!Platform.isIOS) return false;

    final success = await ShortcutsChannel.removeSiriShortcut(shortcutId);

    if (success) {
      final updatedShortcuts = state.shortcuts.map((s) {
        if (s.id == shortcutId) {
          return s.copyWith(siriPhrase: null);
        }
        return s;
      }).toList();

      state = state.copyWith(shortcuts: updatedShortcuts);
    }

    return success;
  }

  /// Activer/désactiver un raccourci
  Future<void> setShortcutEnabled(String shortcutId, bool enabled) async {
    final updatedShortcuts = state.shortcuts.map((s) {
      if (s.id == shortcutId) {
        return s.copyWith(isEnabled: enabled);
      }
      return s;
    }).toList();

    state = state.copyWith(shortcuts: updatedShortcuts);
    await _setupQuickActions();
  }

  /// Rafraîchir les Quick Actions
  Future<void> refreshQuickActions() async {
    await _setupQuickActions();
  }

  /// Activer/désactiver Quick Actions
  Future<void> setQuickActionsEnabled(bool enabled) async {
    state = state.copyWith(quickActionsEnabled: enabled);

    if (enabled) {
      await _setupQuickActions();
    } else {
      await _quickActions.clearShortcutItems();
      if (Platform.isAndroid) {
        await ShortcutsChannel.clearDynamicShortcuts();
      }
    }
  }

  /// Donner un raccourci pour une action récente
  Future<void> donateShortcut(ShortcutType type) async {
    if (!Platform.isIOS) return;

    final shortcut = state.shortcuts.firstWhere(
      (s) => s.type == type,
      orElse: () => predefinedShortcuts.first,
    );

    if (shortcut.siriPhrase != null) {
      // Sur iOS, cela suggère le raccourci à Siri
      await ShortcutsChannel.registerSiriShortcut(
        identifier: shortcut.id,
        title: shortcut.title,
        phrase: shortcut.siriPhrase!,
      );
    }
  }

  /// Obtenir les raccourcis actifs
  List<AppShortcut> get enabledShortcuts {
    return state.shortcuts.where((s) => s.isEnabled).toList();
  }

  /// Obtenir les raccourcis Siri (iOS uniquement)
  List<AppShortcut> get siriShortcuts {
    if (!Platform.isIOS) return [];
    return state.shortcuts.where((s) => s.siriPhrase != null).toList();
  }
}

/// Provider pour le service de raccourcis
final shortcutsServiceProvider = StateNotifierProvider<ShortcutsService, ShortcutsState>((ref) {
  return ShortcutsService();
});

/// Provider pour les raccourcis actifs
final enabledShortcutsProvider = Provider<List<AppShortcut>>((ref) {
  return ref.watch(shortcutsServiceProvider).shortcuts.where((s) => s.isEnabled).toList();
});

/// Provider pour Siri disponible
final siriEnabledProvider = Provider<bool>((ref) {
  return ref.watch(shortcutsServiceProvider).siriEnabled;
});

/// Provider pour le dernier raccourci déclenché
final lastTriggeredShortcutProvider = Provider<String?>((ref) {
  return ref.watch(shortcutsServiceProvider).lastTriggeredShortcut;
});
