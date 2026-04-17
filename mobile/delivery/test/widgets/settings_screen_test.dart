import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/settings_screen.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': true,
      'navigation_app': 'google_maps',
      'language': 'fr',
    });
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: commonWidgetTestOverrides(),
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen', () {
    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Paramètres'), findsOneWidget);
    });

    testWidgets('displays Apparence section with theme', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Affichage & Navigation'), findsOneWidget);
      expect(find.text('Thème'), findsOneWidget);
    });

    testWidgets('displays Préférences section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Affichage & Navigation'), findsOneWidget);
    });

    testWidgets('displays Compte section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Compte & Sécurité'), 200, scrollable: listView);
      
      expect(find.text('Compte & Sécurité'), findsOneWidget);
      expect(find.text('Changer le mot de passe'), findsOneWidget);
      expect(find.text('Langue de l\'application'), findsOneWidget);
    });

    testWidgets('displays Sécurité section with biometric card', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Connexion biométrique'), 200, scrollable: listView);

      expect(find.text('Compte & Sécurité'), findsOneWidget);
      expect(find.text('Connexion biométrique'), findsOneWidget);
    });

    testWidgets('displays Aide & Support section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Scroll to bottom
      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Aide & Support'), 200, scrollable: listView);

      expect(find.text('Aide & Support'), findsOneWidget);
      expect(find.text('Mes demandes de support'), findsOneWidget);
    });

    testWidgets('displays Informations section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Politique de confidentialité'), 200, scrollable: listView);

      expect(find.text('Informations'), findsOneWidget);
      expect(find.text('Politique de confidentialité'), findsOneWidget);
      expect(find.text('Conditions d\'utilisation'), findsOneWidget);
    });

    testWidgets('displays version number', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.textContaining('Version'), 200, scrollable: listView);

      expect(find.textContaining('Version'), findsOneWidget);
    });

    testWidgets('notification preferences card is displayed', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsAtLeastNWidgets(1));
    });

    testWidgets('language selector shows current language', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Langue de l\'application'), 200, scrollable: listView);

      expect(find.text('Français'), findsOneWidget);
    });

    testWidgets('tapping language opens bottom sheet', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Langue de l\'application'), 300, scrollable: listView);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Langue de l\'application'));
      await tester.pumpAndSettle();

      expect(find.text('Langue'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('tapping theme opens theme selector', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thème'));
      await tester.pumpAndSettle();

      expect(find.text('Choisir le thème'), findsOneWidget);
      expect(find.text('Système'), findsOneWidget);
      expect(find.text('Sombre'), findsOneWidget);
    });

    testWidgets('navigation app selector shows Google Maps', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Google Maps'), findsOneWidget);
    });

    testWidgets('tapping navigation app opens bottom sheet', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Application de Navigation'));
      await tester.pumpAndSettle();

      expect(find.text('Choisir l\'application GPS'), findsOneWidget);
      expect(find.text('Waze'), findsOneWidget);
      expect(find.text('Apple Maps'), findsOneWidget);
    });

    testWidgets('selecting Waze persists choice', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Application de Navigation'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Waze'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('navigation_app'), 'waze');
    });

    testWidgets('displays Optimisation section', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Zone dangereuse'), 200, scrollable: listView);

      expect(find.text('Zone dangereuse'), findsOneWidget);
      expect(find.text('Supprimer mon compte'), findsOneWidget);
    });

    testWidgets('displays Centre d\'aide FAQ action', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Centre d\'aide (FAQ)'), 200, scrollable: listView);

      expect(find.text('Centre d\'aide (FAQ)'), findsOneWidget);
    });

    testWidgets('displays Signaler un problème action', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Signaler un problème'), 200, scrollable: listView);

      expect(find.text('Signaler un problème'), findsOneWidget);
    });

    testWidgets('biometric card shows unavailable on test device', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Connexion biométrique'), 200, scrollable: listView);

      expect(find.text('Connexion biométrique'), findsOneWidget);
      expect(find.text('Non disponible sur cet appareil'), findsOneWidget);
    });

    testWidgets('selecting language English persists', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final listView = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Langue de l\'application'), 300, scrollable: listView);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Langue de l\'application'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language'), 'en');
    });

    testWidgets('back button is present', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);
    });
  });
}
