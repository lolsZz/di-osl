# Dify Development Setup Guide

This guide provides comprehensive instructions for setting up Dify for development purposes. It covers both frontend and backend setup, as well as additional components like LLM Models and Tool Integration.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Setup](#backend-setup)
3. [Frontend Setup](#frontend-setup)
4. [LLM Models Integration](#llm-models-integration)
5. [Tool Development](#tool-development)
6. [Testing](#testing)

## Prerequisites

Before starting the development setup, ensure you have the following installed:
- Docker and Docker Compose
- Node.js (v18 or higher)
- Python (v3.10 or higher)
- Git

## Backend Setup

### 1. Environment Setup
1. Clone the repository
2. Navigate to the `api` directory
3. Create and activate a Python virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows, use `venv\Scripts\activate`
   ```
4. Install dependencies:
   ```bash
   pip install -r requirements.txt
   pip install -r requirements-dev.txt
   ```

### 2. Configuration
1. Start the docker-compose stack for required services:
   ```bash
   docker-compose -f docker-compose.yaml up -d redis postgres weaviate
   ```
2. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
3. Generate a `SECRET_KEY` and add it to the `.env` file
4. Configure the database connection in `.env`

### 3. Database Setup
Run database migrations:
```bash
flask db upgrade
```

### 4. Running the Backend
Start the development server:
```bash
flask run --host 0.0.0.0 --port 5001 --debug
```

## Frontend Setup

### 1. Environment Setup
1. Navigate to the `web` directory
2. Install dependencies:
   ```bash
   npm install
   ```

### 2. Configuration
1. Copy the example environment file:
   ```bash
   cp .env.example .env.local
   ```
2. Configure the environment variables in `.env.local`

### 3. Running the Frontend
Start the development server:
```bash
npm run dev
```

The frontend will be available at http://localhost:3000

## LLM Models Integration

The project supports various LLM capabilities:
- Text completion
- Dialogue
- Embeddings
- Speech to text
- Text to speech

Refer to `api/core/model_runtime/README.md` for detailed implementation instructions.

## Tool Development

### Quick Tool Integration
For basic tool integration:
1. Prepare the Tool Provider YAML
2. Set up Provider Credentials
3. Create Tool YAML configuration
4. Implement Tool Logic
5. Add Provider Code

### Advanced Tool Integration
For advanced features:
- Message handling (Text, Image URLs, Links, File BLOBs, JSON)
- Variable pool usage
- Integration with external services

## Testing

### Backend Testing
1. Install test dependencies:
   ```bash
   pip install -r requirements-test.txt
   ```
2. Run tests:
   ```bash
   pytest
   ```

### Frontend Testing
1. Run linting:
   ```bash
   npm run lint
   ```
2. Run tests:
   ```bash
   npm test
   ```

## Development Best Practices

1. Always work in a feature branch
2. Write tests for new features
3. Follow the project's coding style guidelines
4. Document new features and changes
5. Run linting and tests before submitting PRs

## Troubleshooting

Common issues and their solutions will be documented here as they are encountered during development.

---

This guide will be regularly updated with new information and best practices as the project evolves.