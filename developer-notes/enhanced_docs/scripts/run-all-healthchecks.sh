#!/bin/bash

# Exit on error
set -e

# Colors for output 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Run all health checks
echo "Running all service health checks..."

# Core services
./check_network.sh
./scripts/monitor_health.sh
./check_ports.sh
./check_vector_stores.sh

# SSL certificates if enabled
if [ -d "./docker/nginx/ssl" ]; then
    ./check_ssl.sh
fi

# Database initialization check for dev environment
if [ "$DEPLOY_ENV" = "development" ]; then
    ./initialize_database.sh
fi

# Service health checks
docker-compose ps -q | xargs docker inspect -f '{{.State.Health.Status}}' | while read status; do
    if [ "$status" != "healthy" ]; then
        echo -e "${RED}One or more services are not healthy${NC}"
        exit 1
    fi
done

# Space and resource checks
# Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo -e "${RED}Warning: Disk usage is at $DISK_USAGE%${NC}"
fi

# Check memory
MEM_FREE=$(free -m | awk 'NR==2 {print $4}')
if [ "$MEM_FREE" -lt 1024 ]; then
    echo -e "${YELLOW}Warning: Less than 1GB free memory available${NC}"
fi

# Check container status
docker-compose ps | grep -E "(Exit|Restarting)" && {
    echo -e "${RED}One or more containers are not running correctly${NC}"
    exit 1
}

echo -e "${GREEN}All health checks completed successfully${NC}"