#!/bin/bash

# Enhanced validation script for installation and runtime checks

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging setup
LOG_DIR="./logs/validation"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/validation-$(date +%Y%m%d-%H%M%S).log"

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

check_system_requirements() {
    log "INFO" "Checking system requirements..."
    
    # CPU Cores
    CPU_CORES=$(nproc)
    if [ "$CPU_CORES" -lt 4 ]; then
        log "ERROR" "Insufficient CPU cores (found: $CPU_CORES, required: 4)"
        return 1
    fi
    
    # Memory
    TOTAL_RAM_GB=$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)
    if [ "$TOTAL_RAM_GB" -lt 8 ]; then
        log "ERROR" "Insufficient RAM (found: ${TOTAL_RAM_GB}GB, required: 8GB)"
        return 1
    fi
    
    # Disk Space
    FREE_DISK_GB=$(df -BG / | awk 'NR==2 {print +$4}')
    if [ "$FREE_DISK_GB" -lt 20 ]; then
        log "ERROR" "Insufficient free disk space (found: ${FREE_DISK_GB}GB, required: 20GB)"
        return 1
    fi
    
    log "INFO" "System requirements check passed"
    return 0
}

check_docker_environment() {
    log "INFO" "Checking Docker environment..."
    
    # Docker version
    if ! command -v docker &>/dev/null; then
        log "ERROR" "Docker is not installed"
        return 1
    fi
    
    # Docker Compose
    if ! command -v docker-compose &>/dev/null; then
        log "ERROR" "Docker Compose is not installed"
        return 1
    fi
    
    # Docker permissions
    if ! docker info &>/dev/null; then
        log "ERROR" "Cannot connect to Docker daemon"
        return 1
    fi
    
    log "INFO" "Docker environment check passed"
    return 0
}

check_network_configuration() {
    log "INFO" "Checking network configuration..."
    
    # DNS resolution
    if ! host -t A google.com &>/dev/null; then
        log "ERROR" "DNS resolution failed"
        return 1
    fi
    
    # Required ports
    local required_ports=(5001 6379 5432 9200)
    for port in "${required_ports[@]}"; do
        if netstat -tuln | grep -q ":${port} "; then
            log "ERROR" "Port ${port} is already in use"
            return 1
        fi
    done
    
    log "INFO" "Network configuration check passed"
    return 0
}

validate_services() {
    log "INFO" "Validating services..."
    
    local services=("api" "worker" "postgres" "redis")
    for service in "${services[@]}"; do
        if ! docker-compose ps "$service" | grep -q "Up"; then
            log "ERROR" "Service ${service} is not running"
            return 1
        fi
    done
    
    log "INFO" "Service validation passed"
    return 0
}

check_security_configuration() {
    log "INFO" "Checking security configuration..."
    
    # SSL certificates
    if [ -d "./docker/nginx/ssl" ]; then
        if [ ! -f "./docker/nginx/ssl/cert.pem" ] || [ ! -f "./docker/nginx/ssl/key.pem" ]; then
            log "ERROR" "SSL certificates are missing"
            return 1
        fi
    fi
    
    # File permissions
    if [ -w "/var/run/docker.sock" ]; then
        log "WARNING" "Docker socket is world-writable"
    fi
    
    log "INFO" "Security configuration check passed"
    return 0
}

check_python_environment() {
    log "INFO" "Checking Python environment..."
    
    # Python version
    if ! command -v python3 &>/dev/null; then
        log "ERROR" "Python 3 is not installed"
        return 1
    fi
    
    # Virtual environment
    if [ ! -d "venv" ]; then
        log "ERROR" "Virtual environment not found"
        return 1
    fi
    
    # Required packages
    if [ -f "requirements.txt" ]; then
        if ! pip3 freeze | diff - requirements.txt >/dev/null; then
            log "ERROR" "Python package requirements not met"
            return 1
        fi
    fi
    
    log "INFO" "Python environment check passed"
    return 0
}

check_node_environment() {
    log "INFO" "Checking Node.js environment..."
    
    # Node.js version
    if ! command -v node &>/dev/null; then
        log "ERROR" "Node.js is not installed"
        return 1
    fi
    
    # NPM
    if ! command -v npm &>/dev/null; then
        log "ERROR" "NPM is not installed"
        return 1
    fi
    
    # Required packages
    if [ -f "package.json" ]; then
        if ! npm list >/dev/null 2>&1; then
            log "ERROR" "Node.js package requirements not met"
            return 1
        fi
    fi
    
    log "INFO" "Node.js environment check passed"
    return 0
}

check_storage_permissions() {
    log "INFO" "Checking storage permissions..."
    
    local storage_paths=(
        "./volumes/app/storage"
        "./volumes/postgres"
        "./volumes/redis"
        "./volumes/opensearch"
    )
    
    for path in "${storage_paths[@]}"; do
        if [ ! -w "$path" ]; then
            log "ERROR" "Storage path $path is not writable"
            return 1
        fi
    done
    
    log "INFO" "Storage permissions check passed"
    return 0
}

check_database_connectivity() {
    log "INFO" "Checking database connectivity..."
    
    if ! PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -U $POSTGRES_USER -d postgres -c '\q' &>/dev/null; then
        log "ERROR" "Cannot connect to PostgreSQL"
        return 1
    fi
    
    if ! redis-cli ping &>/dev/null; then
        log "ERROR" "Cannot connect to Redis"
        return 1
    fi
    
    log "INFO" "Database connectivity check passed"
    return 0
}

main() {
    log "INFO" "Starting enhanced validation checks"
    
    local checks=(
        check_system_requirements
        check_docker_environment
        check_network_configuration
        check_python_environment
        check_node_environment
        check_storage_permissions
        check_security_configuration
        check_database_connectivity
        validate_services
    )
    
    local failed=0
    for check in "${checks[@]}"; do
        if ! $check; then
            failed=1
            log "ERROR" "Check failed: $check"
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log "INFO" "All validation checks passed successfully"
        return 0
    else
        log "ERROR" "One or more validation checks failed"
        return 1
    fi
}

main "$@"