# Dify Setup Requirements and Configuration Guide

## System Requirements

### Mandatory Requirements
- Docker Engine
- Docker Compose
- Python 3.10 or higher
- Node.js v18 or higher

### Hardware Requirements
- Minimum RAM: 8GB (recommended: 16GB+)
- Storage: At least 20GB free space
- CPU: 4 cores minimum (recommended: 8 cores)

## Service Versions

### Core Services
- API: langgenius/dify-api:0.14.2
- Web: langgenius/dify-web:0.14.2
- Worker: langgenius/dify-api:0.14.2 (same as API)
- Sandbox: langgenius/dify-sandbox:0.2.10

### Database Services
- PostgreSQL: 15-alpine
- Redis: 6-alpine
- PGVector: pgvector/pgvector:pg16
- PGVecto.rs: tensorchord/pgvecto-rs:pg16-v0.3.0
- TiDB: pingcap/tidb:v8.4.0
- Oracle: container-registry.oracle.com/database/free:latest
- OceanBase: oceanbase-ce:4.3.3.0
- Couchbase: Custom build from ./couchbase-server

### Vector Stores
- Weaviate: semitechnologies/weaviate:1.19.0
- Qdrant: langgenius/qdrant:v1.7.3
- Chroma: chroma-core/chroma:0.5.20
- Milvus Components:
  - Etcd: default latest
  - MinIO: default latest
  - Standalone: default latest

### Search and Analytics
- OpenSearch: default latest
- OpenSearch Dashboards: default latest
- Elasticsearch: elasticsearch:8.14.3
- Kibana: kibana:8.14.3

### Support Services
- SSRF Proxy: ubuntu/squid:latest
- Certbot: certbot/certbot:latest
- Nginx: nginx:latest
- Unstructured API: unstructured-io/unstructured-api:latest

## Environment Setup

### Database Requirements
- PostgreSQL 15 (automatically set up via Docker)
  - Default credentials:
    - Username: postgres
    - Password: difyai123456
  - Configurable via environment variables:
    - DB_USERNAME
    - DB_PASSWORD
    - DB_HOST
    - DB_PORT
    - DB_DATABASE
  - Health check: pg_isready command
  - Connection pool size: SQLALCHEMY_POOL_SIZE (default: 30)
- TiDB (optional)
  - Version: v8.4.0
  - Compatible with MySQL protocol
  - Recommended for high-concurrency scenarios
  - Port: 4000
- Oracle Database (optional)
  - Free edition available
  - Requires oradata volume
  - Default password: Dify123456
  - Configurable via ORACLE_PWD
  - Persistence through oradata volume
- OceanBase (optional)
  - Version: CE 4.3.3
  - Memory limit configurable (default: 6G)
  - Configurable via OB_MEMORY_LIMIT
  - High availability features
- Couchbase (optional)
  - Custom build available
  - Username: Administrator
  - Default password configurable
  - Health check via HTTP endpoint
  - Port: 8091

### Cache and Message Queue
- Redis 6
  - Default password: difyai123456
  - Configurable via REDIS_PASSWORD

### Vector Database Options
- pgvector (default)
  - Built on PostgreSQL 15
  - No additional configuration required
- Weaviate
  - Default persistence path: /var/lib/weaviate
  - Environment specific configuration available
- Qdrant
  - Default API key: difyai123456
  - Configurable via QDRANT_API_KEY
- Milvus
  - Requires additional services:
    - Etcd (default endpoint: etcd:2379)
    - MinIO (default credentials: minioadmin)
    - Standalone Milvus instance
- Chroma
  - Authentication credentials required
  - Default: difyai123456
- OpenSearch
  - Single-node discovery by default
  - Configurable memory limits
  - Dashboard included
- Elastic Search
  - Version: 8.14.3
  - Default password: elastic
  - Includes Kibana dashboard

### Logging Configuration
- Log settings:
  - LOG_LEVEL (default: INFO)
  - LOG_FILE (default: /app/logs/server.log)
  - LOG_FILE_MAX_SIZE (default: 20MB)
  - LOG_FILE_BACKUP_COUNT (default: 5)
  - LOG_DATEFORMAT (default: %Y-%m-%d %H:%M:%S)
  - LOG_TZ (default: UTC)

### Monitoring and Error Tracking
- Sentry Integration:
  - API_SENTRY_DSN
  - API_SENTRY_TRACES_SAMPLE_RATE (default: 1.0)
  - API_SENTRY_PROFILES_SAMPLE_RATE (default: 1.0)
  - WEB_SENTRY_DSN
- Debug Options:
  - DEBUG (default: false)
  - FLASK_DEBUG (default: false)
- Health Check Endpoints:
  - Database: pg_isready
  - Redis: ping
  - SSRF Proxy: curl health check
  - Milvus: healthz endpoint
  - Elasticsearch: cluster health

### Security Configuration
- Required environment variables:
  - SECRET_KEY (default: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)
  - SANDBOX_API_KEY (default: dify-sandbox)
  - CONSOLE_API_URL
  - SERVICE_API_URL
  - APP_API_URL
- Authentication:
  - Access token expiry: ACCESS_TOKEN_EXPIRE_MINUTES (default: 60)
  - Refresh token expiry: REFRESH_TOKEN_EXPIRE_DAYS (default: 30)
  - Initial password: Configurable via INIT_PASSWORD
  - Kibana encryption key: d1a66dfd-c4d3-4a0a-8290-2abcb83ab3aa (default)
- API Security:
  - App max active requests: APP_MAX_ACTIVE_REQUESTS (default: 0)
  - App max execution time: APP_MAX_EXECUTION_TIME (default: 1200)
  - Rate limiting: Configurable per endpoint
- Database Security:
  - PostgreSQL authentication
  - Redis password protection
  - Qdrant API key
  - Chroma authentication
  - Elasticsearch security
  - MyScale authentication
  - Clickhouse authentication
- SSL/TLS:
  - Certbot integration available
  - Nginx SSL configuration
  - Certificate auto-renewal
  - Custom certificate support
- Network Security:
  - Service network isolation
  - SSRF protection
  - CSP Whitelist: Configurable via CSP_WHITELIST
- Service Restart Policies:
  - Core services: always
  - Optional services: Configurable
  - Certbot: no
- Access Control:
  - Service-specific API keys
  - Role-based access control
  - IP whitelisting support

### Storage Configuration
- Default storage path: ./volumes/app/storage
- Ensure write permissions for the storage directory

### Network Configuration and Isolation
- Dedicated Networks:
  - ssrf_proxy_network:
    - Purpose: Secure external request handling
    - Services: API, Worker, SSRF Proxy
    - Isolation: Complete from other services
  - default:
    - Purpose: Internal service communication
    - Services: All core services
    - Access: Internal only
  - elastic:
    - Purpose: Elasticsearch cluster communication
    - Services: Elasticsearch, Kibana
    - Isolation: Strict for search services
  - vector_store:
    - Purpose: Vector database communication
    - Services: Vector stores and dependencies
    - Access: Limited to specific services

- Network Security:
  - Internal Networks:
    - No external access
    - Service-specific communication only
  - External Access:
    - Through SSRF proxy only
    - Rate limited and monitored
  - Network Policies:
    - Default deny
    - Explicit allow rules
    - Service-specific access

### Network Configuration
- Default ports:
  - API: 5001 (configurable via DIFY_PORT)
  - Web: 3000
  - Database: 5432
  - Redis: 6379
  - OpenSearch: 9200
  - Kibana: 5601
  - MinIO: 9000
  - Milvus: 9091
  - Elasticsearch: 9200
  - Etcd: 2379
  - Weaviate: default port
  - SSRF proxy: 3128 (configurable via SSRF_HTTP_PORT)
  - Couchbase: 8091
  - TiDB: 4000
  - Unstructured API: default port
  - MyScale: configurable
- Networks:
  - ssrf_proxy_network: Used for secure external requests
    - Purpose: Secure outbound connections
    - Used by: API and worker services
  - default: Internal service communication
    - Purpose: Main service communication
    - Connects: All core services
  - elastic: Elasticsearch-specific network
    - Purpose: Elasticsearch and Kibana communication
    - Isolation: Separate from main network
- URL Configuration:
  - CONSOLE_API_URL: Core API endpoint
  - CONSOLE_WEB_URL: Web interface URL
  - SERVICE_API_URL: Service API endpoint
  - APP_API_URL: Application API URL
  - APP_WEB_URL: Application web interface
  - FILES_URL: File access endpoint
- Binding and Port Configuration:
  - DIFY_BIND_ADDRESS: Bind address (default: 0.0.0.0)
  - DIFY_PORT: API port (default: 5001)
- Additional Services:
  - Nginx (optional)
    - Configurable server name via NGINX_SERVER_NAME
    - SSL support via Certbot
    - Custom configuration options
  - Certbot for SSL (optional)
    - Automatic certificate renewal
    - Volume mounts for persistent certificates
    - Integration with Nginx

### File Processing
- Unstructured API Service:
  - Purpose: File processing and content extraction
  - Image: unstructured-api:latest
  - Configuration via environment variables

### Text Generation
- Timeout settings:
  - TEXT_GENERATION_TIMEOUT_MS (default: 60000)
- Model parameters:
  - TOP_K_MAX_VALUE configurable

### Deployment Environment
- Environment Variables:
  - DEPLOY_ENV: Set deployment environment (default: PRODUCTION)
  - CHECK_UPDATE_URL: Update check endpoint (default: https://updates.dify.ai)
  - MIGRATION_ENABLED: Enable/disable migrations (default: true)

### API Configuration
- OpenAI Settings:
  - OPENAI_API_BASE: API base URL (default: https://api.openai.com/v1)
- Sandbox Configuration:
  - SANDBOX_API_KEY: API key for sandbox (default: dify-sandbox)
  - Custom sandbox endpoints configurable

### Telemetry and Updates
- Telemetry Settings:
  - NEXT_TELEMETRY_DISABLED: Control telemetry (default: 0)
- Update Checking:
  - CHECK_UPDATE_URL: Configure update checks
  - Can be disabled or customized

### Service Startup and Recovery
- Restart Policies:
  - Core services (API, Worker, Web): always
  - Databases (PostgreSQL, Redis): always
  - Vector stores: always
  - Support services: Configurable
- Startup Order:
  1. Databases (PostgreSQL, Redis)
  2. Vector stores and search services
  3. API service
  4. Worker service
  5. Web interface
  6. Support services
- Healthcheck Intervals:
  - PostgreSQL: 10s
  - Redis: 5s
  - Elasticsearch: 10s
  - API: 30s
  - Worker: 30s
  - Vector stores: Varies by service

### Health Check Configuration
- Check Intervals:
  - Critical Services (PostgreSQL, Redis):
    - Interval: 5s
    - Timeout: 3s
    - Retries: 3
  - Core Services (API, Worker):
    - Interval: 30s
    - Timeout: 10s
    - Retries: 5
  - Vector Stores:
    - Interval: 10s
    - Timeout: 5s
    - Retries: 3
  - Support Services:
    - Interval: 60s
    - Timeout: 10s
    - Retries: 3

### Service Health Checks
- API & Worker Services:
  - Health endpoint check
  - Dependent on: db, redis
- Database Services:
  - PostgreSQL: pg_isready command
  - Redis: redis-cli ping
  - TiDB: TCP connection check
  - OceanBase: Custom health check script
  - Couchbase: HTTP endpoint check (port 8091)
- Vector Stores:
  - Milvus: healthz endpoint check
  - Weaviate: HTTP health check
  - Qdrant: Built-in health check
  - Chroma: HTTP endpoint verification
- Search Services:
  - Elasticsearch: Cluster health check via HTTP
  - OpenSearch: Cluster status verification
  - Kibana: HTTP endpoint check
- Support Services:
  - SSRF Proxy: curl health check
  - Nginx: HTTP response check
  - MinIO: Health check endpoint verification

### Shared Environment Variables
Core variables shared between API and worker services:
- URLs and Endpoints:
  - CONSOLE_API_URL
  - CONSOLE_WEB_URL
  - SERVICE_API_URL
  - APP_API_URL
  - APP_WEB_URL
  - FILES_URL
- Logging Configuration:
  - LOG_LEVEL
  - LOG_FILE
  - LOG_FILE_MAX_SIZE
  - LOG_FILE_BACKUP_COUNT
  - LOG_DATEFORMAT
  - LOG_TZ
- Debug Settings:
  - DEBUG
  - FLASK_DEBUG
- Security:
  - SECRET_KEY
  - INIT_PASSWORD
- Deployment:
  - DEPLOY_ENV
  - CHECK_UPDATE_URL
  - MIGRATION_ENABLED
- Timings and Limits:
  - FILES_ACCESS_TIMEOUT
  - ACCESS_TOKEN_EXPIRE_MINUTES
  - REFRESH_TOKEN_EXPIRE_DAYS
  - APP_MAX_ACTIVE_REQUESTS
  - APP_MAX_EXECUTION_TIME

### Production Deployment Recommendations
- File Systems:
  - Read-only root filesystem where possible
  - Separate volumes for data and logs
  - Proper permission settings for data directories
- Resource Management:
  - Set memory and CPU limits for all services
  - Enable swap limitation
  - Configure OOM priority
- Network Security:
  - Use internal DNS for service discovery
  - Enable TLS for all services
  - Configure proper network policies
- High Availability:
  - Use replicated services where possible
  - Configure proper failover settings
  - Implement proper backup strategies
- Monitoring:
  - Enable detailed logging
  - Set up metrics collection
  - Configure proper alerting

### DNS Configuration
- Service Discovery:
  - Internal DNS resolution
  - Custom DNS servers configurable
  - Search domains configuration
- DNS Options:
  - ndots: 5
  - timeout: 2s
  - attempts: 3
  - rotate: enabled
- Name Resolution:
  - Service names
  - Internal domains
  - External endpoints

### Container Configuration
- Resource Limits:
  - OpenSearch:
    - memlock: soft and hard limits (-1)
    - nofile: 65536
    - memory: Configurable via environment
  - Elasticsearch:
    - memory: "1g"
    - memlock: unlimited
  - Redis:
    - memory: "512M"
  - API & Worker:
    - memory: "2G"
    - cpus: "1"

- User Configurations:
  - OpenSearch: nobody
  - Elasticsearch: nobody
  - API/Worker: Default
  - Web: Default
  - Redis: redis

- Command Overrides:
  - TiDB: ["--store=unistore", "--path=/data/tidb"]
  - OpenSearch: ["opensearch-plugin", "install", "-b", "repository-plugins"]
  - Certbot: ["renew"]

- Logging Configuration:
  - Driver: json-file
  - Options:
    - max-size: "10m"
    - max-file: "3"

### MyScale Configuration
- Environment:
  - CLICKHOUSE_USER: default
  - CLICKHOUSE_PASSWORD: password
- Volumes:
  - Data persistence: /var/lib/clickhouse
  - Logs: /var/log/clickhouse-server
- Ports:
  - HTTP Interface: 8123
  - TCP Interface: 9000
- Resource Limits:
  - Memory: Configurable
  - CPU: Configurable

### Service Dependencies
- API Service depends on:
  - Database (PostgreSQL)
  - Redis
  - Storage volume mounted
- Worker Service depends on:
  - Database (PostgreSQL)
  - Redis
  - Storage volume mounted
- Vector Stores:
  - Milvus requires:
    - Etcd
    - MinIO
  - Elasticsearch requires:
    - Dedicated network
    - Volume for data persistence
- Web Service:
  - Independent operation
  - Requires API service for functionality

### Volume Persistence
- Application Storage:
  - Path: ./volumes/app/storage
  - Used by: API and worker services
  - Purpose: User file storage
- Database Data:
  - PostgreSQL: ./volumes/db/data
  - Redis: ./volumes/redis/data
  - Elasticsearch: ./volumes/elasticsearch/data
- Vector Store Data:
  - Weaviate: ./volumes/weaviate
  - Qdrant: ./volumes/qdrant
  - Milvus: ./volumes/milvus
- Certificate Storage:
  - SSL Certificates: ./volumes/nginx/ssl
  - Certbot: ./volumes/certbot

### Performance Tuning
- Server Configuration:
  - Server workers: Configure via SERVER_WORKER_AMOUNT
  - Server worker class: Configurable via SERVER_WORKER_CLASS
  - Connection pool size: SQLALCHEMY_POOL_SIZE (default: 30)
- Celery Configuration:
  - Worker amount: Configure via CELERY_WORKER_AMOUNT
  - Worker class: Configurable via CELERY_WORKER_CLASS
  - Auto scaling: Enable via CELERY_AUTO_SCALE
  - Max workers: Set via CELERY_MAX_WORKERS
  - Min workers: Set via CELERY_MIN_WORKERS
- Timeouts:
  - Gunicorn: GUNICORN_TIMEOUT (default: 360s)
  - API tool connect: API_TOOL_DEFAULT_CONNECT_TIMEOUT (default: 10s)
  - API tool read: API_TOOL_DEFAULT_READ_TIMEOUT (default: 60s)
  - Files access: FILES_ACCESS_TIMEOUT (default: 300s)
- Memory Limits:
  - OpenSearch: Configurable soft/hard limits
  - OceanBase: Configurable via OB_MEMORY_LIMIT
  - Elasticsearch: Configurable heap size

## Pre-installation Steps
1. Ensure all system requirements are met
2. Configure environment variables or accept defaults
3. Ensure sufficient system resources
4. Configure firewall rules for required ports
5. Set up SSL certificates if needed (optional)

## Post-installation Verification
1. Check all services are running:
   ```bash
   docker-compose ps
   ```
2. Verify database connectivity
3. Test Redis connection
4. Validate API accessibility
5. Check web interface
6. Verify storage permissions

## Troubleshooting
- Check logs: docker-compose logs [service_name]
- Verify environment variables
- Ensure all required ports are available
- Check system resources
- Verify network connectivity

## Additional Documentation
- For advanced configuration options, refer to docker-compose.yaml
- For development setup, see dev/development_workflow.md
- For custom deployment scenarios, consult CONTRIBUTING.md