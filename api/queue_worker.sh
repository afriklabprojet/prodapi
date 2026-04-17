#!/bin/bash
# DR-PHARMA Queue Worker Script
# Exécuté toutes les minutes par le cron cPanel
# Mis à jour: 26/03/2026

cd /home/kvyajoqt/public_html

# Lancer le queue worker avec les bons paramètres:
# --max-time=55 : tourne 55s puis s'arrête (le cron relance chaque minute)
# --sleep=3 : vérifie les nouveaux jobs toutes les 3s (pas de gap)
# --tries=3 : réessaie 3 fois avant d'échouer
# --backoff=10 : attente 10s entre les réessais
# --queue=default,payments,notifications : traite les 3 queues par priorité
/usr/local/bin/php artisan queue:work database \
    --queue=default,payments,notifications \
    --max-time=55 \
    --sleep=3 \
    --tries=3 \
    --backoff=10 \
    >> /home/kvyajoqt/logs/queue.log 2>&1
