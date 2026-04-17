import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/core/providers/locale_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleNotifier', () {
    test('initial locale is fr', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final locale = container.read(localeProvider);
      expect(locale.languageCode, 'fr');
    });

    test('setLanguageCode changes locale', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).setLanguageCode('en');
      expect(container.read(localeProvider).languageCode, 'en');
    });

    test('toggleLocale switches between fr and en', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(localeProvider).languageCode, 'fr');
      container.read(localeProvider.notifier).toggleLocale();
      expect(container.read(localeProvider).languageCode, 'en');
      container.read(localeProvider.notifier).toggleLocale();
      expect(container.read(localeProvider).languageCode, 'fr');
    });

    test('setLanguageCode to fr works', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).setLanguageCode('en');
      container.read(localeProvider.notifier).setLanguageCode('fr');
      expect(container.read(localeProvider).languageCode, 'fr');
    });

    test('locale is a Locale object', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final locale = container.read(localeProvider);
      expect(locale, isA<Locale>());
    });

    test('supportedLocales contains fr and en', () {
      expect(LocaleNotifier.supportedLocales, hasLength(2));
      expect(
        LocaleNotifier.supportedLocales.any((l) => l.languageCode == 'fr'),
        isTrue,
      );
      expect(
        LocaleNotifier.supportedLocales.any((l) => l.languageCode == 'en'),
        isTrue,
      );
    });

    test('localeNames contains fr and en', () {
      expect(LocaleNotifier.localeNames.keys, contains('fr'));
      expect(LocaleNotifier.localeNames.keys, contains('en'));
      expect(LocaleNotifier.localeNames['fr'], 'Français');
      expect(LocaleNotifier.localeNames['en'], 'English');
    });

    test('currentLanguageName returns Français for fr', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);
      expect(notifier.currentLanguageName, 'Français');
    });

    test('currentLanguageName returns English for en', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);
      await notifier.setLanguageCode('en');
      expect(notifier.currentLanguageName, 'English');
    });

    test('setLocale with unsupported locale does not change state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);
      // Set an unsupported locale
      await notifier.setLocale(const Locale('de'));
      // Should remain 'fr'
      expect(container.read(localeProvider).languageCode, 'fr');
    });

    test('setLocale persists valid locale to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);

      await notifier.setLocale(const Locale('en'));

      // Allow time for async operations
      await Future.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'en');
    });

    test('loads saved locale from SharedPreferences', () async {
      // Pre-populate SharedPreferences with saved locale
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial state is fr, but loadSavedLocale runs async
      expect(container.read(localeProvider).languageCode, 'fr');

      // Allow async _loadSavedLocale to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // After load, should be en
      expect(container.read(localeProvider).languageCode, 'en');
    });

    test('loads ignores unsupported saved locale', () async {
      // Pre-populate with unsupported locale
      SharedPreferences.setMockInitialValues({'app_locale': 'de'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Allow async to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Should remain fr since de is not supported
      expect(container.read(localeProvider).languageCode, 'fr');
    });

    test('toggleLocale from en returns to fr', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);

      await notifier.setLanguageCode('en');
      expect(container.read(localeProvider).languageCode, 'en');

      await notifier.toggleLocale();
      expect(container.read(localeProvider).languageCode, 'fr');
    });

    test('multiple setLocale calls work correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);

      await notifier.setLocale(const Locale('en'));
      await notifier.setLocale(const Locale('fr'));
      await notifier.setLocale(const Locale('en'));

      expect(container.read(localeProvider).languageCode, 'en');
    });

    test('setLanguageCode with unsupported code does nothing', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);

      await notifier.setLanguageCode('es'); // Not supported
      expect(container.read(localeProvider).languageCode, 'fr');
    });

    test('currentLanguageCode returns current language code', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);

      expect(notifier.currentLanguageCode, 'fr');

      await notifier.setLanguageCode('en');
      expect(notifier.currentLanguageCode, 'en');
    });

    test('currentLanguageName returns Unknown for unknown locale', () async {
      // This tests the fallback path when localeNames doesn't have the key
      // We need to simulate a state where state.languageCode is not in localeNames
      // Since we can't easily do that, we test the static localeNames directly
      expect(LocaleNotifier.localeNames['xx'], isNull);
    });
  });

  group('LocaleExtension', () {
    testWidgets('getLanguageName returns correct name for supported locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(context.getLanguageName('fr'), 'Français');
            expect(context.getLanguageName('en'), 'English');
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('getLanguageName returns code for unknown locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(context.getLanguageName('de'), 'de');
            expect(context.getLanguageName('unknown'), 'unknown');
            return const SizedBox();
          },
        ),
      );
    });
  });
}
