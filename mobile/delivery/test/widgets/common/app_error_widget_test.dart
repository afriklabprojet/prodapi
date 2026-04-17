import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/common/app_error_widget.dart';

void main() {
  Widget buildWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('AppErrorWidget', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        buildWidget(const AppErrorWidget(message: 'Une erreur est survenue')),
      );
      expect(find.text('Une erreur est survenue'), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry provided', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        buildWidget(
          AppErrorWidget(message: 'Erreur', onRetry: () => retried = true),
        ),
      );
      final retryButton = find.text('Réessayer');
      expect(retryButton, findsOneWidget);
      await tester.tap(retryButton);
      expect(retried, true);
    });

    testWidgets('renders custom icon', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const AppErrorWidget(message: 'Erreur', icon: Icons.wifi_off),
        ),
      );
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('renders custom title', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const AppErrorWidget(message: 'Détails de l\'erreur', title: 'Oops!'),
        ),
      );
      expect(find.text('Oops!'), findsOneWidget);
    });

    testWidgets('profile factory creates widget', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          AppErrorWidget.profile(message: 'Profil introuvable', onRetry: () {}),
        ),
      );
      expect(find.byType(AppErrorWidget), findsOneWidget);
    });

    testWidgets('custom retryLabel is displayed', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          AppErrorWidget(
            message: 'Erreur',
            onRetry: () {},
            retryLabel: 'Recharger',
          ),
        ),
      );
      expect(find.text('Recharger'), findsOneWidget);
    });
  });
}
