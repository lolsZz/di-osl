#!/bin/bash

# Automated backup service for critical data

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BACKUP_DIR="./backups"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Logging setup
LOG_DIR="./logs/backup"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/backup-$TIMESTAMP.log"

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

backup_database() {
    log "INFO" "Starting database backup"
    
    local backup_file="$BACKUP_DIR/database/postgres-$TIMESTAMP.sql"
    mkdir -p "$BACKUP_DIR/database"
    
    if ! PGPASSWORD=$POSTGRES_PASSWORD pg_dump -h localhost -U $POSTGRES_USER postgres > "$backup_file"; then
        log "ERROR" "Database backup failed"
        return 1
    fi
    
    # Compress backup
    gzip "$backup_file"
    
    log "INFO" "Database backup completed: ${backup_file}.gz"
    return 0
}

backup_redis() {
    log "INFO" "Starting Redis backup"
    
    local backup_file="$BACKUP_DIR/redis/dump-$TIMESTAMP.rdb"
    mkdir -p "$BACKUP_DIR/redis"
    
    if ! redis-cli save && cp /var/lib/redis/dump.rdb "$backup_file"; then
        log "ERROR" "Redis backup failed"
        return 1
    fi
    
    # Compress backup
    gzip "$backup_file"
    
    log "INFO" "Redis backup completed: ${backup_file}.gz"
    return 0
}

backup_config() {
    log "INFO" "Starting configuration backup"
    
    local backup_file="$BACKUP_DIR/config/config-$TIMESTAMP.tar.gz"
    mkdir -p "$BACKUP_DIR/config"
    
    # Backup all configuration files
    tar -czf "$backup_file" \
        docker-compose.yml \
        .env* \
        config/ \
        docker/nginx/conf.d/ \
        docker/nginx/ssl/
    
    if [ $? -ne 0 ]; then
        log "ERROR" "Configuration backup failed"
        return 1
    fi
    
    log "INFO" "Configuration backup completed: $backup_file"
    return 0
}

backup_storage() {
    log "INFO" "Starting storage backup"
    
    local backup_file="$BACKUP_DIR/storage/storage-$TIMESTAMP.tar.gz"
    mkdir -p "$BACKUP_DIR/storage"
    
    # Backup application storage
    tar -czf "$backup_file" volumes/app/storage/
    
    if [ $? -ne 0 ]; then
        log "ERROR" "Storage backup failed"
        return 1
    fi
    
    log "INFO" "Storage backup completed: $backup_file"
    return 0
}

cleanup_old_backups() {
    log "INFO" "Cleaning up old backups"
    
    find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete
    
    if [ $? -ne 0 ]; then
        log "WARNING" "Cleanup of old backups failed"
        return 1
    fi
    
    log "INFO" "Backup cleanup completed"
    return 0
}

verify_backups() {
    log "INFO" "Verifying backups"
    
    # Verify database backup
    local latest_db_backup=$(ls -t "$BACKUP_DIR/database/"*.gz | head -1)
    if ! gunzip -t "$latest_db_backup"; then
        log "ERROR" "Database backup verification failed"
        return 1
    fi
    
    # Verify config backup
    local latest_config_backup=$(ls -t "$BACKUP_DIR/config/"*.tar.gz | head -1)
    if ! tar -tzf "$latest_config_backup" >/dev/null; then
        log "ERROR" "Configuration backup verification failed"
        return 1
    fi
    
    log "INFO" "Backup verification completed"
    return 0
}

main() {
    log "INFO" "Starting backup process"
    
    local failed=0
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Run backups
    backup_database || failed=1
    backup_redis || failed=1
    backup_config || failed=1
    backup_storage || failed=1
    
    # Verify backups
    verify_backups || failed=1
    
    # Cleanup old backups
    cleanup_old_backups
    
    if [ $failed -eq 0 ]; then
        log "INFO" "All backup operations completed successfully"
        return 0
    else
        log "ERROR" "One or more backup operations failed"
        return 1
    fi
}

main "$@"