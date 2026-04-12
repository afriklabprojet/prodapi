import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/common/loading_dialog.dart';

void main() {
  group('LoadingDialog', () {
    testWidgets('renders with default message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => LoadingDialog.show(context),
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Chargement...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders with custom message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () =>
                    LoadingDialog.show(context, message: 'Envoi en cours...'),
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Envoi en cours...'), findsOneWidget);
    });

    testWidgets('hide closes dialog', (tester) async {
      late BuildContext savedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              savedContext = context;
              return ElevatedButton(
                onPressed: () => LoadingDialog.show(context),
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Chargement...'), findsOneWidget);

      LoadingDialog.hide(savedContext);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Chargement...'), findsNothing);
    });
  });
}
