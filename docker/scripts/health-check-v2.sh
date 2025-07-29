#!/bin/bash

# KuroPanel V2 Health Check Script
# Usage: health-check.sh [quick|full]

MODE=${1:-full}
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="/var/log/kuro-health.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_message() {
    echo -e "${TIMESTAMP} - $1" | tee -a "$LOG_FILE"
}

check_apache() {
    if pgrep apache2 > /dev/null; then
        log_message "${GREEN}✓ Apache is running${NC}"
        return 0
    else
        log_message "${RED}✗ Apache is not running${NC}"
        return 1
    fi
}

check_database() {
    # Test database connection
    php -r "
    try {
        \$pdo = new PDO('mysql:host=db;dbname=kuro_panel', 'kuro_user', 'kuro_pass');
        echo 'DB_OK';
    } catch (Exception \$e) {
        echo 'DB_ERROR: ' . \$e->getMessage();
        exit(1);
    }
    " 2>/dev/null

    if [ $? -eq 0 ]; then
        log_message "${GREEN}✓ Database connection OK${NC}"
        return 0
    else
        log_message "${RED}✗ Database connection failed${NC}"
        return 1
    fi
}

check_web_response() {
    # Check main application
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        log_message "${GREEN}✓ Web application responding (HTTP $HTTP_CODE)${NC}"
    else
        log_message "${RED}✗ Web application not responding (HTTP $HTTP_CODE)${NC}"
        return 1
    fi

    # Check API endpoints
    API_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health 2>/dev/null)
    if [ "$API_CODE" = "200" ]; then
        log_message "${GREEN}✓ API endpoint responding${NC}"
    else
        log_message "${YELLOW}⚠ API endpoint not responding (HTTP $API_CODE)${NC}"
    fi

    # Check Connect endpoint (legacy)
    CONNECT_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/connect/health 2>/dev/null)
    if [ "$CONNECT_CODE" = "200" ]; then
        log_message "${GREEN}✓ Connect endpoint responding${NC}"
    else
        log_message "${YELLOW}⚠ Connect endpoint not responding (HTTP $CONNECT_CODE)${NC}"
    fi

    return 0
}

check_writable_directories() {
    DIRS=("writable/cache" "writable/logs" "writable/session" "writable/uploads")
    
    for dir in "${DIRS[@]}"; do
        if [ -w "/var/www/html/$dir" ]; then
            log_message "${GREEN}✓ Directory $dir is writable${NC}"
        else
            log_message "${RED}✗ Directory $dir is not writable${NC}"
            return 1
        fi
    done
    
    return 0
}

check_php_errors() {
    # Check for recent PHP errors
    ERROR_LOG="/var/log/apache2/error.log"
    if [ -f "$ERROR_LOG" ]; then
        RECENT_ERRORS=$(tail -n 100 "$ERROR_LOG" | grep -i "$(date '+%Y-%m-%d')" | grep -i "fatal\|error" | wc -l)
        if [ "$RECENT_ERRORS" -gt 0 ]; then
            log_message "${YELLOW}⚠ Found $RECENT_ERRORS recent PHP errors${NC}"
        else
            log_message "${GREEN}✓ No recent PHP errors${NC}"
        fi
    fi
}

check_disk_space() {
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 90 ]; then
        log_message "${RED}✗ Disk usage critical: ${DISK_USAGE}%${NC}"
        return 1
    elif [ "$DISK_USAGE" -gt 80 ]; then
        log_message "${YELLOW}⚠ Disk usage high: ${DISK_USAGE}%${NC}"
    else
        log_message "${GREEN}✓ Disk usage OK: ${DISK_USAGE}%${NC}"
    fi
    return 0
}

check_memory_usage() {
    MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$MEMORY_USAGE" -gt 90 ]; then
        log_message "${RED}✗ Memory usage critical: ${MEMORY_USAGE}%${NC}"
        return 1
    elif [ "$MEMORY_USAGE" -gt 80 ]; then
        log_message "${YELLOW}⚠ Memory usage high: ${MEMORY_USAGE}%${NC}"
    else
        log_message "${GREEN}✓ Memory usage OK: ${MEMORY_USAGE}%${NC}"
    fi
    return 0
}

# Main health check logic
main() {
    log_message "=== KuroPanel V2 Health Check ($MODE mode) ==="
    
    OVERALL_STATUS=0
    
    # Core checks (always performed)
    check_apache || OVERALL_STATUS=1
    check_web_response || OVERALL_STATUS=1
    
    if [ "$MODE" = "full" ]; then
        check_database || OVERALL_STATUS=1
        check_writable_directories || OVERALL_STATUS=1
        check_php_errors
        check_disk_space || OVERALL_STATUS=1
        check_memory_usage || OVERALL_STATUS=1
        
        # System info
        log_message "System Load: $(uptime | awk -F'load average:' '{print $2}')"
        log_message "Apache Processes: $(pgrep apache2 | wc -l)"
        log_message "Uptime: $(uptime -p)"
    fi
    
    if [ $OVERALL_STATUS -eq 0 ]; then
        log_message "${GREEN}✓ Overall health: HEALTHY${NC}"
        exit 0
    else
        log_message "${RED}✗ Overall health: UNHEALTHY${NC}"
        exit 1
    fi
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Run main function
main
