import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/widgets/common/common_widgets.dart';

void main() {
  group('AppLoadingWidget', () {
    testWidgets('renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppLoadingWidget())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppLoadingWidget(message: 'Chargement...')),
        ),
      );

      expect(find.text('Chargement...'), findsOneWidget);
    });

    testWidgets('no message by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppLoadingWidget())),
      );

      // Only CircularProgressIndicator, no Text
      expect(find.byType(Text), findsNothing);
    });
  });

  group('AppErrorWidget', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppErrorWidget(message: 'Erreur réseau')),
        ),
      );

      expect(find.text('Erreur réseau'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Erreur',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Réessayer'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(retried, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppErrorWidget(message: 'Erreur')),
        ),
      );

      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('shows title when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Détails...',
              title: 'Erreur critique',
            ),
          ),
        ),
      );

      expect(find.text('Erreur critique'), findsOneWidget);
      expect(find.text('Détails...'), findsOneWidget);
    });

    testWidgets('.profile factory has correct icon and title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget.profile(message: 'Non trouvé'),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_off), findsOneWidget);
      expect(find.text('Profil coursier non configuré'), findsOneWidget);
      expect(find.text('Non trouvé'), findsOneWidget);
    });
  });

  group('AppEmptyWidget', () {
    testWidgets('displays message and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyWidget(
              message: 'Aucune course',
              icon: Icons.inventory_2_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Aucune course'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyWidget(
              message: 'Aucun message',
              subtitle: 'Commencez la conversation',
            ),
          ),
        ),
      );

      expect(find.text('Aucun message'), findsOneWidget);
      expect(find.text('Commencez la conversation'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyWidget(
              message: 'Vide',
              actionLabel: 'Créer',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Créer'), findsOneWidget);
      await tester.tap(find.text('Créer'));
      expect(tapped, isTrue);
    });
  });

  group('AsyncValueWidget', () {
    testWidgets('shows loading when AsyncValue.loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: const AsyncLoading(),
              data: (data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.byType(AppLoadingWidget), findsOneWidget);
    });

    testWidgets('shows data when AsyncValue.data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: const AsyncData('Hello World'),
              data: (data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('shows error when AsyncValue.error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: AsyncError(Exception('Network error'), StackTrace.current),
              data: (data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.byType(AppErrorWidget), findsOneWidget);
    });

    testWidgets('shows retry button on error when onRetry provided', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: AsyncError(Exception('Fail'), StackTrace.current),
              data: (data) => Text(data),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Réessayer'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(retried, isTrue);
    });

    testWidgets('uses profile error for 403-like errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: AsyncError(Exception('coursier non trouvé'), StackTrace.current),
              data: (data) => Text(data),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_off), findsOneWidget);
      expect(find.text('Profil coursier non configuré'), findsOneWidget);
    });

    testWidgets('uses custom loading widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: const AsyncLoading(),
              data: (data) => Text(data),
              loading: const Text('Custom loading'),
            ),
          ),
        ),
      );

      expect(find.text('Custom loading'), findsOneWidget);
    });
  });

  group('AppSectionCard', () {
    testWidgets('renders title and child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSectionCard(
              title: 'Résumé',
              child: Text('Contenu de la section'),
            ),
          ),
        ),
      );

      expect(find.text('Résumé'), findsOneWidget);
      expect(find.text('Contenu de la section'), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSectionCard(
              title: 'Stats',
              trailing: Icon(Icons.arrow_forward),
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });
}
