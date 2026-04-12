# 📚 Documentation des Fonctionnalités

Ce dossier contient la documentation détaillée de toutes les fonctionnalités de l'application DR-PHARMA Mobile.

## 📍 Module Adresses

Documentation complète du module de gestion des adresses de livraison.

### Fichiers disponibles

| Fichier | Description |
|---------|-------------|
| [ADDRESSES_IMPROVEMENTS.md](./ADDRESSES_IMPROVEMENTS.md) | Vue d'ensemble des améliorations v2.0 |
| [ADDRESSES_MIGRATION_GUIDE.md](./ADDRESSES_MIGRATION_GUIDE.md) | Guide de migration et patterns d'utilisation |
| [ADDRESSES_CHANGELOG.md](./ADDRESSES_CHANGELOG.md) | Historique des changements |

### Aperçu rapide

Le module Adresses a été entièrement refondu en version 2.0.0 avec :

- ✅ **Architecture améliorée** : Widget réutilisable et testable
- ✨ **UX moderne** : Animations fluides, swipe-to-delete, design Material 3
- 🎯 **Fonctionnalités** : Recherche, feedbacks visuels, confirmations
- 🧪 **Qualité** : Tests unitaires complets (>90% couverture)
- 📖 **Documentation** : Guides complets avec exemples de code

### Démarrage rapide

```dart
// Import
import 'package:client/features/addresses/presentation/widgets/widgets.dart';

// Utilisation basique
AddressCard(
  address: myAddress,
  onTap: () => editAddress(myAddress),
  onDefault: () => setDefault(myAddress.id),
  onDelete: () => deleteAddress(myAddress.id),
)
```

### Ressources

- 📖 **Guide complet** : Lire [ADDRESSES_IMPROVEMENTS.md](./ADDRESSES_IMPROVEMENTS.md)
- 🔄 **Migration** : Consulter [ADDRESSES_MIGRATION_GUIDE.md](./ADDRESSES_MIGRATION_GUIDE.md)
- 📝 **Changelog** : Voir [ADDRESSES_CHANGELOG.md](./ADDRESSES_CHANGELOG.md)

### Tests

```bash
# Tester le widget AddressCard
flutter test test/features/addresses/presentation/widgets/address_card_test.dart

# Tester tout le module adresses
flutter test test/features/addresses/
```

### Captures d'écran

*(À ajouter : screenshots de l'avant/après)*

---

## 🚀 Autres modules

*(À documenter : Commandes, Produits, Traitements, etc.)*

---

## 📋 Structure de documentation recommandée

Pour chaque nouvelle fonctionnalité majeure, créer :

1. **`FEATURE_IMPROVEMENTS.md`**
   - Vue d'ensemble des améliorations
   - Architecture et design
   - Métriques de qualité
   - Améliorations futures

2. **`FEATURE_MIGRATION_GUIDE.md`**
   - Guide de migration version à version
   - Exemples de code avant/après
   - Bonnes pratiques d'utilisation
   - Troubleshooting

3. **`FEATURE_CHANGELOG.md`**
   - Historique détaillé des versions
   - Breaking changes
   - Notes de migration

## 🎓 Best Practices

Consultez également le dossier [../best-practices/](../best-practices/) pour :

- [FLUTTER_LIST_SCREENS.md](../best-practices/FLUTTER_LIST_SCREENS.md) : Patterns pour les écrans de liste
- *(À venir)* : State management, Architecture, Testing, etc.

## 🤝 Contribution

### Ajouter une nouvelle documentation

1. Créer les fichiers dans ce dossier :
   ```
   docs/features/
   ├── YOUR_FEATURE_IMPROVEMENTS.md
   ├── YOUR_FEATURE_MIGRATION_GUIDE.md
   └── YOUR_FEATURE_CHANGELOG.md
   ```

2. Mettre à jour ce README.md avec une nouvelle section

3. Ajouter des exemples de code clairs

4. Inclure des diagrammes si nécessaire (Mermaid, PlantUML)

### Template de documentation

Un template Markdown est disponible dans `docs/templates/` (à créer)

---

**Maintenu par** : L'équipe Développement Mobile
**Dernière mise à jour** : 9 avril 2026

## 📞 Contact

Pour toute question sur la documentation :
- 💬 Slack : #mobile-dev
- 📧 Email : mobile-team@drpharma.com
- 🐛 Issues : [GitHub Issues](link-to-issues)
