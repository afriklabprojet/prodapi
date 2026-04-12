import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/home/offline_overlay.dart';

void main() {
  group('OfflineOverlay', () {
    testWidgets('displays offline text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OfflineOverlay())),
      );
      await tester.pumpAndSettle();

      expect(find.text('VOUS ÊTES HORS LIGNE'), findsOneWidget);
    });

    testWidgets('displays instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OfflineOverlay())),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Passez en ligne pour recevoir des commandes'),
        findsOneWidget,
      );
    });

    testWidgets('displays cloud_off icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OfflineOverlay())),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OfflineOverlay())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Column widgets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OfflineOverlay())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OfflineOverlay())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('contains Container widgets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OfflineOverlay())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });
  });
}
