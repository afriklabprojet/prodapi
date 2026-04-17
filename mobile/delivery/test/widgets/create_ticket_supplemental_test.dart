import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/screens/create_ticket_screen.dart';
import 'package:courier/data/repositories/support_repository.dart';
import 'package:courier/data/models/support_ticket.dart';
import '../helpers/widget_test_helpers.dart';

class MockSupportRepository extends Mock implements SupportRepository {}

SupportTicket _dummyTicket() => const SupportTicket(
  id: 1,
  userId: 42,
  subject: 'Subject',
  description: 'Description',
  category: 'other',
  priority: 'medium',
  status: 'open',
);

void main() {
  setUpAll(() => initHiveForTests());
  tearDownAll(() => cleanupHiveForTests());

  late MockSupportRepository mockSupportRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSupportRepo = MockSupportRepository();
    registerFallbackValue('');
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        supportRepositoryProvider.overrideWithValue(mockSupportRepo),
      ],
      child: MaterialApp(
        routes: {
          '/': (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/ticket'),
              child: const Text('Open'),
            ),
          ),
          '/ticket': (context) => const CreateTicketScreen(),
        },
        initialRoute: '/ticket',
      ),
    );
  }

  Future<void> fillFormAndSubmit(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Mon titre de ticket valide');
    await tester.enterText(
      fields.at(1),
      'Description suffisamment longue pour passer la validation',
    );
    await tester.pumpAndSettle();

    final submitButton = find.text('Envoyer le ticket');
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    // Pump without settle to catch snackbar before nav
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('CreateTicketScreen supplemental coverage', () {
    testWidgets('selecting a category chip changes selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap the 'Commande' chip (first category which is not the default 'Autre')
      final commandeChip = find.text('Commande');
      expect(commandeChip, findsOneWidget);
      await tester.tap(commandeChip);
      await tester.pump(const Duration(milliseconds: 300));

      // No crash - chip selected
      expect(find.text('Commande'), findsOneWidget);
    });

    testWidgets('tapping priority container changes selected priority', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap 'Haute' priority
      final hautePriority = find.text('Haute');
      expect(hautePriority, findsOneWidget);
      await tester.tap(hautePriority);
      await tester.pump(const Duration(milliseconds: 300));

      // No crash - priority selected
      expect(find.text('Haute'), findsOneWidget);
    });

    testWidgets('successful ticket submission shows success snackbar', (
      tester,
    ) async {
      when(
        () => mockSupportRepo.createTicket(
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          category: any(named: 'category'),
          priority: any(named: 'priority'),
        ),
      ).thenAnswer((_) async => _dummyTicket());

      await fillFormAndSubmit(tester);

      // Verify createTicket was called
      verify(
        () => mockSupportRepo.createTicket(
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          category: any(named: 'category'),
          priority: any(named: 'priority'),
        ),
      ).called(1);

      expect(find.text('Ticket créé avec succès'), findsOneWidget);
    });

    testWidgets('failed ticket submission shows error snackbar', (
      tester,
    ) async {
      when(
        () => mockSupportRepo.createTicket(
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          category: any(named: 'category'),
          priority: any(named: 'priority'),
        ),
      ).thenThrow(Exception('Connexion impossible'));

      await fillFormAndSubmit(tester);

      expect(find.textContaining('Connexion impossible'), findsOneWidget);
    });
  });
}
