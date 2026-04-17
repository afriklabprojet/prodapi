import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/widgets/profile/logout_button.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import '../../helpers/widget_test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  Widget buildWidget() {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: const MaterialApp(home: Scaffold(body: LogoutButton())),
    );
  }

  group('LogoutButton', () {
    testWidgets('renders logout button', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(LogoutButton), findsOneWidget);
    });

    testWidgets('shows confirmation dialog on tap', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byType(LogoutButton));
      await tester.pumpAndSettle();
      // Should show a dialog
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Icon widget', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('dialog has cancel option', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byType(LogoutButton));
      await tester.pumpAndSettle();
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('cancel dismisses dialog', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byType(LogoutButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    // ── Content assertions ──

    testWidgets('shows "Se déconnecter" button text', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Se déconnecter'), findsOneWidget);
    });

    testWidgets('shows logout icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('dialog shows "Déconnexion" title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byType(LogoutButton));
      await tester.pumpAndSettle();
      expect(find.text('Déconnexion'), findsOneWidget);
    });

    testWidgets('dialog shows confirmation message', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byType(LogoutButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('sûr'), findsOneWidget);
    });

    testWidgets('dialog has confirm button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byType(LogoutButton));
      await tester.pumpAndSettle();
      expect(find.text('Déconnecter'), findsOneWidget);
    });
  });
}
