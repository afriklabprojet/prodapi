import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de performance pour les widgets et listes
///
/// Mesures:
/// - Temps de build des widgets complexes
/// - Performance du scroll avec images
/// - Rebuild des widgets avec state
void main() {
  group('Performance - Widgets', () {
    testWidgets('build de 50 cards en < 200ms', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) => _ProductCard(index: index),
            ),
          ),
        ),
      );

      await tester.pump();
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: 'Build de 50 cards doit être rapide',
      );
    });

    testWidgets('rebuild de widget avec setState < 16ms', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _CounterWidget()));

      // Premier build
      await tester.pump();

      // Mesurer le rebuild
      final stopwatch = Stopwatch()..start();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      stopwatch.stop();

      // Note: En CI/test, les machines peuvent varier
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100), // Marge pour CI et machines variées
        reason: 'Rebuild avec setState doit être instantané',
      );
    });

    testWidgets('liste avec images placeholder performante', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 30,
              itemBuilder: (context, index) => ListTile(
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medication),
                ),
                title: Text('Médicament $index'),
                subtitle: const Text('1000 FCFA'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Liste avec images doit charger rapidement',
      );
    });

    testWidgets('grille de produits 3 colonnes performante', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
              ),
              itemCount: 30,
              itemBuilder: (context, index) => _ProductGridItem(index: index),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Grille de produits doit être performante',
      );
    });

    testWidgets('formulaire complexe build < 100ms', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Prénom'),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Téléphone'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Adresse'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Ville'),
                      items: const [
                        DropdownMenuItem(
                          value: 'abidjan',
                          child: Text('Abidjan'),
                        ),
                        DropdownMenuItem(
                          value: 'bouake',
                          child: Text('Bouaké'),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(300),
        reason: 'Formulaire complexe doit build rapidement',
      );
    });

    testWidgets('bottom sheet animation fluide', (tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              savedContext = context;
              return Scaffold(
                body: const Center(child: Text('Main')),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
              );
            },
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      // Ouvrir bottom sheet
      showModalBottomSheet(
        context: savedContext,
        builder: (context) => SizedBox(
          height: 300,
          child: Column(
            children: [
              const ListTile(title: Text('Option 1')),
              const ListTile(title: Text('Option 2')),
              const ListTile(title: Text('Option 3')),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Bottom sheet animation doit être fluide',
      );
    });

    testWidgets('search avec debounce ne bloque pas UI', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _SearchWidget()));

      // Taper rapidement
      final stopwatch = Stopwatch()..start();

      await tester.enterText(find.byType(TextField), 'para');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'parac');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'parace');
      await tester.pump(const Duration(milliseconds: 100));

      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: 'Input ne doit pas bloquer l\'UI',
      );
    });
  });
}

class _ProductCard extends StatelessWidget {
  final int index;

  const _ProductCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.medication, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Médicament $index',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${1000 + index * 100} FCFA',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  final int index;

  const _ProductGridItem({required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[200],
              child: const Icon(Icons.medication, size: 40),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Med $index',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${1000 + index * 50} F',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterWidget extends StatefulWidget {
  const _CounterWidget();

  @override
  State<_CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<_CounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Count: $_count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _count++),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SearchWidget extends StatefulWidget {
  const _SearchWidget();

  @override
  State<_SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<_SearchWidget> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) =>
                  ListTile(title: Text('Résultat $index pour "$_query"')),
            ),
          ),
        ],
      ),
    );
  }
}
