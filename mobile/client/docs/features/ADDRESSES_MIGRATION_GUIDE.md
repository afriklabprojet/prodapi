# Guide de Migration - Widgets d'Adresses

## 🔄 Migration rapide

### Avant (ancien code)
```dart
// Dans addresses_list_page.dart
return _AddressCard(
  address: address,
  onTap: () => context.push('/addresses/${address.id}/edit'),
  onDefault: () => ref.read(addressesProvider.notifier).setDefaultAddress(address.id),
  onDelete: () => ref.read(addressesProvider.notifier).deleteAddress(address.id),
);
```

### Après (nouveau code)
```dart
// Import
import '../widgets/widgets.dart'; // ou address_card.dart

// Utilisation
return AddressCard(
  key: ValueKey(address.id), // Important pour les performances
  address: address,
  onTap: () => _handleAddressTap(address),
  onDefault: () => _handleSetDefault(address.id),
  onDelete: () => _handleDelete(address.id),
  showActions: !widget.selectionMode,
);
```

## 🎨 Personnalisation du widget

### Utilisation basique
```dart
AddressCard(
  address: myAddress,
  onTap: () => print('Adresse sélectionnée'),
)
```

### Mode sélection (sans actions)
```dart
AddressCard(
  address: myAddress,
  onTap: () => context.pop(myAddress),
  showActions: false, // Cache le menu et swipe-to-delete
)
```

### Avec toutes les actions
```dart
AddressCard(
  address: myAddress,
  onTap: () => editAddress(myAddress),
  onDefault: () => setAsDefault(myAddress.id),
  onDelete: () => removeAddress(myAddress.id),
  showActions: true,
)
```

## 🧩 Intégration dans d'autres écrans

### 1. Page de sélection d'adresse
```dart
class AddressSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return AddressCard(
          address: address,
          onTap: () => Navigator.pop(context, address),
          showActions: false, // Pas d'édition en mode sélection
        );
      },
    );
  }
}
```

### 2. Écran de commande avec adresse
```dart
class CheckoutPage extends StatelessWidget {
  final AddressEntity selectedAddress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Adresse de livraison'),
        AddressCard(
          address: selectedAddress,
          onTap: () async {
            final newAddress = await context.push('/addresses/select');
            if (newAddress != null) {
              // Mettre à jour l'adresse sélectionnée
            }
          },
          showActions: false,
        ),
      ],
    );
  }
}
```

### 3. Widget compact pour résumé
```dart
// Créer une variante compacte si nécessaire
class CompactAddressCard extends StatelessWidget {
  final AddressEntity address;
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.location_on),
      title: Text(address.label),
      subtitle: Text(address.address),
      trailing: Icon(Icons.chevron_right),
    );
  }
}
```

## 🔧 Bonnes pratiques

### 1. Toujours utiliser des keys pour les listes
```dart
// ❌ Mauvais
ListView.builder(
  itemBuilder: (context, index) => AddressCard(address: addresses[index]),
)

// ✅ Bon
ListView.builder(
  itemBuilder: (context, index) {
    final address = addresses[index];
    return AddressCard(
      key: ValueKey(address.id), // Important !
      address: address,
    );
  },
)
```

### 2. Gérer les callbacks avec handlers dédiés
```dart
// ❌ Mauvais - Logique inline
AddressCard(
  onDelete: () async {
    await ref.read(provider.notifier).delete(id);
    setState(() {});
  },
)

// ✅ Bon - Handler dédié
AddressCard(
  onDelete: () => _handleDelete(address.id),
)

Future<void> _handleDelete(int id) async {
  await ref.read(addressesProvider.notifier).deleteAddress(id);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Adresse supprimée')),
    );
  }
}
```

### 3. Feedback utilisateur pour chaque action
```dart
Future<void> _handleSetDefault(int addressId) async {
  await ref.read(addressesProvider.notifier).setDefaultAddress(addressId);
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Adresse définie par défaut'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
```

### 4. Gestion des erreurs
```dart
Future<void> _handleDelete(int addressId) async {
  try {
    await ref.read(addressesProvider.notifier).deleteAddress(addressId);
    
    if (mounted) {
      _showSuccessSnackbar('Adresse supprimée');
    }
  } catch (e) {
    if (mounted) {
      _showErrorSnackbar('Impossible de supprimer l\'adresse');
    }
  }
}
```

## 🎯 Patterns d'animation

### Animation d'entrée progressive (Stagger)
```dart
AnimatedBuilder(
  animation: _animationController,
  builder: (context, child) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final animation = Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (index / items.length) * 0.5,
              ((index + 1) / items.length) * 0.5 + 0.5,
              curve: Curves.easeOut,
            ),
          ));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ),
            ),
            child: AddressCard(...),
          ),
        );
      },
    );
  },
)
```

### Initialisation de l'animation
```dart
class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
```

## 🧪 Tests

### Test basique du widget
```dart
testWidgets('should display address details', (tester) async {
  final address = AddressEntity(/* ... */);
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AddressCard(
          address: address,
          onTap: () {},
        ),
      ),
    ),
  );

  expect(find.text(address.label), findsOneWidget);
  expect(find.text(address.address), findsOneWidget);
});
```

### Test des interactions
```dart
testWidgets('should call onTap when tapped', (tester) async {
  var tapped = false;
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AddressCard(
          address: testAddress,
          onTap: () => tapped = true,
        ),
      ),
    ),
  );

  await tester.tap(find.byType(InkWell));
  await tester.pumpAndSettle();

  expect(tapped, isTrue);
});
```

## 📦 Dépendances requises

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0
  equatable: ^2.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## 🐛 Problèmes courants et solutions

### Problème 1 : Animation ne démarre pas
```dart
// ❌ Oubli du forward()
@override
void initState() {
  super.initState();
  _animationController = AnimationController(...);
  // Manque _animationController.forward();
}

// ✅ Solution
@override
void initState() {
  super.initState();
  _animationController = AnimationController(...);
  Future.microtask(() {
    _animationController.forward(); // Lance l'animation
  });
}
```

### Problème 2 : Snackbar ne s'affiche pas
```dart
// ❌ Context perdu après async
Future<void> _handleDelete(int id) async {
  await deleteAddress(id);
  ScaffoldMessenger.of(context).showSnackBar(...); // Peut crasher
}

// ✅ Vérifier mounted
Future<void> _handleDelete(int id) async {
  await deleteAddress(id);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

### Problème 3 : Swipe-to-delete trop sensible
```dart
// Ajuster le seuil de confirmation
Dismissible(
  dismissThresholds: const {
    DismissDirection.endToStart: 0.4, // 40% de l'écran
  },
  confirmDismiss: (_) => _confirmDelete(context),
)
```

## 📚 Ressources additionnelles

- [Documentation Flutter - Dismissible](https://api.flutter.dev/flutter/widgets/Dismissible-class.html)
- [Animation Best Practices](https://docs.flutter.dev/development/ui/animations/tutorial)
- [Widget Testing Guide](https://docs.flutter.dev/cookbook/testing/widget/introduction)

---

**Note** : Ce guide sera mis à jour avec les retours d'expérience de l'équipe.
