#!/bin/bash
# ============================================================
# DR-PHARMA — Script de backup automatique de la base de données
# ============================================================
# Usage: ./scripts/backup_database.sh
# Cron: 0 2 * * * /path/to/scripts/backup_database.sh >> /var/log/drpharma-backup.log 2>&1
# ============================================================

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/var/backups/drpharma}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="drpharma_${TIMESTAMP}.sql.gz"

# Charger les variables d'environnement depuis .env
ENV_FILE="${ENV_FILE:-$(dirname "$0")/../api/.env}"
if [ -f "$ENV_FILE" ]; then
    export $(grep -E '^(DB_CONNECTION|DB_HOST|DB_PORT|DB_DATABASE|DB_USERNAME|DB_PASSWORD)=' "$ENV_FILE" | xargs)
fi

# Valeurs par défaut
DB_CONNECTION="${DB_CONNECTION:-mysql}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_DATABASE="${DB_DATABASE:-drpharma}"
DB_USERNAME="${DB_USERNAME:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"

echo "[$(date)] === Début du backup DR-PHARMA ==="

# Créer le répertoire de backup s'il n'existe pas
mkdir -p "$BACKUP_DIR"

# Effectuer le backup selon le type de base
if [ "$DB_CONNECTION" = "mysql" ]; then
    echo "[$(date)] Backup MySQL: $DB_DATABASE"
    mysqldump \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        --user="$DB_USERNAME" \
        --password="$DB_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --add-drop-table \
        --complete-insert \
        "$DB_DATABASE" | gzip > "$BACKUP_DIR/$BACKUP_FILE"

elif [ "$DB_CONNECTION" = "pgsql" ]; then
    echo "[$(date)] Backup PostgreSQL: $DB_DATABASE"
    export PGPASSWORD="$DB_PASSWORD"
    pg_dump \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        --username="$DB_USERNAME" \
        --format=custom \
        --no-owner \
        "$DB_DATABASE" | gzip > "$BACKUP_DIR/$BACKUP_FILE"
    unset PGPASSWORD

elif [ "$DB_CONNECTION" = "sqlite" ]; then
    echo "[$(date)] Backup SQLite: $DB_DATABASE"
    if [ -f "$DB_DATABASE" ]; then
        gzip -c "$DB_DATABASE" > "$BACKUP_DIR/$BACKUP_FILE"
    else
        echo "[$(date)] ERREUR: Fichier SQLite introuvable: $DB_DATABASE"
        exit 1
    fi

else
    echo "[$(date)] ERREUR: Type de base non supporté: $DB_CONNECTION"
    exit 1
fi

# Vérifier que le backup a été créé
if [ -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    echo "[$(date)] Backup créé: $BACKUP_DIR/$BACKUP_FILE ($BACKUP_SIZE)"
else
    echo "[$(date)] ERREUR: Le backup n'a pas été créé"
    exit 1
fi

# Nettoyage des anciens backups
echo "[$(date)] Nettoyage des backups de plus de $RETENTION_DAYS jours..."
DELETED_COUNT=$(find "$BACKUP_DIR" -name "drpharma_*.sql.gz" -mtime +$RETENTION_DAYS -type f -print -delete | wc -l)
echo "[$(date)] $DELETED_COUNT ancien(s) backup(s) supprimé(s)"

# Résumé
TOTAL_BACKUPS=$(find "$BACKUP_DIR" -name "drpharma_*.sql.gz" -type f | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo "[$(date)] === Backup terminé ==="
echo "[$(date)] Total backups: $TOTAL_BACKUPS | Espace utilisé: $TOTAL_SIZE"
