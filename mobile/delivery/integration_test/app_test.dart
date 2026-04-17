import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/main.dart';

/// Point d'entrée principal des tests d'intégration
/// Lance tous les tests de flux utilisateur
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('App Integration Tests', () {
    testWidgets('App should launch without errors', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();
      
      // L'app devrait démarrer et afficher le splash screen ou login
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
