#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# List of required ports and their services
declare -A ports=(
    # Core Services
    [5001]="API Server"
    [3000]="Web Interface"
    
    # Database Services
    [5432]="PostgreSQL"
    [6379]="Redis"
    [4000]="TiDB"
    [8091]="Couchbase"
    [8123]="MyScale HTTP"
    [9000]="MyScale/MinIO TCP"
    
    # Vector Stores & Search
    [9200]="OpenSearch/Elasticsearch"
    [5601]="Kibana"
    [9091]="Milvus"
    [2379]="Etcd"
    
    # Support Services
    [3128]="SSRF Proxy"
    [7700]="Qdrant REST API"
    [8100]="Chroma API"
)

echo -e "${GREEN}Checking port availability...${NC}"

# Add timeout to netstat checks
check_with_timeout() {
    local cmd="$1"
    local timeout=5
    
    # Start command in background
    eval "$cmd" &
    local pid=$!
    
    # Wait up to timeout seconds for command to complete
    local counter=0
    while kill -0 $pid 2>/dev/null; do
        if [ $counter -ge $timeout ]; then
            kill $pid 2>/dev/null
            return 1
        fi
        sleep 1
        ((counter++))
    done
    
    # Get command exit status
    wait $pid
    return $?
}

# Function to check if a port is available
check_port() {
    local port=$1
    local service=$2
    if netstat -tuln | grep -q ":$port "; then
        echo -e "${RED}Port $port ($service) is already in use${NC}"
        return 1
    else
        echo -e "${GREEN}Port $port ($service) is available${NC}"
        return 0
    fi
}

# Check all ports
failed=0
for port in "${!ports[@]}"; do
    if ! check_port "$port" "${ports[$port]}"; then
        failed=1
    fi
done

if [ $failed -eq 1 ]; then
    echo -e "\n${YELLOW}Some ports are already in use. Please free them before proceeding.${NC}"
    exit 1
else
    echo -e "\n${GREEN}All required ports are available!${NC}"
    exit 0
fi