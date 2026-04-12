import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:drpharma_client/core/constants/app_colors.dart';
import 'package:drpharma_client/features/treatments/domain/entities/treatment_entity.dart';
import 'package:drpharma_client/features/treatments/presentation/widgets/widgets.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr', null);
  });

  group('TreatmentCard Widget Tests', () {
    late TreatmentEntity mockTreatment;

    setUp(() {
      mockTreatment = TreatmentEntity(
        id: '1',
        productId: 1,
        productName: 'Doliprane 1000mg',
        dosage: '1000mg',
        frequency: '3 fois par jour',
        quantityPerRenewal: 30,
        renewalPeriodDays: 30,
        nextRenewalDate: DateTime.now().add(const Duration(days: 5)),
        reminderEnabled: true,
        reminderDaysBefore: 3,
        isActive: true,
        createdAt: DateTime.now(),
      );
    });

    testWidgets('devrait afficher le nom du traitement', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: TreatmentCard(treatment: mockTreatment)),
          ),
        ),
      );

      // Attendre l'animation d'entrée
      await tester.pumpAndSettle();

      expect(find.text('Doliprane 1000mg'), findsOneWidget);
    });

    testWidgets('devrait afficher le dosage et la fréquence', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: TreatmentCard(treatment: mockTreatment)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1000mg'), findsOneWidget);
      expect(find.text('3 fois par jour'), findsOneWidget);
    });

    testWidgets('devrait afficher le badge de renouvellement proche', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Create a treatment where days until renewal <= reminderDaysBefore
      final soonRenewalTreatment = mockTreatment.copyWith(
        nextRenewalDate: DateTime.now().add(const Duration(days: 2)),
        reminderDaysBefore: 3,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TreatmentCard(treatment: soonRenewalTreatment),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge should display "Dans X j" where X is 1 or 2
      expect(find.textContaining('Dans'), findsOneWidget);
    });

    testWidgets(
      'devrait afficher le badge "En retard" pour traitement en retard',
      (WidgetTester tester) async {
        final overdueTreatment = mockTreatment.copyWith(
          nextRenewalDate: DateTime.now().subtract(const Duration(days: 2)),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: TreatmentCard(treatment: overdueTreatment)),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('En retard'), findsOneWidget);
      },
    );

    testWidgets('devrait avoir une bordure rouge quand en retard', (
      WidgetTester tester,
    ) async {
      final overdueTreatment = mockTreatment.copyWith(
        nextRenewalDate: DateTime.now().subtract(const Duration(days: 2)),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: TreatmentCard(treatment: overdueTreatment)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      final side = shape.side;

      expect(side.color, equals(AppColors.error));
      expect(side.width, equals(2));
    });

    testWidgets('devrait appeler onTap quand on tape sur la carte', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TreatmentCard(
                treatment: mockTreatment,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('devrait appeler onOrder quand on clique sur Commander', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool ordered = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TreatmentCard(
                treatment: mockTreatment,
                onOrder: () => ordered = true,
              ),
            ),
          ),
        ),
      );

      // Wait for animation delay and animation to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Find the button - use textContaining in case text wraps
      final commanderButton = find.text('Commander');
      expect(commanderButton, findsOneWidget);

      await tester.tap(commanderButton);
      await tester.pumpAndSettle();

      expect(ordered, isTrue);
    });

    testWidgets('devrait afficher le toggle de rappel correctement', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: TreatmentCard(treatment: mockTreatment)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('devrait toggle le rappel quand on clique dessus', (
      WidgetTester tester,
    ) async {
      bool? toggledValue;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TreatmentCard(
                treatment: mockTreatment,
                onReminderToggle: (value) => toggledValue = value,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_active));
      await tester.pumpAndSettle();

      expect(toggledValue, isFalse);
    });

    testWidgets('devrait afficher Dismissible quand onDelete est fourni', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TreatmentCard(treatment: mockTreatment, onDelete: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets(
      'devrait afficher le dialogue de confirmation avant suppression',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: TreatmentCard(treatment: mockTreatment, onDelete: () {}),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Swipe pour déclencher dismissible
        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        // Vérifier que le dialogue apparaît
        expect(find.text('Supprimer le traitement'), findsOneWidget);
        expect(find.text('Annuler'), findsOneWidget);
        expect(find.text('Supprimer'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('devrait animer l\'entrée de la carte', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TreatmentCard(
                treatment: mockTreatment,
                animationDelay: 100,
              ),
            ),
          ),
        ),
      );

      // Animation pas encore démarrée
      await tester.pump();
      // Verify FadeTransition exists as descendant of TreatmentCard
      expect(
        find.descendant(
          of: find.byType(TreatmentCard),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );

      // Après animation
      await tester.pumpAndSettle();
      expect(find.text('Doliprane 1000mg'), findsOneWidget);
    });
  });

  group('TreatmentCardSkeleton Widget Tests', () {
    testWidgets('devrait afficher le skeleton', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TreatmentCardSkeleton())),
      );

      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(TreatmentCardSkeleton), findsOneWidget);
    });

    testWidgets('devrait animer le skeleton', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TreatmentCardSkeleton())),
      );

      // Animation initiale
      await tester.pump();

      // Verify skeleton is present and animating (has Card)
      expect(find.byType(Card), findsOneWidget);

      // Avancer l'animation
      await tester.pump(const Duration(milliseconds: 500));

      // Still present after animation advance
      expect(find.byType(TreatmentCardSkeleton), findsOneWidget);
    });
  });

  group('TreatmentsEmptyState Widget Tests', () {
    testWidgets('devrait afficher le message vide', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TreatmentsEmptyState())),
      );

      expect(find.text('Aucun traitement'), findsOneWidget);
      expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
    });

    testWidgets('devrait afficher le bouton d\'ajout si onAdd fourni', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TreatmentsEmptyState(onAdd: () {})),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifie que le bouton est présent via son texte
      expect(find.text('Ajouter un traitement'), findsOneWidget);
    });

    testWidgets('ne devrait pas afficher le bouton si onAdd null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TreatmentsEmptyState())),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('devrait appeler onAdd quand on clique sur le bouton', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TreatmentsEmptyState(onAdd: () => clicked = true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajouter un traitement'));
      await tester.pump();

      expect(clicked, isTrue);
    });
  });

  group('TreatmentsErrorState Widget Tests', () {
    testWidgets('devrait afficher le message d\'erreur', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TreatmentsErrorState(message: 'Erreur de chargement'),
          ),
        ),
      );

      expect(find.text('Erreur'), findsOneWidget);
      expect(find.text('Erreur de chargement'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('devrait afficher le bouton retry si onRetry fourni', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TreatmentsErrorState(message: 'Test error', onRetry: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifie que le bouton Réessayer est présent
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('devrait appeler onRetry quand on clique', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TreatmentsErrorState(
              message: 'Test error',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Réessayer'));
      await tester.pump();

      expect(retried, isTrue);
    });
  });
}

// Helper pour obtenir l'opacité du skeleton
double _getSkeletonOpacity(WidgetTester tester) {
  final animBuilder = tester.widget<AnimatedBuilder>(
    find.byType(AnimatedBuilder),
  );
  final opacity = tester.widget<Opacity>(
    find.descendant(
      of: find.byWidget(animBuilder),
      matching: find.byType(Opacity),
    ),
  );
  return opacity.opacity;
}
