import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/home/itinerary_sheet.dart';
import 'package:courier/data/models/route_info.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  RouteInfo makeRouteInfo() {
    return RouteInfo(
      points: const [LatLng(5.36, -4.01), LatLng(5.37, -4.02)],
      totalDistance: '3.5 km',
      totalDuration: '12 min',
      steps: [
        RouteStep(
          instruction: 'Tourner à gauche sur Rue 12',
          distance: '500 m',
          duration: '2 min',
        ),
        RouteStep(
          instruction: 'Continuer tout droit',
          distance: '3 km',
          duration: '10 min',
        ),
      ],
    );
  }

  Widget buildWidget(RouteInfo routeInfo) {
    return MaterialApp(
      home: Scaffold(body: ItinerarySheet(routeInfo: routeInfo)),
    );
  }

  group('ItinerarySheet', () {
    testWidgets('renders with route info', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      expect(find.byType(ItinerarySheet), findsOneWidget);
    });

    testWidgets('displays total distance', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      expect(find.textContaining('3.5'), findsWidgets);
    });

    testWidgets('displays route steps', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      // Steps display distance/duration as Text; instructions rendered via RichText (SimpleHtmlText)
      expect(find.textContaining('500 m'), findsWidgets);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('contains Column widgets', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('displays total duration', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      expect(find.textContaining('12'), findsWidgets);
    });

    testWidgets('contains Container widgets', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      expect(find.byType(Container), findsWidgets);
    });

    // ── Content assertions ──

    testWidgets('shows "Itinéraire" header', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      expect(find.text('Itinéraire'), findsOneWidget);
    });

    testWidgets('shows directions icons for steps', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      expect(find.byIcon(Icons.directions), findsWidgets);
    });

    testWidgets('shows second step distance', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      expect(find.textContaining('3 km'), findsWidgets);
    });

    testWidgets('shows combined distance and duration', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      // Check both total distance and total duration are present
      expect(find.textContaining('3.5 km'), findsWidgets);
      expect(find.textContaining('12 min'), findsWidgets);
    });

    testWidgets('renders with route that has no steps', (tester) async {
      final emptyRoute = RouteInfo(
        points: const [LatLng(5.36, -4.01)],
        totalDistance: '1 km',
        totalDuration: '5 min',
        steps: [],
      );
      await tester.pumpWidget(buildWidget(emptyRoute));
      expect(find.byType(ItinerarySheet), findsOneWidget);
    });

    testWidgets('renders steps content', (tester) async {
      await tester.pumpWidget(buildWidget(makeRouteInfo()));
      // Steps show addresses
      expect(find.byType(ItinerarySheet), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });
  });
}
