#!/bin/bash

# KuroPanel V2 Enhanced Monitoring Script
# Real-time monitoring with alerts and metrics

MODE=${1:-periodic}
INTERVAL=${2:-300} # 5 minutes default
LOG_FILE="/var/log/kuro-monitor.log"
METRICS_FILE="/var/log/kuro-metrics.json"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_message() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

collect_system_metrics() {
    # CPU Usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}' | cut -d'%' -f1)
    
    # Memory Usage
    MEMORY_INFO=$(free | awk 'NR==2{printf "%.0f %.0f %.0f", $3*100/$2, $3/1024/1024, $2/1024/1024}')
    MEMORY_PERCENT=$(echo $MEMORY_INFO | awk '{print $1}')
    MEMORY_USED=$(echo $MEMORY_INFO | awk '{print $2}')
    MEMORY_TOTAL=$(echo $MEMORY_INFO | awk '{print $3}')
    
    # Disk Usage
    DISK_INFO=$(df / | awk 'NR==2 {print $5" "$3" "$2}')
    DISK_PERCENT=$(echo $DISK_INFO | awk '{print $1}' | sed 's/%//')
    DISK_USED=$(echo $DISK_INFO | awk '{print $2}')
    DISK_TOTAL=$(echo $DISK_INFO | awk '{print $3}')
    
    # Apache processes
    APACHE_PROCESSES=$(pgrep apache2 | wc -l)
    
    # Database connections (if available)
    DB_CONNECTIONS=$(php -r "
    try {
        \$pdo = new PDO('mysql:host=db;dbname=kuro_panel', 'kuro_user', 'kuro_pass');
        \$stmt = \$pdo->query('SHOW STATUS LIKE \"Threads_connected\"');
        \$result = \$stmt->fetch();
        echo \$result[1] ?? 0;
    } catch (Exception \$e) { echo '0'; }
    " 2>/dev/null)
    
    # Application-specific metrics
    ACTIVE_USERS=$(php -r "
    try {
        \$pdo = new PDO('mysql:host=db;dbname=kuro_panel', 'kuro_user', 'kuro_pass');
        \$stmt = \$pdo->query('SELECT COUNT(*) FROM users WHERE status = \"active\"');
        echo \$stmt->fetchColumn();
    } catch (Exception \$e) { echo '0'; }
    " 2>/dev/null)
    
    ACTIVE_LICENSES=$(php -r "
    try {
        \$pdo = new PDO('mysql:host=db;dbname=kuro_panel', 'kuro_user', 'kuro_pass');
        \$stmt = \$pdo->query('SELECT COUNT(*) FROM license_keys WHERE status = \"active\"');
        echo \$stmt->fetchColumn();
    } catch (Exception \$e) { echo '0'; }
    " 2>/dev/null)
}

save_metrics() {
    TIMESTAMP=$(date '+%s')
    
    cat > "$METRICS_FILE.tmp" << EOF
{
    "timestamp": $TIMESTAMP,
    "datetime": "$(date '+%Y-%m-%d %H:%M:%S')",
    "system": {
        "cpu_usage": $CPU_USAGE,
        "memory": {
            "percent": $MEMORY_PERCENT,
            "used_gb": $MEMORY_USED,
            "total_gb": $MEMORY_TOTAL
        },
        "disk": {
            "percent": $DISK_PERCENT,
            "used_kb": $DISK_USED,
            "total_kb": $DISK_TOTAL
        }
    },
    "application": {
        "apache_processes": $APACHE_PROCESSES,
        "db_connections": $DB_CONNECTIONS,
        "active_users": $ACTIVE_USERS,
        "active_licenses": $ACTIVE_LICENSES
    }
}
EOF
    
    mv "$METRICS_FILE.tmp" "$METRICS_FILE"
}

check_alerts() {
    ALERTS_TRIGGERED=0
    
    # CPU Alert
    if (( $(echo "$CPU_USAGE > $ALERT_THRESHOLD_CPU" | bc -l 2>/dev/null || echo "0") )); then
        log_message "${RED}🚨 ALERT: High CPU usage: ${CPU_USAGE}%${NC}"
        ALERTS_TRIGGERED=1
    fi
    
    # Memory Alert
    if [ "$MEMORY_PERCENT" -gt "$ALERT_THRESHOLD_MEMORY" ]; then
        log_message "${RED}🚨 ALERT: High memory usage: ${MEMORY_PERCENT}%${NC}"
        ALERTS_TRIGGERED=1
    fi
    
    # Disk Alert
    if [ "$DISK_PERCENT" -gt "$ALERT_THRESHOLD_DISK" ]; then
        log_message "${RED}🚨 ALERT: High disk usage: ${DISK_PERCENT}%${NC}"
        ALERTS_TRIGGERED=1
    fi
    
    # Apache Process Alert
    if [ "$APACHE_PROCESSES" -lt 2 ]; then
        log_message "${RED}🚨 ALERT: Low Apache processes: ${APACHE_PROCESSES}${NC}"
        ALERTS_TRIGGERED=1
    fi
    
    # Database Connection Alert
    if [ "$DB_CONNECTIONS" -gt 100 ]; then
        log_message "${YELLOW}⚠️ WARNING: High DB connections: ${DB_CONNECTIONS}${NC}"
    fi
    
    return $ALERTS_TRIGGERED
}

display_status() {
    log_message "${BLUE}=== KuroPanel V2 System Status ===${NC}"
    log_message "${GREEN}CPU Usage: ${CPU_USAGE}%${NC}"
    log_message "${GREEN}Memory: ${MEMORY_USED}GB/${MEMORY_TOTAL}GB (${MEMORY_PERCENT}%)${NC}"
    log_message "${GREEN}Disk: ${DISK_PERCENT}% used${NC}"
    log_message "${GREEN}Apache Processes: ${APACHE_PROCESSES}${NC}"
    log_message "${GREEN}DB Connections: ${DB_CONNECTIONS}${NC}"
    log_message "${GREEN}Active Users: ${ACTIVE_USERS}${NC}"
    log_message "${GREEN}Active Licenses: ${ACTIVE_LICENSES}${NC}"
    log_message "${BLUE}=================================${NC}"
}

periodic_monitoring() {
    while true; do
        collect_system_metrics
        save_metrics
        
        if check_alerts; then
            log_message "${YELLOW}System alert triggered - check logs${NC}"
        fi
        
        display_status
        sleep $INTERVAL
    done
}

one_time_check() {
    collect_system_metrics
    save_metrics
    display_status
    check_alerts
}

# Main execution
case "$MODE" in
    "continuous"|"periodic")
        log_message "${GREEN}Starting continuous monitoring (interval: ${INTERVAL}s)${NC}"
        periodic_monitoring
        ;;
    "once"|"single")
        one_time_check
        ;;
    *)
        echo "Usage: $0 [continuous|once] [interval_seconds]"
        echo "Examples:"
        echo "  $0 continuous 300  # Monitor every 5 minutes"
        echo "  $0 once           # Single check"
        exit 1
        ;;
esac
