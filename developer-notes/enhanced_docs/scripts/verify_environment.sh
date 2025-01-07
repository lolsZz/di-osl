#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Performing comprehensive environment verification...${NC}"

# System Resources Check
echo "Checking system resources..."

# Check CPU cores
CPU_CORES=$(nproc)
if [ "$CPU_CORES" -lt 4 ]; then
    echo -e "${YELLOW}Warning: Less than 4 CPU cores available (found: $CPU_CORES). This may impact performance.${NC}"
else
    echo -e "${GREEN}CPU cores: $CPU_CORES - OK${NC}"
fi

# Check available RAM
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$((TOTAL_RAM_KB/1024/1024))
if [ "$TOTAL_RAM_GB" -lt 8 ]; then
    echo -e "${YELLOW}Warning: Less than 8GB RAM available (found: ${TOTAL_RAM_GB}GB). This may impact performance.${NC}"
else
    echo -e "${GREEN}RAM: ${TOTAL_RAM_GB}GB - OK${NC}"
fi

# Check available disk space
FREE_DISK_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$FREE_DISK_GB" -lt 20 ]; then
    echo -e "${YELLOW}Warning: Less than 20GB free disk space available (found: ${FREE_DISK_GB}GB).${NC}"
else
    echo -e "${GREEN}Disk space: ${FREE_DISK_GB}GB free - OK${NC}"
fi

# Check network interfaces and connectivity
echo "Checking network interfaces..."

# Check primary interfaces
if ! ip link show | grep -q '^[0-9]: \(eth\|ens\|enp\|wl\)'; then
    echo -e "${YELLOW}Warning: No standard network interfaces found${NC}"
fi

# Verify network configuration
if ! ip addr show | grep -q 'inet '; then
    echo -e "${RED}Error: No IPv4 addresses configured${NC}"
    exit 1
fi

# Check network manager status
if command -v systemctl &>/dev/null && systemctl is-active --quiet NetworkManager; then
    echo -e "${GREEN}NetworkManager is running - OK${NC}"
else
    echo -e "${YELLOW}Warning: NetworkManager not running${NC}"
fi

# Check DNS resolution
if ! host -t A google.com &>/dev/null; then
    echo -e "${RED}Error: DNS resolution not working${NC}"
    exit 1
else
    echo -e "${GREEN}DNS resolution working - OK${NC}"
fi

# Check SELinux/AppArmor status
echo "Checking security modules..."
if command -v getenforce &>/dev/null; then
    SELINUX_STATUS=$(getenforce)
    echo -e "${GREEN}SELinux status: $SELINUX_STATUS${NC}"
    if [ "$SELINUX_STATUS" = "Enforcing" ]; then
        echo -e "${YELLOW}Note: You may need to set appropriate SELinux contexts${NC}"
        echo -e "${YELLOW}Run: chcon -Rt container_file_t ./volumes/${NC}"
    fi
fi

if command -v aa-status &>/dev/null; then
    if aa-status --enabled &>/dev/null; then
        echo -e "${GREEN}AppArmor is enabled${NC}"
        echo -e "${YELLOW}Note: You may need to configure AppArmor profiles${NC}"
    else
        echo -e "${YELLOW}Warning: AppArmor is installed but not enabled${NC}"
    fi
fi

# Check system locales
echo "Checking system locales..."
if ! locale -a | grep -iq 'en_US.utf8'; then
    echo -e "${YELLOW}Warning: en_US.UTF-8 locale not found${NC}"
    echo -e "${YELLOW}Consider: sudo locale-gen en_US.UTF-8${NC}"
fi

if ! locale -a | grep -iq 'C.UTF-8'; then
    echo -e "${YELLOW}Warning: C.UTF-8 locale not found${NC}"
fi

# Check container runtime requirements
echo "Checking container runtime requirements..."

# Check cgroup v2
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    echo -e "${GREEN}Using cgroup v2 - OK${NC}"
else
    echo -e "${YELLOW}Warning: Not using cgroup v2${NC}"
fi

# Check overlay filesystem
if grep -q overlay /proc/filesystems; then
    echo -e "${GREEN}Overlay filesystem supported - OK${NC}"
else
    echo -e "${RED}Error: Overlay filesystem not supported${NC}"
    exit 1
fi

# Check SSH keys for development
if [ "$DEPLOY_ENV" = "development" ]; then
    echo "Checking SSH configuration..."
    if [ ! -f "$HOME/.ssh/id_rsa" ] && [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        echo -e "${YELLOW}Warning: No SSH keys found${NC}"
        echo -e "${YELLOW}Consider: ssh-keygen -t ed25519${NC}"
    fi
    
    if [ -f "$HOME/.ssh/known_hosts" ]; then
        echo -e "${GREEN}SSH known_hosts exists - OK${NC}"
    else
        echo -e "${YELLOW}Warning: SSH known_hosts file not found${NC}"
    fi
fi

# Docker version check and minimum version requirements
min_docker_version="20.10.0"
min_compose_version="2.0.0"

docker_version_check() {
    local current=$1
    local required=$2
    local IFS=.
    local cur_parts=($current)
    local req_parts=($required)
    
    for ((i=0; i<${#req_parts[@]}; i++)); do
        if [[ -z ${cur_parts[i]} ]]; then
            return 1
        fi
        if ((10#${cur_parts[i]} < 10#${req_parts[i]})); then
            return 1
        fi
        if ((10#${cur_parts[i]} > 10#${req_parts[i]})); then
            return 0
        fi
    done
    return 0
}
DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
if docker_version_check "$DOCKER_VERSION" "$min_docker_version"; then
    echo -e "${GREEN}Docker version: $DOCKER_VERSION - OK${NC}"
else
    echo -e "${RED}Error: Docker version $DOCKER_VERSION is less than required $min_docker_version${NC}"
    exit 1
fi

DOCKER_COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
if docker_version_check "$DOCKER_COMPOSE_VERSION" "$min_compose_version"; then
    echo -e "${GREEN}Docker Compose version: $DOCKER_COMPOSE_VERSION - OK${NC}"
else
    echo -e "${RED}Error: Docker Compose version $DOCKER_COMPOSE_VERSION is less than required $min_compose_version${NC}"
    exit 1
fi

# Check Docker daemon is running
if ! docker info &>/dev/null; then
    echo -e "${RED}Error: Docker daemon is not running${NC}"
    exit 1
fi

# Python version check
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
if [ "$(echo $PYTHON_VERSION | cut -d. -f1,2 | sed 's/\.//')" -lt 310 ]; then
    echo -e "${RED}Error: Python 3.10 or higher required (found: $PYTHON_VERSION)${NC}"
    exit 1
else
    echo -e "${GREEN}Python version: $PYTHON_VERSION - OK${NC}"
fi

# Node.js version check
NODE_VERSION=$(node --version | cut -d'v' -f2)
if [ "$(echo $NODE_VERSION | cut -d. -f1)" -lt 18 ]; then
    echo -e "${RED}Error: Node.js v18 or higher required (found: $NODE_VERSION)${NC}"
    exit 1
else
    echo -e "${GREEN}Node.js version: $NODE_VERSION - OK${NC}"
fi

# Check port availability using dedicated script
echo "Checking port availability..."
./check_ports.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}Port availability check failed${NC}"
    exit 1
fi

# Verify volume directories
echo "Checking volume directories..."
volume_dirs=(
    # Core Storage
    "./volumes/app/storage"
    
    # Database Storage
    "./volumes/db/data"
    "./volumes/redis/data"
    "./volumes/clickhouse/data"
    "./volumes/clickhouse/log"
    "./volumes/tidb/data"
    "./volumes/oceanbase/data"
    
    # Vector Store Storage
    "./volumes/elasticsearch/data"
    "./volumes/weaviate"
    "./volumes/qdrant"
    "./volumes/milvus"
    "./volumes/chroma"
    "./volumes/opensearch/data"
    
    # Certificate Storage
    "./volumes/nginx/ssl"
    "./volumes/certbot"
    
    # Additional Storage
    "./volumes/cache"
    "./volumes/tmp"
    "./volumes/log"
    "./volumes/backup"
)

for dir in "${volume_dirs[@]}"; do
    mkdir -p "$dir"
    if [ -w "$dir" ]; then
        echo -e "${GREEN}Directory $dir is writable - OK${NC}"
    else
        echo -e "${RED}Error: Directory $dir is not writable${NC}"
        exit 1
    fi
done

# Check write permissions for storage directory
STORAGE_DIR="./volumes/app/storage"
mkdir -p "$STORAGE_DIR"
if [ -w "$STORAGE_DIR" ]; then
    echo -e "${GREEN}Storage directory permissions - OK${NC}"
else
    echo -e "${RED}Error: Storage directory is not writable${NC}"
    exit 1
fi

# Check Docker socket permissions
if [ ! -S "/var/run/docker.sock" ]; then
    echo -e "${RED}Error: Docker socket not found at /var/run/docker.sock${NC}"
    exit 1
fi

if ! [ -r "/var/run/docker.sock" ] || ! [ -w "/var/run/docker.sock" ]; then
    echo -e "${RED}Error: Insufficient permissions on Docker socket${NC}"
    echo -e "${YELLOW}Try: sudo usermod -aG docker $USER${NC}"
    exit 1
fi

# Check kernel parameters
echo "Checking kernel parameters..."

# Check swappiness
SWAPPINESS=$(cat /proc/sys/vm/swappiness)
if [ "$SWAPPINESS" -gt 10 ]; then
    echo -e "${YELLOW}Warning: vm.swappiness ($SWAPPINESS) is higher than recommended (10)${NC}"
    echo -e "${YELLOW}Consider: sudo sysctl -w vm.swappiness=10${NC}"
fi

# Check IPv4 forwarding
IPV4_FORWARD=$(cat /proc/sys/net/ipv4/ip_forward)
if [ "$IPV4_FORWARD" != "1" ]; then
    echo -e "${YELLOW}Warning: IPv4 forwarding is disabled${NC}"
    echo -e "${YELLOW}Consider: sudo sysctl -w net.ipv4.ip_forward=1${NC}"
fi

# Check shared memory limits
SHM_MAX=$(cat /proc/sys/kernel/shmmax)
if [ "$SHM_MAX" -lt 68719476736 ]; then  # 64GB
    echo -e "${YELLOW}Warning: kernel.shmmax may be too low for high performance${NC}"
    echo -e "${YELLOW}Consider: sudo sysctl -w kernel.shmmax=68719476736${NC}"
fi

# Check max number of file-handles
FILE_MAX=$(cat /proc/sys/fs/file-max)
if [ "$FILE_MAX" -lt 2097152 ]; then  # 2M
    echo -e "${YELLOW}Warning: fs.file-max may be too low${NC}"
    echo -e "${YELLOW}Consider: sudo sysctl -w fs.file-max=2097152${NC}"
fi

# Check max watched files limit
INOTIFY_WATCHES=$(cat /proc/sys/fs/inotify/max_user_watches)
if [ "$INOTIFY_WATCHES" -lt 524288 ]; then  # 512K
    echo -e "${YELLOW}Warning: fs.inotify.max_user_watches may be too low${NC}"
    echo -e "${YELLOW}Consider: sudo sysctl -w fs.inotify.max_user_watches=524288${NC}"
fi

# Check network connection handling
SOMAXCONN=$(cat /proc/sys/net/core/somaxconn)
if [ "$SOMAXCONN" -lt 65535 ]; then
    echo -e "${YELLOW}Warning: net.core.somaxconn may be too low${NC}"
    echo -e "${YELLOW}Consider: sudo sysctl -w net.core.somaxconn=65535${NC}"
fi

# Check for development dependencies if in dev mode
if [ "$DEPLOY_ENV" = "development" ]; then
    echo "Checking development dependencies..."
    
    # Check Git
    if ! command -v git &>/dev/null; then
        echo -e "${RED}Error: Git is not installed${NC}"
        exit 1
    fi
    
    # Check git config
    if ! git config --get user.name >/dev/null || ! git config --get user.email >/dev/null; then
        echo -e "${YELLOW}Warning: Git user.name or user.email not configured${NC}"
        echo -e "${YELLOW}Run: git config --global user.name \"Your Name\"${NC}"
        echo -e "${YELLOW}     git config --global user.email \"your.email@example.com\"${NC}"
    fi
    
    # Check pre-commit hooks
    if [ ! -f ".git/hooks/pre-commit" ]; then
        echo -e "${YELLOW}Warning: Git pre-commit hooks not installed${NC}"
    fi
fi

# Create logging directories with proper permissions
echo "Setting up logging directories..."
LOG_DIRS=(
    "./volumes/log/api"
    "./volumes/log/worker"
    "./volumes/log/web"
    "./volumes/log/nginx"
    "./volumes/log/redis"
    "./volumes/log/elasticsearch"
    "./volumes/log/milvus"
)

for dir in "${LOG_DIRS[@]}"; do
    mkdir -p "$dir"
    chmod 755 "$dir"
    echo -e "${GREEN}Created log directory: $dir${NC}"
done

# Environment variables check
# Check system limits
echo "Checking system limits..."
current_nofile=$(ulimit -n)
if [ "$current_nofile" -lt 65536 ]; then
    echo -e "${YELLOW}Warning: Current file descriptor limit ($current_nofile) is less than recommended (65536)${NC}"
    echo -e "${YELLOW}Consider increasing with: ulimit -n 65536${NC}"
fi

# Check system memory limits
if [ -f "/proc/sys/vm/max_map_count" ]; then
    max_map_count=$(cat /proc/sys/vm/max_map_count)
    if [ "$max_map_count" -lt 262144 ]; then
        echo -e "${YELLOW}Warning: vm.max_map_count ($max_map_count) is less than recommended (262144)${NC}"
        echo -e "${YELLOW}Consider setting: sysctl -w vm.max_map_count=262144${NC}"
    fi
fi

echo "Checking environment variables..."
if [ -f .env ]; then
    echo -e "${GREEN}Found .env file - OK${NC}"
else
    echo -e "${YELLOW}Warning: No .env file found. Will use default values.${NC}"
fi

# Additional service port checks
echo "Checking additional service ports..."
additional_ports=(9200 5601 9000 9091 2379)
for port in "${additional_ports[@]}"; do
    if netstat -tuln | grep -q ":$port "; then
        echo -e "${YELLOW}Warning: Port $port is already in use${NC}"
    else
        echo -e "${GREEN}Port $port is available - OK${NC}"
    fi
done

# Check for SSL certificates if HTTPS is enabled
if [ -d "./docker/nginx/ssl" ]; then
    echo "Checking SSL certificates..."
    if [ -f "./docker/nginx/ssl/cert.pem" ] && [ -f "./docker/nginx/ssl/key.pem" ]; then
        echo -e "${GREEN}SSL certificates found - OK${NC}"
    else
        echo -e "${YELLOW}Warning: SSL directory exists but certificates are missing${NC}"
    fi
fi

# Check deployment environment
echo "Checking deployment environment..."
if [ -z "$DEPLOY_ENV" ]; then
    echo -e "${YELLOW}Warning: DEPLOY_ENV not set, will use default (PRODUCTION)${NC}"
else
    echo -e "${GREEN}Deployment environment: $DEPLOY_ENV - OK${NC}"
fi

# Check OpenAI API configuration
echo "Checking API configuration..."
if [ -z "$OPENAI_API_BASE" ]; then
    echo -e "${YELLOW}Warning: OPENAI_API_BASE not set, will use default${NC}"
else
    echo -e "${GREEN}OpenAI API Base URL configured - OK${NC}"
fi

# Initialize database if in development mode
if [ "$DEPLOY_ENV" = "development" ]; then
    echo "Initializing development database..."
    ./scripts/initialize_database.sh
fi

echo -e "${GREEN}Environment verification completed!${NC}"