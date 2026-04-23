# GitHub Support — Demande de Garbage Collection

**À envoyer à** : https://support.github.com/contact
**Catégorie** : Account & Privacy → Sensitive Data Removal
**Sujet** : Request GC of orphan commit containing sensitive data

---

## Message

Hello GitHub Support,

We recently performed a `git filter-repo` + force-push to remove a folder
(`.backup-api-env/`) from the history of our repository, as it contained
sensitive environment credentials that were accidentally committed.

**Repository**: `afriklabprojet/prodapi` (private)

**Actions taken on our side**:
1. Purged the folder via `git filter-repo --path .backup-api-env --invert-paths`
2. Force-pushed to `main` (new HEAD: `a8bbbcc...` then `4d0ab92...`)
3. Added a pre-commit hook (gitleaks) to prevent recurrence

**Request**: Could you please trigger garbage collection on the orphan commit
`1c9aa74` (and any other commits that referenced `.backup-api-env/`) so that
they are no longer accessible via the GitHub API or direct SHA URLs?

**Reference commit SHA to GC**: `1c9aa74` (and any sibling blobs containing
files under `.backup-api-env/`)

**Also**: Please purge any cached fork refs, PR refs, or activity feeds that
might still surface the leaked content.

We have already rotated the exposed credentials (or are in the process of
rotating them: APP_KEY, DB_PASSWORD, JEKO_API_KEY, JEKO_WEBHOOK_SECRET,
INFOBIP_API_KEY, GOOGLE_MAPS_API_KEY).

Thanks for your help!

---

## Checklist post-envoi

- [ ] Rotation APP_KEY : `php artisan key:generate` sur VPS + redémarrer queue workers
- [ ] Rotation DB_PASSWORD : update MySQL user + .env prod + php artisan config:cache
- [ ] Rotation JEKO_API_KEY + JEKO_WEBHOOK_SECRET : dashboard Jeko
- [ ] Rotation INFOBIP_API_KEY : dashboard Infobip
- [ ] Rotation GOOGLE_MAPS_API_KEY : restriction référer + domaine + régénérer clé
- [ ] Activer GitHub Secret Scanning (Settings → Code security → Secret scanning)
- [ ] Activer GitHub Push Protection (même menu)
