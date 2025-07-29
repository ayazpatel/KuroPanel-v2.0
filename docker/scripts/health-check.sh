#!/bin/bash
# Health check script for the KuroPanel application

set -e

# Configuration
MAX_RETRIES=30
RETRY_INTERVAL=2
APP_URL="http://localhost"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Check if application is responding
check_app_health() {
    local url="$1"
    local expected_status="${2:-200}"
    
    if command -v curl >/dev/null 2>&1; then
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
        if [ "$status_code" = "$expected_status" ]; then
            return 0
        else
            return 1
        fi
    else
        # Fallback to wget if curl is not available
        if wget -q --spider "$url" 2>/dev/null; then
            return 0
        else
            return 1
        fi
    fi
}

# Check database connectivity
check_database() {
    if [ -f "/var/www/html/spark" ]; then
        php /var/www/html/spark about | grep -q "Database"
        return $?
    else
        warn "Spark command not found, skipping database check"
        return 0
    fi
}

# Check writable directories
check_permissions() {
    local dirs=("/var/www/html/writable/cache" "/var/www/html/writable/logs" "/var/www/html/writable/session")
    
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            if [ ! -w "$dir" ]; then
                error "Directory $dir is not writable"
                return 1
            fi
        else
            warn "Directory $dir does not exist"
        fi
    done
    
    return 0
}

# Check PHP extensions
check_php_extensions() {
    local required_extensions=("pdo" "pdo_mysql" "mbstring" "intl" "curl" "zip" "gd")
    
    for ext in "${required_extensions[@]}"; do
        if ! php -m | grep -q "^$ext$"; then
            error "Required PHP extension '$ext' is not loaded"
            return 1
        fi
    done
    
    return 0
}

# Main health check function
main() {
    log "Starting health check..."
    
    # Check PHP extensions
    log "Checking PHP extensions..."
    if check_php_extensions; then
        log "✓ All required PHP extensions are loaded"
    else
        error "✗ Some required PHP extensions are missing"
        exit 1
    fi
    
    # Check file permissions
    log "Checking file permissions..."
    if check_permissions; then
        log "✓ File permissions are correct"
    else
        error "✗ File permission issues detected"
        exit 1
    fi
    
    # Check database connectivity
    log "Checking database connectivity..."
    if check_database; then
        log "✓ Database connection is working"
    else
        warn "Database check failed or unavailable"
    fi
    
    # Check application response
    log "Checking application response..."
    local retries=0
    while [ $retries -lt $MAX_RETRIES ]; do
        if check_app_health "$APP_URL"; then
            log "✓ Application is responding correctly"
            log "Health check completed successfully!"
            exit 0
        else
            retries=$((retries + 1))
            if [ $retries -lt $MAX_RETRIES ]; then
                log "Attempt $retries/$MAX_RETRIES failed, retrying in ${RETRY_INTERVAL}s..."
                sleep $RETRY_INTERVAL
            fi
        fi
    done
    
    error "✗ Application failed to respond after $MAX_RETRIES attempts"
    exit 1
}

# Handle script arguments
case "${1:-health}" in
    "health")
        main
        ;;
    "quick")
        # Quick health check (just HTTP response)
        if check_app_health "$APP_URL"; then
            echo "OK"
            exit 0
        else
            echo "FAIL"
            exit 1
        fi
        ;;
    "app")
        check_app_health "$APP_URL" && echo "OK" || echo "FAIL"
        ;;
    "db")
        check_database && echo "OK" || echo "FAIL"
        ;;
    "permissions")
        check_permissions && echo "OK" || echo "FAIL"
        ;;
    "extensions")
        check_php_extensions && echo "OK" || echo "FAIL"
        ;;
    *)
        echo "Usage: $0 [health|quick|app|db|permissions|extensions]"
        echo ""
        echo "Commands:"
        echo "  health      - Complete health check (default)"
        echo "  quick       - Quick HTTP response check"
        echo "  app         - Check application response only"
        echo "  db          - Check database connectivity only"
        echo "  permissions - Check file permissions only"
        echo "  extensions  - Check PHP extensions only"
        exit 1
        ;;
esac
