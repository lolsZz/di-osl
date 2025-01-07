#!/bin/bash

# Installation Checklist and Verification Script
# This script provides comprehensive installation verification with detailed logging and context

# Set strict error handling
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file setup
LOG_DIR="logs/installation"
LOG_FILE="${LOG_DIR}/installation_$(date +%Y%m%d_%H%M%S).log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Logging function with context
log() {
    local level=$1
    local message=$2
    local context=$3
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    
    case $level in
        "INFO") color=$GREEN ;;
        "WARN") color=$YELLOW ;;
        "ERROR") color=$RED ;;
        *) color=$NC ;;
    esac
    
    # Console output with color
    echo -e "${color}[${timestamp}] ${level}: ${message}${NC}"
    if [ ! -z "$context" ]; then
        echo -e "${BLUE}Context: ${context}${NC}"
    fi
    
    # Log file output without color codes
    echo "[${timestamp}] ${level}: ${message}" >> "$LOG_FILE"
    if [ ! -z "$context" ]; then
        echo "Context: ${context}" >> "$LOG_FILE"
    fi
}

check_system_requirements() {
    log "INFO" "Checking system requirements" "Verifying minimum hardware and OS requirements"
    
    # CPU Cores
    CPU_CORES=$(nproc)
    if [ "$CPU_CORES" -lt 4 ]; then
        log "WARN" "Insufficient CPU cores: $CPU_CORES" "Recommended: At least 4 cores for optimal performance"
    else
        log "INFO" "CPU cores check passed: $CPU_CORES cores" "Meets minimum requirement of 4 cores"
    fi
    
    # RAM
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
    if [ "$TOTAL_RAM_GB" -lt 8 ]; then
        log "WARN" "Insufficient RAM: ${TOTAL_RAM_GB}GB" "Recommended: At least 8GB RAM"
    else
        log "INFO" "RAM check passed: ${TOTAL_RAM_GB}GB" "Meets minimum requirement of 8GB"
    fi
    
    # Disk Space
    FREE_DISK_KB=$(df -k . | tail -1 | awk '{print $4}')
    FREE_DISK_GB=$((FREE_DISK_KB / 1024 / 1024))
    if [ "$FREE_DISK_GB" -lt 20 ]; then
        log "WARN" "Insufficient disk space: ${FREE_DISK_GB}GB free" "Recommended: At least 20GB free space"
    else
        log "INFO" "Disk space check passed: ${FREE_DISK_GB}GB free" "Meets minimum requirement of 20GB"
    fi
}

check_dependencies() {
    log "INFO" "Checking software dependencies" "Verifying required software versions and configurations"
    
    # Docker version check
    if command -v docker &>/dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        log "INFO" "Docker installed: $DOCKER_VERSION" "Required software dependency"
    else
        log "ERROR" "Docker not installed" "Docker is required for containerization"
    fi
    
    # Docker Compose check
    if command -v docker-compose &>/dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
        log "INFO" "Docker Compose installed: $COMPOSE_VERSION" "Required for multi-container management"
    else
        log "ERROR" "Docker Compose not installed" "Docker Compose is required for container orchestration"
    fi
    
    # Python version check
    if command -v python3 &>/dev/null; then
        PYTHON_VERSION=$(python3 --version | awk '{print $2}')
        log "INFO" "Python installed: $PYTHON_VERSION" "Required for application runtime"
    else
        log "ERROR" "Python 3 not installed" "Python 3.10 or higher is required"
    fi
    
    # Node.js version check
    if command -v node &>/dev/null; then
        NODE_VERSION=$(node --version)
        log "INFO" "Node.js installed: $NODE_VERSION" "Required for frontend development"
    else
        log "ERROR" "Node.js not installed" "Node.js 18 or higher is required"
    fi
}

check_permissions() {
    log "INFO" "Checking filesystem permissions" "Verifying access rights and ownership"
    
    # Define critical directories
    declare -a DIRS=(
        "storage"
        "logs"
        "docker"
        "web/node_modules"
        "api/uploads"
    )
    
    for dir in "${DIRS[@]}"; do
        if [ -d "$dir" ]; then
            if [ -w "$dir" ]; then
                log "INFO" "Directory $dir is writable" "Required for application operation"
            else
                log "ERROR" "Directory $dir is not writable" "Please check permissions and ownership"
            fi
        else
            log "WARN" "Directory $dir does not exist" "Will be created during installation"
        fi
    done
    
    # Check Docker socket permissions
    if [ -S "/var/run/docker.sock" ]; then
        if [ -r "/var/run/docker.sock" ] && [ -w "/var/run/docker.sock" ]; then
            log "INFO" "Docker socket is accessible" "Required for Docker operations"
        else
            log "ERROR" "Docker socket is not accessible" "Please check Docker permissions"
        fi
    else
        log "ERROR" "Docker socket not found" "Docker daemon may not be running"
    fi
}

check_network() {
    log "INFO" "Checking network configuration" "Verifying connectivity and port availability"
    
    # Check DNS resolution
    if host -t A google.com &>/dev/null; then
        log "INFO" "DNS resolution working" "Required for external connectivity"
    else
        log "ERROR" "DNS resolution failed" "Please check network configuration"
    fi
    
    # Check required ports
    declare -a PORTS=(80 443 3000 5432 6379)
    for port in "${PORTS[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            log "WARN" "Port $port is in use" "This port must be available for the application"
        else
            log "INFO" "Port $port is available" "Required for application services"
        fi
    done
}

verify_environment_variables() {
    log "INFO" "Checking environment variables" "Verifying configuration settings"
    
    if [ -f .env ]; then
        log "INFO" "Environment file exists" "Using existing .env file"
        # Check required variables without exposing values
        declare -a REQUIRED_VARS=(
            "DEPLOY_ENV"
            "DATABASE_URL"
            "REDIS_URL"
            "SECRET_KEY"
        )
        
        for var in "${REQUIRED_VARS[@]}"; do
            if grep -q "^${var}=" .env; then
                log "INFO" "Found $var in .env" "Required configuration variable"
            else
                log "ERROR" "Missing $var in .env" "Please add this required variable"
            fi
        done
    else
        log "WARN" "No .env file found" "Will need to be created during setup"
    fi
}

main() {
    log "INFO" "Starting installation checklist verification" "This process will check all requirements"
    
    check_system_requirements
    check_dependencies
    check_permissions
    check_network
    verify_environment_variables
    
    # Final status report
    echo -e "\n${BLUE}=== Installation Checklist Summary ===${NC}"
    echo -e "Detailed logs available at: $LOG_FILE"
    
    if grep -q "ERROR" "$LOG_FILE"; then
        echo -e "${RED}❌ Installation checklist found critical issues${NC}"
        echo -e "Please review the log file and address all ERROR messages before proceeding."
        exit 1
    elif grep -q "WARN" "$LOG_FILE"; then
        echo -e "${YELLOW}⚠️  Installation checklist completed with warnings${NC}"
        echo -e "Please review the log file and address any warnings before proceeding."
        exit 0
    else
        echo -e "${GREEN}✅ Installation checklist completed successfully${NC}"
        echo -e "All checks passed. You may proceed with the installation."
        exit 0
    fi
}

main "$@"