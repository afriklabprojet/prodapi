import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/home/go_online_button.dart';

void main() {
  Widget buildButton({
    required bool isOnline,
    bool isToggling = false,
    required VoidCallback onToggle,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            GoOnlineButton(
              isOnline: isOnline,
              isToggling: isToggling,
              onToggle: onToggle,
            ),
          ],
        ),
      ),
    );
  }

  group('GoOnlineButton', () {
    testWidgets('displays offline state', (tester) async {
      await tester.pumpWidget(buildButton(isOnline: false, onToggle: () {}));
      await tester.pumpAndSettle();

      expect(find.byType(GoOnlineButton), findsOneWidget);
      expect(find.text('PASSER EN LIGNE'), findsOneWidget);
    });

    testWidgets('displays online state', (tester) async {
      await tester.pumpWidget(buildButton(isOnline: true, onToggle: () {}));
      await tester.pumpAndSettle();

      expect(find.byType(GoOnlineButton), findsOneWidget);
      expect(find.text('PASSER HORS LIGNE'), findsOneWidget);
    });

    testWidgets('shows loading when toggling', (tester) async {
      await tester.pumpWidget(
        buildButton(isOnline: false, isToggling: true, onToggle: () {}),
      );
      await tester.pump();

      expect(find.byType(GoOnlineButton), findsOneWidget);
      expect(find.text('CHANGEMENT EN COURS...'), findsOneWidget);
    });

    testWidgets('calls onToggle when tapped', (tester) async {
      bool toggled = false;
      await tester.pumpWidget(
        buildButton(isOnline: false, onToggle: () => toggled = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(toggled, true);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(buildButton(isOnline: false, onToggle: () {}));
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await tester.pumpWidget(buildButton(isOnline: false, onToggle: () {}));
      await tester.pumpAndSettle();
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('contains Container widgets', (tester) async {
      await tester.pumpWidget(buildButton(isOnline: false, onToggle: () {}));
      await tester.pumpAndSettle();
      expect(find.byType(Container), findsWidgets);
    });
  });
}
