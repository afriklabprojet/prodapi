# Guide de Contribution - DR-PHARMA Client

Bienvenue ! Ce guide vous aidera à contribuer efficacement au projet DR-PHARMA.

## Table des Matières

- [Prérequis](#prérequis)
- [Configuration de l'environnement](#configuration-de-lenvironnement)
- [Workflow de développement](#workflow-de-développement)
- [Standards de code](#standards-de-code)
- [Tests](#tests)
- [Soumission de Pull Requests](#soumission-de-pull-requests)
- [Revue de code](#revue-de-code)

## Prérequis

### Outils requis

- **Flutter SDK** : >= 3.10.0
- **Dart SDK** : >= 3.0.0
- **Android Studio** ou **VS Code** avec extensions Flutter/Dart
- **Xcode** (macOS uniquement, pour iOS)
- **Git** : >= 2.30

### Vérifier l'installation

```bash
flutter doctor
```

## Configuration de l'environnement

### 1. Cloner le repository

```bash
git clone https://github.com/your-org/dr-pharma.git
cd dr-pharma/mobile/client
```

### 2. Installer les dépendances

```bash
flutter pub get
```

### 3. Configurer les variables d'environnement

```bash
cp .env.example .env
# Éditer .env avec vos valeurs locales
```

### 4. Configurer Firebase (développement)

Demander les fichiers suivants à l'équipe :
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

### 5. Lancer l'application

```bash
flutter run
```

## Workflow de développement

### Branches

Nous utilisons Git Flow simplifié :

| Branche | Usage |
|---------|-------|
| `main` | Production stable |
| `develop` | Développement actif |
| `feature/<nom>` | Nouvelles fonctionnalités |
| `fix/<nom>` | Corrections de bugs |
| `hotfix/<nom>` | Corrections urgentes production |

### Créer une branche

```bash
# Pour une nouvelle fonctionnalité
git checkout develop
git pull origin develop
git checkout -b feature/nom-de-la-feature

# Pour une correction
git checkout develop
git pull origin develop
git checkout -b fix/nom-du-fix
```

### Commits

Utiliser le format **Conventional Commits** :

```
<type>(<scope>): <description>

[corps optionnel]

[footer optionnel]
```

#### Types de commits

| Type | Description |
|------|-------------|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `docs` | Documentation |
| `style` | Formatage (pas de changement de code) |
| `refactor` | Refactoring |
| `test` | Ajout/modification de tests |
| `chore` | Maintenance (dépendances, config) |
| `perf` | Amélioration de performance |

#### Exemples

```bash
git commit -m "feat(cart): ajouter la validation de quantité maximale"
git commit -m "fix(auth): corriger la gestion du token expiré"
git commit -m "docs(readme): mettre à jour les instructions d'installation"
git commit -m "test(orders): ajouter tests unitaires pour OrderService"
```

## Standards de code

### Structure des fichiers

```
lib/
├── core/                    # Code partagé
│   ├── config/              # Configuration
│   ├── constants/           # Constantes
│   ├── errors/              # Gestion d'erreurs
│   ├── extensions/          # Extensions Dart
│   ├── providers/           # Providers globaux
│   ├── router/              # Navigation
│   ├── services/            # Services
│   ├── utils/               # Utilitaires
│   └── widgets/             # Widgets réutilisables
│
├── features/                # Features (par domaine)
│   └── <feature>/
│       ├── data/            # Couche données
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/          # Couche domaine
│       │   ├── entities/
│       │   └── usecases/
│       └── presentation/    # Couche présentation
│           ├── pages/
│           ├── providers/
│           └── widgets/
│
└── l10n/                    # Internationalisation
```

### Conventions de nommage

| Élément | Convention | Exemple |
|---------|------------|---------|
| Classes | PascalCase | `CartService` |
| Variables | camelCase | `cartItems` |
| Constantes | lowerCamelCase | `maxCartItems` |
| Fichiers | snake_case | `cart_service.dart` |
| Dossiers | snake_case | `cart_items/` |

### Règles Dart/Flutter

1. **Préférer `const`** pour les widgets statiques
2. **Utiliser `final`** pour les variables non réassignées
3. **Éviter `dynamic`** - toujours typer explicitement
4. **Utiliser les null-safety** - pas de `!` sans vérification

### Formatage

```bash
# Formater le code
dart format lib test

# Analyser le code
flutter analyze

# Les deux d'un coup
flutter analyze && dart format lib test
```

### Linting

Le projet utilise `flutter_lints`. Corriger tous les warnings avant de commit.

## Tests

### Structure des tests

```
test/
├── core/               # Tests des services/utils core
├── features/           # Tests par feature
│   └── <feature>/
│       ├── data/       # Tests repositories/datasources
│       └── presentation/  # Tests widgets/providers
├── helpers/            # Mocks et utilitaires de test
└── performance/        # Tests de performance

integration_test/
├── helpers/            # Utilitaires E2E
└── flows/              # Tests de flux utilisateur
```

### Lancer les tests

```bash
# Tous les tests unitaires
flutter test

# Un fichier spécifique
flutter test test/features/cart/cart_service_test.dart

# Tests avec coverage
flutter test --coverage

# Tests d'intégration
flutter test integration_test/

# Tests de performance
flutter test test/performance/
```

### Écrire un test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('CartService', () {
    late CartService cartService;
    late MockCartRepository mockRepository;

    setUp(() {
      mockRepository = MockCartRepository();
      cartService = CartService(mockRepository);
    });

    test('addItem should increase cart count', () {
      // Arrange
      final product = Product(id: '1', name: 'Test', price: 100);
      
      // Act
      cartService.addItem(product, quantity: 2);
      
      // Assert
      expect(cartService.itemCount, equals(2));
    });
  });
}
```

### Coverage minimum

- **Nouveau code** : 80% minimum
- **Services critiques** : 90% minimum
- **UI widgets** : 60% minimum

## Soumission de Pull Requests

### Checklist avant PR

- [ ] Code formaté (`dart format`)
- [ ] Pas d'erreurs d'analyse (`flutter analyze`)
- [ ] Tests passent (`flutter test`)
- [ ] Nouveaux tests ajoutés si nécessaire
- [ ] Documentation mise à jour si nécessaire
- [ ] Commits suivent les conventions
- [ ] Branche à jour avec `develop`

### Créer une PR

1. Push votre branche :
   ```bash
   git push origin feature/ma-feature
   ```

2. Créer la PR sur GitHub vers `develop`

3. Remplir le template de PR :
   - Description des changements
   - Screenshots si UI
   - Tests effectués
   - Breaking changes si applicable

### Template de PR

```markdown
## Description
[Description claire des changements]

## Type de changement
- [ ] Nouvelle fonctionnalité
- [ ] Correction de bug
- [ ] Refactoring
- [ ] Documentation

## Tests
- [ ] Tests unitaires ajoutés/mis à jour
- [ ] Tests manuels effectués

## Screenshots (si UI)
[Captures d'écran avant/après]

## Checklist
- [ ] Code formaté et analysé
- [ ] Tests passent
- [ ] Documentation mise à jour
```

## Revue de code

### Critères de revue

1. **Fonctionnalité** : Le code fait ce qu'il doit faire
2. **Architecture** : Respect de la clean architecture
3. **Lisibilité** : Code clair et bien nommé
4. **Tests** : Couverture suffisante
5. **Performance** : Pas de régression
6. **Sécurité** : Pas de faille évidente

### Répondre aux commentaires

- Répondre à chaque commentaire
- Marquer comme résolu après correction
- Demander clarification si nécessaire

### Approbation

- **1 approbation requise** pour les petites PR
- **2 approbations requises** pour les changements majeurs

## Déploiement

### Builds de développement

```bash
# Android APK debug
flutter build apk --debug

# iOS debug (macOS uniquement)
flutter build ios --debug
```

### Builds de production

Les builds de production sont gérés par CI/CD. Ne pas builder manuellement.

## Support

### Canaux de communication

- **Slack** : #dr-pharma-mobile
- **Email** : mobile-team@drpharma.ci
- **Issues GitHub** : Pour les bugs et features

### Ressources

- [Documentation Flutter](https://docs.flutter.dev)
- [Documentation Riverpod](https://riverpod.dev)
- [Documentation GoRouter](https://pub.dev/packages/go_router)
- [Docs internes](./docs/)

---

Merci de contribuer à DR-PHARMA ! 🎉
