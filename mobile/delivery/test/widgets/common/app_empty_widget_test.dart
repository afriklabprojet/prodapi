import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/common/app_empty_widget.dart';

void main() {
  Widget buildWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('AppEmptyWidget', () {
    testWidgets('renders with required message', (tester) async {
      await tester.pumpWidget(
        buildWidget(const AppEmptyWidget(message: 'Aucune donnée')),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Aucune donnée'), findsOneWidget);
    });

    testWidgets('renders with custom icon', (tester) async {
      await tester.pumpWidget(
        buildWidget(const AppEmptyWidget(message: 'Vide', icon: Icons.inbox)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          const AppEmptyWidget(message: 'Vide', subtitle: 'Essayez plus tard'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Essayez plus tard'), findsOneWidget);
    });

    testWidgets('renders action button when provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildWidget(
          AppEmptyWidget(
            message: 'Vide',
            actionLabel: 'Réessayer',
            onAction: () => tapped = true,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Réessayer'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(tapped, true);
    });

    testWidgets('deliveries factory creates widget', (tester) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.deliveries()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppEmptyWidget), findsOneWidget);
    });

    testWidgets('history factory creates widget', (tester) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.history()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppEmptyWidget), findsOneWidget);
    });

    testWidgets('chat factory creates widget', (tester) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.chat()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppEmptyWidget), findsOneWidget);
    });

    testWidgets('support factory creates widget', (tester) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.support()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppEmptyWidget), findsOneWidget);
    });

    testWidgets('notifications factory creates widget', (tester) async {
      await tester.pumpWidget(buildWidget(AppEmptyWidget.notifications()));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppEmptyWidget), findsOneWidget);
    });
  });
}
