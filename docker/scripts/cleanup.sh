#!/bin/bash

# KuroPanel V2 Cleanup Script
# Automated cleanup of logs, cache, and temporary files

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="/var/log/kuro-cleanup.log"
APP_ROOT="/var/www/html"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_message() {
    echo -e "${TIMESTAMP} - $1" | tee -a "$LOG_FILE"
}

cleanup_logs() {
    log_message "${YELLOW}Starting log cleanup...${NC}"
    
    # Apache logs older than 30 days
    find /var/log/apache2/ -name "*.log.*" -mtime +30 -delete 2>/dev/null || true
    
    # Application logs older than 14 days
    find "${APP_ROOT}/writable/logs/" -name "*.log" -mtime +14 -delete 2>/dev/null || true
    
    # System logs
    find /var/log/ -name "*.log.*.gz" -mtime +60 -delete 2>/dev/null || true
    
    log_message "${GREEN}✓ Log cleanup completed${NC}"
}

cleanup_cache() {
    log_message "${YELLOW}Starting cache cleanup...${NC}"
    
    # Clear application cache
    rm -rf "${APP_ROOT}/writable/cache/"* 2>/dev/null || true
    
    # Clear session files older than 24 hours
    find "${APP_ROOT}/writable/session/" -name "ci_session*" -mtime +1 -delete 2>/dev/null || true
    
    # Clear OPCache if available
    if command -v php >/dev/null 2>&1; then
        php -r "if (function_exists('opcache_reset')) { opcache_reset(); echo 'OPCache cleared\n'; }"
    fi
    
    log_message "${GREEN}✓ Cache cleanup completed${NC}"
}

cleanup_database() {
    log_message "${YELLOW}Starting database cleanup...${NC}"
    
    # Clean up expired license keys
    php "${APP_ROOT}/spark" kuro:cleanup-expired-keys 2>/dev/null || true
    
    # Clean up old history records (older than 90 days)
    php "${APP_ROOT}/spark" kuro:cleanup-old-history 2>/dev/null || true
    
    # Clean up unused invite codes (older than 30 days)
    php "${APP_ROOT}/spark" kuro:cleanup-unused-invites 2>/dev/null || true
    
    log_message "${GREEN}✓ Database cleanup completed${NC}"
}

cleanup_temp_files() {
    log_message "${YELLOW}Starting temporary file cleanup...${NC}"
    
    # System temp files
    find /tmp -type f -mtime +7 -delete 2>/dev/null || true
    
    # PHP temp files
    find /tmp -name "php*" -type f -mtime +1 -delete 2>/dev/null || true
    
    # Application uploads older than 90 days
    find "${APP_ROOT}/writable/uploads/" -type f -mtime +90 -delete 2>/dev/null || true
    
    log_message "${GREEN}✓ Temporary file cleanup completed${NC}"
}

generate_cleanup_report() {
    log_message "${YELLOW}Generating cleanup report...${NC}"
    
    # Disk usage after cleanup
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
    DISK_AVAILABLE=$(df -h / | awk 'NR==2 {print $4}')
    
    # Memory usage
    MEMORY_USAGE=$(free -h | awk 'NR==2{print $3"/"$2}')
    
    # File counts
    LOG_COUNT=$(find "${APP_ROOT}/writable/logs/" -name "*.log" | wc -l)
    CACHE_COUNT=$(find "${APP_ROOT}/writable/cache/" -type f | wc -l)
    SESSION_COUNT=$(find "${APP_ROOT}/writable/session/" -name "ci_session*" | wc -l)
    
    log_message "=== Cleanup Report ==="
    log_message "Disk Usage: ${DISK_USAGE} (${DISK_AVAILABLE} available)"
    log_message "Memory Usage: ${MEMORY_USAGE}"
    log_message "Log Files: ${LOG_COUNT}"
    log_message "Cache Files: ${CACHE_COUNT}"
    log_message "Session Files: ${SESSION_COUNT}"
    log_message "=== End Report ==="
}

optimize_database() {
    log_message "${YELLOW}Starting database optimization...${NC}"
    
    php -r "
    try {
        \$pdo = new PDO('mysql:host=db;dbname=kuro_panel', 'kuro_user', 'kuro_pass');
        \$tables = ['users', 'license_keys', 'history', 'codes', 'apps'];
        foreach (\$tables as \$table) {
            \$pdo->exec(\"OPTIMIZE TABLE \$table\");
        }
        echo 'Database optimization completed\n';
    } catch (Exception \$e) {
        echo 'Database optimization failed: ' . \$e->getMessage() . \"\n\";
    }
    " 2>/dev/null || log_message "${RED}Database optimization failed${NC}"
    
    log_message "${GREEN}✓ Database optimization completed${NC}"
}

main() {
    log_message "=== KuroPanel V2 Cleanup Started ==="
    
    cleanup_logs
    cleanup_cache
    cleanup_temp_files
    cleanup_database
    optimize_database
    generate_cleanup_report
    
    log_message "${GREEN}=== KuroPanel V2 Cleanup Completed ===${NC}"
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Run main function
main
