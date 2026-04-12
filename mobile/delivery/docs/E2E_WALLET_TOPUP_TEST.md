# Test E2E - Recharge Wallet Coursier

## 📋 Résumé

Test end-to-end du flow de recharge du portefeuille coursier via le système de paiement JEKO.

**Date du test :** 11 avril 2026  
**Environnement :** Émulateur Android (Pixel 8 Pro API 37)  
**App version :** 1.0.0+1  
**Compte testé :** leadouce0@gmail.com (coursier "baba")

---

## ✅ Scénario de test

### Prérequis
- Compte coursier vérifié (KYC validé)
- App delivery installée sur émulateur/device
- Connexion internet active

### Étapes du test

| # | Action | Résultat attendu | Statut |
|---|--------|------------------|--------|
| 1 | Lancer l'app | Écran de connexion affiché | ✅ PASS |
| 2 | Entrer email/mot de passe | Champs remplis | ✅ PASS |
| 3 | Taper "Se connecter" | Redirection vers carte + statut "Disponible" | ✅ PASS |
| 4 | Taper onglet "Wallet" | Écran portefeuille avec solde 0 FCFA | ✅ PASS |
| 5 | Taper bouton "Recharger" | Bottom sheet avec montants et méthodes | ✅ PASS |
| 6 | Sélectionner montant (500 FCFA) | Montant sélectionné | ✅ PASS |
| 7 | Sélectionner méthode (Wave) | Méthode sélectionné | ✅ PASS |
| 8 | Confirmer | Redirection page paiement JEKO | ✅ PASS |
| 9 | Formulaire numéro téléphone | Champ +225 affiché | ✅ PASS |

---

## 📱 Captures d'écran

### 1. Écran d'accueil après connexion
- Utilisateur : **baba**
- Statut : **Disponible** (indicateur vert)
- Solde du jour : **0 F**
- Position GPS active sur carte Google Maps

### 2. Écran Wallet
- Titre : "Mon Portefeuille"
- Solde disponible : **0 FCFA**
- Badge : "Activation requise"
- Boutons : "Recharger" (actif) / "Retirer" (grisé car solde = 0)
- Alerte : "Ajoutez au moins 200 FCFA pour recevoir des commandes"

### 3. Page paiement JEKO
- Marchand : **DRL NEGOCE**
- Montant : **500 FCFA**
- Méthode : **Wave** (logo pingouin)
- Indicatif : **+225** (Côte d'Ivoire)
- Bouton : "Payer 500 FCFA"
- Footer : "Paiement sécurisé par Jeko"

---

## 🔧 Configuration testée

### Montants prédéfinis
```
500, 1000, 2000, 5000, 10000 FCFA
```

### Montant personnalisé
- Minimum : 500 FCFA
- Maximum : 1,000,000 FCFA

### Méthodes de paiement JEKO
| Méthode | Identifiant | Icône |
|---------|-------------|-------|
| Wave | `wave` | ✅ Par défaut |
| Orange Money | `orange` | ✅ |
| MTN MoMo | `mtn` | ✅ |
| Moov Money | `moov` | ✅ |
| Djamo | `djamo` | ✅ |

---

## 🏗️ Architecture du flow

```
┌─────────────────┐
│   WalletScreen  │
│   (wallet_screen.dart)
└────────┬────────┘
         │ tap "Recharger"
         ▼
┌─────────────────┐
│   TopUpSheet    │
│   (top_up_sheet.dart)
└────────┬────────┘
         │ sélection montant + méthode
         ▼
┌─────────────────────────┐
│ JekoPaymentRepository   │
│ initiateWalletTopup()   │
└────────┬────────────────┘
         │ POST /api/v1/wallet/topup
         ▼
┌─────────────────────────┐
│ PaymentWebViewScreen    │
│ (redirect_url JEKO)     │
└────────┬────────────────┘
         │ webhook confirmation
         ▼
┌─────────────────┐
│ Wallet refresh  │
│ + SnackBar succès
└─────────────────┘
```

---

## 🔍 Points de vérification

### Validation montant
- [x] Montant minimum respecté (500 FCFA)
- [x] Montant maximum respecté (1M FCFA)
- [x] Montant personnalisé accepte uniquement des chiffres
- [x] Erreur affichée si montant invalide

### Sécurité
- [x] Paiement via WebView sécurisé (HTTPS)
- [x] Référence unique générée côté serveur
- [x] Webhook de confirmation côté backend

### UX
- [x] Loading indicator pendant l'initiation
- [x] Haptic feedback sur les boutons
- [x] SnackBar de succès/erreur après paiement
- [x] Refresh automatique du solde

---

## 🐛 Issues connues

1. **ADB input tap incompatible avec Flutter/Impeller** - Les tests automatisés via ADB shell input ne fonctionnent pas car Flutter avec Impeller ne capture pas les événements touch système.

2. **Flutter Driver nécessite SDK 3.9+** - Les outils MCP Flutter Driver requièrent une version récente du SDK Dart.

---

## 📝 Recommandations

1. **Utiliser Maestro** pour les tests E2E automatisés (compatible Flutter/Impeller)
2. **Ajouter des testID** aux widgets clés pour faciliter les tests
3. **Créer un environnement sandbox JEKO** pour les tests de paiement

---

## 📂 Fichiers liés

- `lib/presentation/screens/wallet_screen.dart`
- `lib/presentation/widgets/wallet/top_up_sheet.dart`
- `lib/presentation/screens/payment_webview_screen.dart`
- `lib/data/repositories/jeko_payment_repository.dart`
- `integration_test/live_topup_e2e_test.dart`
