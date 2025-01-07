#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Dify development environment...${NC}"

# Create development environment file
cat > .env.development << EOF
# Development environment settings
FLASK_ENV=development
FLASK_DEBUG=1
DEBUG=true

# Database settings
DB_DATABASE=dify_dev
DB_USERNAME=dify_dev
DB_PASSWORD=dify_dev_pass
DB_HOST=localhost
DB_PORT=5432

# Redis settings
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=dify_dev_pass

# Development specific settings
NEXT_TELEMETRY_DISABLED=1
DEPLOY_ENV=development
CHECK_UPDATE_URL=

# API settings
API_SENTRY_DSN=
WEB_SENTRY_DSN=
EOF

# Set up Python development environment
echo "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install development dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Set up pre-commit hooks
echo "Setting up Git pre-commit hooks..."
if [ ! -f ".git/hooks/pre-commit" ]; then
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Run linting
echo "Running flake8..."
flake8 app tests || exit 1

echo "Running black..."
black --check app tests || exit 1

echo "Running isort..."
isort --check-only app tests || exit 1

# Run tests
echo "Running tests..."
python -m pytest tests/ || exit 1
EOF
    chmod +x .git/hooks/pre-commit
fi

# Configure Git for development
echo "Configuring Git..."
if ! git config --get user.name >/dev/null; then
    echo -e "${YELLOW}Git user.name not configured${NC}"
    read -p "Enter your name for Git: " git_name
    git config --global user.name "$git_name"
fi

if ! git config --get user.email >/dev/null; then
    echo -e "${YELLOW}Git user.email not configured${NC}"
    read -p "Enter your email for Git: " git_email
    git config --global user.email "$git_email"
fi

# Create development database
echo "Setting up development database..."
if ! psql -h localhost -U postgres -lqt | cut -d \| -f 1 | grep -qw dify_dev; then
    psql -h localhost -U postgres << EOF
CREATE DATABASE dify_dev;
CREATE USER dify_dev WITH PASSWORD 'dify_dev_pass';
GRANT ALL PRIVILEGES ON DATABASE dify_dev TO dify_dev;
EOF
fi

# Run database migrations
echo "Running database migrations..."
flask db upgrade

echo -e "${GREEN}Development environment setup completed!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Start development services: docker-compose -f docker-compose.dev.yml up -d"
echo "2. Run API server: flask run --debug"
echo "3. Run worker: celery -A app.celery worker --loglevel=info"
echo "4. Run web server: npm run dev"