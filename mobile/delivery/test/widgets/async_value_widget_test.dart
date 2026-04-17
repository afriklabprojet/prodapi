import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/widgets/common/async_value_widget.dart';

void main() {
  group('AsyncValueWidget', () {
    testWidgets('shows data when AsyncData', (tester) async {
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
      await tester.pumpAndSettle();
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('shows loading when AsyncLoading', (tester) async {
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
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows custom loading message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: const AsyncLoading(),
              data: (data) => Text(data),
              loadingMessage: 'Chargement en cours...',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Chargement en cours...'), findsOneWidget);
    });

    testWidgets('shows custom loading widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: const AsyncLoading(),
              data: (data) => Text(data),
              loading: const Text('Custom Loading'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Custom Loading'), findsOneWidget);
    });

    testWidgets('shows error message on AsyncError', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: AsyncError('Something went wrong', StackTrace.current),
              data: (data) => Text(data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows custom error widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: AsyncError('err', StackTrace.current),
              data: (data) => Text(data),
              error: (e, st) => Text('Custom: $e'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Custom: err'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: AsyncError('Error', StackTrace.current),
              data: (data) => Text(data),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Réessayer'), findsOneWidget);
      await tester.tap(find.textContaining('Réessayer'));
      expect(retried, true);
    });

    testWidgets('shows profile error for coursier message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: AsyncError('Profil coursier non trouvé', StackTrace.current),
              data: (data) => Text(data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('coursier'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows profile error for 403 message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncValueWidget<String>(
              value: AsyncError('Erreur 403 accès refusé', StackTrace.current),
              data: (data) => Text(data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('403'), findsAtLeastNWidgets(1));
    });
  });

  group('SliverAsyncValueWidget', () {
    testWidgets('shows data in sliver context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAsyncValueWidget<String>(
                  value: const AsyncData('Sliver Data'),
                  data: (data) => SliverToBoxAdapter(child: Text(data)),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sliver Data'), findsOneWidget);
    });

    testWidgets('shows loading in sliver context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAsyncValueWidget<String>(
                  value: const AsyncLoading(),
                  data: (data) => SliverToBoxAdapter(child: Text(data)),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error in sliver context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAsyncValueWidget<String>(
                  value: AsyncError('Sliver error', StackTrace.current),
                  data: (data) => SliverToBoxAdapter(child: Text(data)),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Sliver error'), findsOneWidget);
    });

    testWidgets('shows loading message in sliver', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAsyncValueWidget<String>(
                  value: const AsyncLoading(),
                  data: (data) => SliverToBoxAdapter(child: Text(data)),
                  loadingMessage: 'Patientez...',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Patientez...'), findsOneWidget);
    });
  });
}
