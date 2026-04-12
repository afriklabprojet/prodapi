import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/settings/settings_widgets.dart';

void main() {
  group('SettingsCard', () {
    testWidgets('renders children in a card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsCard(
              children: [
                ListTile(title: Text('Option 1')),
                ListTile(title: Text('Option 2')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SettingsCard), findsOneWidget);
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
    });

    testWidgets('has rounded corners', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsCard(children: [Text('Test')])),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));
    });
  });

  group('SettingsSectionHeader', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsSectionHeader(title: 'Apparence')),
        ),
      );

      expect(find.text('Apparence'), findsOneWidget);
    });

    testWidgets('applies correct text style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsSectionHeader(title: 'Notifications')),
        ),
      );

      final text = tester.widget<Text>(find.text('Notifications'));
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(text.style?.fontSize, 13);
    });
  });

  group('SettingsActionTile', () {
    testWidgets('renders with icon and title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsActionTile(
              icon: Icons.language,
              title: 'Langue',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Langue'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('shows default trailing arrow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsActionTile(icon: Icons.help, title: 'Aide'),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('shows custom trailing widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsActionTile(
              icon: Icons.notifications,
              title: 'Notifications',
              trailing: Icon(Icons.check),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('applies custom title color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsActionTile(
              icon: Icons.delete,
              title: 'Supprimer',
              titleColor: Colors.red,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Supprimer'));
      expect(text.style?.color, Colors.red);
    });

    testWidgets('calls onTap when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsActionTile(
              icon: Icons.settings,
              title: 'Paramètres',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Paramètres'));
      expect(tapped, isTrue);
    });
  });

  group('SettingsSwitchTile', () {
    testWidgets('renders with icon, title and switch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSwitchTile(
              icon: Icons.fingerprint,
              title: 'Biométrie',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Biométrie'), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('renders with subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSwitchTile(
              icon: Icons.dark_mode,
              title: 'Mode sombre',
              subtitle: 'Activer le thème sombre',
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Activer le thème sombre'), findsOneWidget);
    });

    testWidgets('switch reflects value state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSwitchTile(
              icon: Icons.notifications,
              title: 'Notifications',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('calls onChanged when toggled', (tester) async {
      bool? newValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSwitchTile(
              icon: Icons.volume_up,
              title: 'Son',
              value: false,
              onChanged: (value) => newValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      expect(newValue, isTrue);
    });
  });

  group('SettingsSelectionOption', () {
    testWidgets('renders with icon and title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSelectionOption(
              icon: Icons.map,
              title: 'Google Maps',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Google Maps'), findsOneWidget);
      expect(find.byIcon(Icons.map), findsOneWidget);
    });

    testWidgets('shows check icon when selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSelectionOption(
              icon: Icons.navigation,
              title: 'Waze',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not show check when not selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSelectionOption(
              icon: Icons.apple,
              title: 'Apple Maps',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('calls onTap when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSelectionOption(
              icon: Icons.map,
              title: 'Maps',
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Maps'));
      expect(tapped, isTrue);
    });
  });

  group('SettingsVersionLabel', () {
    testWidgets('renders version text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsVersionLabel(version: '1.2.3+45')),
        ),
      );

      expect(find.text('Version 1.2.3+45'), findsOneWidget);
    });

    testWidgets('centers the text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsVersionLabel(version: '1.0.0')),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('applies grey color to text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsVersionLabel(version: '2.0.0')),
        ),
      );

      final text = tester.widget<Text>(find.text('Version 2.0.0'));
      expect(text.style?.color, Colors.grey);
    });
  });
}
