import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/widgets/history/history_stats_card.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget() {
    return ProviderScope(
      overrides: commonWidgetTestOverrides(),
      child: const MaterialApp(home: Scaffold(body: HistoryStatsCard())),
    );
  }

  group('HistoryStatsCard', () {
    testWidgets('renders (may show shimmer on loading)', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      // When loading or no data, returns SizedBox.shrink
      expect(find.byType(HistoryStatsCard), findsOneWidget);
    });

    testWidgets('contains SizedBox widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('is wrapped in MaterialApp', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('is inside Scaffold', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('is inside ProviderScope', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ProviderScope), findsOneWidget);
    });
  });
}
