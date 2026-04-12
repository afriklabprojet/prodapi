#!/bin/bash
# ============================================
# DR-PHARMA - Configuration Cron Jobs cPanel
# ============================================
# Dernière mise à jour: 26/03/2026
#
# INSTRUCTIONS pour configurer les crons dans cPanel:
#
# 1. Connectez-vous à cPanel
# 2. Allez dans "Cron Jobs" (ou "Tâches planifiées")
# 3. Ajoutez les crons suivants:
#
# ============================================
# CRON 1: Laravel Scheduler (OBLIGATOIRE)
# ============================================
# Fréquence: Toutes les minutes (* * * * *)
# Commande:
cd /home/kvyajoqt/public_html && /usr/local/bin/php artisan schedule:run >> /home/kvyajoqt/logs/scheduler.log 2>&1

# ============================================
# CRON 2: Queue Worker (OBLIGATOIRE)
# ============================================
# Fréquence: Toutes les minutes (* * * * *)
# Note: --max-time=55 = le worker tourne 55s puis s'arrête proprement
#        avant que le prochain cron le relance à la minute suivante.
#        PAS de --stop-when-empty pour éviter les gaps de traitement.
#        --sleep=3 = vérifie les nouveaux jobs toutes les 3 secondes.
# Commande:
cd /home/kvyajoqt/public_html && /usr/local/bin/php artisan queue:work database --queue=default,payments,notifications --max-time=55 --sleep=3 --tries=3 --backoff=10 >> /home/kvyajoqt/logs/queue.log 2>&1

# ============================================
# CRON 3: Cache Cleanup (OPTIONNEL - hebdomadaire)
# ============================================
# Fréquence: Dimanche 4h (0 4 * * 0)
# Commande:
cd /home/kvyajoqt/public_html && /usr/local/bin/php artisan cache:clear && /usr/local/bin/php artisan config:cache && /usr/local/bin/php artisan route:cache >> /home/kvyajoqt/logs/cache.log 2>&1

# ============================================
# CRON 4: Storage Cleanup (OPTIONNEL - quotidien)
# ============================================
# Fréquence: 5h quotidien (0 5 * * *)
# Commande:
find /home/kvyajoqt/public_html/storage/logs/*.log -mtime +7 -delete 2>/dev/null; find /home/kvyajoqt/public_html/storage/framework/cache/data -type f -mtime +1 -delete 2>/dev/null

# ============================================
# RÉSUMÉ DES CRONS À AJOUTER DANS CPANEL:
# ============================================
#
# | Fréquence     | Commande                                                       |
# |---------------|----------------------------------------------------------------|
# | * * * * *     | cd /home/kvyajoqt/public_html && php artisan schedule:run >> /home/kvyajoqt/logs/scheduler.log 2>&1 |
# | * * * * *     | cd /home/kvyajoqt/public_html && php artisan queue:work database --queue=default,payments,notifications --max-time=55 --sleep=3 --tries=3 --backoff=10 >> /home/kvyajoqt/logs/queue.log 2>&1 |
# | 0 4 * * 0     | cd /home/kvyajoqt/public_html && php artisan cache:clear && php artisan config:cache && php artisan route:cache |
# | 0 5 * * *     | find /home/kvyajoqt/public_html/storage/logs -mtime +7 -delete  |
#
# ============================================
# VÉRIFICATION
# ============================================
# Pour vérifier que les crons fonctionnent:
#
# 1. Via SSH (si disponible):
#    crontab -l
#
# 2. Via l'API:
#    curl https://drlpharma.com/api/health
#    → Doit retourner {"queue": "ok", "queue_size": 0}
#
# 3. Vérifier les logs:
#    tail -20 /home/kvyajoqt/logs/scheduler.log
#    tail -20 /home/kvyajoqt/logs/queue.log
#
# 4. Vérifier les failed_jobs:
#    cd /home/kvyajoqt/public_html && php artisan queue:failed
#
# 5. Relancer un job échoué:
#    cd /home/kvyajoqt/public_html && php artisan queue:retry <uuid>
#
# ============================================
# TÂCHES PLANIFIÉES LARAVEL (routes/console.php)
# ============================================
# Ces tâches sont gérées automatiquement par le scheduler (CRON 1):
#
# HAUTE FRÉQUENCE (critiques):
# - CheckWaitingDeliveryTimeouts : Toutes les minutes     → Annule les livraisons en timeout
# - CheckPendingPaymentsJob      : Toutes les 2 minutes   → Vérifie paiements JEKO en attente
# - Expire wallet payments        : Toutes les 2 minutes   → Expire rechargements wallet >10min
# - CancelStaleOrdersJob          : Toutes les 5 minutes   → Annule commandes impayées >30min
#
# FRÉQUENCE MOYENNE:
# - CheckStuckDeliveriesJob       : Toutes les 30 minutes  → Détecte livraisons bloquées
# - Cleanup expired payments      : Toutes les heures      → Marque transactions >4h expirées
# - MonitorFailedJobsJob          : Toutes les 2 heures    → Alerte admin si jobs échouent
# - Timeout withdrawal requests   : Toutes les 4 heures    → Auto-échoue retraits stuck >48h
# - Deactivate expired on-call    : Toutes les 6 heures    → Désactive pharmacies de garde expirées
# - Auto-stop delivery waiting    : Toutes les 10 minutes  → Stoppe frais d'attente >30min
#
# QUOTIDIEN:
# - CourierActivityHealthCheckJob : 01:00  → Audit statut livreurs
# - ReconcileWalletBalancesJob    : 02:00  → Audit soldes wallets
# - sanctum:prune-expired         : 03:00  → Nettoie tokens API >48h
# - ProcessMissingCommissionsJob  : 04:00  → Calcule commissions manquantes
# - DailyAdminDigestJob           : 06:00  → Rapport KPI quotidien admin
# - SendScheduledStatements       : 08:00  → Relevés de compte pharmacies
# - SupportTicketEscalationJob    : 08:30  → Escalade tickets support
#
# HEBDOMADAIRE:
# - CleanupOldDataJob             : Dimanche 03:00 → Purge données >6 mois
# - Cleanup webhook logs          : Hebdomadaire    → Supprime logs >30 jours
# - Cleanup stale FCM tokens      : Hebdomadaire    → Nettoie tokens FCM inactifs >60j
# - Cleanup old job batches       : Hebdomadaire    → Purge job_batches terminés >30j
#
# ============================================
