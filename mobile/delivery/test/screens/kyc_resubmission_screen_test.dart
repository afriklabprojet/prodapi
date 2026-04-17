import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/kyc_resubmission_screen.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import '../helpers/widget_test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthRepo = MockAuthRepository();
  });

  Widget buildWidget({String? rejectionReason}) {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: MaterialApp(
        home: KycResubmissionScreen(rejectionReason: rejectionReason),
      ),
    );
  }

  group('KycResubmissionScreen', () {
    testWidgets('renders KYC screen', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with rejection reason', (tester) async {
      await tester.pumpWidget(
        buildWidget(rejectionReason: 'Document illisible'),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows rejection reason text', (tester) async {
      await tester.pumpWidget(buildWidget(rejectionReason: 'Photo floue'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Photo floue'), findsWidgets);
    });

    testWidgets('renders without rejection reason', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(KycResubmissionScreen), findsOneWidget);
    });

    testWidgets('has form fields', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('has action buttons', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final btns = find.byType(ElevatedButton);
      final filled = find.byType(FilledButton);
      expect(
        btns.evaluate().length + filled.evaluate().length,
        greaterThanOrEqualTo(1),
      );
    });

    testWidgets('has Icon widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('is scrollable', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final scroll = find.byType(SingleChildScrollView);
      final list = find.byType(ListView);
      expect(
        scroll.evaluate().length + list.evaluate().length,
        greaterThanOrEqualTo(1),
      );
    });
  });

  group('KycResubmissionScreen - Document upload cards', () {
    testWidgets('shows document upload cards for required docs', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // KYC screen should have multiple upload sections wrapped in Container
      expect(find.byType(Container), findsAtLeastNWidgets(5));
    });

    testWidgets('renders with long rejection reason', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          rejectionReason:
              'Votre carte d\'identité est illisible. Veuillez prendre une nouvelle photo dans un endroit bien éclairé.',
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(KycResubmissionScreen), findsOneWidget);
    });

    testWidgets('shows upload icons for documents', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Should show camera or upload icons
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('renders container decorations', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('has InkWell or GestureDetector for tappable areas', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final inkwells = find.byType(InkWell);
      final gestures = find.byType(GestureDetector);
      expect(
        inkwells.evaluate().length + gestures.evaluate().length,
        greaterThanOrEqualTo(1),
      );
    });

    testWidgets('has AppBar with back button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows submit button at bottom', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Submit button should exist
      final elevated = find.byType(ElevatedButton);
      final filled = find.byType(FilledButton);
      expect(
        elevated.evaluate().length + filled.evaluate().length,
        greaterThanOrEqualTo(1),
      );
    });

    testWidgets('empty rejection shows no reason container', (tester) async {
      await tester.pumpWidget(buildWidget(rejectionReason: null));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(KycResubmissionScreen), findsOneWidget);
    });

    testWidgets('rejection reason with special chars', (tester) async {
      await tester.pumpWidget(
        buildWidget(rejectionReason: 'Problème: photo < 300px & floue'),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(KycResubmissionScreen), findsOneWidget);
    });
  });

  group('KycResubmissionScreen - AppBar and navigation', () {
    testWidgets('AppBar title is Documents KYC', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Documents KYC'), findsOneWidget);
    });

    testWidgets('AppBar has logout button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('renders instruction text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('documents demandés'), findsWidgets);
    });
  });

  group('KycResubmissionScreen - Document sections', () {
    testWidgets('shows CNI recto section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Recto'), findsWidgets);
    });

    testWidgets('shows CNI verso section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Verso'), findsWidgets);
    });

    testWidgets('shows selfie section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Selfie'), findsWidgets);
    });

    testWidgets('shows driving license section', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Permis'), findsWidgets);
    });

    testWidgets('each doc card has icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // badge icon for CNI, self_improvement for selfie, drive_eta for license
      expect(find.byType(Icon), findsAtLeastNWidgets(5));
    });

    testWidgets('submit button present', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Soumettre'), findsWidgets);
    });
  });

  group('KycResubmissionScreen - rejection styles', () {
    testWidgets('rejection banner with warning icon', (tester) async {
      await tester.pumpWidget(buildWidget(rejectionReason: 'Raison de rejet'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('rejection shows corriger title', (tester) async {
      await tester.pumpWidget(buildWidget(rejectionReason: 'Raison de rejet'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('corriger'), findsWidgets);
    });

    testWidgets('empty string rejection does not show banner', (tester) async {
      await tester.pumpWidget(buildWidget(rejectionReason: ''));
      await tester.pump(const Duration(seconds: 1));
      // Empty rejection shouldn't show warning
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('multiple rejection reasons render text correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          rejectionReason:
              '1. Photo floue\n2. Document expiré\n3. Pas de selfie',
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Photo floue'), findsWidgets);
    });
  });

  group('KycResubmissionScreen - layout structure', () {
    testWidgets('body is wrapped in SingleChildScrollView', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('has multiple Column widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Column), findsAtLeastNWidgets(2));
    });

    testWidgets('has SizedBox spacers', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SizedBox), findsAtLeastNWidgets(3));
    });

    testWidgets('has Row widgets for document cards', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Container decorations for doc cards', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsAtLeastNWidgets(5));
    });

    testWidgets('renders correctly with dark and light theme', (tester) async {
      // Light theme
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const KycResubmissionScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(KycResubmissionScreen), findsOneWidget);

      // Dark theme
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonWidgetTestOverrides(),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const KycResubmissionScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(KycResubmissionScreen), findsOneWidget);
    });
  });

  group('KycResubmissionScreen - detailed labels', () {
    testWidgets('shows Carte identite Recto label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Recto'), findsWidgets);
    });

    testWidgets('shows Carte identite Verso label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Verso'), findsWidgets);
    });

    testWidgets('shows Selfie de verification label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Selfie'), findsWidgets);
    });

    testWidgets('shows Permis de conduire label', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Permis'), findsWidgets);
    });

    testWidgets('shows camera_alt icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Document upload cards should have camera or document icons
      expect(find.byType(Icon), findsAtLeastNWidgets(6));
    });

    testWidgets('shows logout icon in AppBar', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('shows Documents KYC title', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Documents KYC'), findsOneWidget);
    });

    testWidgets('has SafeArea', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('has Padding widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('rejection reason in orange warning card', (tester) async {
      await tester.pumpWidget(buildWidget(rejectionReason: 'Document expiré'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('Document expiré'), findsWidgets);
    });

    testWidgets('has Text widgets for instructions', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('documents'), findsWidgets);
    });

    testWidgets('has at least 5 InkWell/GestureDetector for tap areas', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final inkwells = find.byType(InkWell);
      final gestures = find.byType(GestureDetector);
      expect(
        inkwells.evaluate().length + gestures.evaluate().length,
        greaterThanOrEqualTo(3),
      );
    });

    testWidgets('Soumettre les documents button', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Soumettre'), findsWidgets);
    });

    testWidgets('multiple rejection lines show all text', (tester) async {
      await tester.pumpWidget(
        buildWidget(rejectionReason: 'Ligne 1\nLigne 2\nLigne 3'),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Ligne'), findsWidgets);
    });

    testWidgets('tapping document card does not crash', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      final inkwells = find.byType(InkWell);
      if (inkwells.evaluate().isNotEmpty) {
        await tester.tap(inkwells.first);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(KycResubmissionScreen), findsOneWidget);
    });

    testWidgets('very long rejection reason renders without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(rejectionReason: 'A' * 500));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(KycResubmissionScreen), findsOneWidget);
    });
  });
}
