import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/common/password_strength_indicator.dart';

void main() {
  Widget buildWidget(
    String password, {
    bool showCriteria = true,
    bool animated = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PasswordStrengthIndicator(
          password: password,
          showCriteria: showCriteria,
          animated: animated,
        ),
      ),
    );
  }

  group('PasswordStrengthIndicator', () {
    testWidgets('renders with empty password', (tester) async {
      await tester.pumpWidget(buildWidget(''));
      expect(find.byType(PasswordStrengthIndicator), findsOneWidget);
    });

    testWidgets('renders with weak password', (tester) async {
      await tester.pumpWidget(buildWidget('abc'));
      expect(find.byType(PasswordStrengthIndicator), findsOneWidget);
    });

    testWidgets('renders with medium password', (tester) async {
      await tester.pumpWidget(buildWidget('Abcdef1'));
      expect(find.byType(PasswordStrengthIndicator), findsOneWidget);
    });

    testWidgets('renders with strong password', (tester) async {
      await tester.pumpWidget(buildWidget('Abcdef1!@#Strong'));
      expect(find.byType(PasswordStrengthIndicator), findsOneWidget);
    });

    testWidgets('shows criteria when showCriteria is true', (tester) async {
      await tester.pumpWidget(buildWidget('test', showCriteria: true));
      expect(find.byType(PasswordStrengthIndicator), findsOneWidget);
    });

    // ── Strength label tests ──

    testWidgets('very weak password shows "Très faible"', (tester) async {
      // 'a' → score = 15 (lowercase only) - 10 (letters only) = 5 → <20 → Très faible
      await tester.pumpWidget(buildWidget('a'));
      await tester.pump();
      expect(find.text('Très faible'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('weak password shows "Faible"', (tester) async {
      // 'abcdefgh' → 20 (len≥8) + 15 (lowercase) - 10 (letters only) = 25 → 20..39 → Faible
      await tester.pumpWidget(buildWidget('abcdefgh'));
      await tester.pump();
      expect(find.text('Faible'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('medium password shows "Moyen"', (tester) async {
      // 'Abcdefgh' → 20 (len≥8) + 15 (lower) + 15 (upper) = 50 → 40..59 → Moyen
      await tester.pumpWidget(buildWidget('Abcdefgh'));
      await tester.pump();
      expect(find.text('Moyen'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('strong password shows "Fort"', (tester) async {
      // 'Abcdefgh1' → 20 (len≥8) + 15 (lower) + 15 (upper) + 15 (digit) = 65 → 60..79 → Fort
      await tester.pumpWidget(buildWidget('Abcdefgh1'));
      await tester.pump();
      expect(find.text('Fort'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('very strong password shows "Très fort"', (tester) async {
      // 'Abcdefgh1234!@#$' → 20+10+10 (len≥16) + 15+15+15+15 (all types) = 100 → ≥80 → Très fort
      await tester.pumpWidget(buildWidget('Abcdefgh1234!@#\$'));
      await tester.pump();
      expect(find.text('Très fort'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
    });

    // ── Criteria tests ──

    testWidgets('criteria shows 5 criteria items when password non-empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget('test'));
      await tester.pump();
      expect(find.text('Au moins 8 caractères'), findsOneWidget);
      expect(find.text('Une lettre minuscule'), findsOneWidget);
      expect(find.text('Une lettre majuscule'), findsOneWidget);
      expect(find.text('Un chiffre'), findsOneWidget);
      expect(find.textContaining('Un caractère spécial'), findsOneWidget);
    });

    testWidgets('lowercase criterion shows check when lowercase present', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget('abc'));
      await tester.pump();
      // 'abc' has lowercase → check_circle for that criterion
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('all criteria valid for strong password', (tester) async {
      // 'Abcdefgh1!' has all 5 criteria met
      await tester.pumpWidget(buildWidget('Abcdefgh1!'));
      await tester.pump();
      // 5 criteria check_circle icons + 1 strength icon (check_circle for Fort)
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      // No unfulfilled criteria circles
      expect(find.byIcon(Icons.circle_outlined), findsNothing);
    });

    testWidgets('length criterion invalid for short password', (tester) async {
      await tester.pumpWidget(buildWidget('Ab1!'));
      await tester.pump();
      // 'Ab1!' has 4 chars → length criterion not met → circle_outlined
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
      // Other 4 criteria met → check_circle
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('empty password shows no criteria', (tester) async {
      await tester.pumpWidget(buildWidget(''));
      await tester.pump();
      // Criteria list not shown for empty password
      expect(find.text('Au moins 8 caractères'), findsNothing);
    });

    // ── showCriteria false ──

    testWidgets('hides criteria list when showCriteria is false', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget('test123', showCriteria: false));
      await tester.pump();
      expect(find.text('Au moins 8 caractères'), findsNothing);
      expect(find.text('Une lettre minuscule'), findsNothing);
    });

    // ── animated false ──

    testWidgets('renders non-animated bar when animated is false', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget('Abcdefg1', animated: false));
      await tester.pump();
      expect(find.text('Fort'), findsOneWidget);
      // No AnimatedContainer should be used
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    // ── Dark mode ──

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: PasswordStrengthIndicator(password: 'test')),
        ),
      );
      await tester.pump();
      expect(find.text('Très faible'), findsOneWidget);
    });
  });
}
