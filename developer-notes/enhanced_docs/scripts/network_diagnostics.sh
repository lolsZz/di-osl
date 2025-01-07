#!/bin/bash

# Network diagnostics script for troubleshooting connectivity issues

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging setup
LOG_DIR="./logs/network"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/network-$(date +%Y%m%d-%H%M%S).log"

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

check_dns_resolution() {
    log "INFO" "Checking DNS resolution..."
    
    local domains=("google.com" "github.com" "docker.io")
    local failed=0
    
    for domain in "${domains[@]}"; do
        if ! host -t A "$domain" &>/dev/null; then
            log "ERROR" "Failed to resolve $domain"
            failed=1
        else
            log "INFO" "Successfully resolved $domain"
        fi
    done
    
    return $failed
}

check_network_latency() {
    log "INFO" "Checking network latency..."
    
    local targets=("8.8.8.8" "1.1.1.1")
    local max_latency=100
    local failed=0
    
    for target in "${targets[@]}"; do
        local latency=$(ping -c 1 "$target" | grep "time=" | cut -d "=" -f4)
        if [ -n "$latency" ]; then
            if [ "${latency%.*}" -gt "$max_latency" ]; then
                log "WARNING" "High latency to $target: $latency ms"
                failed=1
            else
                log "INFO" "Acceptable latency to $target: $latency ms"
            fi
        else
            log "ERROR" "Failed to ping $target"
            failed=1
        fi
    done
    
    return $failed
}

verify_required_ports() {
    log "INFO" "Verifying required ports..."
    
    local ports=(
        5001  # API
        6379  # Redis
        5432  # PostgreSQL
        9200  # OpenSearch
        2379  # etcd
    )
    
    local failed=0
    
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":${port} "; then
            log "INFO" "Port $port is open"
        else
            log "ERROR" "Port $port is not available"
            failed=1
        fi
    done
    
    return $failed
}

check_network_interfaces() {
    log "INFO" "Checking network interfaces..."
    
    # Check if at least one interface is up and has an IP
    if ! ip a | grep -q "state UP"; then
        log "ERROR" "No active network interfaces found"
        return 1
    fi
    
    # Check for Docker network interfaces
    if ! ip a | grep -q "docker0"; then
        log "ERROR" "Docker network interface not found"
        return 1
    fi
    
    log "INFO" "Network interfaces check passed"
    return 0
}

check_network_bandwidth() {
    log "INFO" "Testing network bandwidth..."
    
    # Using iperf3 if available
    if command -v iperf3 &>/dev/null; then
        if ! iperf3 -c iperf.he.net -t 5 >/dev/null 2>&1; then
            log "WARNING" "Bandwidth test failed"
            return 1
        fi
    else
        log "WARNING" "iperf3 not installed, skipping bandwidth test"
    fi
    
    return 0
}

check_ssl_certificates() {
    log "INFO" "Checking SSL certificates..."
    
    local cert_dir="./docker/nginx/ssl"
    local failed=0
    
    if [ -d "$cert_dir" ]; then
        if [ -f "$cert_dir/cert.pem" ] && [ -f "$cert_dir/key.pem" ]; then
            # Check certificate expiration
            local expiry=$(openssl x509 -enddate -noout -in "$cert_dir/cert.pem" | cut -d= -f2)
            local expiry_epoch=$(date -d "$expiry" +%s)
            local current_epoch=$(date +%s)
            local days_until_expiry=$(( ($expiry_epoch - $current_epoch) / 86400 ))
            
            if [ $days_until_expiry -lt 30 ]; then
                log "WARNING" "SSL certificate will expire in $days_until_expiry days"
                failed=1
            else
                log "INFO" "SSL certificate is valid for $days_until_expiry more days"
            fi
        else
            log "ERROR" "SSL certificate files missing"
            failed=1
        fi
    else
        log "WARNING" "SSL directory not found"
        failed=1
    fi
    
    return $failed
}

check_docker_networks() {
    log "INFO" "Checking Docker networks..."
    
    # Verify required networks exist
    local networks=("backend" "frontend" "proxy")
    local failed=0
    
    for network in "${networks[@]}"; do
        if ! docker network ls | grep -q "$network"; then
            log "ERROR" "Docker network '$network' not found"
            failed=1
        fi
    done
    
    # Check network connectivity between containers
    if ! docker network inspect bridge >/dev/null 2>&1; then
        log "ERROR" "Docker bridge network not available"
        failed=1
    fi
    
    return $failed
}

main() {
    log "INFO" "Starting network diagnostics"
    
    local checks=(
        check_dns_resolution
        check_network_latency
        verify_required_ports
        check_network_interfaces
        check_network_bandwidth
        check_ssl_certificates
        check_docker_networks
    )
    
    local failed=0
    for check in "${checks[@]}"; do
        if ! $check; then
            failed=1
            log "ERROR" "Check failed: $check"
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log "INFO" "All network diagnostic checks passed"
        return 0
    else
        log "ERROR" "One or more network diagnostic checks failed"
        return 1
    fi
}

main "$@"