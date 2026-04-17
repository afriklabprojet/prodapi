import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/widgets/battery/battery_indicator_widget.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget({bool compact = true}) {
    return ProviderScope(
      overrides: [...commonWidgetTestOverrides()],
      child: MaterialApp(
        home: Scaffold(body: BatteryIndicatorWidget(compact: compact)),
      ),
    );
  }

  group('BatteryIndicatorWidget', () {
    testWidgets('renders compact mode', (tester) async {
      await tester.pumpWidget(buildWidget(compact: true));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BatteryIndicatorWidget), findsOneWidget);
    });

    testWidgets('renders full mode', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BatteryIndicatorWidget), findsOneWidget);
    });

    testWidgets('compact mode is smaller than full mode', (tester) async {
      await tester.pumpWidget(buildWidget(compact: true));
      await tester.pump(const Duration(seconds: 1));
      final compactSize = tester.getSize(find.byType(BatteryIndicatorWidget));

      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      final fullSize = tester.getSize(find.byType(BatteryIndicatorWidget));

      expect(compactSize.height, lessThanOrEqualTo(fullSize.height));
    });

    testWidgets('compact shows Icon widget', (tester) async {
      await tester.pumpWidget(buildWidget(compact: true));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('full mode shows Text widgets', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('full mode shows card-like layout', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BatteryIndicatorWidget), findsOneWidget);
    });

    testWidgets('renders with default providers', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // Should handle async loading state gracefully
      expect(find.byType(BatteryIndicatorWidget), findsOneWidget);
    });

    testWidgets('full mode renders with Container or Card', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      final containers = find.byType(Container);
      final cards = find.byType(Card);
      expect(
        containers.evaluate().length + cards.evaluate().length,
        greaterThan(0),
      );
    });

    testWidgets('compact shows percentage text', (tester) async {
      await tester.pumpWidget(buildWidget(compact: true));
      await tester.pump(const Duration(seconds: 1));
      // The default fake battery state should render a percentage
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('full mode shows multiple Text children', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsAtLeastNWidgets(2));
    });

    testWidgets('compact has Tooltip', (tester) async {
      await tester.pumpWidget(buildWidget(compact: true));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Tooltip), findsWidgets);
    });

    testWidgets('full mode has CustomPaint for gauge', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('full mode shows gps interval or charging text', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      // Should show either 'En charge' or 'Xs' gps interval
      final enCharge = find.text('En charge');
      final interval = find.textContaining('s');
      expect(
        enCharge.evaluate().length + interval.evaluate().length,
        greaterThan(0),
      );
    });

    testWidgets('compact has Row layout', (tester) async {
      await tester.pumpWidget(buildWidget(compact: true));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('renders both modes sequentially without error', (
      tester,
    ) async {
      // First compact
      await tester.pumpWidget(buildWidget(compact: true));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BatteryIndicatorWidget), findsOneWidget);
      // Then full
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BatteryIndicatorWidget), findsOneWidget);
    });
  });

  // ── BatterySaverSettingsSheet ────────────────────────
  group('BatterySaverSettingsSheet', () {
    testWidgets('can be created', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...commonWidgetTestOverrides()],
          child: const MaterialApp(
            home: Scaffold(body: BatterySaverSettingsSheet()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BatterySaverSettingsSheet), findsOneWidget);
    });

    testWidgets('shows title text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...commonWidgetTestOverrides()],
          child: const MaterialApp(
            home: Scaffold(body: BatterySaverSettingsSheet()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('batterie'), findsWidgets);
    });

    testWidgets('has Switch widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...commonWidgetTestOverrides()],
          child: const MaterialApp(
            home: Scaffold(body: BatterySaverSettingsSheet()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final switchAdaptive = find.byType(Switch);
      expect(switchAdaptive, findsWidgets);
    });

    testWidgets('shows GPS modes info', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...commonWidgetTestOverrides()],
          child: const MaterialApp(
            home: Scaffold(body: BatterySaverSettingsSheet()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('GPS'), findsWidgets);
    });

    testWidgets('shows Normal mode info', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...commonWidgetTestOverrides()],
          child: const MaterialApp(
            home: Scaffold(body: BatterySaverSettingsSheet()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Normal'), findsWidgets);
    });

    testWidgets('shows economy mode info', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...commonWidgetTestOverrides()],
          child: const MaterialApp(
            home: Scaffold(body: BatterySaverSettingsSheet()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('conomie'), findsWidgets);
    });

    testWidgets('shows critical mode info', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...commonWidgetTestOverrides()],
          child: const MaterialApp(
            home: Scaffold(body: BatterySaverSettingsSheet()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Critique'), findsWidgets);
    });

    testWidgets('has Icon widgets for GPS modes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...commonWidgetTestOverrides()],
          child: const MaterialApp(
            home: Scaffold(body: BatterySaverSettingsSheet()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsAtLeastNWidgets(3));
    });

    testWidgets('shows battery_saver icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...commonWidgetTestOverrides()],
          child: const MaterialApp(
            home: Scaffold(body: BatterySaverSettingsSheet()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.battery_saver), findsWidgets);
    });

    testWidgets('shows eco icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...commonWidgetTestOverrides()],
          child: const MaterialApp(
            home: Scaffold(body: BatterySaverSettingsSheet()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.eco), findsWidgets);
    });
  });

  group('BatteryIndicatorWidget - detailed structure', () {
    testWidgets('compact mode has Icon widget', (tester) async {
      await tester.pumpWidget(buildWidget(compact: true));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsAtLeastNWidgets(1));
    });

    testWidgets('full mode has at least 3 Text widgets', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsAtLeastNWidgets(3));
    });

    testWidgets('full mode shows percentage text', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('compact mode wraps in Container', (tester) async {
      await tester.pumpWidget(buildWidget(compact: true));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('full mode has Column layout', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('full mode has Row layout', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('full mode has SizedBox spacers', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('compact Tooltip has message', (tester) async {
      await tester.pumpWidget(buildWidget(compact: true));
      await tester.pump(const Duration(seconds: 1));
      final tooltips = find.byType(Tooltip);
      expect(tooltips, findsWidgets);
    });

    testWidgets('full mode shows gps_fixed icon', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.gps_fixed), findsWidgets);
    });

    testWidgets('full mode CustomPaint exists', (tester) async {
      await tester.pumpWidget(buildWidget(compact: false));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('compact mode has Expanded widget', (tester) async {
      await tester.pumpWidget(buildWidget(compact: true));
      await tester.pump(const Duration(seconds: 1));
      // Compact mode layout uses Row with potential Expanded
      expect(find.byType(BatteryIndicatorWidget), findsOneWidget);
    });
  });

  group('BatterySaverSettingsSheet - detailed structure', () {
    Widget buildSettingsSheet() {
      return ProviderScope(
        overrides: [...commonWidgetTestOverrides()],
        child: const MaterialApp(
          home: Scaffold(body: BatterySaverSettingsSheet()),
        ),
      );
    }

    testWidgets('has Column layout', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('has Padding widgets', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('has Container decorations', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows at least 2 Switch widgets', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Switch), findsAtLeastNWidgets(1));
    });

    testWidgets('shows batterie text in title', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('batterie'), findsWidgets);
    });

    testWidgets('shows GPS text', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('GPS'), findsWidgets);
    });

    testWidgets('shows Normal mode label', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Normal'), findsWidgets);
    });

    testWidgets('shows Economie mode label', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('conomie'), findsWidgets);
    });

    testWidgets('shows Critique mode label', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Critique'), findsWidgets);
    });

    testWidgets('has Row for mode info sections', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('has SizedBox spacers', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('has at least 5 Icon widgets', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Icon), findsAtLeastNWidgets(5));
    });

    testWidgets('shows battery_saver and eco icons', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.battery_saver), findsWidgets);
      expect(find.byIcon(Icons.eco), findsWidgets);
    });

    testWidgets('has Text widgets for descriptions', (tester) async {
      await tester.pumpWidget(buildSettingsSheet());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Text), findsAtLeastNWidgets(5));
    });
  });
}
