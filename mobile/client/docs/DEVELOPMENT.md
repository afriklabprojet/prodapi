# 🚀 Guide de Développement - DR-Pharma User

Ce guide définit les standards, conventions et bonnes pratiques pour le développement de l'application DR-Pharma User.

## 📋 Table des Matières

1. [Configuration de l'Environnement](#configuration-de-lenvironnement)
2. [Conventions de Code](#conventions-de-code)
3. [Structure des Fichiers](#structure-des-fichiers)
4. [Patterns et Bonnes Pratiques](#patterns-et-bonnes-pratiques)
5. [Tests](#tests)
6. [Git Workflow](#git-workflow)
7. [Performance](#performance)
8. [Debugging](#debugging)

---

## 🛠️ Configuration de l'Environnement

### Prérequis

```bash
# Flutter SDK
flutter --version
# Flutter 3.10.0 ou supérieur requis

# Dart SDK
dart --version
# Dart 3.0.0 ou supérieur requis
```

### Installation

```bash
# Cloner le repository
git clone <repository-url>
cd DR-PHARMA/Mobile/user

# Installer les dépendances
flutter pub get

# Vérifier l'installation
flutter doctor
```

### Configuration IDE

#### VS Code Extensions Recommandées

```json
{
  "recommendations": [
    "Dart-Code.dart-code",
    "Dart-Code.flutter",
    "usernamehw.errorlens",
    "pflannery.vscode-versionlens",
    "alexisvt.flutter-snippets"
  ]
}
```

#### Settings VS Code

```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "[dart]": {
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.rulers": [80]
  }
}
```

### Variables d'Environnement

```dart
// lib/core/config/environment.dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );
  
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
}
```

```bash
# Lancer avec des variables d'environnement
flutter run --dart-define=API_BASE_URL=https://api.drlpharma.pro
```

---

## 📝 Conventions de Code

### Nommage

| Type | Convention | Exemple |
|------|------------|---------|
| Classes | PascalCase | `PharmacyRepository` |
| Variables | camelCase | `selectedPharmacy` |
| Constantes | camelCase | `maxRetryAttempts` |
| Fichiers | snake_case | `pharmacy_repository.dart` |
| Dossiers | snake_case | `data_sources` |
| Providers | camelCase + Provider | `pharmacyProvider` |
| Extensions | PascalCase + Extension | `StringExtension` |

### Imports

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Packages externes
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. Packages internes (absolus)
import 'package:drpharma_client/core/security/security.dart';
import 'package:drpharma_client/features/pharmacy/domain/entities/pharmacy.dart';

// 4. Imports relatifs (même feature)
import '../widgets/pharmacy_card.dart';
import '../../domain/entities/pharmacy.dart';
```

### Documentation

```dart
/// Représente une pharmacie dans le système DR-Pharma.
/// 
/// Cette entité contient toutes les informations nécessaires
/// pour afficher et gérer une pharmacie.
/// 
/// Exemple d'utilisation:
/// ```dart
/// final pharmacy = Pharmacy(
///   id: '123',
///   name: 'Pharmacie du Centre',
///   address: Address(...),
/// );
/// ```
class Pharmacy {
  /// Identifiant unique de la pharmacie.
  final String id;
  
  /// Nom commercial de la pharmacie.
  final String name;
  
  /// Crée une nouvelle instance de [Pharmacy].
  /// 
  /// [id] et [name] sont obligatoires.
  const Pharmacy({
    required this.id,
    required this.name,
  });
}
```

### Formatage

```dart
// ✅ Bon : paramètres sur plusieurs lignes si > 80 caractères
Widget buildCard({
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  Color? backgroundColor,
}) {
  return Card(...);
}

// ✅ Bon : trailing comma pour formatage automatique
return Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(title),
);

// ❌ Mauvais : tout sur une ligne
return Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Text(title));
```

---

## 📁 Structure des Fichiers

### Feature Module

```
lib/features/pharmacy/
├── data/
│   ├── datasources/
│   │   ├── pharmacy_local_datasource.dart
│   │   └── pharmacy_remote_datasource.dart
│   ├── models/
│   │   ├── pharmacy_model.dart
│   │   └── pharmacy_model.g.dart  # Generated
│   └── repositories/
│       └── pharmacy_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── pharmacy.dart
│   ├── repositories/
│   │   └── pharmacy_repository.dart  # Interface
│   └── usecases/
│       ├── get_nearby_pharmacies.dart
│       └── get_pharmacy_details.dart
└── presentation/
    ├── pages/
    │   ├── pharmacy_list_page.dart
    │   └── pharmacy_details_page.dart
    ├── providers/
    │   └── pharmacy_providers.dart
    └── widgets/
        ├── pharmacy_card.dart
        └── pharmacy_map.dart
```

### Core Module

```
lib/core/
├── accessibility/     # Widgets et thèmes accessibles
├── animations/        # Animations réutilisables
├── config/           # Configuration et environnement
├── constants/        # Constantes globales
├── errors/           # Classes d'exception
├── extensions/       # Extensions Dart
├── network/          # Client HTTP et intercepteurs
├── performance/      # Optimisations et monitoring
├── providers/        # Providers globaux
├── security/         # Sécurité et validation
├── storage/          # Stockage local
├── theme/            # Thèmes et styles
├── utils/            # Utilitaires
└── widgets/          # Widgets réutilisables
```

---

## 🎯 Patterns et Bonnes Pratiques

### Clean Architecture

```dart
// 1. Entity (Domain) - Pure Dart, pas de dépendances
class Pharmacy {
  final String id;
  final String name;
  final Address address;
  
  const Pharmacy({
    required this.id,
    required this.name,
    required this.address,
  });
}

// 2. Repository Interface (Domain)
abstract class PharmacyRepository {
  Future<List<Pharmacy>> getNearby(LatLng location);
  Future<Pharmacy> getById(String id);
}

// 3. Model (Data) - Avec sérialisation JSON
class PharmacyModel extends Pharmacy {
  const PharmacyModel({
    required super.id,
    required super.name,
    required super.address,
  });
  
  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: AddressModel.fromJson(json['address']),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': (address as AddressModel).toJson(),
  };
}

// 4. Repository Implementation (Data)
class PharmacyRepositoryImpl implements PharmacyRepository {
  final PharmacyRemoteDataSource _remoteDataSource;
  final PharmacyLocalDataSource _localDataSource;
  
  @override
  Future<List<Pharmacy>> getNearby(LatLng location) async {
    try {
      final pharmacies = await _remoteDataSource.getNearby(location);
      await _localDataSource.cachePharmacies(pharmacies);
      return pharmacies;
    } catch (e) {
      return await _localDataSource.getCachedPharmacies();
    }
  }
}
```

### State Management avec Riverpod

```dart
// Provider simple
final pharmacyRepositoryProvider = Provider<PharmacyRepository>((ref) {
  return PharmacyRepositoryImpl(
    remoteDataSource: ref.watch(remoteDataSourceProvider),
    localDataSource: ref.watch(localDataSourceProvider),
  );
});

// FutureProvider pour données asynchrones
final nearbyPharmaciesProvider = FutureProvider.family<List<Pharmacy>, LatLng>(
  (ref, location) async {
    final repository = ref.watch(pharmacyRepositoryProvider);
    return repository.getNearby(location);
  },
);

// StateNotifierProvider pour état mutable
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());
  
  void addItem(Product product) {
    state = state.copyWith(
      items: [...state.items, CartItem(product: product, quantity: 1)],
    );
  }
}
```

### Widgets Réutilisables

```dart
// Widget paramétrable et testable
class PharmacyCard extends StatelessWidget {
  final Pharmacy pharmacy;
  final VoidCallback? onTap;
  final bool showDistance;
  
  const PharmacyCard({
    super.key,
    required this.pharmacy,
    this.onTap,
    this.showDistance = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      semanticLabel: _buildSemanticLabel(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pharmacy.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              pharmacy.address.formatted,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (showDistance && pharmacy.distance != null) ...[
              const SizedBox(height: 8),
              _DistanceChip(distance: pharmacy.distance!),
            ],
          ],
        ),
      ),
    );
  }
  
  String _buildSemanticLabel() {
    final parts = [pharmacy.name, pharmacy.address.formatted];
    if (showDistance && pharmacy.distance != null) {
      parts.add('à ${pharmacy.distance!.toStringAsFixed(1)} km');
    }
    return parts.join(', ');
  }
}
```

### Gestion des Erreurs

```dart
// Result pattern pour éviter les exceptions
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error);
}

// Utilisation
Future<Result<Pharmacy>> getPharmacy(String id) async {
  try {
    final pharmacy = await _dataSource.getPharmacy(id);
    return Success(pharmacy);
  } on NetworkException catch (e) {
    return Failure(e);
  } on ApiException catch (e) {
    return Failure(e);
  }
}

// Dans l'UI
final result = await getPharmacy(id);
switch (result) {
  case Success(value: final pharmacy):
    return PharmacyDetails(pharmacy: pharmacy);
  case Failure(error: final error):
    return ErrorWidget(message: error.message);
}
```

---

## 🧪 Tests

### Structure des Tests

```
test/
├── core/
│   ├── accessibility/
│   │   └── accessibility_test.dart
│   ├── security/
│   │   ├── input_sanitizer_test.dart
│   │   └── network_security_test.dart
│   └── widgets/
│       └── common_widgets_test.dart
├── features/
│   ├── pharmacy/
│   │   ├── data/
│   │   │   └── pharmacy_repository_test.dart
│   │   ├── domain/
│   │   │   └── get_nearby_pharmacies_test.dart
│   │   └── presentation/
│   │       ├── pharmacy_list_page_test.dart
│   │       └── pharmacy_providers_test.dart
│   └── order/
│       └── ...
├── fixtures/
│   └── pharmacy_fixtures.dart
└── mocks/
    └── mock_providers.dart
```

### Test Unitaire

```dart
void main() {
  group('InputSanitizer', () {
    group('sanitizeText', () {
      test('removes HTML tags', () {
        expect(
          InputSanitizer.sanitizeText('<script>alert("xss")</script>Hello'),
          equals('Hello'),
        );
      });
      
      test('trims whitespace', () {
        expect(
          InputSanitizer.sanitizeText('  hello world  '),
          equals('hello world'),
        );
      });
      
      test('handles empty string', () {
        expect(InputSanitizer.sanitizeText(''), equals(''));
      });
    });
    
    group('isValidEmail', () {
      test('returns true for valid email', () {
        expect(InputSanitizer.isValidEmail('test@example.com'), isTrue);
      });
      
      test('returns false for invalid email', () {
        expect(InputSanitizer.isValidEmail('invalid'), isFalse);
      });
    });
  });
}
```

### Test de Widget

```dart
void main() {
  group('PharmacyCard', () {
    testWidgets('displays pharmacy name', (tester) async {
      final pharmacy = Pharmacy(
        id: '1',
        name: 'Pharmacie Test',
        address: Address(street: '123 Rue Test'),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PharmacyCard(pharmacy: pharmacy),
          ),
        ),
      );
      
      expect(find.text('Pharmacie Test'), findsOneWidget);
      expect(find.text('123 Rue Test'), findsOneWidget);
    });
    
    testWidgets('calls onTap when pressed', (tester) async {
      var tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PharmacyCard(
              pharmacy: testPharmacy,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      
      await tester.tap(find.byType(PharmacyCard));
      expect(tapped, isTrue);
    });
    
    testWidgets('has semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PharmacyCard(pharmacy: testPharmacy),
          ),
        ),
      );
      
      expect(
        find.bySemanticsLabel(contains('Pharmacie Test')),
        findsOneWidget,
      );
    });
  });
}
```

### Test d'Intégration

```dart
void main() {
  group('Pharmacy Flow', () {
    testWidgets('user can search and view pharmacy', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pharmacyRepositoryProvider.overrideWithValue(
              MockPharmacyRepository(),
            ),
          ],
          child: const MyApp(),
        ),
      );
      
      // Naviguer vers la recherche
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      // Entrer une recherche
      await tester.enterText(
        find.byType(TextField),
        'Pharmacie du Centre',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      
      // Vérifier les résultats
      expect(find.text('Pharmacie du Centre'), findsOneWidget);
      
      // Ouvrir les détails
      await tester.tap(find.text('Pharmacie du Centre'));
      await tester.pumpAndSettle();
      
      // Vérifier la page de détails
      expect(find.byType(PharmacyDetailsPage), findsOneWidget);
    });
  });
}
```

### Commandes de Test

```bash
# Tous les tests
flutter test

# Tests spécifiques
flutter test test/core/security/

# Avec couverture
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Tests en mode watch
flutter test --watch

# Tests d'intégration
flutter test integration_test/
```

---

## 🌿 Git Workflow

### Branches

| Branche | Description |
|---------|-------------|
| `main` | Production stable |
| `develop` | Développement |
| `feature/*` | Nouvelles fonctionnalités |
| `bugfix/*` | Corrections de bugs |
| `hotfix/*` | Corrections urgentes |
| `release/*` | Préparation de release |

### Commits

```bash
# Format
<type>(<scope>): <description>

# Types
feat:     Nouvelle fonctionnalité
fix:      Correction de bug
docs:     Documentation
style:    Formatage (pas de changement de code)
refactor: Refactoring
test:     Ajout de tests
chore:    Tâches de maintenance

# Exemples
feat(pharmacy): add nearby pharmacies search
fix(auth): handle token refresh on 401
docs(readme): update installation steps
test(security): add InputSanitizer tests
```

### Pull Request

```markdown
## Description
Brève description des changements.

## Type de changement
- [ ] Bug fix
- [ ] Nouvelle fonctionnalité
- [ ] Breaking change
- [ ] Documentation

## Checklist
- [ ] Tests ajoutés/mis à jour
- [ ] Documentation mise à jour
- [ ] Code formaté (`flutter format .`)
- [ ] Pas de warnings (`flutter analyze`)
- [ ] Tests passent (`flutter test`)
```

---

## ⚡ Performance

### Optimisations Widget

```dart
// Utiliser const quand possible
const SizedBox(height: 16)
const EdgeInsets.all(16)
const Text('Static text')

// Éviter rebuilds inutiles
class MyWidget extends StatelessWidget {
  // ✅ Préférer ConsumerWidget à Consumer
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final data = ref.watch(myProvider);
        return Column(
          children: [
            child!, // ✅ Partie statique préservée
            Text(data.value),
          ],
        );
      },
      child: const ExpensiveStaticWidget(), // ✅ Build une seule fois
    );
  }
}

// Utiliser select pour granularité fine
final userName = ref.watch(userProvider.select((u) => u.name));
```

### Optimisations Liste

```dart
// ✅ Utiliser ListView.builder pour listes longues
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
)

// ✅ Utiliser itemExtent pour optimiser le scroll
ListView.builder(
  itemCount: items.length,
  itemExtent: 72, // Hauteur fixe connue
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
)

// ✅ Utiliser cacheExtent pour préchargement
ListView.builder(
  cacheExtent: 500, // Pixels de préchargement
  itemBuilder: ...
)
```

### Optimisations Images

```dart
// ✅ Spécifier les dimensions
Image.network(
  url,
  width: 100,
  height: 100,
  cacheWidth: 200, // Cache en 2x pour retina
  cacheHeight: 200,
)

// ✅ Utiliser CachedNetworkImage
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 200,
  placeholder: (context, url) => Shimmer(...),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

---

## 🐛 Debugging

### Logs

```dart
import 'package:flutter/foundation.dart';

// Log conditionnel (dev only)
if (kDebugMode) {
  print('Debug: $message');
}

// Logger structuré
class AppLogger {
  static void debug(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      print('🔵 DEBUG: $message');
      if (error != null) print('   Error: $error');
    }
  }
  
  static void error(String message, [Object? error, StackTrace? stack]) {
    print('🔴 ERROR: $message');
    if (error != null) print('   Error: $error');
    if (stack != null) print('   Stack: $stack');
  }
  
  static void info(String message) {
    print('🟢 INFO: $message');
  }
}
```

### DevTools

```bash
# Ouvrir DevTools
flutter run
# Puis presser 'd' dans le terminal

# Ou via URL
flutter run --observatory-port=8888
# Ouvrir http://localhost:8888
```

### Performance Overlay

```dart
MaterialApp(
  showPerformanceOverlay: kDebugMode,
  // ...
)
```

### Riverpod Logger

```dart
class ProviderLogger extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      print('Provider created: ${provider.name ?? provider.runtimeType}');
    }
  }
  
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      print('Provider updated: ${provider.name ?? provider.runtimeType}');
    }
  }
}

// Usage
void main() {
  runApp(
    ProviderScope(
      observers: [if (kDebugMode) ProviderLogger()],
      child: const MyApp(),
    ),
  );
}
```

---

## 📚 Ressources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Performance](https://docs.flutter.dev/perf)

---

*Documentation générée pour DR-Pharma User v1.0*
