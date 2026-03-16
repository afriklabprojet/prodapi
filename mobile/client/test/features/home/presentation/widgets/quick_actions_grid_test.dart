import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:drpharma_client/features/home/presentation/widgets/quick_actions_grid.dart';
import 'package:drpharma_client/core/constants/app_colors.dart';

/// Helper widget that provides GoRouter context for QuickActionsGrid tests
Widget _buildGridTestApp({required Widget child}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'productsList',
        builder: (_, _,) => Scaffold(body: child),
      ),
      GoRoute(path: '/pharmacies', builder: (_, _,) => const SizedBox()),
      GoRoute(path: '/on-duty-pharmacies', builder: (_, _,) => const SizedBox()),
      GoRoute(path: '/prescriptions', builder: (_, _,) => const SizedBox()),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('QuickActionCard', () {
    testWidgets('should render with given title and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionCard(
              icon: Icons.category,
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              color: Colors.blue,
              isDark: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('should render with given icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionCard(
              icon: Icons.medication,
              title: 'Title',
              subtitle: 'Subtitle',
              color: Colors.red,
              isDark: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.medication), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      bool wasTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionCard(
              icon: Icons.touch_app,
              title: 'Tap Me',
              subtitle: 'Tap here',
              color: Colors.green,
              isDark: false,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('should have white background when not dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionCard(
              icon: Icons.category,
              title: 'Light Mode',
              subtitle: 'Subtitle',
              color: Colors.blue,
              isDark: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(QuickActionCard),
          matching: find.byType(Container),
        ),
      ).firstWhere((c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).color == Colors.white);

      expect(container, isNotNull);
    });

    testWidgets('should have icon with given color', (tester) async {
      const testColor = Colors.orange;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionCard(
              icon: Icons.star,
              title: 'Title',
              subtitle: 'Subtitle',
              color: testColor,
              isDark: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, testColor);
    });

    testWidgets('should have dark text when not in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionCard(
              icon: Icons.category,
              title: 'Dark Text Title',
              subtitle: 'Subtitle',
              color: Colors.blue,
              isDark: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Dark Text Title'));
      expect(title.style?.color, AppColors.textPrimary);
    });

    testWidgets('should have white text when in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionCard(
              icon: Icons.category,
              title: 'White Text Title',
              subtitle: 'Subtitle',
              color: Colors.blue,
              isDark: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('White Text Title'));
      expect(title.style?.color, Colors.white);
    });

    testWidgets('should have bold title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionCard(
              icon: Icons.category,
              title: 'Bold Title',
              subtitle: 'Subtitle',
              color: Colors.blue,
              isDark: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Bold Title'));
      expect(title.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('should truncate long subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150, // Constrain width
              child: QuickActionCard(
                icon: Icons.category,
                title: 'Title',
                subtitle: 'This is a very very very long subtitle that should be truncated',
                color: Colors.blue,
                isDark: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final subtitle = tester.widget<Text>(
        find.text('This is a very very very long subtitle that should be truncated'),
      );
      expect(subtitle.maxLines, 1);
      expect(subtitle.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should have rounded corners', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionCard(
              icon: Icons.category,
              title: 'Title',
              subtitle: 'Subtitle',
              color: Colors.blue,
              isDark: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(QuickActionCard),
          matching: find.byType(Container),
        ),
      ).firstWhere(
        (c) => c.decoration is BoxDecoration && 
               (c.decoration as BoxDecoration).borderRadius == BorderRadius.circular(20),
        orElse: () => throw Exception('No container with expected border radius found'),
      );

      expect(container, isNotNull);
    });
  });

  group('QuickActionsGrid', () {
    testWidgets('should render four quick action cards', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(child: const QuickActionsGrid(isDark: false)),
      );

      expect(find.byType(QuickActionCard), findsNWidgets(4));
    });

    testWidgets('should have Médicaments card', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(child: const QuickActionsGrid(isDark: false)),
      );

      expect(find.text('Médicaments'), findsOneWidget);
      expect(find.text('Tous les produits'), findsOneWidget);
    });

    testWidgets('should have Garde card', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(child: const QuickActionsGrid(isDark: false)),
      );

      expect(find.text('Garde'), findsOneWidget);
      expect(find.text('Pharmacies de garde'), findsOneWidget);
    });

    testWidgets('should have Pharmacies card', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(child: const QuickActionsGrid(isDark: false)),
      );

      expect(find.text('Pharmacies'), findsOneWidget);
      expect(find.text('Trouver à proximité'), findsOneWidget);
    });

    testWidgets('should have Ordonnance card', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(child: const QuickActionsGrid(isDark: false)),
      );

      expect(find.text('Ordonnance'), findsOneWidget);
      expect(find.text('Mes ordonnances'), findsOneWidget);
    });

    testWidgets('should pass isDark to cards', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(child: const QuickActionsGrid(isDark: true)),
      );

      final cards = tester.widgetList<QuickActionCard>(find.byType(QuickActionCard));
      for (final card in cards) {
        expect(card.isDark, isTrue);
      }
    });

    testWidgets('should have medication icon for Médicaments card', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(child: const QuickActionsGrid(isDark: false)),
      );

      expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
    });

    testWidgets('should have emergency icon for Garde card', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(child: const QuickActionsGrid(isDark: false)),
      );

      expect(find.byIcon(Icons.emergency_outlined), findsOneWidget);
    });

    testWidgets('should have pharmacy icon for Pharmacies card', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(child: const QuickActionsGrid(isDark: false)),
      );

      expect(find.byIcon(Icons.local_pharmacy_outlined), findsOneWidget);
    });

    testWidgets('should have upload icon for Ordonnance card', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(child: const QuickActionsGrid(isDark: false)),
      );

      expect(find.byIcon(Icons.upload_file_outlined), findsOneWidget);
    });

    testWidgets('should render as 2x2 grid', (tester) async {
      // Set a mobile-sized screen (< 768px width) so ResponsiveUtils returns mobile values
      // Use a tall enough screen to avoid RenderFlex overflow
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildGridTestApp(child: const QuickActionsGrid(isDark: false)),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect((gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount, 2);
    });
  });
}
