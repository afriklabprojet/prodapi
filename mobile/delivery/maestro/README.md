# Maestro - Tests E2E DR Pharma Delivery

Tests d'interface automatisés pour l'application coursier DR Pharma.

## 📦 Installation

```bash
# macOS / Linux
curl -Ls https://get.maestro.mobile.dev | bash

# Vérifier l'installation
maestro --version
```

## 🚀 Exécution des tests

### Tous les tests
```bash
cd mobile/delivery
maestro test maestro/
```

### Test spécifique
```bash
maestro test maestro/wallet_topup_flow.yaml
```

### Avec variables personnalisées
```bash
maestro test maestro/wallet_topup_flow.yaml \
  --env EMAIL=autre@email.com \
  --env PASSWORD=MotDePasse123
```

### Mode studio (debug interactif)
```bash
maestro studio
```

## 📁 Structure des tests

```
maestro/
├── config.yaml              # Configuration globale
├── wallet_topup_flow.yaml   # Test recharge wallet
├── login_flow.yaml          # Test connexion
└── README.md                # Ce fichier
```

## 🧪 Tests disponibles

| Fichier | Description | Durée estimée |
|---------|-------------|---------------|
| `wallet_topup_flow.yaml` | Flow complet de recharge wallet via JEKO | ~45s |
| `login_flow.yaml` | Connexion coursier | ~20s |

## 📸 Screenshots

Les captures d'écran sont sauvegardées dans `./screenshots/` après chaque exécution.

## ⚙️ Variables d'environnement

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `EMAIL` | Email du compte test | `leadouce0@gmail.com` |
| `PASSWORD` | Mot de passe | `Paris2026` |
| `TOPUP_AMOUNT` | Montant de recharge | `500` |

## 🔧 Prérequis

1. **Émulateur Android** ou device connecté
2. **App installée** : `flutter build apk && adb install build/app/outputs/flutter-apk/app-release.apk`
3. **Maestro installé**

## 🐛 Dépannage

### L'émulateur n'est pas détecté
```bash
adb devices
# Doit afficher un device
```

### Test timeout
Augmenter le timeout dans le test :
```yaml
- extendedWaitUntil:
    visible: "Element"
    timeout: 30000  # 30 secondes
```

### Élément non trouvé
Utiliser le mode studio pour inspecter les éléments :
```bash
maestro studio
```

## 📊 CI/CD

Pour GitHub Actions, ajouter ce workflow :

```yaml
# .github/workflows/e2e-tests.yml
name: E2E Tests
on: [push, pull_request]

jobs:
  e2e:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        
      - name: Install Maestro
        run: curl -Ls https://get.maestro.mobile.dev | bash
        
      - name: Build APK
        run: cd mobile/delivery && flutter build apk
        
      - name: Start emulator
        run: |
          $ANDROID_HOME/emulator/emulator -avd test -no-audio -no-window &
          adb wait-for-device
          
      - name: Run tests
        run: maestro test mobile/delivery/maestro/
```

## 📝 Créer un nouveau test

1. Copier un test existant
2. Modifier les étapes selon le flow à tester
3. Exécuter avec `maestro test <fichier.yaml>`
4. Ajuster les sélecteurs si nécessaire

### Template de base

```yaml
appId: com.drpharma.delivery

---
- launchApp
- assertVisible: "Élément attendu"
- tapOn: "Bouton"
- takeScreenshot: "resultat"
```
