# 📦 Livraison Backend DR-PHARMA — 27 avril 2026

**Tag Git :** `prod-launch-2026.04.27`  
**Tag audit :** `backend-audit-2026.04.27`  
**Production :** https://drlpharma.pro  
**Smoke test final :** ✅ PASS (27/04/2026 15:17 UTC)

---

## ✅ Statut production

| Endpoint | Statut | Détail |
|---|---|---|
| `GET /api/health` | **200** | db, cache, redis, queue, horizon (3 supervisors) = ok |
| `GET /api/metrics` | **403** | Auth Bearer token OK (METRICS_TOKEN) |
| `POST /api/auth/resend` | **429 après 3 req** | Rate limit OTP-send fonctionnel |
| HTTPS / HTTP2 | ✅ | Cert valide |

### Headers sécurité actifs
- `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
- `X-Frame-Options: DENY`
- `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy` : tous capteurs/medias/payment désactivés

---

## 🔐 Sécurité — corrections livrées

| Priorité | Item | Commit |
|---|---|---|
| P0 | Idempotency hardening, pricing snapshot, reassign 15min, Sentry, Reverb | `8aadf88` |
| P1.3 | Migration queue → Horizon (3 supervisors systemd) | `aef29bc` |
| P-Haute #1 | Rate limits multi-policy (auth, otp, otp-send, payment, uploads, search, chat, orders, liveness, webhook) | déjà actif |
| P-Haute #2 | Sentry actif backend + mobile | déjà actif |
| P2.3 | 2FA TOTP obligatoire admin Filament | `9edb03c` |
| P2.4 | `/api/health` + `/api/metrics` Prometheus | `82a2ecb` + `9fe7f95` |
| P-Moy #5 | CSP verrouillée sur réponses API JSON | `abfd62c` |
| P-Moy #6 | Logging accès refusés (channel security) | `9578f34` + `2f0336e` + `22381b4` |
| Hardening | Redis password rotated (64-hex), HORIZON_ADMINS=admin@drlpharma.pro | manuel sur prod |
| P-Bas #7 | `composer audit` clean | déjà OK |
| Supply chain | Dependabot patches (axios, vite, rollup, follow-redirects, picomatch, protobuf, phpseclib) | `e0048e0` + `1912cad` |
| CI | Gitleaks workflow (PR + push + weekly) | `cd8f439` |

---

## 🏗️ Infrastructure prod

- **VPS :** Hetzner (204.168.193.244) — Ubuntu, 4GB RAM, 38GB disk
- **Stack :** Nginx + PHP 8.3-FPM + Laravel 12 + MariaDB + Redis 6379
- **Queue :** Horizon (3 supervisors via `drpharma-horizon.service` systemd)
- **TLS :** Let's Encrypt
- **Logs :** stack `security` channel séparée pour accès refusés
- **Backup :** scripts `scripts/backup_database.sh` (cron)

---

## 📋 Post-launch (non bloquant)

| Item | Statut | Action requise |
|---|---|---|
| **Cloudflare WAF** | ⏳ Zone créée, configurée | **Client doit basculer NS chez Beehosting** vers `angela.ns.cloudflare.com` + `randy.ns.cloudflare.com` |
| **Grafana Cloud Prometheus** | ⏳ Compte créé `kteya96` | Récupérer credentials push (URL + username + token `metrics:write`) puis déployer Grafana Alloy sur VPS |
| **JEKO_WEBHOOK_IPS** | ⏳ Vide en prod | Demander au provider Jeko les IPs sortantes, puis : `sudo -u www-data sed -i 's\|^JEKO_WEBHOOK_IPS=.*\|JEKO_WEBHOOK_IPS=ip1,ip2,ip3\|' .env && php8.3 artisan config:cache` |
| **Sanctum token rotation** | 📅 Policy à définir | Définir TTL + script rotation |
| **Pentest externe** | 📅 Planifier | Engagement prestataire tiers (recommandé sous 90j) |
| **Bot Fight Mode CF** | 📅 Manuel dashboard | Une fois NS basculés : Dashboard CF → Security → Bots → Enable |

---

## 🧪 Tests appliqués

```bash
# Health check
curl https://drlpharma.pro/api/health
# → {"success":true,"status":"healthy","checks":{...all ok}}

# Métriques protégées
curl -I https://drlpharma.pro/api/metrics
# → HTTP/2 403

# Rate limit OTP send (3/min)
for i in 1..7; do curl -X POST https://drlpharma.pro/api/auth/resend ...; done
# → 422, 422, 429, 429, 429, 429, 429
```

---

## 📞 Contacts & Accès

- **Admin :** admin@drlpharma.pro (2FA TOTP requis)
- **Sentry :** dashboard configuré, alertes actives
- **Cloudflare :** parfaiteya1996@gmail.com (zone `drlpharma.pro` pending NS)
- **Grafana :** https://kteya96.grafana.net/
- **Repo :** https://github.com/afriklabprojet/prodapi (tag `prod-launch-2026.04.27`)

---

**Backend DR-PHARMA est en production.** 🚀

_Audit & livraison : senior backend / 27 avril 2026_
