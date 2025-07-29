#!/bin/bash
# Backup script for KuroPanel project

set -e

# Configuration
BACKUP_DIR="backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="kuropanel_backup_${TIMESTAMP}"
CONTAINER_DB="kuropanel_db"
DB_NAME="kuropanel"
DB_USER="kuro_user"
DB_PASS="kuro_password"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Create backup directory
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log "Created backup directory: $BACKUP_DIR"
    fi
    
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$backup_path"
    echo "$backup_path"
}

# Backup database
backup_database() {
    local backup_path=$1
    
    log "Backing up database..."
    
    if ! docker ps | grep -q "$CONTAINER_DB"; then
        error "Database container $CONTAINER_DB is not running"
        return 1
    fi
    
    # Create database dump
    docker exec "$CONTAINER_DB" mysqldump \
        -u"$DB_USER" \
        -p"$DB_PASS" \
        "$DB_NAME" > "$backup_path/database.sql"
    
    if [ $? -eq 0 ]; then
        log "✓ Database backup completed"
        info "Database backup saved to: $backup_path/database.sql"
    else
        error "✗ Database backup failed"
        return 1
    fi
}

# Backup application files
backup_application() {
    local backup_path=$1
    
    log "Backing up application files..."
    
    # Files and directories to backup
    local items_to_backup=(
        "app/"
        "public/"
        "writable/"
        ".env"
        ".env.development"
        ".env.testing"
        "composer.json"
        "composer.lock"
        "spark"
    )
    
    # Create application backup directory
    mkdir -p "$backup_path/application"
    
    for item in "${items_to_backup[@]}"; do
        if [ -e "$item" ]; then
            cp -r "$item" "$backup_path/application/"
            log "✓ Backed up: $item"
        else
            warn "Item not found, skipping: $item"
        fi
    done
    
    log "✓ Application files backup completed"
}

# Backup Docker configuration
backup_docker_config() {
    local backup_path=$1
    
    log "Backing up Docker configuration..."
    
    local docker_items=(
        "Dockerfile"
        "Dockerfile.test"
        "docker-compose.yml"
        "docker/"
        ".dockerignore"
    )
    
    mkdir -p "$backup_path/docker"
    
    for item in "${docker_items[@]}"; do
        if [ -e "$item" ]; then
            cp -r "$item" "$backup_path/docker/"
            log "✓ Backed up: $item"
        fi
    done
    
    log "✓ Docker configuration backup completed"
}

# Backup logs
backup_logs() {
    local backup_path=$1
    
    log "Backing up container logs..."
    
    mkdir -p "$backup_path/logs"
    
    # Export container logs
    local containers=("kuropanel_app" "kuropanel_db" "kuropanel_phpmyadmin")
    
    for container in "${containers[@]}"; do
        if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
            docker logs "$container" > "$backup_path/logs/${container}.log" 2>&1
            log "✓ Exported logs for: $container"
        fi
    done
    
    # Backup application logs
    if [ -d "writable/logs" ]; then
        cp -r writable/logs/* "$backup_path/logs/" 2>/dev/null || true
        log "✓ Backed up application logs"
    fi
}

# Create backup archive
create_archive() {
    local backup_path=$1
    local archive_name="${backup_path}.tar.gz"
    
    log "Creating backup archive..."
    
    tar -czf "$archive_name" -C "$BACKUP_DIR" "$BACKUP_NAME"
    
    if [ $? -eq 0 ]; then
        log "✓ Backup archive created: $archive_name"
        
        # Show archive size
        local size=$(du -h "$archive_name" | cut -f1)
        info "Archive size: $size"
        
        # Optionally remove the directory after archiving
        read -p "Remove backup directory? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$backup_path"
            log "Backup directory removed"
        fi
        
        return 0
    else
        error "Failed to create backup archive"
        return 1
    fi
}

# Restore from backup
restore_backup() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        error "Please specify a backup file to restore"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    warn "This will replace current application files and database!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Restore cancelled"
        return 0
    fi
    
    log "Restoring from backup: $backup_file"
    
    # Extract backup
    local temp_dir="temp_restore_$$"
    mkdir -p "$temp_dir"
    tar -xzf "$backup_file" -C "$temp_dir"
    
    local extracted_dir="$temp_dir/$(basename "$backup_file" .tar.gz)"
    
    # Restore database
    if [ -f "$extracted_dir/database.sql" ]; then
        log "Restoring database..."
        docker exec -i "$CONTAINER_DB" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$extracted_dir/database.sql"
        log "✓ Database restored"
    fi
    
    # Restore application files
    if [ -d "$extracted_dir/application" ]; then
        log "Restoring application files..."
        cp -r "$extracted_dir/application"/* .
        log "✓ Application files restored"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    log "✓ Restore completed"
}

# List available backups
list_backups() {
    log "Available backups:"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        info "No backup directory found"
        return 0
    fi
    
    local backups=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f | sort -r)
    
    if [ -z "$backups" ]; then
        info "No backups found"
        return 0
    fi
    
    echo "----------------------------------------"
    for backup in $backups; do
        local size=$(du -h "$backup" | cut -f1)
        local date=$(date -r "$backup" "+%Y-%m-%d %H:%M:%S")
        printf "%-40s %8s %s\n" "$(basename "$backup")" "$size" "$date"
    done
    echo "----------------------------------------"
}

# Clean old backups
clean_old_backups() {
    local keep_days=${1:-7}
    
    log "Cleaning backups older than $keep_days days..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        info "No backup directory found"
        return 0
    fi
    
    local old_backups=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$keep_days)
    
    if [ -z "$old_backups" ]; then
        info "No old backups to clean"
        return 0
    fi
    
    for backup in $old_backups; do
        rm -f "$backup"
        log "Removed old backup: $(basename "$backup")"
    done
}

# Main backup function
main_backup() {
    log "Starting KuroPanel backup..."
    
    local backup_path=$(create_backup_dir)
    
    # Perform backups
    backup_database "$backup_path" || error "Database backup failed"
    backup_application "$backup_path"
    backup_docker_config "$backup_path"
    backup_logs "$backup_path"
    
    # Create metadata file
    cat > "$backup_path/backup_info.txt" << EOF
KuroPanel Backup Information
============================
Backup Date: $(date)
Backup Name: $BACKUP_NAME
Hostname: $(hostname)
Docker Compose Services: $(docker-compose ps --services | tr '\n' ' ')
Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "N/A")
Git Branch: $(git branch --show-current 2>/dev/null || echo "N/A")
EOF
    
    # Create archive
    if create_archive "$backup_path"; then
        log "✓ Backup completed successfully!"
    else
        error "✗ Backup failed!"
        exit 1
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  backup      - Create full backup (default)"
    echo "  restore     - Restore from backup file"
    echo "  list        - List available backups"
    echo "  clean       - Clean old backups (default: 7 days)"
    echo ""
    echo "Examples:"
    echo "  $0 backup"
    echo "  $0 restore backups/kuropanel_backup_20240101_120000.tar.gz"
    echo "  $0 list"
    echo "  $0 clean 30"
    echo ""
}

# Main execution
case "${1:-backup}" in
    "backup")
        main_backup
        ;;
    "restore")
        restore_backup "$2"
        ;;
    "list")
        list_backups
        ;;
    "clean")
        clean_old_backups "$2"
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
