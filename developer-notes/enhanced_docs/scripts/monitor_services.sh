#!/bin/bash

# Service monitoring script for continuous health checking

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging setup
LOG_DIR="./logs/monitoring"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/monitoring-$(date +%Y%m%d-%H%M%S).log"

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

check_service_health() {
    local service=$1
    if ! docker-compose ps "$service" | grep -q "Up"; then
        return 1
    fi
    return 0
}

check_api_health() {
    if ! curl -s http://localhost:5001/health >/dev/null; then
        return 1
    fi
    return 0
}

check_database_health() {
    if ! PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -U $POSTGRES_USER -d postgres -c '\q' >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

check_redis_health() {
    if ! redis-cli ping >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

check_disk_usage() {
    local threshold=90
    local usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
    if [ "$usage" -gt "$threshold" ]; then
        return 1
    fi
    return 0
}

check_memory_usage() {
    local threshold=90
    local usage=$(free | awk '/Mem:/ {print int($3/$2 * 100)}')
    if [ "$usage" -gt "$threshold" ]; then
        return 1
    fi
    return 0
}

monitor_services() {
    while true; do
        log "INFO" "Running health checks..."
        
        # Check core services
        local services=("api" "worker" "postgres" "redis")
        for service in "${services[@]}"; do
            if ! check_service_health "$service"; then
                log "ERROR" "Service $service is down"
                notify_admin "Service $service is down"
            fi
        done
        
        # Check API health
        if ! check_api_health; then
            log "ERROR" "API health check failed"
            notify_admin "API health check failed"
        fi
        
        # Check database health
        if ! check_database_health; then
            log "ERROR" "Database health check failed"
            notify_admin "Database health check failed"
        fi
        
        # Check Redis health
        if ! check_redis_health; then
            log "ERROR" "Redis health check failed"
            notify_admin "Redis health check failed"
        fi
        
        # Check system resources
        if ! check_disk_usage; then
            log "WARNING" "High disk usage detected"
            notify_admin "High disk usage warning"
        fi
        
        if ! check_memory_usage; then
            log "WARNING" "High memory usage detected"
            notify_admin "High memory usage warning"
        fi
        
        sleep 60
    done
}

notify_admin() {
    local message=$1
    # Implementation depends on preferred notification method
    # Example: Send email, Slack message, etc.
    echo "ADMIN NOTIFICATION: $message"
}

main() {
    log "INFO" "Starting service monitoring"
    monitor_services
}

main "$@"