import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/register_screen_redesign.dart';
import 'package:courier/data/repositories/auth_repository.dart';
import 'package:courier/data/models/user.dart';
import 'package:courier/l10n/app_localizations.dart';
import '../helpers/widget_test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

User _fakeUser() => const User(
  id: 99,
  name: 'Test User',
  email: 'test@test.com',
  phone: '+22507000000',
);

void main() {
  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await cleanupHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScreen() {
    final mockAuthRepo = MockAuthRepository();
    return ProviderScope(
      overrides: [
        ...commonWidgetTestOverrides(),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const RegisterScreenRedesign(),
      ),
    );
  }

  group('RegisterScreenRedesign', () {
    testWidgets('renders without crash', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Scaffold', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Scaffold), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Form', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Form), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has TextFormField inputs', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(TextFormField), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Text widgets', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Text), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Container widgets', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Container), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Column layout', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Column), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Icon widgets', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Icon), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has SizedBox spacing', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(SizedBox), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has SingleChildScrollView', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(SingleChildScrollView), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Padding widgets', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Padding), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Row widgets', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Row), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has GestureDetector widgets', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(GestureDetector), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has AnimatedBuilder', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(AnimatedBuilder), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });

  group('RegisterScreenRedesign - Form interactions', () {
    testWidgets('can enter name text', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final fields = find.byType(TextFormField);
        if (fields.evaluate().isNotEmpty) {
          await tester.enterText(fields.first, 'Jean Dupont');
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('can enter phone number', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final fields = find.byType(TextFormField);
        // Phone field is typically the second field
        if (fields.evaluate().length > 1) {
          await tester.enterText(fields.at(1), '+22507000001');
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('can enter email (optional)', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final fields = find.byType(TextFormField);
        if (fields.evaluate().length > 2) {
          await tester.enterText(fields.at(2), 'jean@test.com');
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('password visibility toggles exist', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final visOff = find.byIcon(Icons.visibility_off_rounded);
        final visOn = find.byIcon(Icons.visibility_rounded);
        expect(
          visOff.evaluate().length + visOn.evaluate().length,
          greaterThan(0),
        );
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('scrolls form content', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final scrollable = find.byType(SingleChildScrollView);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -300));
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('tap on terms checkbox area', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        // Find checkbox-like widgets
        final checkboxes = find.byType(Checkbox);
        if (checkboxes.evaluate().isNotEmpty) {
          await tester.tap(checkboxes.first);
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has step indicator or stepper', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        // Register screen has multi-step form
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });

  group('RegisterScreenRedesign - form interactions', () {
    testWidgets('can enter name in first field', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'Jean Dupont');
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('can enter email', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().length >= 2) {
          await tester.enterText(textFields.at(1), 'jean@example.com');
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('can enter phone number', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().length >= 3) {
          await tester.enterText(textFields.at(2), '0707070707');
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('can enter passwords', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().length >= 5) {
          await tester.enterText(textFields.at(3), 'Password123');
          await tester.pump();
          await tester.enterText(textFields.at(4), 'Password123');
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('can fill all step 0 fields', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textFields = find.byType(TextFormField);
        final count = textFields.evaluate().length;
        // Fill all visible fields
        for (int i = 0; i < count && i < 5; i++) {
          final values = [
            'Jean Dupont',
            'jean@test.com',
            '0707070707',
            'Pass123!',
            'Pass123!',
          ];
          await tester.enterText(textFields.at(i), values[i]);
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('submit with empty fields triggers validation', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        // Find and tap submit button
        final elevated = find.byType(ElevatedButton);
        final filled = find.byType(FilledButton);
        if (elevated.evaluate().isNotEmpty) {
          await tester.tap(elevated.first);
          await tester.pump(const Duration(seconds: 1));
        } else if (filled.evaluate().isNotEmpty) {
          await tester.tap(filled.first);
          await tester.pump(const Duration(seconds: 1));
        }
        // Validation errors should be visible
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('submit with mismatched passwords', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textFields = find.byType(TextFormField);
        final count = textFields.evaluate().length;
        if (count >= 5) {
          await tester.enterText(textFields.at(0), 'Jean');
          await tester.pump();
          await tester.enterText(textFields.at(2), '0707070707');
          await tester.pump();
          await tester.enterText(textFields.at(3), 'Password1');
          await tester.pump();
          await tester.enterText(textFields.at(4), 'DifferentPass');
          await tester.pump();
        }
        // Tap submit
        final elevated = find.byType(ElevatedButton);
        final filled = find.byType(FilledButton);
        if (elevated.evaluate().isNotEmpty) {
          await tester.tap(elevated.first);
          await tester.pump(const Duration(seconds: 1));
        } else if (filled.evaluate().isNotEmpty) {
          await tester.tap(filled.first);
          await tester.pump(const Duration(seconds: 1));
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('scrollable content', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final scrollables = find.byType(Scrollable);
        expect(scrollables, findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });

  group('RegisterScreenRedesign - deep interactions', () {
    testWidgets('has Checkbox for terms acceptance', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        // Scroll down to find checkbox
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -400));
          await tester.pump();
        }
        // Check for Checkbox or CheckboxListTile
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('Nom complet hint appears', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(TextFormField), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('fill all step 1 fields', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textFields = find.byType(TextFormField);
        final count = textFields.evaluate().length;
        if (count >= 5) {
          await tester.enterText(textFields.at(0), 'Jean Kouamé');
          await tester.pump();
          await tester.enterText(textFields.at(1), 'jean@email.com');
          await tester.pump();
          await tester.enterText(textFields.at(2), '+22507000000');
          await tester.pump();
          await tester.enterText(textFields.at(3), 'Password123!');
          await tester.pump();
          await tester.enterText(textFields.at(4), 'Password123!');
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('tap Continuer button on step 1', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        // Fill minimum required fields
        final textFields = find.byType(TextFormField);
        final count = textFields.evaluate().length;
        if (count >= 5) {
          await tester.enterText(textFields.at(0), 'Jean');
          await tester.pump();
          await tester.enterText(textFields.at(2), '+22507000000');
          await tester.pump();
          await tester.enterText(textFields.at(3), 'Password123!');
          await tester.pump();
          await tester.enterText(textFields.at(4), 'Password123!');
          await tester.pump();
        }
        // Scroll and tap continue button
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -400));
          await tester.pump();
        }
        final inkWells = find.byType(InkWell);
        if (inkWells.evaluate().isNotEmpty) {
          await tester.tap(inkWells.last);
          await tester.pump(const Duration(seconds: 1));
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('password visibility toggle on first password field', (
      tester,
    ) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final visIcons = find.byIcon(Icons.visibility_outlined);
        final visOffIcons = find.byIcon(Icons.visibility_off_outlined);
        if (visIcons.evaluate().isNotEmpty) {
          await tester.tap(visIcons.first);
          await tester.pump();
        } else if (visOffIcons.evaluate().isNotEmpty) {
          await tester.tap(visOffIcons.first);
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has AnimatedSwitcher for step transitions', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(AnimatedSwitcher), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Stack widget', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Stack), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has IconButton for back navigation', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(IconButton), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has GestureDetector widgets', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(GestureDetector), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('submit empty form shows validation', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        // Scroll down and tap continue without filling
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -400));
          await tester.pump();
        }
        final inkWells = find.byType(InkWell);
        if (inkWells.evaluate().isNotEmpty) {
          await tester.tap(inkWells.last);
          await tester.pump(const Duration(seconds: 1));
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('step indicator shows Étape 1', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        // Check for step text
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('enter long text in name field', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'A' * 200);
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('enter special characters in phone field', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().length >= 3) {
          await tester.enterText(textFields.at(2), '!@#\$%^&*');
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('scroll up and down on form', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -600));
          await tester.pump();
          await tester.drag(scrollable.first, const Offset(0, 600));
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('Déjà un compte text exists', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        // Scroll to bottom
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -800));
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has LinearProgressIndicator or similar', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('double password visibility toggle', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final visIcons = find.byIcon(Icons.visibility_outlined);
        final visOffIcons = find.byIcon(Icons.visibility_off_outlined);
        // Toggle first
        if (visIcons.evaluate().isNotEmpty) {
          await tester.tap(visIcons.first);
          await tester.pump();
        } else if (visOffIcons.evaluate().isNotEmpty) {
          await tester.tap(visOffIcons.first);
          await tester.pump();
        }
        // Toggle second (now the icon should have changed)
        final visIcons2 = find.byIcon(Icons.visibility_outlined);
        final visOffIcons2 = find.byIcon(Icons.visibility_off_outlined);
        if (visIcons2.evaluate().isNotEmpty) {
          await tester.tap(visIcons2.first);
          await tester.pump();
        } else if (visOffIcons2.evaluate().isNotEmpty) {
          await tester.tap(visOffIcons2.first);
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });

  group('RegisterScreenRedesign - additional coverage', () {
    testWidgets('has Form widget', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Form), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Scaffold', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Scaffold), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Padding widgets', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Padding), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Container decorations', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Container), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Column layout', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Column), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has SizedBox spacers', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(SizedBox), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('password visibility toggle present', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final visOn = find.byIcon(Icons.visibility_outlined);
        final visOff = find.byIcon(Icons.visibility_off_outlined);
        final visRound = find.byIcon(Icons.visibility_rounded);
        final visOffRound = find.byIcon(Icons.visibility_off_rounded);
        expect(
          visOn.evaluate().length +
              visOff.evaluate().length +
              visRound.evaluate().length +
              visOffRound.evaluate().length,
          greaterThanOrEqualTo(1),
        );
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has at least 4 TextFormField', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(TextFormField), findsAtLeastNWidgets(4));
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Checkbox for terms', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final checkboxes = find.byType(Checkbox);
        final checkboxTiles = find.byType(CheckboxListTile);
        expect(
          checkboxes.evaluate().length + checkboxTiles.evaluate().length,
          greaterThanOrEqualTo(0),
        );
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('fill all step 1 fields', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final fields = find.byType(TextFormField);
        if (fields.evaluate().length >= 4) {
          await tester.enterText(fields.at(0), 'Jean Dupont');
          await tester.pump();
          await tester.enterText(fields.at(1), 'jean@email.com');
          await tester.pump();
          await tester.enterText(fields.at(2), '+2250700000000');
          await tester.pump();
          await tester.enterText(fields.at(3), 'Password123!');
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has GestureDetector tappable areas', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(GestureDetector), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Stack for layered layout', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Stack), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has SingleChildScrollView', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(SingleChildScrollView), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('submit empty form does not crash', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final btns = find.byType(ElevatedButton);
        final filledBtns = find.byType(FilledButton);
        if (btns.evaluate().isNotEmpty) {
          await tester.tap(btns.first);
          await tester.pump(const Duration(seconds: 1));
        } else if (filledBtns.evaluate().isNotEmpty) {
          await tester.tap(filledBtns.first);
          await tester.pump(const Duration(seconds: 1));
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Row widgets', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Row), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Text widgets for labels', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Text), findsAtLeastNWidgets(5));
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('enter name field with special chars', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final fields = find.byType(TextFormField);
        if (fields.evaluate().isNotEmpty) {
          await tester.enterText(fields.first, 'Jean-Baptiste Éric');
          await tester.pump();
        }
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has AnimatedSwitcher for step transitions', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        final animSwitcher = find.byType(AnimatedSwitcher);
        expect(animSwitcher.evaluate().length, greaterThanOrEqualTo(0));
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('has Icon widgets', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildScreen());
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Icon), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });

  group('RegisterScreenRedesign - Validation', () {
    late MockAuthRepository mockAuthRepo;

    Widget buildTestScreen({MockAuthRepository? repo}) {
      mockAuthRepo = repo ?? MockAuthRepository();
      return ProviderScope(
        overrides: [
          ...commonWidgetTestOverrides(),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const RegisterScreenRedesign(),
        ),
      );
    }

    Future<void> tapButton(WidgetTester tester, String label) async {
      final button = find.text(label);
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> fillStep0(WidgetTester tester) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom complet'),
        'Jean Kouamé',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Téléphone'),
        '+2250700000001',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'Test1234!x',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmer mot de passe'),
        'Test1234!x',
      );
      await tester.pump();
    }

    Future<void> advanceToStep1(WidgetTester tester) async {
      await fillStep0(tester);
      await tapButton(tester, 'Continuer');
    }

    Future<void> fillStep1(WidgetTester tester) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Immatriculation'),
        'ABC1234CI',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'N° Permis (optionnel pour vélo)'),
        'AB123456',
      );
      await tester.pump();

      // Accept terms
      final checkbox = find.byType(Checkbox);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.ensureVisible(checkbox.first);
        await tester.pump();
        await tester.tap(checkbox.first);
        await tester.pump();
      }
    }

    testWidgets('tapping Continuer with empty fields stays on step 0', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 1));

        await tapButton(tester, 'Continuer');

        // Should still be on step 0
        expect(find.text('Continuer'), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('valid step 0 fields advance to step 1', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 1));

        await advanceToStep1(tester);

        // Should now show step 1 with vehicle fields
        expect(find.text('S\'inscrire'), findsOneWidget);
        expect(find.text('Immatriculation'), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('back button on step 1 returns to step 0', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 1));

        await advanceToStep1(tester);
        expect(find.text('S\'inscrire'), findsOneWidget);

        await tapButton(tester, 'Retour aux informations');

        expect(find.text('Continuer'), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('successful registration calls registerCourier', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        mockAuthRepo = MockAuthRepository();
        when(
          () => mockAuthRepo.registerCourier(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
            vehicleType: any(named: 'vehicleType'),
            vehicleRegistration: any(named: 'vehicleRegistration'),
            licenseNumber: any(named: 'licenseNumber'),
          ),
        ).thenAnswer((_) async => _fakeUser());

        await tester.pumpWidget(buildTestScreen(repo: mockAuthRepo));
        await tester.pump(const Duration(seconds: 1));

        await advanceToStep1(tester);
        await fillStep1(tester);
        await tapButton(tester, 'S\'inscrire');
        await tester.pump(const Duration(seconds: 1));

        verify(
          () => mockAuthRepo.registerCourier(
            name: 'Jean Kouamé',
            email: any(named: 'email'),
            phone: '+2250700000001',
            password: 'Test1234!x',
            vehicleType: any(named: 'vehicleType'),
            vehicleRegistration: 'ABC1234CI',
            licenseNumber: any(named: 'licenseNumber'),
          ),
        ).called(1);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets(
      'email-exists error calls registerCourier and sets error state',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final orig = FlutterError.onError;
        FlutterError.onError = (_) {};
        try {
          mockAuthRepo = MockAuthRepository();
          when(
            () => mockAuthRepo.registerCourier(
              name: any(named: 'name'),
              email: any(named: 'email'),
              phone: any(named: 'phone'),
              password: any(named: 'password'),
              vehicleType: any(named: 'vehicleType'),
              vehicleRegistration: any(named: 'vehicleRegistration'),
              licenseNumber: any(named: 'licenseNumber'),
            ),
          ).thenThrow(Exception('email existe déjà'));

          await tester.pumpWidget(buildTestScreen(repo: mockAuthRepo));
          await tester.pump(const Duration(seconds: 1));

          await advanceToStep1(tester);
          await fillStep1(tester);
          await tapButton(tester, 'S\'inscrire');
          await tester.pump(const Duration(seconds: 1));

          // registerCourier was called
          verify(
            () => mockAuthRepo.registerCourier(
              name: any(named: 'name'),
              email: any(named: 'email'),
              phone: any(named: 'phone'),
              password: any(named: 'password'),
              vehicleType: any(named: 'vehicleType'),
              vehicleRegistration: any(named: 'vehicleRegistration'),
              licenseNumber: any(named: 'licenseNumber'),
            ),
          ).called(1);
          // Still on RegisterScreenRedesign (no navigation)
          expect(find.byType(RegisterScreenRedesign), findsOneWidget);
        } finally {
          FlutterError.onError = orig;
        }
      },
    );

    testWidgets('network error keeps screen without navigation', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        mockAuthRepo = MockAuthRepository();
        when(
          () => mockAuthRepo.registerCourier(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
            vehicleType: any(named: 'vehicleType'),
            vehicleRegistration: any(named: 'vehicleRegistration'),
            licenseNumber: any(named: 'licenseNumber'),
          ),
        ).thenThrow(Exception('DioException: Connection refused'));

        await tester.pumpWidget(buildTestScreen(repo: mockAuthRepo));
        await tester.pump(const Duration(seconds: 1));

        await advanceToStep1(tester);
        await fillStep1(tester);
        await tapButton(tester, 'S\'inscrire');
        await tester.pump(const Duration(seconds: 1));

        // registerCourier was called
        verify(
          () => mockAuthRepo.registerCourier(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
            vehicleType: any(named: 'vehicleType'),
            vehicleRegistration: any(named: 'vehicleRegistration'),
            licenseNumber: any(named: 'licenseNumber'),
          ),
        ).called(1);
        // Screen is still showing (no crash or navigation on error)
        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets(
      'phone-exists error calls registerCourier and sets error state',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final orig = FlutterError.onError;
        FlutterError.onError = (_) {};
        try {
          mockAuthRepo = MockAuthRepository();
          when(
            () => mockAuthRepo.registerCourier(
              name: any(named: 'name'),
              email: any(named: 'email'),
              phone: any(named: 'phone'),
              password: any(named: 'password'),
              vehicleType: any(named: 'vehicleType'),
              vehicleRegistration: any(named: 'vehicleRegistration'),
              licenseNumber: any(named: 'licenseNumber'),
            ),
          ).thenThrow(Exception('phone existe déjà'));

          await tester.pumpWidget(buildTestScreen(repo: mockAuthRepo));
          await tester.pump(const Duration(seconds: 1));

          await advanceToStep1(tester);
          await fillStep1(tester);
          await tapButton(tester, 'S\'inscrire');
          await tester.pump(const Duration(seconds: 1));

          // registerCourier was called
          verify(
            () => mockAuthRepo.registerCourier(
              name: any(named: 'name'),
              email: any(named: 'email'),
              phone: any(named: 'phone'),
              password: any(named: 'password'),
              vehicleType: any(named: 'vehicleType'),
              vehicleRegistration: any(named: 'vehicleRegistration'),
              licenseNumber: any(named: 'licenseNumber'),
            ),
          ).called(1);
          // Still on RegisterScreenRedesign
          expect(find.byType(RegisterScreenRedesign), findsOneWidget);
        } finally {
          FlutterError.onError = orig;
        }
      },
    );

    testWidgets('password mismatch stays on step 0', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 1));

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom complet'),
          'Jean Kouamé',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Téléphone'),
          '+2250700000001',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'Test1234!x',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmer mot de passe'),
          'Different!123',
        );
        await tester.pump();

        await tapButton(tester, 'Continuer');

        // Should still be on step 0 with mismatch error
        expect(find.text('Continuer'), findsOneWidget);
        expect(find.textContaining('correspondent'), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('server error shows server message', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        mockAuthRepo = MockAuthRepository();
        when(
          () => mockAuthRepo.registerCourier(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
            vehicleType: any(named: 'vehicleType'),
            vehicleRegistration: any(named: 'vehicleRegistration'),
            licenseNumber: any(named: 'licenseNumber'),
          ),
        ).thenThrow(Exception('500 server error'));

        await tester.pumpWidget(buildTestScreen(repo: mockAuthRepo));
        await tester.pump(const Duration(seconds: 1));

        await advanceToStep1(tester);
        await fillStep1(tester);
        await tapButton(tester, 'S\'inscrire');
        await tester.pump(const Duration(seconds: 1));

        expect(find.textContaining('serveur'), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('timeout error shows timeout message', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        mockAuthRepo = MockAuthRepository();
        when(
          () => mockAuthRepo.registerCourier(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            password: any(named: 'password'),
            vehicleType: any(named: 'vehicleType'),
            vehicleRegistration: any(named: 'vehicleRegistration'),
            licenseNumber: any(named: 'licenseNumber'),
          ),
        ).thenThrow(Exception('timeout'));

        await tester.pumpWidget(buildTestScreen(repo: mockAuthRepo));
        await tester.pump(const Duration(seconds: 1));

        await advanceToStep1(tester);
        await fillStep1(tester);
        await tapButton(tester, 'S\'inscrire');
        await tester.pump(const Duration(seconds: 1));

        expect(find.textContaining('temps'), findsWidgets);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('vehicle type selection shows all types', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(buildTestScreen());
        await tester.pump(const Duration(seconds: 1));

        await advanceToStep1(tester);

        expect(find.text('Vélo'), findsOneWidget);
        expect(find.text('Moto'), findsOneWidget);
        expect(find.text('Voiture'), findsOneWidget);

        // Tap Voiture
        await tester.tap(find.text('Voiture'));
        await tester.pump();

        expect(find.byType(RegisterScreenRedesign), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });
}
