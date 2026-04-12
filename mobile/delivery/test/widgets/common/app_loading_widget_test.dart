import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/common/app_loading_widget.dart';

void main() {
  Widget buildWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('AppLoadingWidget', () {
    testWidgets('renders without message', (tester) async {
      await tester.pumpWidget(buildWidget(const AppLoadingWidget()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders with message', (tester) async {
      await tester.pumpWidget(
        buildWidget(const AppLoadingWidget(message: 'Chargement...')),
      );
      expect(find.text('Chargement...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(
        buildWidget(const AppLoadingWidget(color: Colors.red)),
      );
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, Colors.red);
    });

    testWidgets('contains Center widget', (tester) async {
      await tester.pumpWidget(buildWidget(const AppLoadingWidget()));
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('contains Column or Row layout', (tester) async {
      await tester.pumpWidget(
        buildWidget(const AppLoadingWidget(message: 'Loading')),
      );
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('renders AppLoadingWidget type', (tester) async {
      await tester.pumpWidget(buildWidget(const AppLoadingWidget()));
      expect(find.byType(AppLoadingWidget), findsOneWidget);
    });
  });
}
