#!/bin/bash
# Container monitoring script for KuroPanel

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SERVICES=("app" "database" "phpmyadmin")
CHECK_INTERVAL=30
LOG_FILE="monitoring.log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

# Check container health
check_container_health() {
    local service_name=$1
    local container_name="kuropanel_${service_name}"
    
    # Check if container is running
    if ! docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        error "Container $container_name is not running"
        return 1
    fi
    
    # Check container health if health check is configured
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")
    
    case $health_status in
        "healthy")
            log "✓ $container_name is healthy"
            return 0
            ;;
        "unhealthy")
            error "✗ $container_name is unhealthy"
            return 1
            ;;
        "starting")
            warn "⚠ $container_name is starting up"
            return 0
            ;;
        "none")
            # No health check configured, just check if running
            log "✓ $container_name is running (no health check configured)"
            return 0
            ;;
        *)
            warn "? $container_name has unknown health status: $health_status"
            return 0
            ;;
    esac
}

# Check service connectivity
check_service_connectivity() {
    info "Checking service connectivity..."
    
    # Check application
    if curl -s -f http://localhost:8080 >/dev/null; then
        log "✓ Application is accessible"
    else
        error "✗ Application is not accessible"
    fi
    
    # Check phpMyAdmin
    if curl -s -f http://localhost:8081 >/dev/null; then
        log "✓ phpMyAdmin is accessible"
    else
        error "✗ phpMyAdmin is not accessible"
    fi
    
    # Check database port
    if nc -z localhost 3306 2>/dev/null; then
        log "✓ Database port is accessible"
    else
        error "✗ Database port is not accessible"
    fi
}

# Get container resource usage
get_resource_usage() {
    info "Container resource usage:"
    
    for service in "${SERVICES[@]}"; do
        local container_name="kuropanel_${service}"
        if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
            local stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" "$container_name")
            echo "$stats" | tee -a "$LOG_FILE"
        fi
    done
}

# Check disk usage
check_disk_usage() {
    info "Checking disk usage..."
    
    # Check Docker system disk usage
    local docker_space=$(docker system df --format "table {{.Type}}\t{{.Total}}\t{{.Active}}\t{{.Size}}\t{{.Reclaimable}}")
    echo "Docker Disk Usage:" | tee -a "$LOG_FILE"
    echo "$docker_space" | tee -a "$LOG_FILE"
    
    # Check writable directory space
    local writable_space=$(du -sh writable/ 2>/dev/null || echo "N/A")
    echo "Writable directory size: $writable_space" | tee -a "$LOG_FILE"
}

# Monitor logs for errors
check_container_logs() {
    local service=$1
    local container_name="kuropanel_${service}"
    local lines=${2:-50}
    
    info "Checking recent logs for $container_name..."
    
    # Look for error patterns in logs
    local error_patterns=("ERROR" "FATAL" "Exception" "Warning" "Notice")
    local recent_errors=0
    
    for pattern in "${error_patterns[@]}"; do
        local count=$(docker logs --tail "$lines" "$container_name" 2>&1 | grep -c "$pattern" || echo "0")
        if [ "$count" -gt 0 ]; then
            warn "Found $count '$pattern' entries in $container_name logs"
            recent_errors=$((recent_errors + count))
        fi
    done
    
    if [ "$recent_errors" -eq 0 ]; then
        log "✓ No recent errors found in $container_name logs"
    else
        warn "Found $recent_errors potential issues in $container_name logs"
    fi
}

# Send alert (placeholder for actual alerting system)
send_alert() {
    local message=$1
    local severity=${2:-"warning"}
    
    error "ALERT [$severity]: $message"
    
    # Here you could integrate with:
    # - Slack webhook
    # - Discord webhook
    # - Email notification
    # - PagerDuty
    # - etc.
}

# Main monitoring function
monitor() {
    local failed_checks=0
    
    info "Starting monitoring check..."
    
    # Check each service
    for service in "${SERVICES[@]}"; do
        if ! check_container_health "$service"; then
            failed_checks=$((failed_checks + 1))
            send_alert "Container $service health check failed" "critical"
        fi
        
        # Check logs for recent errors
        check_container_logs "$service"
    done
    
    # Check connectivity
    check_service_connectivity
    
    # Get resource usage
    get_resource_usage
    
    # Check disk usage
    check_disk_usage
    
    if [ "$failed_checks" -eq 0 ]; then
        log "All services are healthy"
    else
        error "$failed_checks service(s) failed health checks"
    fi
    
    echo "----------------------------------------" | tee -a "$LOG_FILE"
}

# Continuous monitoring
continuous_monitor() {
    log "Starting continuous monitoring (interval: ${CHECK_INTERVAL}s)"
    log "Log file: $LOG_FILE"
    log "Press Ctrl+C to stop"
    
    while true; do
        monitor
        sleep "$CHECK_INTERVAL"
    done
}

# Show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  monitor     - Run single monitoring check (default)"
    echo "  continuous  - Run continuous monitoring"
    echo "  health      - Check service health only"
    echo "  logs        - Check container logs for errors"
    echo "  resources   - Show resource usage"
    echo "  disk        - Check disk usage"
    echo "  status      - Show container status"
    echo ""
}

# Main execution
case "${1:-monitor}" in
    "monitor")
        monitor
        ;;
    "continuous")
        continuous_monitor
        ;;
    "health")
        for service in "${SERVICES[@]}"; do
            check_container_health "$service"
        done
        ;;
    "logs")
        for service in "${SERVICES[@]}"; do
            check_container_logs "$service" 100
        done
        ;;
    "resources")
        get_resource_usage
        ;;
    "disk")
        check_disk_usage
        ;;
    "status")
        docker-compose ps
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        echo "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
