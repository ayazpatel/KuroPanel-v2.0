#!/bin/bash
# MySQL Backup Script for KuroPanel V2 Production

set -euo pipefail

# Configuration
BACKUP_DIR="/var/backups/mysql"
DB_USER="root"
DB_PASS="${MYSQL_ROOT_PASSWORD}"
DB_NAME="${MYSQL_DATABASE:-kuropanel_prod}"
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

# Create backup filename with timestamp
BACKUP_FILE="kuropanel_backup_$(date +%Y%m%d_%H%M%S).sql"

# Create database backup
echo "Creating MySQL backup: $BACKUP_FILE"
mysqldump -u "$DB_USER" -p"$DB_PASS" \
    --single-transaction \
    --routines \
    --triggers \
    --all-databases \
    --add-drop-database \
    > "$BACKUP_FILE"

# Compress backup
gzip "$BACKUP_FILE"
echo "Backup compressed: ${BACKUP_FILE}.gz"

# Remove old backups (keep only last 30 days)
find "$BACKUP_DIR" -name "kuropanel_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete

# List current backups
echo "Current backups:"
ls -lah "$BACKUP_DIR"/kuropanel_backup_*.sql.gz

echo "MySQL backup completed successfully"
