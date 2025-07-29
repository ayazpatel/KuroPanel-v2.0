#!/bin/bash
# Production Deployment Script for KuroPanel V2
# Automated production deployment with safety checks

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env.production"
BACKUP_DIR="$PROJECT_DIR/backups/deployment"
LOG_FILE="$PROJECT_DIR/deploy.log"
COMPOSE_FILE="docker-compose.production.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

# Help function
show_help() {
    cat << EOF
KuroPanel V2 Production Deployment Script

Usage: $0 [OPTION]

Options:
    deploy          Full production deployment
    update          Update existing deployment
    rollback        Rollback to previous version
    backup          Create full backup
    restore         Restore from backup
    health          Check system health
    logs            Show application logs
    scale           Scale services
    ssl             Setup SSL certificates
    monitor         Start monitoring services
    help            Show this help

Examples:
    $0 deploy           # Full production deployment
    $0 update           # Update existing deployment
    $0 rollback         # Rollback to previous version
    $0 health           # Check system health
    $0 logs app         # Show application logs
    $0 scale app 3      # Scale app service to 3 replicas

EOF
}

# Pre-deployment checks
pre_deployment_checks() {
    log "Running pre-deployment checks..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        warn "Running as root. Consider using a dedicated user for security."
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed"
    fi
    
    # Check environment file
    if [[ ! -f "$ENV_FILE" ]]; then
        error "Production environment file not found: $ENV_FILE"
    fi
    
    # Check required directories
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Check disk space (require at least 5GB)
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=5242880  # 5GB in KB
    
    if [[ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]]; then
        error "Insufficient disk space. Required: 5GB, Available: $(($AVAILABLE_SPACE/1024/1024))GB"
    fi
    
    # Check memory (require at least 2GB)
    AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    REQUIRED_MEM=2048
    
    if [[ $AVAILABLE_MEM -lt $REQUIRED_MEM ]]; then
        warn "Low available memory. Required: ${REQUIRED_MEM}MB, Available: ${AVAILABLE_MEM}MB"
    fi
    
    log "Pre-deployment checks completed successfully"
}

# Create backup
create_backup() {
    log "Creating backup..."
    
    BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/backup_$BACKUP_TIMESTAMP"
    
    mkdir -p "$BACKUP_PATH"
    
    # Backup database
    if docker ps | grep -q kuropanel_db_prod; then
        log "Backing up database..."
        docker exec kuropanel_db_prod mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases > "$BACKUP_PATH/database.sql"
    fi
    
    # Backup application data
    log "Backing up application data..."
    cp -r "$PROJECT_DIR/data" "$BACKUP_PATH/" 2>/dev/null || true
    cp -r "$PROJECT_DIR/ssl" "$BACKUP_PATH/" 2>/dev/null || true
    cp "$ENV_FILE" "$BACKUP_PATH/" 2>/dev/null || true
    
    # Create archive
    tar -czf "$BACKUP_PATH.tar.gz" -C "$BACKUP_DIR" "backup_$BACKUP_TIMESTAMP"
    rm -rf "$BACKUP_PATH"
    
    log "Backup created: $BACKUP_PATH.tar.gz"
    echo "$BACKUP_PATH.tar.gz" > "$PROJECT_DIR/.last_backup"
}

# Deploy function
deploy() {
    log "Starting KuroPanel V2 production deployment..."
    
    pre_deployment_checks
    create_backup
    
    # Pull latest images
    log "Pulling Docker images..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull
    
    # Build custom images
    log "Building application images..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build --no-cache
    
    # Start services
    log "Starting services..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    sleep 30
    
    # Run database migrations
    log "Running database setup..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T app php spark migrate:latest
    
    # Health check
    if health_check; then
        log "Deployment completed successfully!"
    else
        error "Deployment failed health check"
    fi
}

# Update function
update() {
    log "Updating KuroPanel V2..."
    
    pre_deployment_checks
    create_backup
    
    # Pull latest images
    log "Pulling updated images..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull
    
    # Rebuild and restart services
    log "Rebuilding and restarting services..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --build
    
    # Health check
    if health_check; then
        log "Update completed successfully!"
    else
        error "Update failed health check"
    fi
}

# Rollback function
rollback() {
    log "Rolling back KuroPanel V2..."
    
    if [[ ! -f "$PROJECT_DIR/.last_backup" ]]; then
        error "No backup found for rollback"
    fi
    
    BACKUP_FILE=$(cat "$PROJECT_DIR/.last_backup")
    
    if [[ ! -f "$BACKUP_FILE" ]]; then
        error "Backup file not found: $BACKUP_FILE"
    fi
    
    # Stop services
    log "Stopping services..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down
    
    # Restore backup
    log "Restoring from backup..."
    RESTORE_DIR="$BACKUP_DIR/restore_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$RESTORE_DIR"
    tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"
    
    # Restore data
    BACKUP_NAME=$(basename "$BACKUP_FILE" .tar.gz)
    cp -r "$RESTORE_DIR/$BACKUP_NAME/data" "$PROJECT_DIR/" 2>/dev/null || true
    cp -r "$RESTORE_DIR/$BACKUP_NAME/ssl" "$PROJECT_DIR/" 2>/dev/null || true
    
    # Restore database
    if [[ -f "$RESTORE_DIR/$BACKUP_NAME/database.sql" ]]; then
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d database
        sleep 10
        docker exec -i kuropanel_db_prod mysql -u root -p"$MYSQL_ROOT_PASSWORD" < "$RESTORE_DIR/$BACKUP_NAME/database.sql"
    fi
    
    # Start services
    log "Starting services..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d
    
    # Cleanup
    rm -rf "$RESTORE_DIR"
    
    log "Rollback completed successfully!"
}

# Health check function
health_check() {
    log "Performing health check..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f -s http://localhost/api/health >/dev/null 2>&1; then
            log "Health check passed"
            return 0
        fi
        
        log "Health check attempt $attempt/$max_attempts failed, retrying..."
        sleep 10
        ((attempt++))
    done
    
    error "Health check failed after $max_attempts attempts"
    return 1
}

# Show logs function
show_logs() {
    local service=${1:-""}
    
    if [[ -n "$service" ]]; then
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f "$service"
    else
        docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f
    fi
}

# Scale services function
scale_services() {
    local service=${1:-"app"}
    local replicas=${2:-"2"}
    
    log "Scaling $service to $replicas replicas..."
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --scale "$service=$replicas"
    log "Scaling completed"
}

# Setup SSL certificates
setup_ssl() {
    log "Setting up SSL certificates..."
    
    local domain=${1:-$(grep DOMAIN= "$ENV_FILE" | cut -d'=' -f2)}
    local ssl_dir="$PROJECT_DIR/ssl"
    
    mkdir -p "$ssl_dir"
    
    # Generate self-signed certificate if none exists
    if [[ ! -f "$ssl_dir/fullchain.pem" ]] || [[ ! -f "$ssl_dir/privkey.pem" ]]; then
        log "Generating self-signed SSL certificate..."
        openssl req -x509 -newkey rsa:4096 -keyout "$ssl_dir/privkey.pem" -out "$ssl_dir/fullchain.pem" -days 365 -nodes \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"
        chmod 600 "$ssl_dir/privkey.pem"
        chmod 644 "$ssl_dir/fullchain.pem"
    fi
    
    log "SSL certificates ready"
}

# Start monitoring services
start_monitoring() {
    log "Starting monitoring services..."
    
    docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --profile with-monitoring up -d
    
    log "Monitoring services started"
    log "Grafana: http://localhost:3000"
    log "Prometheus: http://localhost:9090"
}

# Main script logic
main() {
    cd "$PROJECT_DIR"
    
    case "${1:-help}" in
        deploy)
            deploy
            ;;
        update)
            update
            ;;
        rollback)
            rollback
            ;;
        backup)
            create_backup
            ;;
        health)
            health_check
            ;;
        logs)
            show_logs "${2:-}"
            ;;
        scale)
            scale_services "${2:-app}" "${3:-2}"
            ;;
        ssl)
            setup_ssl "${2:-}"
            ;;
        monitor)
            start_monitoring
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $1. Use 'help' for available commands."
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
