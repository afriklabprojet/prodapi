# ⚡ Quick Start - Widget AddressCard

Guide ultra-rapide pour utiliser le nouveau widget AddressCard en 2 minutes.

## 🚀 Installation / Import

```dart
// Import simple
import 'package:client/features/addresses/presentation/widgets/address_card.dart';

// Ou importer tous les widgets d'adresses
import 'package:client/features/addresses/presentation/widgets/widgets.dart';
```

## 💡 Utilisation Basique

### Cas 1 : Affichage simple (lecture seule)

```dart
AddressCard(
  address: myAddress,
  onTap: () => print('Adresse tapée'),
)
```

### Cas 2 : Avec toutes les actions

```dart
AddressCard(
  key: ValueKey(address.id),  // Important pour les performances !
  address: address,
  onTap: () => editAddress(address),
  onDefault: () => setAsDefault(address.id),
  onDelete: () => deleteAddress(address.id),
)
```

### Cas 3 : Mode sélection (sans menu)

```dart
AddressCard(
  address: address,
  onTap: () => Navigator.pop(context, address),
  showActions: false,  // Cache le menu et swipe-to-delete
)
```

## 📋 Dans une ListView

```dart
ListView.builder(
  padding: EdgeInsets.all(16),
  itemCount: addresses.length,
  itemBuilder: (context, index) {
    final address = addresses[index];
    return AddressCard(
      key: ValueKey(address.id),  // ⚠️ NE PAS OUBLIER !
      address: address,
      onTap: () => _editAddress(address),
      onDefault: () => _setDefault(address.id),
      onDelete: () => _deleteAddress(address.id),
    );
  },
)
```

## 🎯 Handlers recommandés

```dart
// Dans votre State
Future<void> _setDefault(int addressId) async {
  await ref.read(provider.notifier).setDefaultAddress(addressId);
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Adresse définie par défaut'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}

Future<void> _deleteAddress(int addressId) async {
  await ref.read(provider.notifier).deleteAddress(addressId);
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Adresse supprimée'),
          ],
        ),
        backgroundColor: Colors.red[700],
      ),
    );
  }
}
```

## ⚠️ Points d'Attention

### 1. Toujours utiliser ValueKey dans les listes
```dart
// ❌ MAUVAIS
AddressCard(address: address)

// ✅ BON
AddressCard(key: ValueKey(address.id), address: address)
```

### 2. Vérifier `mounted` avant SnackBar
```dart
// ❌ MAUVAIS
Future<void> action() async {
  await doSomething();
  ScaffoldMessenger.of(context).showSnackBar(...);  // Peut crasher
}

// ✅ BON
Future<void> action() async {
  await doSomething();
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

### 3. showActions = false en mode sélection
```dart
// En mode sélection d'adresse
AddressCard(
  address: address,
  onTap: () => Navigator.pop(context, address),
  showActions: false,  // Pas de menu ni swipe
)
```

## 🎨 Personnalisation

Le widget s'adapte automatiquement :

- ✅ **Bordure spéciale** si `address.isDefault == true`
- ✅ **Badge "Par défaut"** affiché automatiquement
- ✅ **Indicateur GPS** si `address.hasCoordinates == true`
- ✅ **Section détails** affichée si `phone` ou `instructions` non null
- ✅ **Menu d'actions** cache "Définir par défaut" si déjà par défaut

Aucune configuration nécessaire, tout est géré automatiquement ! 🎉

## 🧪 Tester votre implémentation

```dart
testWidgets('should display address card', (tester) async {
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

## 📚 Pour aller plus loin

- **Documentation complète** : [ADDRESSES_IMPROVEMENTS.md](./ADDRESSES_IMPROVEMENTS.md)
- **Guide de migration** : [ADDRESSES_MIGRATION_GUIDE.md](./ADDRESSES_MIGRATION_GUIDE.md)
- **Architecture** : [ADDRESSES_ARCHITECTURE.md](./ADDRESSES_ARCHITECTURE.md)
- **Rapport complet** : [ADDRESSES_IMPROVEMENT_REPORT.md](./ADDRESSES_IMPROVEMENT_REPORT.md)

## 🆘 Problème ?

1. Vérifier que l'import est correct
2. S'assurer que `AddressEntity` contient les bonnes données
3. Vérifier les ValueKey dans les listes
4. Lire le troubleshooting dans [ADDRESSES_MIGRATION_GUIDE.md](./ADDRESSES_MIGRATION_GUIDE.md)

---

**C'est tout !** 🎉 Vous êtes prêt à utiliser AddressCard.

Pour toute question : #mobile-dev sur Slack
