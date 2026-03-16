# 🏥 DR-PHARMA API Backend

API REST Laravel pour la plateforme de livraison de médicaments DR-PHARMA.

## 📋 Prérequis

- PHP 8.1 ou supérieur
- Composer 2.x
- SQLite (développement) ou MySQL/PostgreSQL (production)
- Extensions PHP : PDO, SQLite, OpenSSL, Mbstring, JSON

## 🚀 Installation Rapide

### 1. Cloner le repository

```bash
git clone https://github.com/afriklabprojet/dr-api.git
cd dr-api
```

### 2. Installer les dépendances

```bash
composer install
```

### 3. Configuration de l'environnement

```bash
# Copier le fichier d'exemple
cp .env.example .env

# Générer la clé d'application
php artisan key:generate
```

### 4. Créer la base de données SQLite

```bash
touch database/database.sqlite
```

### 5. Exécuter les migrations et seeders

```bash
# Créer toutes les tables
php artisan migrate

# Ou créer les tables avec des données de test
php artisan migrate --seed
```

### 6. Lancer le serveur de développement

```bash
php artisan serve
```

L'API sera accessible sur : `http://127.0.0.1:8000`

## 👥 Comptes de test (après seeding)

| Rôle | Email | Mot de passe |
|------|-------|--------------|
| Admin | admin@drlpharma.com | password |
 | password |
| Pharmacie 1 | plateau@drlpharma.com | password |
| Pharmacie 2 | cocody@drlpharma.com | password |
| Coursier 1 | coursier1@drlpharma.com | password |
| Coursier 2 | coursier2@drlpharma.com | password |

## 📁 Structure de la base de données

### Tables principales

- **users** - Utilisateurs (admin, clients, pharmaciens, coursiers)
- **pharmacies** - Pharmacies partenaires
- **couriers** - Profils coursiers
- **products** - Catalogue produits
- **categories** - Catégories produits
- **orders** - Commandes
- **deliveries** - Livraisons
- **payments** - Paiements (JEKO)
- **wallets** - Portefeuilles électroniques
- **commissions** - Commissions plateforme/pharmacie/coursier

### 32 migrations disponibles

Toutes les tables sont versionnées et peuvent être recréées avec :
```bash
php artisan migrate:fresh --seed
```

## 🧪 Tests

```bash
# Exécuter tous les tests
php artisan test

# Tests avec couverture
php artisan test --coverage
```

**63 tests PHPUnit** disponibles couvrant toutes les fonctionnalités.

## 🔧 Configuration des services tiers

### Firebase (Notifications Push)

1. Télécharger les credentials depuis Firebase Console
2. Placer le fichier dans : `storage/app/firebase-credentials.json`
3. Vérifier la variable dans `.env` : `FIREBASE_CREDENTIALS`

### JEKO (Paiements)

```env
JEKO_API_KEY=votre_jeko_api_key
JEKO_API_KEY_ID=votre_jeko_api_key_id
JEKO_STORE_ID=votre_jeko_store_id
JEKO_WEBHOOK_SECRET=votre_webhook_secret
```

## 📱 Applications mobiles

- **Client** : `/Mobile/user/` (Flutter)
- **Pharmacie** : `/Mobile/pharmacy/` (Flutter)
- **Coursier** : `/Mobile/coursier/` (Flutter)

## 🛠️ Commandes utiles

```bash
# Réinitialiser la base de données
php artisan migrate:fresh --seed

# Créer un nouveau contrôleur
php artisan make:controller NomController

# Créer un modèle avec migration et factory
php artisan make:model NomModel -mf

# Effacer le cache
php artisan cache:clear
php artisan config:clear
php artisan route:clear

# Lister toutes les routes
php artisan route:list

# Lancer la queue
php artisan queue:work

# Vérifier les jobs en attente
php artisan queue:failed
```

## 🐛 Debug avec Telescope

Telescope est activé en développement : `http://127.0.0.1:8000/telescope`

## 📚 Documentation API

La documentation complète de l'API est disponible dans `/docs/`:

- `README_API.md` - Documentation générale
- `QUICK_START.md` - Guide de démarrage rapide
- `INTEGRATION_GUIDE.md` - Guide d'intégration

## 🤝 Contribution

1. Créer une branche : `git checkout -b feature/ma-fonctionnalite`
2. Commit : `git commit -m "Ajout de ma fonctionnalité"`
3. Push : `git push origin feature/ma-fonctionnalite`
4. Créer une Pull Request

## 📄 Licence

Propriétaire - AfrikLab Projet

## 📞 Support

- Email : support@drlpharma.com
- GitHub Issues : https://github.com/afriklabprojet/dr-api/issues

