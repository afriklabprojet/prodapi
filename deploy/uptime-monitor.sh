#!/usr/bin/env bash
# ============================================================
# DR-PHARMA — Uptime monitor (cron every 5 min)
# Install: sudo cp deploy/uptime-monitor.sh /usr/local/bin/
#          sudo chmod +x /usr/local/bin/uptime-monitor.sh
# Cron:    */5 * * * * /usr/local/bin/uptime-monitor.sh
# ============================================================
set -euo pipefail

HEALTH_URL="https://drlpharma.pro/api/health"
LOG_FILE="/var/log/drpharma-uptime.log"
ALERT_FILE="/tmp/drpharma-alert-sent"
MAX_RETRIES=3

check_health() {
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        HTTP_CODE=$(curl -s -o /tmp/drpharma-health.json -w '%{http_code}' \
            --connect-timeout 10 --max-time 30 "$HEALTH_URL" 2>/dev/null || echo "000")

        if [ "$HTTP_CODE" = "200" ]; then
            STATUS=$(cat /tmp/drpharma-health.json | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))" 2>/dev/null || echo "unknown")
            echo "$(date '+%Y-%m-%d %H:%M:%S') OK status=$STATUS http=$HTTP_CODE" >> "$LOG_FILE"

            # Clear alert flag on recovery
            if [ -f "$ALERT_FILE" ]; then
                rm -f "$ALERT_FILE"
                echo "$(date '+%Y-%m-%d %H:%M:%S') RECOVERED" >> "$LOG_FILE"
            fi
            return 0
        fi

        attempt=$((attempt + 1))
        sleep 5
    done

    # All retries failed
    echo "$(date '+%Y-%m-%d %H:%M:%S') FAIL http=$HTTP_CODE after $MAX_RETRIES attempts" >> "$LOG_FILE"

    # Send alert (max once per hour)
    if [ ! -f "$ALERT_FILE" ] || [ $(($(date +%s) - $(stat -c %Y "$ALERT_FILE" 2>/dev/null || echo 0))) -gt 3600 ]; then
        touch "$ALERT_FILE"
        # Check individual services for diagnostics
        DIAG=""
        systemctl is-active nginx &>/dev/null || DIAG="$DIAG nginx:DOWN"
        systemctl is-active mysql &>/dev/null || DIAG="$DIAG mysql:DOWN"
        systemctl is-active php8.3-fpm &>/dev/null || DIAG="$DIAG php-fpm:DOWN"
        redis-cli ping &>/dev/null || DIAG="$DIAG redis:DOWN"

        echo "$(date '+%Y-%m-%d %H:%M:%S') ALERT http=$HTTP_CODE services=[$DIAG]" >> "$LOG_FILE"
    fi
}

# Rotate log (keep last 10000 lines)
if [ -f "$LOG_FILE" ] && [ $(wc -l < "$LOG_FILE") -gt 10000 ]; then
    tail -5000 "$LOG_FILE" > "${LOG_FILE}.tmp"
    mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi

check_health
