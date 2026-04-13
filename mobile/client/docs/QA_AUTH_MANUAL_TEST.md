# QA Auth — Scénario de test manuel (appareil)

> **Cible** : Android + iOS, mode clair & sombre  
> **Pré-requis** : build debug/release installé, compte test existant, SIM active pour SMS  

---

## T1 — Login (téléphone)

| # | Action | Résultat attendu |
|---|--------|------------------|
| 1.1 | Ouvrir l'app (1ère fois ou déconnecté) | Splash → écran Login |
| 1.2 | Vérifier le toggle Téléphone/Email | Téléphone sélectionné par défaut, **ripple** au tap |
| 1.3 | Taper "Se connecter" sans remplir | Validation form : erreurs inline sous les champs |
| 1.4 | Entrer un numéro inconnu + mdp | Banner erreur "Identifiant ou mot de passe incorrect" |
| 1.5 | Entrer un compte valide + mauvais mdp | Erreur sous le champ mot de passe |
| 1.6 | Entrer un compte valide + bon mdp | Loader → redirection vers Home (ou OTP si téléphone non vérifié) |
| 1.7 | Vérifier "Mot de passe oublié ?" | Navigation vers l'écran de réinitialisation |
| 1.8 | Vérifier le lien "Créer un compte" | Navigation vers l'écran inscription, tap target ≥ 44px |

## T2 — Login (email)

| # | Action | Résultat attendu |
|---|--------|------------------|
| 2.1 | Taper le toggle "Email" | Bascule vers champ email avec **ripple feedback** |
| 2.2 | Entrer un email invalide (ex: "abc") | Validation : "Email invalide" sous le champ |
| 2.3 | Entrer email valide + bon mdp | Loader → Home |

## T3 — Login biométrique

| # | Action | Résultat attendu |
|---|--------|------------------|
| 3.1 | Se connecter une première fois (T1.6) | Bouton Face ID / Empreinte visible au prochain login |
| 3.2 | Se déconnecter, revenir au login | Bouton biométrique visible sous le séparateur "ou" |
| 3.3 | Taper le bouton biométrique | Prompt système → connexion automatique → Home |

## T4 — Inscription

| # | Action | Résultat attendu |
|---|--------|------------------|
| 4.1 | Depuis le login, taper "Créer un compte" | Écran inscription, étape 1/2, stepper visible |
| 4.2 | Taper "Continuer" sans remplir | Erreurs inline sous chaque champ vide |
| 4.3 | Remplir nom + email existant + téléphone | Passer à étape 2, puis erreur "Email déjà utilisé" après soumission |
| 4.4 | **Étape 1** : Remplir nom, email neuf, téléphone | Champ téléphone accepte : `0700000000`, `+22507...`, `2250700...` |
| 4.5 | Taper "Continuer" | Transition vers étape 2 (Sécurité) |
| 4.6 | Vérifier le bouton retour (header) | **Ripple feedback** → retour étape 1, données conservées |
| 4.7 | **Étape 2** : mdp faible (ex: "123") | Indicateur force "Faible", couleur rouge |
| 4.8 | Mdp fort (ex: "Dr@Pharma2026!") | Indicateur "Fort", couleur verte |
| 4.9 | Confirmation ≠ mdp | Erreur "Les mots de passe ne correspondent pas" |
| 4.10 | Ne pas cocher CGU, taper "Créer" | Erreur "Veuillez accepter les conditions" |
| 4.11 | Taper le lien CGU | Navigation vers la page CGU |
| 4.12 | Taper le lien Politique de confidentialité | Navigation vers la page Politique |
| 4.13 | Cocher CGU + mdp OK → "Créer mon compte" | Loader → redirection vers OTP |
| 4.14 | Vérifier le snackbar de transition | Message vert "Inscription réussie. Vérifiez maintenant votre numéro." visible sur l'écran OTP |

## T5 — Google Sign-In

| # | Action | Résultat attendu |
|---|--------|------------------|
| 5.1 | Écran inscription étape 1, repérer le bouton Google | Bouton "Continuer avec Google" avec icône "G" bleue, style `OutlinedButton` |
| 5.2 | Taper le bouton Google | Popup Google Account picker |
| 5.3 | Sélectionner un compte Google neuf | Inscription auto → redirection (Home ou OTP) |
| 5.4 | Sélectionner un compte Google déjà lié | Connexion directe → Home |
| 5.5 | Annuler le picker Google | Retour à l'écran inscription, pas de crash |
| 5.6 | **Mode avion** → taper Google | Erreur réseau affichée proprement |

## T6 — Vérification OTP (6 chiffres)

| # | Action | Résultat attendu |
|---|--------|------------------|
| 6.1 | Arriver sur l'écran OTP après inscription | 6 cases vides, timer 60s, bouton retour avec **ripple** |
| 6.2 | Recevoir le SMS, auto-fill | Les 6 chiffres se remplissent automatiquement (Android) |
| 6.3 | Saisie manuelle d'un code invalide | Message erreur "Code invalide" |
| 6.4 | Attendre 60s | Bouton "Renvoyer" devient actif |
| 6.5 | Taper "Renvoyer" | Nouveau SMS envoyé, timer repart |
| 6.6 | Saisir le bon code | Vérification → navigation vers Home |
| 6.7 | Taper le bouton retour | Retour au login (pas de crash ni écran blanc) |
| 6.8 | **Fallback** : si Firebase timeout (30s) | Bascule auto vers SMS backend (Infobip), message info visible |

## T7 — Mot de passe oublié

| # | Action | Résultat attendu |
|---|--------|------------------|
| 7.1 | Depuis login, taper "Mot de passe oublié ?" | Écran reset, toggle Email/Téléphone avec **ripple** |
| 7.2 | Mode email : entrer email inconnu | Erreur "Aucun compte trouvé" |
| 7.3 | Email valide → "Envoyer" | OTP 4 chiffres reçu par email |
| 7.4 | Saisir le code OTP → valider | Passe à l'étape nouveau mot de passe |
| 7.5 | Nouveau mdp + confirmation → "Réinitialiser" | Écran succès → retour login |

## T8 — Dark mode & accessibilité

| # | Action | Résultat attendu |
|---|--------|------------------|
| 8.1 | Basculer en dark mode (réglages système) | Tous les écrans auth s'adaptent (contrast OK, textes lisibles) |
| 8.2 | Activer TalkBack / VoiceOver | Tous les boutons annoncent leur label (toggle, retour, fermer erreur, Google) |
| 8.3 | Zoomer le texte système à 200% | Les écrans scrollent, rien ne se coupe |

## T9 — Cas limites

| # | Action | Résultat attendu |
|---|--------|------------------|
| 9.1 | Double-tap rapide sur "Se connecter" | Un seul appel API (pas de doublon) |
| 9.2 | Couper le réseau pendant le login | Erreur réseau propre, pas de crash |
| 9.3 | Background l'app pendant l'OTP → revenir | L'écran reprend normalement, timer cohérent |
| 9.4 | Rotation écran (si autorisée) | Pas de perte de données saisies |

---

**Légende :**  
✅ Pass | ❌ Fail | ⚠️ Partiel | ⏭️ N/A (appareil ne supporte pas)
