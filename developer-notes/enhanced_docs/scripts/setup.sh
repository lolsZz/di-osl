#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Dify Development Environment Setup...${NC}"

# Run comprehensive environment verification
echo "Running environment verification..."
./verify_environment.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}Environment verification failed. Please check the requirements and try again.${NC}"
    echo -e "${YELLOW}Refer to SETUP_REQUIREMENTS.md for detailed requirements and troubleshooting.${NC}"
    exit 1
fi

echo -e "${GREEN}Environment verification passed. Proceeding with setup...${NC}"

# Backend Setup
echo "Setting up backend..."
cd api

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt
pip install -r requirements-test.txt

# Copy environment file
cp .env.example .env

# Generate SECRET_KEY
SECRET_KEY=$(python -c 'import secrets; print(secrets.token_hex(32))')
sed -i.bak "s/^SECRET_KEY=.*$/SECRET_KEY=$SECRET_KEY/" .env

# Start Docker services
docker-compose -f docker-compose.yaml up -d redis postgres weaviate

# Run database migrations
flask db upgrade

echo -e "${GREEN}Backend setup completed.${NC}"

# Frontend Setup
echo "Setting up frontend..."
cd ../web

# Install dependencies
npm install

# Copy environment file
cp .env.example .env.local

echo -e "${GREEN}Frontend setup completed.${NC}"

echo -e "${GREEN}Setup complete! You can now start the development servers:${NC}"
echo "Backend: cd api && flask run --host 0.0.0.0 --port 5001 --debug"
echo "Frontend: cd web && npm run dev"