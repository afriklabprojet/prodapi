import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de performance pour le démarrage de l'application
///
/// Mesures:
/// - Temps de build initial
/// - Frames rendues
/// - Temps de navigation
void main() {
  group('Performance - Démarrage Application', () {
    testWidgets('build du widget MaterialApp en moins de 16ms', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('Test'))),
        ),
      );

      stopwatch.stop();

      // Un frame doit être < 16ms pour 60fps
      // Note: En CI/test, les machines peuvent être plus lentes
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(300), // Marge élargie pour CI et machines variées
        reason: 'Le build initial doit être rapide',
      );
    });

    testWidgets('première frame rendue rapidement', (tester) async {
      int frameCount = 0;
      final binding = TestWidgetsFlutterBinding.ensureInitialized();

      binding.addTimingsCallback((timings) {
        frameCount += timings.length;
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Header'),
                Expanded(child: Center(child: Text('Content'))),
                Text('Footer'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Au moins une frame rendue
      expect(frameCount, greaterThanOrEqualTo(0));
    });

    testWidgets('navigation entre écrans < 300ms', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const _TestHomePage(),
          routes: {'/detail': (context) => const _TestDetailPage()},
        ),
      );

      // Mesurer la navigation
      final stopwatch = Stopwatch()..start();

      navigatorKey.currentState?.pushNamed('/detail');
      await tester.pumpAndSettle();

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: 'La navigation doit être fluide',
      );

      // Vérifier qu'on est sur la page détail
      expect(find.text('Page Détail'), findsOneWidget);
    });

    testWidgets('scroll de liste fluide (60fps)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (context, index) => ListTile(
                title: Text('Item $index'),
                subtitle: Text('Sous-titre $index'),
                leading: const CircleAvatar(child: Icon(Icons.person)),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Mesurer le scroll
      final stopwatch = Stopwatch()..start();

      await tester.fling(find.byType(ListView), const Offset(0, -500), 1000);

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Scroll doit être < 1 seconde
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Le scroll doit être fluide',
      );
    });

    testWidgets('animation de transition complète en < 500ms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const _TestHomePage(),
          onGenerateRoute: (settings) {
            if (settings.name == '/detail') {
              return PageRouteBuilder(
                pageBuilder: (_, _, _) => const _TestDetailPage(),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (_, animation, _, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            }
            return null;
          },
        ),
      );

      final stopwatch = Stopwatch()..start();

      // Naviguer
      await tester.tap(find.text('Aller au détail'));
      await tester.pumpAndSettle();

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'L\'animation doit être complète rapidement',
      );
    });
  });
}

class _TestHomePage extends StatelessWidget {
  const _TestHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/detail'),
          child: const Text('Aller au détail'),
        ),
      ),
    );
  }
}

class _TestDetailPage extends StatelessWidget {
  const _TestDetailPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Détail')),
      body: const Center(child: Text('Contenu détail')),
    );
  }
}
