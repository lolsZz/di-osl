#!/bin/bash

# SSL certificate management script

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
SSL_DIR="./docker/nginx/ssl"
DAYS_WARNING=30
CERT_BITS=4096
CERT_DAYS=365

# Logging setup
LOG_DIR="./logs/ssl"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ssl-$(date +%Y%m%d-%H%M%S).log"

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

check_openssl() {
    if ! command -v openssl &>/dev/null; then
        log "ERROR" "OpenSSL is not installed"
        return 1
    fi
    return 0
}

create_self_signed_cert() {
    log "INFO" "Creating new self-signed certificate..."
    
    mkdir -p "$SSL_DIR"
    
    # Generate private key
    if ! openssl genrsa -out "$SSL_DIR/key.pem" $CERT_BITS; then
        log "ERROR" "Failed to generate private key"
        return 1
    fi
    
    # Generate CSR
    if ! openssl req -new -key "$SSL_DIR/key.pem" -out "$SSL_DIR/csr.pem" -subj "/CN=localhost"; then
        log "ERROR" "Failed to generate CSR"
        return 1
    fi
    
    # Generate certificate
    if ! openssl x509 -req -days $CERT_DAYS -in "$SSL_DIR/csr.pem" \
         -signkey "$SSL_DIR/key.pem" -out "$SSL_DIR/cert.pem"; then
        log "ERROR" "Failed to generate certificate"
        return 1
    fi
    
    # Clean up CSR
    rm -f "$SSL_DIR/csr.pem"
    
    log "INFO" "Self-signed certificate created successfully"
    return 0
}

check_cert_expiry() {
    local cert_file="$SSL_DIR/cert.pem"
    
    if [ ! -f "$cert_file" ]; then
        log "ERROR" "Certificate file not found"
        return 1
    fi
    
    local expiry=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
    local expiry_epoch=$(date -d "$expiry" +%s)
    local current_epoch=$(date +%s)
    local days_until_expiry=$(( ($expiry_epoch - $current_epoch) / 86400 ))
    
    if [ $days_until_expiry -lt 0 ]; then
        log "ERROR" "Certificate has expired"
        return 1
    elif [ $days_until_expiry -lt $DAYS_WARNING ]; then
        log "WARNING" "Certificate will expire in $days_until_expiry days"
        return 1
    else
        log "INFO" "Certificate is valid for $days_until_expiry more days"
        return 0
    fi
}

backup_certificates() {
    log "INFO" "Backing up SSL certificates..."
    
    local backup_dir="$SSL_DIR/backup"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    mkdir -p "$backup_dir"
    
    if [ -f "$SSL_DIR/cert.pem" ] && [ -f "$SSL_DIR/key.pem" ]; then
        if ! tar -czf "$backup_dir/ssl-$timestamp.tar.gz" \
             -C "$SSL_DIR" cert.pem key.pem; then
            log "ERROR" "Failed to backup certificates"
            return 1
        fi
        log "INFO" "Certificates backed up successfully"
        return 0
    else
        log "ERROR" "Certificate files not found"
        return 1
    fi
}

verify_certificate() {
    log "INFO" "Verifying certificate..."
    
    local cert_file="$SSL_DIR/cert.pem"
    local key_file="$SSL_DIR/key.pem"
    
    # Check if files exist
    if [ ! -f "$cert_file" ] || [ ! -f "$key_file" ]; then
        log "ERROR" "Certificate or key file missing"
        return 1
    fi
    
    # Verify certificate matches private key
    if ! openssl x509 -noout -modulus -in "$cert_file" | \
         openssl md5 | \
         grep -q "$(openssl rsa -noout -modulus -in "$key_file" | openssl md5)"; then
        log "ERROR" "Certificate does not match private key"
        return 1
    fi
    
    # Verify certificate validity
    if ! openssl x509 -noout -in "$cert_file" 2>/dev/null; then
        log "ERROR" "Invalid certificate"
        return 1
    fi
    
    log "INFO" "Certificate verification passed"
    return 0
}

check_permissions() {
    log "INFO" "Checking SSL file permissions..."
    
    local files=("$SSL_DIR/cert.pem" "$SSL_DIR/key.pem")
    local failed=0
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            local perms=$(stat -c "%a" "$file")
            if [ "$perms" != "600" ]; then
                log "ERROR" "Incorrect permissions on $file: $perms (should be 600)"
                chmod 600 "$file"
                failed=1
            fi
        else
            log "ERROR" "File not found: $file"
            failed=1
        fi
    done
    
    return $failed
}

main() {
    log "INFO" "Starting SSL certificate management"
    
    local failed=0
    
    # Check OpenSSL installation
    if ! check_openssl; then
        log "ERROR" "OpenSSL check failed"
        exit 1
    fi
    
    # Create SSL directory if it doesn't exist
    mkdir -p "$SSL_DIR"
    
    # Check if certificates exist
    if [ ! -f "$SSL_DIR/cert.pem" ] || [ ! -f "$SSL_DIR/key.pem" ]; then
        log "WARNING" "SSL certificates not found, creating self-signed certificates"
        if ! create_self_signed_cert; then
            failed=1
        fi
    fi
    
    # Run checks
    check_cert_expiry || failed=1
    verify_certificate || failed=1
    check_permissions || failed=1
    
    # Backup certificates
    backup_certificates
    
    if [ $failed -eq 0 ]; then
        log "INFO" "SSL certificate management completed successfully"
        return 0
    else
        log "ERROR" "SSL certificate management encountered issues"
        return 1
    fi
}

main "$@"