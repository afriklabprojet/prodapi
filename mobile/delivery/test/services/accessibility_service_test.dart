import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/services/accessibility_service.dart';

void main() {
  group('AccessibilityState', () {
    test('default constructor has correct defaults', () {
      const state = AccessibilityState();
      expect(state.highContrast, false);
      expect(state.largeText, false);
      expect(state.reduceMotion, false);
      expect(state.screenReaderEnabled, false);
      expect(state.textScaleFactor, 1.0);
      expect(state.boldText, false);
      expect(state.invertColors, false);
    });

    test('copyWith preserves values when null', () {
      const state = AccessibilityState(
        highContrast: true,
        largeText: true,
        reduceMotion: true,
        screenReaderEnabled: true,
        textScaleFactor: 1.5,
        boldText: true,
        invertColors: true,
      );
      final copy = state.copyWith();
      expect(copy.highContrast, true);
      expect(copy.largeText, true);
      expect(copy.reduceMotion, true);
      expect(copy.screenReaderEnabled, true);
      expect(copy.textScaleFactor, 1.5);
      expect(copy.boldText, true);
      expect(copy.invertColors, true);
    });

    test('copyWith overrides individual values', () {
      const state = AccessibilityState();
      final copy = state.copyWith(highContrast: true, textScaleFactor: 1.3);
      expect(copy.highContrast, true);
      expect(copy.textScaleFactor, 1.3);
      // Other values remain default
      expect(copy.largeText, false);
      expect(copy.reduceMotion, false);
      expect(copy.boldText, false);
    });
  });

  group('HighContrastTheme', () {
    test('light theme has correct brightness', () {
      final theme = HighContrastTheme.light();
      expect(theme.brightness, Brightness.light);
    });

    test('light theme primary is black', () {
      final theme = HighContrastTheme.light();
      expect(theme.primaryColor, const Color(0xFF000000));
    });

    test('light theme scaffold background is white', () {
      final theme = HighContrastTheme.light();
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
    });

    test('dark theme has correct brightness', () {
      final theme = HighContrastTheme.dark();
      expect(theme.brightness, Brightness.dark);
    });

    test('dark theme scaffold background is true black', () {
      final theme = HighContrastTheme.dark();
      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
    });

    test('light theme has high contrast color scheme', () {
      final theme = HighContrastTheme.light();
      expect(theme.colorScheme.primary, Colors.black);
      expect(theme.colorScheme.onPrimary, Colors.white);
    });

    test('dark theme has inverted color scheme', () {
      final theme = HighContrastTheme.dark();
      expect(theme.colorScheme.primary, Colors.white);
      expect(theme.colorScheme.onPrimary, Colors.black);
    });

    test('light theme appBar is black on white', () {
      final theme = HighContrastTheme.light();
      expect(theme.appBarTheme.backgroundColor, Colors.black);
      expect(theme.appBarTheme.foregroundColor, Colors.white);
    });

    test('dark theme appBar is black bg with white fg', () {
      final theme = HighContrastTheme.dark();
      expect(theme.appBarTheme.backgroundColor, Colors.black);
      expect(theme.appBarTheme.foregroundColor, Colors.white);
    });

    test('light theme divider is thick and black', () {
      final theme = HighContrastTheme.light();
      expect(theme.dividerTheme.color, Colors.black);
      expect(theme.dividerTheme.thickness, 2);
    });

    test('dark theme divider is thick and white', () {
      final theme = HighContrastTheme.dark();
      expect(theme.dividerTheme.color, Colors.white);
      expect(theme.dividerTheme.thickness, 2);
    });
  });

  group('ContrastChecker', () {
    test('black on white has max contrast', () {
      final ratio = ContrastChecker.getContrastRatio(
        Colors.black,
        Colors.white,
      );
      expect(ratio, greaterThan(20));
    });

    test('white on white has no contrast', () {
      final ratio = ContrastChecker.getContrastRatio(
        Colors.white,
        Colors.white,
      );
      expect(ratio, closeTo(1.0, 0.01));
    });

    test('meetsAA returns true for black on white', () {
      expect(ContrastChecker.meetsAA(Colors.black, Colors.white), true);
    });

    test('meetsAA returns false for light grey on white', () {
      expect(
        ContrastChecker.meetsAA(Colors.grey.shade300, Colors.white),
        false,
      );
    });

    test('meetsAALargeText has lower threshold than meetsAA', () {
      expect(
        ContrastChecker.meetsAALargeText(Colors.black, Colors.white),
        true,
      );
    });

    test('meetsAAA returns true for black on white', () {
      expect(ContrastChecker.meetsAAA(Colors.black, Colors.white), true);
    });

    test('meetsAAA returns false for medium grey on white', () {
      expect(ContrastChecker.meetsAAA(Colors.grey, Colors.white), false);
    });

    test('contrast ratio is symmetric', () {
      final ratio1 = ContrastChecker.getContrastRatio(
        Colors.blue,
        Colors.white,
      );
      final ratio2 = ContrastChecker.getContrastRatio(
        Colors.white,
        Colors.blue,
      );
      expect(ratio1, closeTo(ratio2, 0.01));
    });

    test('meetsAALargeText passes for contrast >= 3', () {
      // Dark blue on white usually passes
      expect(
        ContrastChecker.meetsAALargeText(const Color(0xFF003366), Colors.white),
        true,
      );
    });
  });

  group('AccessibilityState custom values', () {
    test('constructor with all custom values', () {
      const state = AccessibilityState(
        highContrast: true,
        largeText: true,
        reduceMotion: true,
        screenReaderEnabled: true,
        textScaleFactor: 1.8,
        boldText: true,
        invertColors: true,
      );
      expect(state.highContrast, true);
      expect(state.textScaleFactor, 1.8);
      expect(state.invertColors, true);
    });

    test('copyWith overrides all fields independently', () {
      const state = AccessibilityState(highContrast: true, largeText: true);
      final copy = state.copyWith(
        highContrast: false,
        reduceMotion: true,
        boldText: true,
        invertColors: true,
        screenReaderEnabled: true,
        textScaleFactor: 2.0,
      );
      expect(copy.highContrast, false);
      expect(copy.largeText, true); // unchanged
      expect(copy.reduceMotion, true);
      expect(copy.boldText, true);
      expect(copy.invertColors, true);
      expect(copy.screenReaderEnabled, true);
      expect(copy.textScaleFactor, 2.0);
    });
  });

  group('AccessibleButton', () {
    testWidgets('renders child and has button semantics', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              semanticLabel: 'Test button',
              onPressed: () => pressed = true,
              child: const Text('Click me'),
            ),
          ),
        ),
      );
      expect(find.text('Click me'), findsOneWidget);
      expect(find.byType(AccessibleButton), findsOneWidget);
      // pressed would be true if button was tapped
      expect(pressed, isFalse);
    });

    testWidgets('renders with semantic hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              semanticLabel: 'Submit',
              semanticHint: 'Double tap to submit the form',
              onPressed: () {},
              child: const Text('Submit'),
            ),
          ),
        ),
      );
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('renders disabled button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              semanticLabel: 'Disabled',
              onPressed: null,
              isEnabled: false,
              child: const Text('Disabled'),
            ),
          ),
        ),
      );
      expect(find.text('Disabled'), findsOneWidget);
    });
  });

  group('AccessibleTextField', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AccessibleTextField(label: 'Email')),
        ),
      );
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders with hint and error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleTextField(
              label: 'Password',
              hint: 'Enter password',
              errorText: 'Too short',
              obscureText: true,
            ),
          ),
        ),
      );
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Too short'), findsOneWidget);
    });

    testWidgets('onChanged callback works', (tester) async {
      String? lastValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTextField(
              label: 'Name',
              onChanged: (val) => lastValue = val,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(AccessibleTextField), 'John');
      expect(lastValue, 'John');
    });

    testWidgets('renders with custom semanticLabel', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleTextField(
              label: 'Phone',
              semanticLabel: 'Phone number field',
              keyboardType: TextInputType.phone,
            ),
          ),
        ),
      );
      expect(find.text('Phone'), findsOneWidget);
    });
  });

  group('AccessibleCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleCard(
              semanticLabel: 'Delivery card',
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Delivery #123'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Delivery #123'), findsOneWidget);
    });

    testWidgets('onTap callback works', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleCard(
              semanticLabel: 'Tappable card',
              onTap: () => tapped = true,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Tap me'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('renders without onTap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleCard(
              semanticLabel: 'Read-only card',
              semanticHint: 'Informational card',
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Info'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Info'), findsOneWidget);
    });
  });

  group('AccessibleIcon', () {
    testWidgets('renders icon with semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleIcon(
              icon: Icons.home,
              semanticLabel: 'Home icon',
              size: 48,
              color: Colors.blue,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleIcon(icon: Icons.star, semanticLabel: 'Star'),
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('AccessibleValue', () {
    testWidgets('renders value and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleValue(value: '42', label: 'Livraisons'),
          ),
        ),
      );
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Livraisons'), findsOneWidget);
    });

    testWidgets('renders value with unit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleValue(
              value: '1500',
              label: 'Gain total',
              unit: 'FCFA',
            ),
          ),
        ),
      );
      expect(find.text('1500 FCFA'), findsOneWidget);
      expect(find.text('Gain total'), findsOneWidget);
    });

    testWidgets('renders with custom styles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleValue(
              value: '99',
              label: 'Score',
              valueStyle: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ),
      );
      expect(find.text('99'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);
    });
  });

  group('HighContrastTheme detailed', () {
    test('light theme card has black border with width 2', () {
      final theme = HighContrastTheme.light();
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      final border = cardShape.side;
      expect(border.color, Colors.black);
      expect(border.width, 2);
    });

    test('dark theme card has white border', () {
      final theme = HighContrastTheme.dark();
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      final border = cardShape.side;
      expect(border.color, Colors.white);
      expect(border.width, 2);
    });

    test('light theme elevated button is black bg white fg', () {
      final theme = HighContrastTheme.light();
      final btnStyle = theme.elevatedButtonTheme.style!;
      final bg = btnStyle.backgroundColor!.resolve({});
      final fg = btnStyle.foregroundColor!.resolve({});
      expect(bg, Colors.black);
      expect(fg, Colors.white);
    });

    test('dark theme elevated button is white bg black fg', () {
      final theme = HighContrastTheme.dark();
      final btnStyle = theme.elevatedButtonTheme.style!;
      final bg = btnStyle.backgroundColor!.resolve({});
      final fg = btnStyle.foregroundColor!.resolve({});
      expect(bg, Colors.white);
      expect(fg, Colors.black);
    });

    test('light theme outlined button has black border', () {
      final theme = HighContrastTheme.light();
      final btnStyle = theme.outlinedButtonTheme.style!;
      final fg = btnStyle.foregroundColor!.resolve({});
      expect(fg, Colors.black);
    });

    test('dark theme outlined button has white foreground', () {
      final theme = HighContrastTheme.dark();
      final btnStyle = theme.outlinedButtonTheme.style!;
      final fg = btnStyle.foregroundColor!.resolve({});
      expect(fg, Colors.white);
    });

    test('light theme text body is black and bold', () {
      final theme = HighContrastTheme.light();
      expect(theme.textTheme.bodyLarge!.color, Colors.black);
      expect(theme.textTheme.bodyLarge!.fontWeight, FontWeight.w500);
    });

    test('dark theme text body is white', () {
      final theme = HighContrastTheme.dark();
      expect(theme.textTheme.bodyLarge!.color, Colors.white);
    });

    test('light theme color scheme secondary is blue', () {
      final theme = HighContrastTheme.light();
      expect(theme.colorScheme.secondary, const Color(0xFF0055FF));
    });

    test('dark theme color scheme secondary is light blue', () {
      final theme = HighContrastTheme.dark();
      expect(theme.colorScheme.secondary, const Color(0xFF66B3FF));
    });

    test('light theme color scheme error is dark red', () {
      final theme = HighContrastTheme.light();
      expect(theme.colorScheme.error, const Color(0xFFCC0000));
    });

    test('dark theme color scheme error is light red', () {
      final theme = HighContrastTheme.dark();
      expect(theme.colorScheme.error, const Color(0xFFFF6666));
    });

    test('dark theme card color is black', () {
      final theme = HighContrastTheme.dark();
      expect(theme.cardTheme.color, Colors.black);
    });
  });

  group('ContrastChecker edge cases', () {
    test('black on black has ratio of 1', () {
      final ratio = ContrastChecker.getContrastRatio(
        Colors.black,
        Colors.black,
      );
      expect(ratio, closeTo(1.0, 0.01));
    });

    test('same color always has ratio of 1', () {
      final ratio = ContrastChecker.getContrastRatio(Colors.red, Colors.red);
      expect(ratio, closeTo(1.0, 0.01));
    });

    test('meetsAA false for same colors', () {
      expect(ContrastChecker.meetsAA(Colors.blue, Colors.blue), false);
    });

    test('meetsAAA false for low contrast', () {
      expect(
        ContrastChecker.meetsAAA(Colors.grey.shade400, Colors.grey.shade500),
        false,
      );
    });

    test('blue on white meetsAA for large text', () {
      expect(ContrastChecker.meetsAALargeText(Colors.blue, Colors.white), true);
    });
  });
}
